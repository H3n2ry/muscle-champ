-- Conformidade LGPD (BR) + GDPR (UE) + Google Play Data Deletion
--
-- 1) Tabela user_consents — registro auditável de consentimento por finalidade
-- 2) handle_new_user passa a gravar os consentimentos dados no cadastro
-- 3) export_my_data()   — LGPD Art. 18 V / GDPR Art. 15 e 20 (acesso + portabilidade)
-- 4) delete_my_account() — LGPD Art. 18 VI / GDPR Art. 17 + exigência do Google Play
-- 5) revoke_consent() / grant_consent() — GDPR Art. 7(3), revogação tão fácil quanto dar
--
-- Revisar e aplicar no projeto jryetjysjiyuuoznaejc.

-- ── 1) Registro de consentimento ───────────────────────────────────────────
-- Uma linha por (usuário, finalidade, versão). Nunca fazemos UPDATE destrutivo:
-- revogar grava revoked_at, mantendo a trilha de auditoria exigida pelo
-- princípio da responsabilização (LGPD Art. 6 X / GDPR Art. 5(2)).
CREATE TABLE IF NOT EXISTS public.user_consents (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_type  text NOT NULL CHECK (consent_type = ANY (ARRAY[
                  'terms',              -- Termos de Uso
                  'privacy',            -- Política de Privacidade
                  'health_data',        -- dado sensível — LGPD Art. 11 / GDPR Art. 9
                  'ai_photo_transfer',  -- envio de foto à Groq (EUA) — transf. internacional
                  'marketing'           -- opcional, não bloqueia o uso do app
                ])),
  document_version text NOT NULL,       -- ex: '2026-08-17' — casa com LegalTexts.version
  granted       boolean NOT NULL,
  granted_at    timestamptz NOT NULL DEFAULT now(),
  revoked_at    timestamptz,
  locale        text,                   -- idioma em que o texto foi aceito
  source        text NOT NULL DEFAULT 'signup'
                  CHECK (source = ANY (ARRAY['signup','settings','reconsent']))
);

CREATE INDEX IF NOT EXISTS idx_user_consents_user_type
  ON public.user_consents (user_id, consent_type, granted_at DESC);

ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_consents_select_own ON public.user_consents;
CREATE POLICY user_consents_select_own ON public.user_consents
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS user_consents_insert_own ON public.user_consents;
CREATE POLICY user_consents_insert_own ON public.user_consents
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Sem policy de UPDATE/DELETE: a trilha de consentimento é append-only.
-- Revogação passa por revoke_consent(), que grava uma nova linha.

-- ── 2) Cadastro grava os consentimentos ────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
  v_version text := COALESCE(NEW.raw_user_meta_data->>'consent_version', 'unknown');
  v_locale  text := NEW.raw_user_meta_data->>'consent_locale';
BEGIN
  INSERT INTO public.profiles (id, name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', 'Usuário'))
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.goals (
    user_id, goal_type, height_cm, current_weight, target_weight,
    weekly_workout_goal, birth_date)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'goal_type', 'maintain'),
    COALESCE((NEW.raw_user_meta_data->>'height_cm')::double precision, 170),
    COALESCE((NEW.raw_user_meta_data->>'current_weight')::double precision, 70),
    COALESCE((NEW.raw_user_meta_data->>'target_weight')::double precision, 70),
    COALESCE((NEW.raw_user_meta_data->>'weekly_workout_goal')::int, 3),
    (NEW.raw_user_meta_data->>'birth_date')::date
  )
  ON CONFLICT (user_id) DO NOTHING;

  -- Consentimentos obrigatórios + o opcional de marketing.
  -- O app envia estas flags em raw_user_meta_data no signUp().
  INSERT INTO public.user_consents
    (user_id, consent_type, document_version, granted, locale, source)
  SELECT NEW.id, t.consent_type, v_version, t.granted, v_locale, 'signup'
  FROM (VALUES
    ('terms',             COALESCE((NEW.raw_user_meta_data->>'consent_terms')::boolean, false)),
    ('privacy',           COALESCE((NEW.raw_user_meta_data->>'consent_privacy')::boolean, false)),
    ('health_data',       COALESCE((NEW.raw_user_meta_data->>'consent_health')::boolean, false)),
    ('ai_photo_transfer', COALESCE((NEW.raw_user_meta_data->>'consent_ai_photo')::boolean, false)),
    ('marketing',         COALESCE((NEW.raw_user_meta_data->>'consent_marketing')::boolean, false))
  ) AS t(consent_type, granted);

  RETURN NEW;
