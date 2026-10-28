-- Recria o esquema de produção no projeto Supabase de TESTE
-- (muscle-camp-teste, ref cqnuthoovekdrwzbsltx). NUNCA rode isto em produção.
--
-- Baixa o schema.sql de um commit do GitHub (repo público) e executa. Troque
-- o commit na URL pelo que quer espelhar. Só estrutura: nenhum dado de
-- usuário sai de produção.
--
-- Dois ajustes que o schema.sql sozinho não aguenta numa base vazia:
--   * o cabeçalho tem um CR solto dentro de um comentário, e o Postgres trata
--     CR como fim de linha — o resto da linha vira código. Por isso executa a
--     partir da linha do `set check_function_bodies = off;`.
--   * assinar_demo() RETURNS assinaturas: tipo de retorno não é adiado pelo
--     check_function_bodies, e a tabela só nasce depois das funções. Cria a
--     tabela antes (o `if not exists` do arquivo vira no-op).
--   * as constraints saem em ordem alfabética de tabela, e várias FKs vêm
--     antes da PK da tabela que referenciam. Aqui as FKs rodam por último.
--
-- Depois dele, rode espelhar_no_banco_de_teste_extras.sql (auth e storage,
-- que o schema.sql não cobre).

create extension if not exists http with schema extensions;

do $$
declare
  v_sql   text;
  v_cons  text;
  v_resto text;
  v_linha text;
begin
  select content into v_sql
    from extensions.http_get('https://raw.githubusercontent.com/H3n2ry/muscle-champ/COMMIT/supabase/schema.sql');
  if v_sql is null or length(v_sql) < 60000 then
    raise exception 'schema.sql nao baixou (% bytes)', length(v_sql);
  end if;

  v_sql := substr(v_sql, strpos(v_sql, E'\nset check_function_bodies = off;'));

  create table if not exists public.assinaturas (
    user_id uuid not null,
    plano_id text not null,
    expira_em timestamp with time zone not null,
    em_trial boolean not null default false,
    proxima_cobranca integer not null default 0,
    atualizado_em timestamp with time zone not null default now()
  );

  v_cons  := substr(v_sql, strpos(v_sql, '-- ===== CONSTRAINTS ====='));
  v_resto := substr(v_cons, strpos(v_cons, '-- ===== INDICES ====='));
  v_cons  := left(v_cons, strpos(v_cons, '-- ===== INDICES =====') - 1);
  v_sql   := left(v_sql, strpos(v_sql, '-- ===== CONSTRAINTS =====') - 1);

  execute v_sql;
  for v_linha in
    select l from regexp_split_to_table(v_cons, E'\n') l
     where l like 'alter table %'
     order by (l like '%FOREIGN KEY%'), l
  loop
    execute v_linha;
  end loop;
  execute v_resto;
end $$;
