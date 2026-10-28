-- A posição do dashboard ("#N Global") passa a vir do servidor, e as quatro
-- funções de ranking passam a ordenar do mesmo jeito.
--
-- ## O defeito
--
-- O dashboard calculava a posição lendo `points` de TODOS os usuários e
-- ordenando no app. Só que a RLS de `points` devolve apenas as linhas do
-- próprio usuário: a lista chegava com uma entrada, e todo mundo aparecia em
-- "#1 Global". Um `catch (_) {}` em volta escondia qualquer erro.
--
-- As RPCs que deveriam resolver isso existiam e também estavam erradas:
--   * `get_global_rank` era SECURITY INVOKER — sob a mesma RLS, mesmo "#1";
--     e contava só quem TEM pontos, enquanto a aba Ranking lista todo perfil.
--     Mesmo funcionando, as duas telas dariam números diferentes.
--   * `get_friends_rank` lia `auth.users`, que o papel authenticated não
--     enxerga: falharia sempre. E confiava no `p_user_id` recebido.
-- Nenhuma tela as chamava.
--
-- ## Empates
--
-- As listas usavam `ROW_NUMBER() OVER (ORDER BY pontos DESC)` sem desempate.
-- Entre empatados — e todo mundo com 0 pontos está empatado — o Postgres
-- devolve qualquer ordem, e ela pode mudar de uma consulta para a outra: a
-- pessoa via a própria posição pular sem ter feito nada.
--
-- Desempate agora: quem entrou primeiro (`created_at`), depois `id`. As quatro
-- funções usam exatamente a mesma ordenação, então o "#N" do dashboard é a
-- linha N da aba Ranking.
--
-- ⚠️ Mudar a ordenação em uma delas exige mudar nas quatro. Senão o dashboard
-- e a aba Ranking voltam a discordar, e ninguém percebe até alguém reclamar.
--
-- `p_user_id` continua na assinatura só por compatibilidade (APK antigo pode
-- chamar); é IGNORADO — vale `auth.uid()`, como em todas as RPCs do banco.

create or replace function public.get_global_rank(p_user_id uuid)
 returns integer
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select pos::integer from (
    select pr.id,
           row_number() over (
             order by coalesce(sum(pt.amount), 0) desc, pr.created_at, pr.id
           ) as pos
      from profiles pr
      left join points pt on pt.user_id = pr.id
     group by pr.id
  ) r
  where r.id = auth.uid();
$function$;

create or replace function public.get_friends_rank(p_user_id uuid)
 returns integer
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select pos::integer from (
    select pr.id,
           row_number() over (
             order by coalesce(sum(pt.amount), 0) desc, pr.created_at, pr.id
           ) as pos
      from profiles pr
      left join points pt on pt.user_id = pr.id
     where pr.id = auth.uid()
        or pr.id in (
          select friend_id from friendships where user_id = auth.uid() and status = 'accepted'
          union
          select user_id  from friendships where friend_id = auth.uid() and status = 'accepted'
        )
     group by pr.id
  ) r
  where r.id = auth.uid();
$function$;

create or replace function public.get_global_ranking(p_user_id uuid)
 returns table(rank_position bigint, user_id uuid, user_name text, avatar_url text, total_points bigint, is_current_user boolean)
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select
    row_number() over (
      order by coalesce(sum(pt.amount), 0) desc, pr.created_at, pr.id
    )                                   as rank_position,
    pr.id                               as user_id,
    pr.name                             as user_name,
    pr.avatar_url                       as avatar_url,
    coalesce(sum(pt.amount), 0)         as total_points,
    (pr.id = auth.uid())                as is_current_user
  from profiles pr
  left join points pt on pt.user_id = pr.id
  group by pr.id, pr.name, pr.avatar_url
  order by rank_position
  limit 100;
$function$;

create or replace function public.get_friends_ranking(p_user_id uuid)
 returns table(rank_position bigint, user_id uuid, user_name text, avatar_url text, total_points bigint, is_current_user boolean, is_friend boolean)
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select
    row_number() over (
      order by coalesce(sum(pt.amount), 0) desc, pr.created_at, pr.id
    )                                   as rank_position,
    pr.id                               as user_id,
    pr.name                             as user_name,
    pr.avatar_url                       as avatar_url,
    coalesce(sum(pt.amount), 0)         as total_points,
    (pr.id = auth.uid())                as is_current_user,
    (pr.id <> auth.uid())               as is_friend
  from profiles pr
  left join points pt on pt.user_id = pr.id
  where pr.id = auth.uid()
     or pr.id in (
       select friend_id from friendships where user_id = auth.uid() and status = 'accepted'
       union
       select user_id  from friendships where friend_id = auth.uid() and status = 'accepted'
     )
  group by pr.id, pr.name, pr.avatar_url
  order by rank_position;
$function$;

-- Viraram DEFINER: anon não pode executar nenhuma das quatro.
revoke all on function public.get_global_rank(uuid)     from public, anon;
revoke all on function public.get_friends_rank(uuid)    from public, anon;
revoke all on function public.get_global_ranking(uuid)  from public, anon;
revoke all on function public.get_friends_ranking(uuid) from public, anon;
grant execute on function public.get_global_rank(uuid)     to authenticated, service_role;
grant execute on function public.get_friends_rank(uuid)    to authenticated, service_role;
grant execute on function public.get_global_ranking(uuid)  to authenticated, service_role;
grant execute on function public.get_friends_ranking(uuid) to authenticated, service_role;
