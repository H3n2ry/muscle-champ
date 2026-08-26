-- Gera o conteúdo de schema.sql a partir do banco vivo.
--
-- Rode no SQL Editor do Supabase e cole o resultado inteiro em schema.sql,
-- substituindo tudo abaixo do cabeçalho.
--
-- Por que introspecção e não pg_dump: o dump exige a senha do Postgres, que
-- não vive no repositório. Isto roda com a sessão que você já tem aberta.
--
-- A ordem do script gerado importa: funções antes das tabelas (há colunas com
-- `default app_today()`), e `check_function_bodies = off` no topo porque
-- funções em linguagem SQL são validadas na criação e algumas referenciam
-- tabelas que só nascem depois. É o mesmo recurso que o pg_dump usa.

with funcs as (
  select string_agg(pg_get_functiondef(p.oid) || ';', E'\n\n' order by p.proname) as s
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
),
tabs as (
  select string_agg(x.ddl, E'\n\n' order by x.tbl) as s from (
    select c.relname as tbl,
           format(E'create table if not exists public.%I (\n%s\n);', c.relname,
             string_agg(format('  %I %s%s%s',
               a.attname,
               format_type(a.atttypid, a.atttypmod),
               case when a.attnotnull then ' not null' else '' end,
               case when d.adbin is not null
                    then ' default ' || pg_get_expr(d.adbin, d.adrelid) else '' end
             ), E',\n' order by a.attnum)) as ddl
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
    left join pg_attrdef d on d.adrelid = c.oid and d.adnum = a.attnum
    where n.nspname = 'public' and c.relkind = 'r'
    group by c.relname
  ) x
),
cons as (
  select string_agg(format('alter table public.%I add constraint %I %s;',
                           rel.relname, con.conname, pg_get_constraintdef(con.oid)),
                    E'\n' order by rel.relname, con.contype desc, con.conname) as s
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace n on n.oid = rel.relnamespace
  where n.nspname = 'public'
),
idx as (
  -- Índices de PK/UNIQUE já vêm pelas constraints acima; repetir daria erro.
  select string_agg(indexdef || ';', E'\n' order by tablename, indexname) as s
  from pg_indexes
  where schemaname = 'public'
    and indexname not in (select conname from pg_constraint where contype in ('p','u'))
),
rls as (
  select string_agg(format('alter table public.%I enable row level security;', c.relname),
                    E'\n' order by c.relname) as s
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname='public' and c.relkind='r' and c.relrowsecurity
),
-- %I e nao %L no nome da politica: nome de politica e IDENTIFICADOR.
-- Com %L sai create policy 'nome' com aspas simples e o script inteiro quebra.
pols as (
  select string_agg(format(E'create policy %I on public.%I as %s for %s to %s%s%s;',
           policyname, tablename, permissive, cmd, array_to_string(roles, ', '),
           case when qual is not null then E'\n  using (' || qual || ')' else '' end,
           case when with_check is not null then E'\n  with check (' || with_check || ')' else '' end),
         E'\n' order by tablename, cmd) as s
  from pg_policies where schemaname='public'
),
trigs as (
  select coalesce(string_agg(pg_get_triggerdef(t.oid) || ';', E'\n' order by t.tgname), '') as s
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and not t.tgisinternal
),
-- Sem este bloco, reconstruir deixaria TODA função executável por `anon`:
-- no Postgres, PUBLIC ganha EXECUTE por padrão ao criar uma função.
privs as (
  select string_agg(
    format('revoke all on function public.%I(%s) from public;', f.proname, f.args)
    || coalesce((select string_agg(format(E'\ngrant execute on function public.%I(%s) to %I;',
                                          f.proname, f.args, g), '')
                 from unnest(f.quem) g
                 where g <> 'PUBLIC' and g not in ('postgres','supabase_admin')), ''),
    E'\n' order by f.proname) as s
  from (
    select p.proname,
           pg_get_function_identity_arguments(p.oid) as args,
           coalesce((select array_agg(distinct coalesce(r.rolname,'PUBLIC')
                                      order by coalesce(r.rolname,'PUBLIC'))
                     from aclexplode(p.proacl) a
                     left join pg_roles r on r.oid = a.grantee
                     where a.privilege_type = 'EXECUTE'),
                    array['PUBLIC']) as quem
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prokind = 'f'
  ) f
)
select
  E'set check_function_bodies = off;\n\n-- ===== FUNCOES =====\n\n' || funcs.s ||
  E'\n\n-- ===== TABELAS =====\n\n' || tabs.s ||
  E'\n\n-- ===== CONSTRAINTS =====\n\n' || cons.s ||
  E'\n\n-- ===== INDICES =====\n\n' || coalesce(idx.s,'') ||
  E'\n\n-- ===== RLS =====\n\n' || rls.s ||
  E'\n\n-- ===== POLITICAS =====\n\n' || pols.s ||
  E'\n\n-- ===== TRIGGERS =====\n\n' || trigs.s ||
  E'\n\n-- ===== PERMISSOES DE FUNCAO =====\n\n' || privs.s || E'\n'
  as script
from funcs, tabs, cons, idx, rls, pols, trigs, privs;
