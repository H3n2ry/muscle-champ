-- Anotação por exercício e histórico de carga/repetição por sessão.
--
-- ## Por que a tabela nova é obrigatória
--
-- Até hoje NENHUM dado de sessão passada sobrevivia. O
-- `complete_workout_template` lia o peso antigo, contava a progressão, dava os
-- pontos e então SOBRESCREVIA `template_exercises.weight_kg` com o novo valor.
-- O número anterior morria ali. E `workout_completions` guarda só
-- `(user_id, template_id, completed_date)`: registra QUE houve treino, nunca
-- O QUE foi levantado.
--
-- Ou seja, o app sempre soube comparar duas sessões seguidas o bastante para
-- dar ponto, e jogava fora o histórico logo depois.
--
-- ⚠️ Consequência aceita: o gráfico nasce VAZIO para todo mundo, inclusive para
-- quem treina há meses. Não há como preencher retroativamente — o dado nunca
-- existiu. Ele enche a partir do primeiro treino concluído depois desta
-- migração.
--
-- ## A ordem importa
--
-- O INSERT do histórico entra ANTES do UPDATE que sobrescreve. Invertido, ele
-- gravaria o valor novo como se fosse o de hoje e o de hoje sumiria — que é
-- exatamente o defeito que esta migração existe para consertar.

-- ── Anotação, presa ao exercício ────────────────────────────────────────────
--
-- Uma por exercício, não uma por sessão: serve para o que NÃO muda entre
-- treinos ("banco na altura 4", "pegada média", "não travar o cotovelo"), então
-- tem que aparecer toda vez. Editar substitui a anterior.
alter table public.template_exercises
  add column if not exists anotacao text;

-- ── Histórico ───────────────────────────────────────────────────────────────
create table if not exists public.historico_de_exercicios (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users(id) on delete cascade,
  template_exercise_id  uuid not null
                          references public.template_exercises(id) on delete cascade,
  -- Cópia do nome no dia. O exercício pode ser renomeado depois, e o gráfico
  -- de uma sessão antiga deve continuar dizendo o que foi feito naquele dia.
  nome                  text not null,
  peso_kg               numeric(6,2) not null,
  series                integer not null,
  reps                  integer not null,
  data                  date not null default public.app_today(),
  created_at            timestamptz default now(),

  -- Uma linha por exercício por dia. Hoje isso já é garantido antes de chegar
  -- aqui — `workout_completions` tem `on conflict do nothing` em
  -- (user_id, template_id, completed_date) e a função sai com `already_done`
  -- antes do laço. A restrição está aqui para a garantia não depender de essa
  -- outra tabela continuar se comportando.
  constraint historico_de_exercicios_um_por_dia
    unique (template_exercise_id, data)
);

-- O gráfico sempre pergunta "os últimos N desta série, do mais novo para o
-- mais antigo".
create index if not exists historico_de_exercicios_linha_do_tempo
  on public.historico_de_exercicios (template_exercise_id, data desc);

alter table public.historico_de_exercicios enable row level security;

-- ⚠️ SELECT apenas, de propósito — mesmo padrão de `cota_ia_diaria`.
--
-- Sem política de escrita, nem o dono insere daqui de fora: quem grava é só o
-- `complete_workout_template`, que é SECURITY DEFINER. Histórico de progressão
-- que o cliente pode fabricar não é histórico, é rascunho — e a pessoa estaria
-- mentindo para si mesma, que é o único público deste gráfico.
create policy "own exercise history" on public.historico_de_exercicios
  for select using (auth.uid() = user_id);

-- ── A função passa a gravar antes de apagar ─────────────────────────────────
create or replace function public.complete_workout_template(
  p_user_id uuid, p_template_id uuid, p_exercises jsonb)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_progression int := 0;
  v_old_weight  decimal;
  v_nome        text;
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
    -- Este SELECT é também a checagem de dono: se o exercício não pertence a um
    -- template de quem chamou, NOT FOUND e o item é ignorado.
    SELECT te.weight_kg, te.name INTO v_old_weight, v_nome
    FROM template_exercises te
    JOIN workout_templates wt ON wt.id = te.template_id
    WHERE te.id = v_ex.id AND wt.user_id = auth.uid();

    IF NOT FOUND THEN CONTINUE; END IF;

    -- ⚠️ ANTES do UPDATE abaixo. Grava o que foi feito HOJE.
    INSERT INTO historico_de_exercicios
      (user_id, template_exercise_id, nome, peso_kg, series, reps, data)
    VALUES
      (auth.uid(), v_ex.id, v_nome, v_ex.weight_kg, v_ex.sets, v_ex.reps, v_hoje)
    ON CONFLICT (template_exercise_id, data) DO NOTHING;

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
$function$;

-- O Supabase concede EXECUTE a anon/authenticated por default privileges em
-- toda função nova do schema public, e `revoke from public` NÃO encosta nesses
-- grants por papel (ver 20260901_chave_brevo_no_vault.sql). Como esta função já
-- existia, os grants dela permanecem; reafirmados aqui para o arquivo ser
-- aplicável sozinho.
revoke all on function public.complete_workout_template(uuid, uuid, jsonb) from anon;
grant execute on function public.complete_workout_template(uuid, uuid, jsonb) to authenticated;
