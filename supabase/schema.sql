-- Esquema completo do banco, extraído da PRODUÇÃO em 2026-08-27.
--
-- Existe porque a pasta migrations/ nunca foi um registro completo: produção
-- tinha 27 migrações e o repositório guardava 8. Reconstruir o banco a partir
-- dela deixaria de fora, entre outras coisas, as correções que consertaram o
-- cast de bigint no get_streak e a guarda do storage no delete_my_account —
-- ou seja, reintroduziria bugs já resolvidos.
--
-- A divisão a partir daqui:
--   * ESTE arquivo  = como o banco E hoje. E o que reproduz produção.
--   * migrations/   = registro do que MUDOU, daqui para frente.
--
-- Para regenerar depois de mexer no esquema, rode a consulta descrita em
-- CLAUDE.md (secão "Banco de dados") e substitua este arquivo inteiro.
--
-- O "set check_function_bodies = off;

-- ===== FUNCOES =====

CREATE OR REPLACE FUNCTION public._streak_de(p_uid uuid)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_hoje   date := public.app_today();
  v_ancora date;
  v_total  int;
begin
  select max(completed_date) into v_ancora
    from workout_completions
   where user_id = p_uid and completed_date <= v_hoje;

  if v_ancora is null or v_ancora < v_hoje - 1 then
    return 0;
  end if;

  select count(*) into v_total
  from (
    select completed_date,
           row_number() over (order by completed_date desc) as rn
    from (select distinct completed_date
            from workout_completions
           where user_id = p_uid and completed_date <= v_ancora) d
  ) t
  where completed_date = v_ancora - (rn - 1)::int;

  return coalesce(v_total, 0);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.app_today()
 RETURNS date
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$ SELECT (timezone('America/Sao_Paulo', now()))::date $function$
;

CREATE OR REPLACE FUNCTION public.assinar_demo(p_plano_id text, p_proxima_cobranca integer)
 RETURNS assinaturas
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_uid  uuid := auth.uid();
  v_linha public.assinaturas;
begin
  if v_uid is null then
    raise exception 'nao autenticado';
  end if;

  if p_plano_id not in ('mensal', 'trimestral', 'anual', 'lancamento') then
    raise exception 'plano invalido: %', p_plano_id;
  end if;

  if p_proxima_cobranca < 0 or p_proxima_cobranca > 100000 then
    raise exception 'valor invalido';
  end if;

  insert into public.assinaturas
    (user_id, plano_id, expira_em, em_trial, proxima_cobranca, atualizado_em)
  values (
    v_uid,
    p_plano_id,
    (app_today()::date + 14)::timestamptz,
    true,
    p_proxima_cobranca,
    now()
  )
  on conflict (user_id) do update set
    plano_id         = excluded.plano_id,
    expira_em        = excluded.expira_em,
    em_trial         = excluded.em_trial,
    proxima_cobranca = excluded.proxima_cobranca,
    atualizado_em    = excluded.atualizado_em
  returning * into v_linha;

  return v_linha;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.calc_daily_calories(p_weight double precision, p_height double precision, p_goal_type text)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
DECLARE
  v_bmr  double precision := 10 * COALESCE(p_weight, 70) + 6.25 * COALESCE(p_height, 170) - 500;
  v_tdee double precision;
BEGIN
  v_tdee := v_bmr * 1.55;
  CASE p_goal_type
    WHEN 'lose_weight' THEN RETURN GREATEST(1200, LEAST(9999, (v_tdee - 500)::int));
    WHEN 'gain_weight' THEN RETURN GREATEST(1200, LEAST(9999, (v_tdee + 300)::int));
    ELSE                    RETURN GREATEST(1200, LEAST(9999,  v_tdee::int));
  END CASE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calc_daily_water(p_weight double precision, p_birth_date date)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
DECLARE
  v_age    int;
  v_factor int;
