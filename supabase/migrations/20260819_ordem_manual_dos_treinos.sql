-- Ordem manual dos treinos.
--
-- Até aqui a listagem saía por created_at, sem controle do usuário. Agora
-- workout_templates ganha order_index e o usuário reordena na tela.
--
-- Backfill: numera por created_at dentro de cada usuário, preservando
-- exatamente a ordem que ele já via.
--
-- ⚠️ A assinatura de get_workout_templates NÃO muda de propósito. Devolver
-- order_index exigiria DROP FUNCTION, e isso deixaria a listagem quebrada para
-- quem estivesse com o app aberto durante o deploy. O cliente só precisa da
-- lista já ordenada.

ALTER TABLE public.workout_templates
  ADD COLUMN IF NOT EXISTS order_index integer;

WITH numerados AS (
  SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) - 1 AS pos
  FROM public.workout_templates
)
UPDATE public.workout_templates t
   SET order_index = n.pos
  FROM numerados n
 WHERE t.id = n.id AND t.order_index IS NULL;

ALTER TABLE public.workout_templates
  ALTER COLUMN order_index SET DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_workout_templates_user_order
  ON public.workout_templates (user_id, order_index);

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
  -- created_at desempata: template novo entra com default 0 até o próximo
  -- reorder, e a ordem continua estável.
  ORDER BY COALESCE(t.order_index, 0) ASC, t.created_at ASC;
$$;

-- Template novo entra no fim da lista, não no início.
CREATE OR REPLACE FUNCTION public.next_template_order()
 RETURNS integer
 LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path = 'public'
AS $$
  SELECT COALESCE(MAX(order_index), -1) + 1
    FROM workout_templates WHERE user_id = auth.uid();
$$;

-- Persiste a nova ordem. p_ids vem na sequência final desejada.
--
-- Um UPDATE por posição, filtrando por user_id: um id de outro usuário
-- simplesmente não casa nenhuma linha, então não há como reordenar treino
-- alheio mesmo mandando o id dele. (Testado.)
CREATE OR REPLACE FUNCTION public.reorder_workout_templates(p_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = 'public'
AS $$
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
$$;

REVOKE ALL ON FUNCTION public.next_template_order()             FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.reorder_workout_templates(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.next_template_order()             TO authenticated;
GRANT EXECUTE ON FUNCTION public.reorder_workout_templates(uuid[]) TO authenticated;
