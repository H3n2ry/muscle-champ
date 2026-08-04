-- Feature: contador de água + data de nascimento (idade).
--
-- 1) Adiciona `birth_date` em goals (necessário para o cálculo de água por idade)
-- 2) Adiciona `daily_water_ml` em goals (meta diária de água sugerida)
-- 3) Função calc_daily_water: Água (ml) = peso(kg) * fator por faixa etária
--       até 17 anos: 40 | 18-55: 35 | 56-65: 30 | acima de 65: 25
-- 4) Estende o trigger de recálculo de goals para também recalcular a água
-- 5) Cria a tabela water_logs (registros de consumo) com RLS owner-scoped
-- 6) handle_new_user passa a gravar birth_date vindo do cadastro
--
-- Revisar e aplicar no projeto jryetjysjiyuuoznaejc.

-- ── 1 + 2) Novas colunas em goals ──────────────────────────────────────────
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS birth_date     date;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS daily_water_ml integer;

-- ── 3) Fórmula da meta de água ─────────────────────────────────────────────
-- STABLE (não IMMUTABLE) porque age()/CURRENT_DATE dependem da data atual.
CREATE OR REPLACE FUNCTION public.calc_daily_water(
  p_weight double precision, p_birth_date date)
 RETURNS integer
 LANGUAGE plpgsql STABLE
 SET search_path = 'public'
AS $$
DECLARE
  v_age    int;
  v_factor int;
BEGIN
  IF p_weight IS NULL OR p_weight <= 0 THEN
    RETURN NULL;
  END IF;

  -- Sem data de nascimento → assume faixa 18-55 (fator 35)
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
$$;

-- ── 4) Estende o recálculo de goals (calorias + água) ──────────────────────
CREATE OR REPLACE FUNCTION public.goals_recalc_calories()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = 'public'
AS $$
BEGIN
  NEW.daily_calories := public.calc_daily_calories(
    NEW.current_weight, NEW.height_cm, NEW.goal_type);
  NEW.daily_water_ml := public.calc_daily_water(
    NEW.current_weight, NEW.birth_date);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_goals_recalc ON public.goals;
CREATE TRIGGER trg_goals_recalc
  BEFORE INSERT OR UPDATE OF current_weight, height_cm, goal_type, birth_date
  ON public.goals
  FOR EACH ROW EXECUTE FUNCTION public.goals_recalc_calories();

-- Preenche daily_water_ml para linhas já existentes
UPDATE public.goals
   SET daily_water_ml = public.calc_daily_water(current_weight, birth_date)
 WHERE daily_water_ml IS NULL;

-- ── 5) Tabela de registros de água ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.water_logs (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date       date NOT NULL DEFAULT CURRENT_DATE,
  amount_ml  integer NOT NULL CHECK (amount_ml > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_water_logs_user_date
  ON public.water_logs (user_id, date);

ALTER TABLE public.water_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS water_logs_select_own ON public.water_logs;
CREATE POLICY water_logs_select_own ON public.water_logs
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS water_logs_insert_own ON public.water_logs;
CREATE POLICY water_logs_insert_own ON public.water_logs
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS water_logs_delete_own ON public.water_logs;
CREATE POLICY water_logs_delete_own ON public.water_logs
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ── 6) Cadastro grava a data de nascimento ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
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
  RETURN NEW;
END;
$$;
