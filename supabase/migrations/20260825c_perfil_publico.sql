-- Perfil público: tocar na foto de um competidor no ranking abre o perfil dele.
--
-- POR QUE RPC E NÃO AFROUXAR RLS. A tentação seria abrir `goals` e
-- `workout_templates` para leitura por qualquer autenticado. Só que `goals`
-- guarda peso atual, peso alvo, altura, data de nascimento, meta calórica e as
-- medidas da mão — abrir a tabela publicaria TUDO isso. Uma função lista
-- exatamente o que sai, e o que não está escrito aqui não vaza.
--
-- Fica de fora, de propósito: current_weight, target_weight, height_cm,
-- birth_date, daily_calories, hand_*. Peso é dado de saúde (LGPD Art. 11 /
-- GDPR Art. 9) e o consentimento do cadastro autoriza o app a TRATAR, não a
-- publicar para outros usuários.

-- ── Sequência, num lugar só ─────────────────────────────────────────────────

-- `get_streak` calcula sempre para quem chamou (COALESCE(auth.uid(), ...)),
-- que é o certo para ele. O perfil público precisa da sequência de OUTRA
-- pessoa, então o cálculo sai para cá em vez de ser copiado: duas cópias
-- divergiriam e a pessoa veria um número no próprio perfil e outro no público.
create or replace function public._streak_de(p_uid uuid)
returns integer
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_hoje   date := public.app_today();
  v_ancora date;
  v_total  int;
begin
  select max(completed_date) into v_ancora
    from workout_completions
   where user_id = p_uid and completed_date <= v_hoje;

  -- Sem treino ontem nem hoje, a sequência quebrou.
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
  -- O cast é obrigatório: row_number() devolve bigint e `date - bigint` não
  -- existe. Já quebrou o perfil inteiro uma vez por causa disso.
  where completed_date = v_ancora - (rn - 1)::int;

  return coalesce(v_total, 0);
end;
$$;

-- Ninguém chama direto; só as duas funções abaixo, que rodam como o dono.
revoke execute on function public._streak_de(uuid) from public, anon, authenticated;

create or replace function public.get_streak(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  -- Continua ignorando o argumento quando há sessão: a assinatura antiga
  -- ficou só por compatibilidade, e confiar nela deixaria qualquer um pedir
  -- a sequência de qualquer pessoa por esta porta.
  select public._streak_de(coalesce(auth.uid(), p_user_id));
$$;

-- ── Perfil público ──────────────────────────────────────────────────────────

create or replace function public.get_perfil_publico(p_user_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case when auth.uid() is null then null else jsonb_build_object(
    'id',            p.id,
    'nome',          p.name,
    'avatar_url',    p.avatar_url,
    'membro_desde',  p.created_at,
    -- Só o TIPO do objetivo. Os pesos ficam de fora.
    'objetivo',      coalesce(g.goal_type, 'maintain'),
    'meta_semanal',  coalesce(g.weekly_workout_goal, 0),
    'total_pontos',  coalesce((select sum(amount) from points
                                where user_id = p.id), 0),
    'total_treinos', coalesce((select count(*) from workout_completions
                                where user_id = p.id), 0),
    'streak',        public._streak_de(p.id),
    'treinos',       coalesce((
      select jsonb_agg(x.treino order by x.ordem)
      from (
        select w.order_index as ordem,
               jsonb_build_object(
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
$$;

revoke execute on function public.get_perfil_publico(uuid) from public, anon;
grant  execute on function public.get_perfil_publico(uuid) to authenticated;