END;
$$;

-- ── 3) Exportação de dados (acesso + portabilidade) ────────────────────────
-- LGPD Art. 18, incisos II e V · GDPR Art. 15 e Art. 20.
-- Retorna TUDO que o app guarda sobre o titular, em formato legível por máquina.
CREATE OR REPLACE FUNCTION public.export_my_data()
 RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_out jsonb;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT jsonb_build_object(
    'export_generated_at', now(),
    'export_format_version', 2,
    'account', (
      SELECT jsonb_build_object('id', u.id, 'email', u.email,
                                'created_at', u.created_at,
                                'last_sign_in_at', u.last_sign_in_at)
      FROM auth.users u WHERE u.id = v_uid),
    'profile',             (SELECT to_jsonb(p) FROM public.profiles p WHERE p.id = v_uid),
    'goals',               (SELECT to_jsonb(g) FROM public.goals g WHERE g.user_id = v_uid),
    'consents',            COALESCE((SELECT jsonb_agg(to_jsonb(c) ORDER BY c.granted_at)
                                     FROM public.user_consents c WHERE c.user_id = v_uid), '[]'::jsonb),
    'weight_logs',         COALESCE((SELECT jsonb_agg(to_jsonb(w) ORDER BY w.date)
                                     FROM public.weight_logs w WHERE w.user_id = v_uid), '[]'::jsonb),
    'bioimpedance_logs',   COALESCE((SELECT jsonb_agg(to_jsonb(b) ORDER BY b.measured_at)
                                     FROM public.bioimpedance_logs b WHERE b.user_id = v_uid), '[]'::jsonb),
    'diet_logs',           COALESCE((SELECT jsonb_agg(to_jsonb(d) ORDER BY d.date)
                                     FROM public.diet_logs d WHERE d.user_id = v_uid), '[]'::jsonb),
    'water_logs',          COALESCE((SELECT jsonb_agg(to_jsonb(wl) ORDER BY wl.date)
                                     FROM public.water_logs wl WHERE wl.user_id = v_uid), '[]'::jsonb),
    -- Workouts (legado) carregam seus exercises aninhados — portabilidade
    -- precisa ser completa (LGPD Art. 18 V / GDPR Art. 20)
    'workouts',            COALESCE((SELECT jsonb_agg(jsonb_build_object(
                                       'workout', to_jsonb(wo),
                                       'exercises', COALESCE((SELECT jsonb_agg(to_jsonb(ex) ORDER BY ex.created_at)
                                                              FROM public.exercises ex
                                                              WHERE ex.workout_id = wo.id), '[]'::jsonb))
                                     ORDER BY wo.date)
                                     FROM public.workouts wo WHERE wo.user_id = v_uid), '[]'::jsonb),
    'workout_templates',   COALESCE((SELECT jsonb_agg(jsonb_build_object(
                                       'template', to_jsonb(t),
                                       'exercises', COALESCE((SELECT jsonb_agg(to_jsonb(te) ORDER BY te.order_index)
                                                              FROM public.template_exercises te
                                                              WHERE te.template_id = t.id), '[]'::jsonb)))
                                     FROM public.workout_templates t WHERE t.user_id = v_uid), '[]'::jsonb),
    'workout_completions', COALESCE((SELECT jsonb_agg(to_jsonb(wc) ORDER BY wc.completed_date)
                                     FROM public.workout_completions wc WHERE wc.user_id = v_uid), '[]'::jsonb),
    'points',              COALESCE((SELECT jsonb_agg(to_jsonb(pt) ORDER BY pt.created_at)
                                     FROM public.points pt WHERE pt.user_id = v_uid), '[]'::jsonb),
    'friendships',         COALESCE((SELECT jsonb_agg(to_jsonb(f) ORDER BY f.created_at)
                                     FROM public.friendships f
                                     WHERE f.user_id = v_uid OR f.friend_id = v_uid), '[]'::jsonb)
  ) INTO v_out;

  RETURN v_out;
END;
$$;

