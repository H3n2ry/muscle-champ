-- O perfil público passa a dizer qual é o vínculo com quem está olhando.
--
-- Aplicada em produção como `perfil_publico_estado_de_amizade`
-- (20260826132333). Sem isto o selo do avatar apareceria sempre, virando um
-- botão que refaz um pedido já feito ou que "adiciona" quem já é amigo.
--
-- Quatro valores: proprio | amigos | pendente | nenhum. Só `nenhum` mostra o
-- "+", só `amigos` mostra o "−".
--
-- ⚠️ A consulta olha as DUAS direções. A versão ingênua (`f.user_id =
-- auth.uid()`) diria `nenhum` para quem já te mandou um pedido, e a pessoa
-- veria o "+" para alguém que a convidou primeiro.

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
                         -- Aceita ganha de pendente quando as duas linhas
                         -- existem (cada lado pediu antes de aceitar).
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
$$;
