-- Bug fix: a meta calórica (goals.daily_calories) só era calculada no cadastro
-- (trigger handle_new_user) e nunca era recalculada quando o usuário editava
-- peso, altura ou objetivo no perfil. Esta migration centraliza a fórmula numa
-- função e adiciona um trigger que recalcula em toda mudança relevante.
--
-- Aplicada no projeto jryetjysjiyuuoznaejc em 2026-07-02.

-- Fonte única da fórmula de meta calórica
CREATE OR REPLACE FUNCTION public.calc_daily_calories(
  p_weight double precision, p_height double precision, p_goal_type text)
 RETURNS integer
 LANGUAGE plpgsql IMMUTABLE
 SET search_path = 'public'
AS $$
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
$$;

-- Recalcula daily_calories no INSERT e quando peso/altura/objetivo mudam
CREATE OR REPLACE FUNCTION public.goals_recalc_calories()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = 'public'
AS $$
BEGIN
  NEW.daily_calories := public.calc_daily_calories(
    NEW.current_weight, NEW.height_cm, NEW.goal_type);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_goals_recalc ON public.goals;
CREATE TRIGGER trg_goals_recalc
  BEFORE INSERT OR UPDATE OF current_weight, height_cm, goal_type
  ON public.goals
  FOR EACH ROW EXECUTE FUNCTION public.goals_recalc_calories();

-- handle_new_user deixa de calcular (o trigger de goals cuida) — sem duplicar a fórmula
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
BEGIN
  INSERT INTO public.profiles (id, name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', 'Usuário'))
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.goals (user_id, goal_type, height_cm, current_weight, target_weight, weekly_workout_goal)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'goal_type', 'maintain'),
    COALESCE((NEW.raw_user_meta_data->>'height_cm')::double precision, 170),
    COALESCE((NEW.raw_user_meta_data->>'current_weight')::double precision, 70),
    COALESCE((NEW.raw_user_meta_data->>'target_weight')::double precision, 70),
    COALESCE((NEW.raw_user_meta_data->>'weekly_workout_goal')::int, 3)
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;