-- ── 4) Exclusão de conta ───────────────────────────────────────────────────
-- LGPD Art. 18 VI · GDPR Art. 17 · exigência do Google Play (Data deletion).
-- Apaga tudo e o próprio usuário do auth. Irreversível.
--
-- Deleta explicitamente tabela por tabela em vez de confiar em ON DELETE CASCADE:
-- nem todas as FKs do schema declaram a regra, então o cascade não é garantido.
CREATE OR REPLACE FUNCTION public.delete_my_account()
 RETURNS void
 LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Filhos antes dos pais
  DELETE FROM public.template_exercises te
   USING public.workout_templates t
   WHERE te.template_id = t.id AND t.user_id = v_uid;

  DELETE FROM public.exercises e
   USING public.workouts w
   WHERE e.workout_id = w.id AND w.user_id = v_uid;

  DELETE FROM public.workout_completions WHERE user_id = v_uid;
  DELETE FROM public.workout_templates   WHERE user_id = v_uid;
  DELETE FROM public.workouts            WHERE user_id = v_uid;
  DELETE FROM public.diet_logs           WHERE user_id = v_uid;
  DELETE FROM public.water_logs          WHERE user_id = v_uid;
  DELETE FROM public.weight_logs         WHERE user_id = v_uid;
  DELETE FROM public.bioimpedance_logs   WHERE user_id = v_uid;
  DELETE FROM public.points              WHERE user_id = v_uid;

  -- Amizades nos dois sentidos — o outro lado não pode ficar com um vínculo órfão
  DELETE FROM public.friendships WHERE user_id = v_uid OR friend_id = v_uid;

  DELETE FROM public.goals    WHERE user_id = v_uid;
  DELETE FROM public.profiles WHERE id = v_uid;

  -- O avatar NÃO é apagado aqui. O Postgres bloqueia DELETE direto em
  -- storage.objects (trigger storage.protect_delete) e, como tudo roda em uma
  -- transação, a função inteira abortaria e nada seria excluído.
  -- A remoção acontece no cliente, via Storage API, antes desta chamada —
  -- ver PrivacyRepository.deleteMyAccount().

  -- user_consents é apagado por CASCADE junto com auth.users.
  -- A trilha de consentimento morre com o titular: manter seria guardar dado
  -- pessoal de quem pediu exclusão, o que contraria o próprio Art. 18 VI.
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

-- ── 5) Conceder / revogar consentimento fora do cadastro ───────────────────
-- GDPR Art. 7(3): revogar tem que ser tão fácil quanto consentir.
CREATE OR REPLACE FUNCTION public.grant_consent(
  p_consent_type text, p_document_version text, p_locale text DEFAULT NULL)
 RETURNS void
 LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  INSERT INTO public.user_consents
    (user_id, consent_type, document_version, granted, locale, source)
  VALUES (v_uid, p_consent_type, p_document_version, true, p_locale, 'settings');
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_consent(p_consent_type text)
 RETURNS void
 LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_ver text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- terms/privacy não são revogáveis mantendo a conta: sem eles não há
  -- base legal para operar o serviço. O caminho é delete_my_account().
  IF p_consent_type IN ('terms', 'privacy') THEN
    RAISE EXCEPTION 'consent_required_for_service';
  END IF;

  SELECT document_version INTO v_ver
    FROM public.user_consents
   WHERE user_id = v_uid AND consent_type = p_consent_type
   ORDER BY granted_at DESC LIMIT 1;

  -- Marca a concessão vigente como revogada e grava a linha de revogação
  UPDATE public.user_consents
     SET revoked_at = now()
   WHERE user_id = v_uid AND consent_type = p_consent_type AND revoked_at IS NULL;

  INSERT INTO public.user_consents
    (user_id, consent_type, document_version, granted, source)
  VALUES (v_uid, p_consent_type, COALESCE(v_ver, 'unknown'), false, 'settings');
END;
$$;

-- ── Permissões ─────────────────────────────────────────────────────────────
-- Mesmo padrão do resto do schema: nada exposto a PUBLIC/anon.
REVOKE ALL ON FUNCTION public.export_my_data()     FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.delete_my_account()  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.grant_consent(text, text, text)  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.revoke_consent(text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.export_my_data()    TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
GRANT EXECUTE ON FUNCTION public.grant_consent(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_consent(text) TO authenticated;
