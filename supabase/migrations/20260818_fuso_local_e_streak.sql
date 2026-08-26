-- Corrige o "dia" do app: fuso local em vez de UTC, e conserta a sequência.
--
-- PROBLEMA
-- O banco roda em UTC e o usuário está em BRT (UTC-3). Tudo que usava
-- CURRENT_DATE virava o dia às 21:00 no horário do usuário, três horas antes
-- da meia-noite dele. Consequências observadas:
--
--   • Treino concluído entre 21:00 e 00:00 era gravado com a data de AMANHÃ,
--     e o card "FEITO HOJE" ficava verde o dia seguinte inteiro — parecia
--     "resetar 24h depois" em vez de na virada do dia.
--   • get_streak ancorava em CURRENT_DATE, então a sequência ZERAVA às 21:00
--     todo dia, mesmo com treino feito naquela tarde.
--
-- SOLUÇÃO
-- Uma única fonte de verdade para "hoje": app_today(). Todos os defaults de
-- coluna e todas as funções passam a usá-la.
--
-- ⚠️ Fuso fixo em America/Sao_Paulo. Resolve o problema real de hoje, mas se o
-- app for mesmo distribuído fora do Brasil (ver docs/juridico/), isso vira
-- dívida: o certo passa a ser guardar o fuso de cada usuário em `goals` e
-- resolver o dia por titular.

-- ── Fonte única de "hoje" ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.app_today()
 RETURNS date
 LANGUAGE sql STABLE
 SET search_path = 'public'
AS $$ SELECT (timezone('America/Sao_Paulo', now()))::date $$;

COMMENT ON FUNCTION public.app_today() IS
  'Data corrente no fuso do usuário. NÃO usar CURRENT_DATE no schema: ele é UTC '
  'e vira o dia às 21:00 BRT.';

GRANT EXECUTE ON FUNCTION public.app_today() TO authenticated;

-- ── Defaults de coluna ─────────────────────────────────────────────────────
ALTER TABLE public.workouts            ALTER COLUMN date           SET DEFAULT public.app_today();
ALTER TABLE public.diet_logs           ALTER COLUMN date           SET DEFAULT public.app_today();
ALTER TABLE public.water_logs          ALTER COLUMN date           SET DEFAULT public.app_today();
ALTER TABLE public.weight_logs         ALTER COLUMN date           SET DEFAULT public.app_today();
ALTER TABLE public.bioimpedance_logs   ALTER COLUMN measured_at    SET DEFAULT public.app_today();
ALTER TABLE public.workout_completions ALTER COLUMN completed_date SET DEFAULT public.app_today();

-- ── Sequência ──────────────────────────────────────────────────────────────
-- Reescrita em duas frentes:
--
-- 1) Passa a ler workout_completions (sistema de templates, o que o app usa
--    hoje) em vez de workouts, que é legado.
-- 2) Âncora tolerante: conta a partir de hoje se houve treino hoje, senão a
--    partir de ontem. A versão antiga exigia treino HOJE, então a sequência
--    zerava à meia-noite e só voltava depois do treino do dia — o usuário via
--    "0 dias consecutivos" durante toda a manhã.
CREATE OR REPLACE FUNCTION public.get_streak(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql STABLE SECURITY DEFINER
 SET search_path = 'public'
AS $$
DECLARE
  v_uid    uuid := COALESCE(auth.uid(), p_user_id);
  v_hoje   date := public.app_today();
  v_ancora date;
  v_total  int;
BEGIN
  SELECT max(completed_date) INTO v_ancora
    FROM workout_completions
   WHERE user_id = v_uid AND completed_date <= v_hoje;

  -- Sem treino, ou último treino anterior a ontem → sequência quebrada
  IF v_ancora IS NULL OR v_ancora < v_hoje - 1 THEN
    RETURN 0;
  END IF;

  SELECT count(*) INTO v_total
  FROM (
    SELECT completed_date,
           ROW_NUMBER() OVER (ORDER BY completed_date DESC) AS rn
    FROM (SELECT DISTINCT completed_date
            FROM workout_completions
           WHERE user_id = v_uid AND completed_date <= v_ancora) d
  ) t
  -- O cast para int é obrigatório: ROW_NUMBER() devolve bigint e o Postgres
  -- só tem operador `date - integer`. Sem ele a função lança
  -- "operator does not exist: date - bigint" e, como o perfil monta os dados
  -- com Future.wait, a tela INTEIRA cai junto.
  WHERE completed_date = v_ancora - (rn - 1)::int;

  RETURN COALESCE(v_total, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.get_streak(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_streak(uuid) TO authenticated;

-- ── Atividade da semana ────────────────────────────────────────────────────
-- O card de sequência desenhava sete caixas com rótulos fixos ['S','T','Q',...]
-- e acendia as N primeiras da esquerda. Ou seja: sempre começava na segunda e
-- acendia caixas sem relação com o dia que representavam.
--
-- Agora o servidor devolve os 7 dias reais terminando HOJE, com o dia da
-- semana de cada um e se houve treino. A UI só desenha.
CREATE OR REPLACE FUNCTION public.get_week_activity()
 RETURNS TABLE(dia date, dow int, treinou boolean)
 LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path = 'public'
AS $$
  SELECT d::date AS dia,
         EXTRACT(ISODOW FROM d)::int AS dow,          -- 1=segunda … 7=domingo
         EXISTS (SELECT 1 FROM workout_completions c
                  WHERE c.user_id = auth.uid()
                    AND c.completed_date = d::date) AS treinou
    FROM generate_series(public.app_today() - 6, public.app_today(), interval '1 day') d
   ORDER BY d;
$$;

REVOKE ALL ON FUNCTION public.get_week_activity() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_week_activity() TO authenticated;

-- ── Funções que ainda usavam CURRENT_DATE ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_workout_templates(p_user_id uuid)
 RETURNS TABLE(id uuid, name text, done_today boolean, exercise_count integer)
 LANGUAGE sql SECURITY DEFINER
 SET search_path = 'public'
AS $$
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
  ORDER BY t.created_at ASC;
$$;

CREATE OR REPLACE FUNCTION public.complete_workout_template(
  p_user_id uuid, p_template_id uuid, p_exercises jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = 'public'
AS $$
DECLARE
  v_progression int := 0;
  v_old_weight  decimal;
  v_ex          record;
  v_hoje        date := public.app_today();
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Não autorizado';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM workout_templates
    WHERE id = p_template_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Template não encontrado';
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
$$;
