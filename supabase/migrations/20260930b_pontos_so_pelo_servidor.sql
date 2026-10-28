-- Pontos só nascem de regra do servidor. Nenhum caminho deixa o cliente se dar
-- pontos à vontade.
--
-- O ranking é o coração do app ("Compete. Evolua. Domine."), e havia CINCO
-- jeitos de fabricar pontos, todos pela API pública com o próprio login:
--
--   1. INSERT direto em `points` — a política "Inserir pontos próprios"
--      aceitava qualquer `amount`. Um POST levava ao topo do ranking. O app
--      nunca usou isso: só LÊ `points`.
--   2. `workouts` (+10 por linha com completed = true, sem teto). O cliente
--      podia inserir quantas quisesse. Só a RPC `complete_workout_template`
--      deveria escrever ali — e é a única que escreve desde os templates.
--   3. `exercises` (+5 por linha com weight > previous_weight, sem teto).
--      Tabela legada: nunca recebeu uma linha, e nenhuma tela a usa.
--   4. `weight_logs` (+20 a cada pesagem abaixo do peso das metas, sem teto).
--      O gatilho disparava em INSERT **OR UPDATE**, então reenviar a pesagem
--      do mesmo dia pontuava de novo. E comparava com `goals.current_weight`,
--      que o app grava EM PARALELO com a pesagem (Future.wait) — a pontuação
--      legítima dependia de qual das duas escritas chegava primeiro.
--   5. `diet_logs` (+10 pela meta calórica) — "uma vez por dia", mas o dia
--      checado era `NEW.date`, a data que o CLIENTE manda. Refeições em datas
--      passadas inventadas pontuavam uma vez por data falsa.
--
-- ⚠️ A armadilha do conserto: quatro desses gatilhos eram SECURITY INVOKER.
-- Rodavam como o usuário, sob a RLS de `points` — e precisavam da política de
-- INSERT para funcionar. Apagar a política sozinha teria feito o INSERT do
-- ponto falhar DENTRO da transação do registro da refeição: ninguém mais
-- conseguiria registrar comida. Por isso os gatilhos viram DEFINER antes.
--
-- Gatilho SECURITY DEFINER não vira porta de entrada: função que devolve
-- `trigger` não pode ser chamada via /rest/v1/rpc, só disparada pela tabela —
-- e a tabela continua sob a RLS do dono.

-- ── 1. Gatilhos: DEFINER, e com teto de verdade ─────────────────────────────

create or replace function public.fn_award_diet_points()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v_total_cal   integer;
  v_goal_cal    integer;
  v_already_won boolean;
begin
  -- Só a meta de HOJE pontua. Antes a data vinha do cliente, e cada data
  -- passada inventada era um "hoje" novo.
  if NEW.date <> public.app_today() then
    return NEW;
  end if;

  select coalesce(sum(calories), 0) into v_total_cal
    from public.diet_logs where user_id = NEW.user_id and date = NEW.date;

  select coalesce(daily_calories, 2000) into v_goal_cal
    from public.goals where user_id = NEW.user_id;

  -- "Já ganhou hoje" pelo relógio do servidor, no mesmo fuso de app_today().
  select exists (
    select 1 from public.points
     where user_id = NEW.user_id
       and reason = 'diet_goal_met'
       and timezone('America/Sao_Paulo', created_at)::date = public.app_today()
  ) into v_already_won;

  if not v_already_won
     and v_total_cal >= (v_goal_cal * 0.9)
     and v_total_cal <= (v_goal_cal * 1.1) then
    insert into public.points (user_id, amount, reason, reference_id)
    values (NEW.user_id, 10, 'diet_goal_met', NEW.id);
  end if;
  return NEW;
end;
$function$;

-- Com `workouts` e `exercises` só-leitura para o cliente (seção 3), estes dois
-- só disparam por escrita do servidor. DEFINER para não dependerem de política
-- de INSERT em `points` que não existe mais.
create or replace function public.fn_award_workout_points()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
begin
  if NEW.completed = true and (OLD.completed is null or OLD.completed = false) then
    insert into public.points (user_id, amount, reason, reference_id)
    values (NEW.user_id, 10, 'workout_completed', NEW.id);
  end if;
  return NEW;
end;
$function$;

create or replace function public.fn_award_load_progression()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
begin
  if NEW.previous_weight is not null and NEW.weight > NEW.previous_weight then
    insert into public.points (user_id, amount, reason, reference_id)
    select w.user_id, 5, 'load_progression', NEW.id
      from public.workouts w where w.id = NEW.workout_id;
  end if;
  return NEW;
end;
$function$;

create or replace function public.fn_award_weight_progression()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v_goal_type text;
  v_anterior  decimal;
begin
  select goal_type into v_goal_type from public.goals where user_id = NEW.user_id;
  if v_goal_type is null or v_goal_type not in ('lose_weight', 'gain_weight') then
    return NEW;
  end if;

  -- Compara com a PESAGEM ANTERIOR, não com goals.current_weight. O app grava
  -- as duas coisas em paralelo, então comparar com goals era uma corrida: se a
  -- meta chegasse primeiro, a pesagem nunca parecia progresso.
  select weight into v_anterior
    from public.weight_logs
   where user_id = NEW.user_id and date < NEW.date
   order by date desc
   limit 1;
  if v_anterior is null then
    return NEW;
  end if;

  if not ((v_goal_type = 'lose_weight' and NEW.weight <= v_anterior - 0.1)
       or (v_goal_type = 'gain_weight' and NEW.weight >= v_anterior + 0.1)) then
    return NEW;
  end if;

  -- No máximo uma vez por semana — é a cadência do lembrete de segunda-feira.
  -- Sem isto, reenviar a pesagem (o gatilho dispara também em UPDATE) ou
  -- inventar pesagens em datas passadas pontuava sem fim.
  if exists (select 1 from public.points
              where user_id = NEW.user_id
                and reason = 'weight_progression'
                and created_at >= date_trunc('week', now())) then
    return NEW;
  end if;

  insert into public.points (user_id, amount, reason)
  values (NEW.user_id, 20, 'weight_progression');
  return NEW;
end;
$function$;

-- ── 2. Sem INSERT direto em points ──────────────────────────────────────────
drop policy if exists "Inserir pontos próprios" on public.points;

-- ── 3. workouts e exercises: o cliente só lê ────────────────────────────────
--
-- `workouts` recebe linha só da RPC `complete_workout_template` (DEFINER). O
-- repositório legado que escrevia aqui (WorkoutRepository) não tem nenhuma
-- tela e foi removido junto com esta migração.
drop policy if exists "Acesso próprios treinos" on public.workouts;
create policy "Ver próprios treinos" on public.workouts
  for select using (auth.uid() = user_id);

drop policy if exists "Acesso próprios exercícios" on public.exercises;
create policy "Ver próprios exercícios" on public.exercises
  for select using (exists (
    select 1 from public.workouts w
     where w.id = exercises.workout_id and w.user_id = auth.uid()));
