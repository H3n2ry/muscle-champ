-- Copiar o treino de outro competidor para os seus.
--
-- Aplicada em produção como `copiar_treino_de_outro_atleta` (20260825181804).
-- O arquivo ficou faltando na hora; sem ele, reconstruir o banco a partir da
-- pasta deixaria o botão COPIAR quebrado.

-- `get_perfil_publico` passa a devolver o id de cada treino. A versão anterior
-- listava só o que aparece na tela, e copiar precisa referenciar a origem.
-- É um UUID: não diz nada sobre a pessoa.
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

-- Copia estrutura e nomes; NÃO copia carga.
--
-- Zerar `weight_kg` é decisão de produto, não descuido: o supino de 100 kg de
-- outra pessoa não diz nada sobre o seu, e um iniciante tentando repetir é
-- risco de lesão num app que já carrega disclaimer de saúde. O app pede a
-- carga na hora do treino de qualquer forma.
--
-- SECURITY DEFINER porque precisa ler `workout_templates` e
-- `template_exercises` de OUTRO usuário — as duas continuam fechadas por RLS.
create or replace function public.copiar_treino(
  p_template_id uuid,
  p_nome        text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
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

  -- Copiar o próprio treino encheria a lista de duplicata sem sentido.
  if exists (select 1 from workout_templates
              where id = p_template_id and user_id = v_uid) then
    raise exception 'treino ja e seu';
  end if;

  -- O nome vem do cliente (leva o crédito ao autor), então é limitado.
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
$$;

revoke execute on function public.copiar_treino(uuid, text) from public, anon;
grant  execute on function public.copiar_treino(uuid, text) to authenticated;