BEGIN
  IF p_weight IS NULL OR p_weight <= 0 THEN
    RETURN NULL;
  END IF;

  v_age := CASE
             WHEN p_birth_date IS NULL THEN 30
             ELSE date_part('year', age(p_birth_date))::int
           END;

  v_factor := CASE
                WHEN v_age <= 17 THEN 40
                WHEN v_age <= 55 THEN 35
                WHEN v_age <= 65 THEN 30
                ELSE                  25
              END;

  RETURN round(p_weight * v_factor)::int;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.cancelar_assinatura()
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  delete from public.assinaturas where user_id = auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.check_email_exists(p_email text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users WHERE email = lower(trim(p_email))
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.complete_workout_template(p_user_id uuid, p_template_id uuid, p_exercises jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_progression int := 0;
  v_old_weight  decimal;
  v_ex          record;
  v_hoje        date := public.app_today();
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Nao autorizado';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM workout_templates
    WHERE id = p_template_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Template nao encontrado';
  END IF;

  INSERT INTO workout_completions (user_id, template_id, completed_date)
  VALUES (auth.uid(), p_template_id, v_hoje)
  ON CONFLICT (user_id, template_id, completed_date) DO NOTHING;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('already_done', true, 'progression', 0);
  END IF;

  INSERT INTO workouts (user_id, date, completed)
  VALUES (auth.uid(), v_hoje, true);

  FOR v_ex IN
    SELECT * FROM jsonb_to_recordset(p_exercises)
      AS x(id uuid, weight_kg decimal, sets int, reps int)
  LOOP
    SELECT te.weight_kg INTO v_old_weight
    FROM template_exercises te
    JOIN workout_templates wt ON wt.id = te.template_id
    WHERE te.id = v_ex.id AND wt.user_id = auth.uid();

    IF NOT FOUND THEN CONTINUE; END IF;

    IF v_ex.weight_kg > COALESCE(v_old_weight, 0) THEN
      v_progression := v_progression + 1;
    END IF;

    UPDATE template_exercises te
    SET weight_kg = v_ex.weight_kg,
        sets      = v_ex.sets,
        reps      = v_ex.reps
    FROM workout_templates wt
    WHERE te.id = v_ex.id AND wt.id = te.template_id AND wt.user_id = auth.uid();
  END LOOP;

  IF v_progression > 0 THEN
    INSERT INTO points (user_id, amount, reason)
    VALUES (auth.uid(), v_progression * 5, 'load_progression');
  END IF;

  RETURN jsonb_build_object('already_done', false, 'progression', v_progression);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.consumir_cota_ia(p_recurso text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_uid   uuid := auth.uid();
  v_dia   date := app_today()::date;
  v_usos  integer;
begin
  if v_uid is null then
    raise exception 'nao autenticado';
  end if;

  if p_recurso not in ('foto', 'texto', 'treino', 'dieta') then
    raise exception 'recurso invalido: %', p_recurso;
  end if;

  insert into public.cota_ia_diaria (user_id, dia, recurso, usos)
  values (v_uid, v_dia, p_recurso, 1)
  on conflict (user_id, dia, recurso)
    do update set usos = public.cota_ia_diaria.usos + 1
  returning usos into v_usos;

  return v_usos;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.copiar_treino(p_template_id uuid, p_nome text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_uid   uuid := auth.uid();
  v_nome  text;
  v_novo  uuid;
begin
  if v_uid is null then
    raise exception 'nao autenticado';
  end if;

  if not exists (select 1 from workout_templates where id = p_template_id) then
    raise exception 'treino nao encontrado';
  end if;

  if exists (select 1 from workout_templates
              where id = p_template_id and user_id = v_uid) then
    raise exception 'treino ja e seu';
  end if;

  v_nome := coalesce(nullif(btrim(p_nome), ''), 'Treino');
  if length(v_nome) > 80 then
    v_nome := left(v_nome, 80);
  end if;

  insert into workout_templates (user_id, name, order_index)
  values (v_uid, v_nome, public.next_template_order())
  returning id into v_novo;

  insert into template_exercises
    (template_id, name, sets, reps, weight_kg, order_index)
  select v_novo, e.name, e.sets, e.reps, 0, e.order_index
  from template_exercises e
  where e.template_id = p_template_id;

  return v_novo;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_my_account()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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

  -- Amizades nos dois sentidos — o outro lado não pode ficar com vínculo órfão
  DELETE FROM public.friendships WHERE user_id = v_uid OR friend_id = v_uid;

  DELETE FROM public.goals    WHERE user_id = v_uid;
  DELETE FROM public.profiles WHERE id = v_uid;

  -- user_consents cai por CASCADE junto com auth.users
  DELETE FROM auth.users WHERE id = v_uid;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.export_my_data()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    -- Workouts (legado) agora carregam seus exercises aninhados
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
$function$
;

CREATE OR REPLACE FUNCTION public.fn_award_diet_points()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_total_cal   INTEGER;
  v_goal_cal    INTEGER;
  v_already_won BOOLEAN;
BEGIN
  SELECT COALESCE(SUM(calories), 0) INTO v_total_cal
  FROM diet_logs WHERE user_id = NEW.user_id AND date = NEW.date;

  SELECT COALESCE(daily_calories, 2000) INTO v_goal_cal
  FROM goals WHERE user_id = NEW.user_id;

  SELECT EXISTS (
    SELECT 1 FROM points
    WHERE user_id = NEW.user_id
      AND reason = 'diet_goal_met'
      AND created_at::date = NEW.date
  ) INTO v_already_won;

  IF NOT v_already_won
     AND v_total_cal >= (v_goal_cal * 0.9)
     AND v_total_cal <= (v_goal_cal * 1.1) THEN
    INSERT INTO points (user_id, amount, reason, reference_id)
    VALUES (NEW.user_id, 10, 'diet_goal_met', NEW.id);
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_award_load_progression()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.previous_weight IS NOT NULL AND NEW.weight > NEW.previous_weight THEN
    INSERT INTO points (user_id, amount, reason, reference_id)
    SELECT w.user_id, 5, 'load_progression', NEW.id
    FROM workouts w WHERE w.id = NEW.workout_id;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_award_weight_progression()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_goal_type   TEXT;
  v_prev_weight DECIMAL;
  v_progressing BOOLEAN := FALSE;
BEGIN
  SELECT goal_type, current_weight INTO v_goal_type, v_prev_weight
  FROM goals WHERE user_id = NEW.user_id;

  IF v_prev_weight IS NULL THEN RETURN NEW; END IF;

  IF v_goal_type = 'lose_weight' AND NEW.weight < v_prev_weight THEN
    v_progressing := TRUE;
  ELSIF v_goal_type = 'gain_weight' AND NEW.weight > v_prev_weight THEN
    v_progressing := TRUE;
  END IF;

  IF v_progressing AND ABS(NEW.weight - v_prev_weight) >= 0.1 THEN
    INSERT INTO points (user_id, amount, reason)
    VALUES (NEW.user_id, 20, 'weight_progression');
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_award_workout_points()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.completed = TRUE AND (OLD.completed IS NULL OR OLD.completed = FALSE) THEN
    INSERT INTO points (user_id, amount, reason, reference_id)
    VALUES (NEW.user_id, 10, 'workout_completed', NEW.id);
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_cota_ia()
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select coalesce(jsonb_object_agg(recurso, usos), '{}'::jsonb)
  from public.cota_ia_diaria
  where user_id = auth.uid()
    and dia = app_today()::date;
$function$
;

CREATE OR REPLACE FUNCTION public.get_friends_rank(p_user_id uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT pos::INTEGER FROM (
    SELECT u.id AS user_id,
           ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(p.amount),0) DESC) AS pos
    FROM auth.users u
    LEFT JOIN points p ON p.user_id = u.id
    WHERE u.id = p_user_id
       OR u.id IN (
         SELECT friend_id FROM friendships WHERE user_id = p_user_id AND status='accepted'
         UNION
         SELECT user_id FROM friendships WHERE friend_id = p_user_id AND status='accepted'
       )
    GROUP BY u.id
  ) r WHERE user_id = p_user_id;
$function$
;

CREATE OR REPLACE FUNCTION public.get_friends_ranking(p_user_id uuid)
 RETURNS TABLE(rank_position bigint, user_id uuid, user_name text, avatar_url text, total_points bigint, is_current_user boolean, is_friend boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(pt.amount),0) DESC)  AS rank_position,
    pr.id                                                           AS user_id,
    pr.name                                                         AS user_name,
    pr.avatar_url                                                   AS avatar_url,
    COALESCE(SUM(pt.amount),0)                                      AS total_points,
    (pr.id = auth.uid())                                            AS is_current_user,
    (pr.id <> auth.uid())                                           AS is_friend
  FROM profiles pr
  LEFT JOIN points pt ON pt.user_id = pr.id
  WHERE pr.id = auth.uid()
     OR pr.id IN (
       SELECT friend_id FROM friendships WHERE user_id = auth.uid() AND status = 'accepted'
       UNION
       SELECT user_id  FROM friendships WHERE friend_id = auth.uid() AND status = 'accepted'
     )
  GROUP BY pr.id, pr.name, pr.avatar_url
  ORDER BY total_points DESC;
$function$
;

CREATE OR REPLACE FUNCTION public.get_global_rank(p_user_id uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT pos::INTEGER FROM (
    SELECT user_id,
           ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(amount),0) DESC) AS pos
    FROM points GROUP BY user_id
  ) r WHERE user_id = p_user_id;
$function$
;

CREATE OR REPLACE FUNCTION public.get_global_ranking(p_user_id uuid)
 RETURNS TABLE(rank_position bigint, user_id uuid, user_name text, avatar_url text, total_points bigint, is_current_user boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(pt.amount),0) DESC)  AS rank_position,
    pr.id                                                           AS user_id,
    pr.name                                                         AS user_name,
    pr.avatar_url                                                   AS avatar_url,
    COALESCE(SUM(pt.amount),0)                                      AS total_points,
    (pr.id = auth.uid())                                            AS is_current_user
  FROM profiles pr
  LEFT JOIN points pt ON pt.user_id = pr.id
  GROUP BY pr.id, pr.name, pr.avatar_url
  ORDER BY total_points DESC
  LIMIT 100;
$function$
;

CREATE OR REPLACE FUNCTION public.get_groq_api_key()
 RETURNS text
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'groq_api_key' LIMIT 1;
$function$
;

CREATE OR REPLACE FUNCTION public.get_pending_requests(p_user_id uuid)
 RETURNS TABLE(request_id uuid, requester_id uuid, requester_name text, requester_avatar text, requester_points bigint, created_at timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    f.id                          AS request_id,
    pr.id                         AS requester_id,
    pr.name                       AS requester_name,
    pr.avatar_url                 AS requester_avatar,
    COALESCE(SUM(pt.amount), 0)   AS requester_points,
    f.created_at
  FROM friendships f
  JOIN profiles pr ON pr.id = f.user_id
  LEFT JOIN points pt ON pt.user_id = pr.id
  WHERE f.friend_id = auth.uid()
    AND f.status = 'pending'
  GROUP BY f.id, pr.id, pr.name, pr.avatar_url, f.created_at
  ORDER BY f.created_at DESC;
$function$
;

CREATE OR REPLACE FUNCTION public.get_pending_requests_count(p_user_id uuid)
 RETURNS integer
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COUNT(*)::integer
  FROM friendships
  WHERE friend_id = auth.uid() AND status = 'pending';
$function$
;

CREATE OR REPLACE FUNCTION public.get_perfil_publico(p_user_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select case when auth.uid() is null then null else jsonb_build_object(
    'id',            p.id,
    'nome',          p.name,
    'avatar_url',    p.avatar_url,
    'membro_desde',  p.created_at,
    'objetivo',      coalesce(g.goal_type, 'maintain'),
    'meta_semanal',  coalesce(g.weekly_workout_goal, 0),
    'total_pontos',  coalesce((select sum(amount) from points
                                where user_id = p.id), 0),
    'total_treinos', coalesce((select count(*) from workout_completions
                                where user_id = p.id), 0),
    'streak',        public._streak_de(p.id),
    'amizade',       case
                       when auth.uid() = p.id then 'proprio'
                       else coalesce((
                         select case when f.status = 'accepted'
                                     then 'amigos' else 'pendente' end
                         from friendships f
                         where (f.user_id = auth.uid() and f.friend_id = p.id)
                            or (f.user_id = p.id and f.friend_id = auth.uid())
                         order by case when f.status = 'accepted' then 0 else 1 end
                         limit 1
                       ), 'nenhum')
                     end,
    'treinos',       coalesce((
      select jsonb_agg(x.treino order by x.ordem)
      from (
        select w.order_index as ordem,
               jsonb_build_object(
                 'id',   w.id,
                 'nome', w.name,
                 'exercicios', coalesce((
                   select jsonb_agg(jsonb_build_object(
                            'nome',    e.name,
                            'series',  e.sets,
                            'reps',    e.reps,
                            'peso_kg', e.weight_kg
                          ) order by e.order_index)
                   from template_exercises e
                   where e.template_id = w.id
                 ), '[]'::jsonb)
               ) as treino
        from workout_templates w
        where w.user_id = p.id
      ) x
    ), '[]'::jsonb)
  ) end
  from profiles p
  left join goals g on g.user_id = p.id
  where p.id = p_user_id;
$function$
;

CREATE OR REPLACE FUNCTION public.get_streak(p_user_id uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select public._streak_de(coalesce(auth.uid(), p_user_id));
$function$
;

CREATE OR REPLACE FUNCTION public.get_week_activity()
 RETURNS TABLE(dia date, dow integer, treinou boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT d::date AS dia,
         EXTRACT(ISODOW FROM d)::int AS dow,
         EXISTS (SELECT 1 FROM workout_completions c
                  WHERE c.user_id = auth.uid()
                    AND c.completed_date = d::date) AS treinou
    FROM generate_series(public.app_today() - 6, public.app_today(), interval '1 day') d
   ORDER BY d;
$function$
;

CREATE OR REPLACE FUNCTION public.get_workout_templates(p_user_id uuid)
 RETURNS TABLE(id uuid, name text, done_today boolean, exercise_count integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    t.id,
    t.name,
    EXISTS (
      SELECT 1 FROM workout_completions c
      WHERE c.template_id = t.id
        AND c.user_id = auth.uid()
        AND c.completed_date = public.app_today()
    ) AS done_today,
    (SELECT COUNT(*) FROM template_exercises e WHERE e.template_id = t.id)::int
      AS exercise_count
  FROM workout_templates t
  WHERE t.user_id = auth.uid()
  -- created_at desempata: template novo entra com default 0 ate o proximo
  -- reorder, e a ordem continua estavel.
  ORDER BY COALESCE(t.order_index, 0) ASC, t.created_at ASC;
$function$
;

CREATE OR REPLACE FUNCTION public.goals_recalc_calories()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  NEW.daily_calories := public.calc_daily_calories(
    NEW.current_weight, NEW.height_cm, NEW.goal_type);
  NEW.daily_water_ml := public.calc_daily_water(
    NEW.current_weight, NEW.birth_date);
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.grant_consent(p_consent_type text, p_document_version text, p_locale text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.next_template_order()
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(MAX(order_index), -1) + 1
    FROM workout_templates WHERE user_id = auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.reorder_workout_templates(p_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  UPDATE public.workout_templates t
     SET order_index = pos.idx
    FROM (SELECT unnest(p_ids) AS id,
                 generate_subscripts(p_ids, 1) - 1 AS idx) pos
   WHERE t.id = pos.id AND t.user_id = v_uid;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.revoke_consent(p_consent_type text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_ver text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF p_consent_type IN ('terms', 'privacy') THEN
    RAISE EXCEPTION 'consent_required_for_service';
  END IF;

  SELECT document_version INTO v_ver
    FROM public.user_consents
   WHERE user_id = v_uid AND consent_type = p_consent_type
   ORDER BY granted_at DESC LIMIT 1;

  UPDATE public.user_consents
     SET revoked_at = now()
   WHERE user_id = v_uid AND consent_type = p_consent_type AND revoked_at IS NULL;

  INSERT INTO public.user_consents
    (user_id, consent_type, document_version, granted, source)
  VALUES (v_uid, p_consent_type, COALESCE(v_ver, 'unknown'), false, 'settings');
END;
$function$
;

CREATE OR REPLACE FUNCTION public.search_users(p_query text, p_current_user_id uuid)
 RETURNS TABLE(user_id uuid, user_name text, avatar_url text, total_points bigint, is_friend boolean, is_pending boolean, request_id uuid)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    pr.id                                                       AS user_id,
    pr.name                                                     AS user_name,
    pr.avatar_url,
    COALESCE(SUM(pt.amount), 0)                                 AS total_points,
    EXISTS(
      SELECT 1 FROM friendships f
      WHERE ((f.user_id = auth.uid() AND f.friend_id = pr.id)
          OR (f.friend_id = auth.uid() AND f.user_id = pr.id))
        AND f.status = 'accepted'
    )                                                           AS is_friend,
    EXISTS(
      SELECT 1 FROM friendships f
      WHERE f.user_id = auth.uid() AND f.friend_id = pr.id
        AND f.status = 'pending'
    )                                                           AS is_pending,
    (
      SELECT f.id FROM friendships f
      WHERE f.user_id = auth.uid() AND f.friend_id = pr.id
        AND f.status = 'pending'
      LIMIT 1
    )                                                           AS request_id
  FROM profiles pr
  LEFT JOIN points pt ON pt.user_id = pr.id
  WHERE pr.id <> auth.uid()
    AND LOWER(pr.name) LIKE '%' || LOWER(p_query) || '%'
  GROUP BY pr.id, pr.name, pr.avatar_url
  ORDER BY is_friend DESC, total_points DESC
  LIMIT 30;
$function$
;

CREATE OR REPLACE FUNCTION public.sou_conta_de_teste()
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select exists (
    select 1 from public.contas_de_teste where user_id = auth.uid()
  );
$function$
;

CREATE OR REPLACE FUNCTION public.zerar_cota_ia()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if not sou_conta_de_teste() then
    raise exception 'nao autorizado';
  end if;

  delete from public.cota_ia_diaria
  where user_id = auth.uid() and dia = app_today()::date;
end;
$function$
;

-- ===== TABELAS =====

create table if not exists public.assinaturas (
  user_id uuid not null,
  plano_id text not null,
  expira_em timestamp with time zone not null,
  em_trial boolean not null default false,
  proxima_cobranca integer not null default 0,
  atualizado_em timestamp with time zone not null default now()
);

create table if not exists public.bioimpedance_logs (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  body_fat_pct numeric,
  muscle_mass_kg numeric,
  visceral_fat integer,
  hydration_pct numeric,
  bone_mass_kg numeric,
  bmr_kcal integer,
  measured_at date not null default app_today(),
  created_at timestamp with time zone default now()
);

create table if not exists public.contas_de_teste (
  user_id uuid not null,
  nota text
);

create table if not exists public.cota_ia_diaria (
  user_id uuid not null,
  dia date not null,
  recurso text not null,
  usos integer not null default 0
);

create table if not exists public.diet_logs (
  id uuid not null default gen_random_uuid(),
  user_id uuid,
  date date not null default app_today(),
  meal_name text not null,
  calories integer default 0,
  protein numeric(6,2) default 0,
  carbs numeric(6,2) default 0,
  fat numeric(6,2) default 0,
  created_at timestamp with time zone default now()
);

create table if not exists public.exercises (
  id uuid not null default gen_random_uuid(),
  workout_id uuid,
  name text not null,
  sets integer default 3,
  reps integer default 10,
  weight numeric(6,2) default 0,
  previous_weight numeric(6,2),
  created_at timestamp with time zone default now()
);

create table if not exists public.friendships (
  id uuid not null default gen_random_uuid(),
  user_id uuid,
  friend_id uuid,
  status text default 'accepted'::text,
  created_at timestamp with time zone default now()
);

create table if not exists public.goals (
  id uuid not null default gen_random_uuid(),
  user_id uuid,
  goal_type text not null default 'maintain'::text,
  target_weight numeric(5,2),
  current_weight numeric(5,2),
  daily_calories integer default 2000,
  weekly_workout_goal integer default 5,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  height_cm numeric,
  hand_length_cm numeric(4,1),
  hand_width_cm numeric(4,1),
  hand_calibrated_at timestamp with time zone,
  birth_date date,
  daily_water_ml integer
);

create table if not exists public.points (
  id uuid not null default gen_random_uuid(),
  user_id uuid,
  amount integer not null,
  reason text not null,
  reference_id uuid,
  created_at timestamp with time zone default now()
);

create table if not exists public.profiles (
  id uuid not null,
  name text not null,
  avatar_url text,
  created_at timestamp with time zone default now()
);

create table if not exists public.template_exercises (
  id uuid not null default gen_random_uuid(),
  template_id uuid not null,
  name text not null,
  sets integer not null default 3,
  reps integer not null default 10,
  weight_kg numeric(6,2) not null default 0,
  order_index integer not null default 0
);

create table if not exists public.user_consents (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  consent_type text not null,
  document_version text not null,
  granted boolean not null,
  granted_at timestamp with time zone not null default now(),
  revoked_at timestamp with time zone,
  locale text,
  source text not null default 'signup'::text
);

create table if not exists public.water_logs (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  date date not null default app_today(),
  amount_ml integer not null,
  created_at timestamp with time zone not null default now()
);

create table if not exists public.weight_logs (
  id uuid not null default gen_random_uuid(),
  user_id uuid,
  weight numeric(5,2) not null,
  date date not null default app_today(),
  created_at timestamp with time zone default now()
);

create table if not exists public.workout_completions (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  template_id uuid not null,
  completed_date date not null default app_today(),
  created_at timestamp with time zone default now()
);

create table if not exists public.workout_templates (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  name text not null,
  created_at timestamp with time zone default now(),
  order_index integer default 0
);

create table if not exists public.workouts (
  id uuid not null default gen_random_uuid(),
  user_id uuid,
  date date not null default app_today(),
  completed boolean default false,
  notes text,
  created_at timestamp with time zone default now()
);

-- ===== CONSTRAINTS =====

alter table public.assinaturas add constraint assinaturas_pkey PRIMARY KEY (user_id);
alter table public.assinaturas add constraint assinaturas_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.bioimpedance_logs add constraint bioimpedance_logs_user_date_unique UNIQUE (user_id, measured_at);
alter table public.bioimpedance_logs add constraint bioimpedance_logs_pkey PRIMARY KEY (id);
alter table public.bioimpedance_logs add constraint bioimpedance_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.contas_de_teste add constraint contas_de_teste_pkey PRIMARY KEY (user_id);
alter table public.contas_de_teste add constraint contas_de_teste_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.cota_ia_diaria add constraint cota_ia_diaria_pkey PRIMARY KEY (user_id, dia, recurso);
alter table public.cota_ia_diaria add constraint cota_ia_diaria_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.diet_logs add constraint diet_logs_pkey PRIMARY KEY (id);
alter table public.diet_logs add constraint diet_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.exercises add constraint exercises_pkey PRIMARY KEY (id);
alter table public.exercises add constraint exercises_workout_id_fkey FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE;
alter table public.friendships add constraint friendships_user_id_friend_id_key UNIQUE (user_id, friend_id);
alter table public.friendships add constraint friendships_pkey PRIMARY KEY (id);
alter table public.friendships add constraint friendships_friend_id_fkey FOREIGN KEY (friend_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.friendships add constraint friendships_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.friendships add constraint friendships_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text])));
alter table public.goals add constraint goals_user_id_key UNIQUE (user_id);
alter table public.goals add constraint goals_pkey PRIMARY KEY (id);
alter table public.goals add constraint goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.goals add constraint goals_goal_type_check CHECK ((goal_type = ANY (ARRAY['lose_weight'::text, 'gain_weight'::text, 'maintain'::text])));
alter table public.points add constraint points_pkey PRIMARY KEY (id);
alter table public.points add constraint points_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.points add constraint points_reason_check CHECK ((reason = ANY (ARRAY['workout_completed'::text, 'diet_goal_met'::text, 'load_progression'::text, 'weight_progression'::text])));
alter table public.profiles add constraint profiles_pkey PRIMARY KEY (id);
alter table public.profiles add constraint profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.template_exercises add constraint template_exercises_pkey PRIMARY KEY (id);
alter table public.template_exercises add constraint template_exercises_template_id_fkey FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE;
alter table public.user_consents add constraint user_consents_pkey PRIMARY KEY (id);
alter table public.user_consents add constraint user_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.user_consents add constraint user_consents_consent_type_check CHECK ((consent_type = ANY (ARRAY['terms'::text, 'privacy'::text, 'health_data'::text, 'ai_photo_transfer'::text, 'marketing'::text])));
alter table public.user_consents add constraint user_consents_source_check CHECK ((source = ANY (ARRAY['signup'::text, 'settings'::text, 'reconsent'::text])));
alter table public.water_logs add constraint water_logs_pkey PRIMARY KEY (id);
alter table public.water_logs add constraint water_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.water_logs add constraint water_logs_amount_ml_check CHECK ((amount_ml > 0));
alter table public.weight_logs add constraint weight_logs_user_id_date_key UNIQUE (user_id, date);
alter table public.weight_logs add constraint weight_logs_pkey PRIMARY KEY (id);
alter table public.weight_logs add constraint weight_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.workout_completions add constraint workout_completions_user_id_template_id_completed_date_key UNIQUE (user_id, template_id, completed_date);
alter table public.workout_completions add constraint workout_completions_pkey PRIMARY KEY (id);
alter table public.workout_completions add constraint workout_completions_template_id_fkey FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE;
alter table public.workout_completions add constraint workout_completions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.workout_templates add constraint workout_templates_pkey PRIMARY KEY (id);
alter table public.workout_templates add constraint workout_templates_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.workouts add constraint workouts_pkey PRIMARY KEY (id);
alter table public.workouts add constraint workouts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- ===== INDICES =====

CREATE INDEX idx_cota_ia_dia ON public.cota_ia_diaria USING btree (dia);
CREATE INDEX idx_diet_logs_user_date ON public.diet_logs USING btree (user_id, date DESC);
CREATE INDEX idx_friendships_friend ON public.friendships USING btree (friend_id);
CREATE INDEX idx_friendships_user ON public.friendships USING btree (user_id);
CREATE INDEX idx_points_user ON public.points USING btree (user_id, created_at DESC);
CREATE INDEX idx_user_consents_user_type ON public.user_consents USING btree (user_id, consent_type, granted_at DESC);
CREATE INDEX idx_water_logs_user_date ON public.water_logs USING btree (user_id, date);
CREATE INDEX idx_workout_templates_user_order ON public.workout_templates USING btree (user_id, order_index);
CREATE INDEX idx_workouts_user_date ON public.workouts USING btree (user_id, date DESC);

-- ===== RLS =====

alter table public.assinaturas enable row level security;
alter table public.bioimpedance_logs enable row level security;
alter table public.contas_de_teste enable row level security;
alter table public.cota_ia_diaria enable row level security;
alter table public.diet_logs enable row level security;
alter table public.exercises enable row level security;
alter table public.friendships enable row level security;
alter table public.goals enable row level security;
alter table public.points enable row level security;
alter table public.profiles enable row level security;
alter table public.template_exercises enable row level security;
alter table public.user_consents enable row level security;
alter table public.water_logs enable row level security;
alter table public.weight_logs enable row level security;
alter table public.workout_completions enable row level security;
alter table public.workout_templates enable row level security;
alter table public.workouts enable row level security;

-- ===== POLITICAS =====

create policy "assinatura: dono le" on public.assinaturas as PERMISSIVE for SELECT to public
  using ((auth.uid() = user_id));
create policy bio_delete_own on public.bioimpedance_logs as PERMISSIVE for DELETE to authenticated
  using ((auth.uid() = user_id));
create policy bio_insert_own on public.bioimpedance_logs as PERMISSIVE for INSERT to authenticated
  with check ((auth.uid() = user_id));
create policy bio_select_own on public.bioimpedance_logs as PERMISSIVE for SELECT to public
  using ((auth.uid() = user_id));
create policy bio_update_own on public.bioimpedance_logs as PERMISSIVE for UPDATE to authenticated
  using ((auth.uid() = user_id));
create policy "cota: dono le" on public.cota_ia_diaria as PERMISSIVE for SELECT to public
  using ((auth.uid() = user_id));
create policy "Acesso própria dieta" on public.diet_logs as PERMISSIVE for ALL to public
  using ((auth.uid() = user_id));
create policy "Acesso próprios exercícios" on public.exercises as PERMISSIVE for ALL to public
  using ((EXISTS ( SELECT 1
   FROM workouts w
  WHERE ((w.id = exercises.workout_id) AND (w.user_id = auth.uid())))));
create policy "Acesso próprias amizades" on public.friendships as PERMISSIVE for ALL to public
  using (((auth.uid() = user_id) OR (auth.uid() = friend_id)));
create policy friendships_delete on public.friendships as PERMISSIVE for DELETE to authenticated
  using ((auth.uid() = user_id));
create policy friendships_insert on public.friendships as PERMISSIVE for INSERT to authenticated
  with check ((auth.uid() = user_id));
create policy friendships_select on public.friendships as PERMISSIVE for SELECT to public
  using (((auth.uid() = user_id) OR (auth.uid() = friend_id)));
create policy "Acesso próprias metas" on public.goals as PERMISSIVE for ALL to public
  using ((auth.uid() = user_id));
create policy "Inserir pontos próprios" on public.points as PERMISSIVE for INSERT to authenticated
  with check ((auth.uid() = user_id));
create policy "Ver próprios pontos" on public.points as PERMISSIVE for SELECT to public
  using ((auth.uid() = user_id));
create policy "Criar próprio perfil" on public.profiles as PERMISSIVE for INSERT to public
  with check ((auth.uid() = id));
create policy "Ver perfis no ranking" on public.profiles as PERMISSIVE for SELECT to authenticated
  using (true);
create policy "Ver próprio perfil" on public.profiles as PERMISSIVE for SELECT to public
  using ((auth.uid() = id));
create policy "Editar próprio perfil" on public.profiles as PERMISSIVE for UPDATE to public
  using ((auth.uid() = id));
create policy "own template exercises" on public.template_exercises as PERMISSIVE for ALL to public
  using ((EXISTS ( SELECT 1
   FROM workout_templates t
  WHERE ((t.id = template_exercises.template_id) AND (t.user_id = auth.uid())))))
  with check ((EXISTS ( SELECT 1
   FROM workout_templates t
  WHERE ((t.id = template_exercises.template_id) AND (t.user_id = auth.uid())))));
create policy user_consents_insert_own on public.user_consents as PERMISSIVE for INSERT to authenticated
  with check ((auth.uid() = user_id));
create policy user_consents_select_own on public.user_consents as PERMISSIVE for SELECT to authenticated
  using ((auth.uid() = user_id));
create policy water_logs_delete_own on public.water_logs as PERMISSIVE for DELETE to authenticated
  using ((auth.uid() = user_id));
create policy water_logs_insert_own on public.water_logs as PERMISSIVE for INSERT to authenticated
  with check ((auth.uid() = user_id));
create policy water_logs_select_own on public.water_logs as PERMISSIVE for SELECT to authenticated
  using ((auth.uid() = user_id));
create policy "Acesso próprio peso" on public.weight_logs as PERMISSIVE for ALL to public
  using ((auth.uid() = user_id));
create policy "own completions" on public.workout_completions as PERMISSIVE for ALL to public
  using ((auth.uid() = user_id))
  with check ((auth.uid() = user_id));
create policy "own templates" on public.workout_templates as PERMISSIVE for ALL to public
  using ((auth.uid() = user_id))
  with check ((auth.uid() = user_id));
create policy "Acesso próprios treinos" on public.workouts as PERMISSIVE for ALL to public
  using ((auth.uid() = user_id));

-- ===== TRIGGERS =====

CREATE TRIGGER trg_diet_points AFTER INSERT ON public.diet_logs FOR EACH ROW EXECUTE FUNCTION fn_award_diet_points();
CREATE TRIGGER trg_goals_recalc BEFORE INSERT OR UPDATE OF current_weight, height_cm, goal_type, birth_date ON public.goals FOR EACH ROW EXECUTE FUNCTION goals_recalc_calories();
CREATE TRIGGER trg_load_progression AFTER INSERT ON public.exercises FOR EACH ROW EXECUTE FUNCTION fn_award_load_progression();
CREATE TRIGGER trg_weight_progression AFTER INSERT OR UPDATE ON public.weight_logs FOR EACH ROW EXECUTE FUNCTION fn_award_weight_progression();
CREATE TRIGGER trg_workout_points AFTER INSERT OR UPDATE OF completed ON public.workouts FOR EACH ROW EXECUTE FUNCTION fn_award_workout_points();

-- ===== PERMISSOES DE FUNCAO =====

revoke all on function public._streak_de(p_uid uuid) from public;
grant execute on function public._streak_de(p_uid uuid) to service_role;
revoke all on function public.app_today() from public;
grant execute on function public.app_today() to anon;
grant execute on function public.app_today() to authenticated;
grant execute on function public.app_today() to service_role;
revoke all on function public.assinar_demo(p_plano_id text, p_proxima_cobranca integer) from public;
grant execute on function public.assinar_demo(p_plano_id text, p_proxima_cobranca integer) to authenticated;
grant execute on function public.assinar_demo(p_plano_id text, p_proxima_cobranca integer) to service_role;
revoke all on function public.calc_daily_calories(p_weight double precision, p_height double precision, p_goal_type text) from public;
grant execute on function public.calc_daily_calories(p_weight double precision, p_height double precision, p_goal_type text) to anon;
grant execute on function public.calc_daily_calories(p_weight double precision, p_height double precision, p_goal_type text) to authenticated;
grant execute on function public.calc_daily_calories(p_weight double precision, p_height double precision, p_goal_type text) to service_role;
revoke all on function public.calc_daily_water(p_weight double precision, p_birth_date date) from public;
grant execute on function public.calc_daily_water(p_weight double precision, p_birth_date date) to anon;
grant execute on function public.calc_daily_water(p_weight double precision, p_birth_date date) to authenticated;
grant execute on function public.calc_daily_water(p_weight double precision, p_birth_date date) to service_role;
revoke all on function public.cancelar_assinatura() from public;
grant execute on function public.cancelar_assinatura() to authenticated;
grant execute on function public.cancelar_assinatura() to service_role;
revoke all on function public.check_email_exists(p_email text) from public;
grant execute on function public.check_email_exists(p_email text) to anon;
grant execute on function public.check_email_exists(p_email text) to authenticated;
grant execute on function public.check_email_exists(p_email text) to service_role;
revoke all on function public.complete_workout_template(p_user_id uuid, p_template_id uuid, p_exercises jsonb) from public;
grant execute on function public.complete_workout_template(p_user_id uuid, p_template_id uuid, p_exercises jsonb) to authenticated;
grant execute on function public.complete_workout_template(p_user_id uuid, p_template_id uuid, p_exercises jsonb) to service_role;
revoke all on function public.consumir_cota_ia(p_recurso text) from public;
grant execute on function public.consumir_cota_ia(p_recurso text) to authenticated;
grant execute on function public.consumir_cota_ia(p_recurso text) to service_role;
revoke all on function public.copiar_treino(p_template_id uuid, p_nome text) from public;
grant execute on function public.copiar_treino(p_template_id uuid, p_nome text) to authenticated;
grant execute on function public.copiar_treino(p_template_id uuid, p_nome text) to service_role;
revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
grant execute on function public.delete_my_account() to service_role;
revoke all on function public.export_my_data() from public;
grant execute on function public.export_my_data() to authenticated;
grant execute on function public.export_my_data() to service_role;
revoke all on function public.fn_award_diet_points() from public;
grant execute on function public.fn_award_diet_points() to anon;
grant execute on function public.fn_award_diet_points() to authenticated;
grant execute on function public.fn_award_diet_points() to service_role;
revoke all on function public.fn_award_load_progression() from public;
grant execute on function public.fn_award_load_progression() to anon;
grant execute on function public.fn_award_load_progression() to authenticated;
grant execute on function public.fn_award_load_progression() to service_role;
revoke all on function public.fn_award_weight_progression() from public;
grant execute on function public.fn_award_weight_progression() to anon;
grant execute on function public.fn_award_weight_progression() to authenticated;
grant execute on function public.fn_award_weight_progression() to service_role;
revoke all on function public.fn_award_workout_points() from public;
grant execute on function public.fn_award_workout_points() to anon;
grant execute on function public.fn_award_workout_points() to authenticated;
grant execute on function public.fn_award_workout_points() to service_role;
revoke all on function public.get_cota_ia() from public;
grant execute on function public.get_cota_ia() to authenticated;
grant execute on function public.get_cota_ia() to service_role;
revoke all on function public.get_friends_rank(p_user_id uuid) from public;
grant execute on function public.get_friends_rank(p_user_id uuid) to authenticated;
grant execute on function public.get_friends_rank(p_user_id uuid) to service_role;
revoke all on function public.get_friends_ranking(p_user_id uuid) from public;
grant execute on function public.get_friends_ranking(p_user_id uuid) to authenticated;
grant execute on function public.get_friends_ranking(p_user_id uuid) to service_role;
revoke all on function public.get_global_rank(p_user_id uuid) from public;
grant execute on function public.get_global_rank(p_user_id uuid) to authenticated;
grant execute on function public.get_global_rank(p_user_id uuid) to service_role;
revoke all on function public.get_global_ranking(p_user_id uuid) from public;
grant execute on function public.get_global_ranking(p_user_id uuid) to authenticated;
grant execute on function public.get_global_ranking(p_user_id uuid) to service_role;
revoke all on function public.get_groq_api_key() from public;
grant execute on function public.get_groq_api_key() to service_role;
revoke all on function public.get_pending_requests(p_user_id uuid) from public;
grant execute on function public.get_pending_requests(p_user_id uuid) to authenticated;
grant execute on function public.get_pending_requests(p_user_id uuid) to service_role;
revoke all on function public.get_pending_requests_count(p_user_id uuid) from public;
grant execute on function public.get_pending_requests_count(p_user_id uuid) to authenticated;
grant execute on function public.get_pending_requests_count(p_user_id uuid) to service_role;
revoke all on function public.get_perfil_publico(p_user_id uuid) from public;
grant execute on function public.get_perfil_publico(p_user_id uuid) to authenticated;
grant execute on function public.get_perfil_publico(p_user_id uuid) to service_role;
revoke all on function public.get_streak(p_user_id uuid) from public;
grant execute on function public.get_streak(p_user_id uuid) to authenticated;
grant execute on function public.get_streak(p_user_id uuid) to service_role;
revoke all on function public.get_week_activity() from public;
grant execute on function public.get_week_activity() to authenticated;
grant execute on function public.get_week_activity() to service_role;
revoke all on function public.get_workout_templates(p_user_id uuid) from public;
grant execute on function public.get_workout_templates(p_user_id uuid) to authenticated;
grant execute on function public.get_workout_templates(p_user_id uuid) to service_role;
revoke all on function public.goals_recalc_calories() from public;
grant execute on function public.goals_recalc_calories() to anon;
grant execute on function public.goals_recalc_calories() to authenticated;
grant execute on function public.goals_recalc_calories() to service_role;
revoke all on function public.grant_consent(p_consent_type text, p_document_version text, p_locale text) from public;
grant execute on function public.grant_consent(p_consent_type text, p_document_version text, p_locale text) to authenticated;
grant execute on function public.grant_consent(p_consent_type text, p_document_version text, p_locale text) to service_role;
revoke all on function public.handle_new_user() from public;
grant execute on function public.handle_new_user() to service_role;
revoke all on function public.next_template_order() from public;
grant execute on function public.next_template_order() to authenticated;
grant execute on function public.next_template_order() to service_role;
revoke all on function public.reorder_workout_templates(p_ids uuid[]) from public;
grant execute on function public.reorder_workout_templates(p_ids uuid[]) to authenticated;
grant execute on function public.reorder_workout_templates(p_ids uuid[]) to service_role;
revoke all on function public.revoke_consent(p_consent_type text) from public;
grant execute on function public.revoke_consent(p_consent_type text) to authenticated;
grant execute on function public.revoke_consent(p_consent_type text) to service_role;
revoke all on function public.search_users(p_query text, p_current_user_id uuid) from public;
grant execute on function public.search_users(p_query text, p_current_user_id uuid) to authenticated;
grant execute on function public.search_users(p_query text, p_current_user_id uuid) to service_role;
revoke all on function public.sou_conta_de_teste() from public;
grant execute on function public.sou_conta_de_teste() to authenticated;
grant execute on function public.sou_conta_de_teste() to service_role;
revoke all on function public.zerar_cota_ia() from public;
grant execute on function public.zerar_cota_ia() to authenticated;
grant execute on function public.zerar_cota_ia() to service_role;
