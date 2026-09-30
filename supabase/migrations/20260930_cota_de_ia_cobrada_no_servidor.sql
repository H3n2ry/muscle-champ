-- A cota diária de IA passa a ser cobrada pelo SERVIDOR, dentro do groq-proxy.
--
-- ## O buraco
--
-- Até aqui quem cobrava era o cliente: `podeUsar()` antes da chamada,
-- `registrarUso()` → `consumir_cota_ia` depois do sucesso. O proxy não olhava
-- cota nenhuma. Bastava chamar o proxy direto, sem passar pelo app, para usar a
-- IA sem limite — e o proxy aceitava até a anon key, que é pública (vai no app
-- e estava no workflow do repositório público). Qualquer pessoa, sem conta,
-- usava a chave Groq do projeto com prompt livre. Verificado em 30/09/2026:
-- HTTP 200 com a anon key.
--
-- A correção tem duas metades, e esta é a do banco:
--   * o proxy exige usuário real (ou o token de serviço do healthcheck);
--   * o proxy RESERVA a cota antes de chamar a Groq e DEVOLVE se falhar.
--
-- ## Por que reservar antes, e não cobrar depois
--
-- Cobrar depois do sucesso deixaria passar rajada: dez chamadas paralelas
-- chegam antes de qualquer uma ser cobrada. A reserva é um upsert condicional,
-- atômico — a décima primeira esbarra no limite, venha junto ou separada.
--
-- ## O que se preserva do comportamento antigo
--
-- * Falha de rede ou da Groq não gasta cota: o proxy devolve.
-- * Foto não reconhecida não gasta cota — mas só UMA vez por dia por recurso.
--   Sem esse teto a regra vira brecha: o prompt é livre, então bastaria pedir
--   ao modelo para responder `{"error": "<o que eu quero saber>"}` e toda
--   chamada sairia de graça. As de visão são ~88% do custo.
-- * Pro não tem contador.

-- Quantas devoluções por "não reconheceu" já houve hoje neste recurso.
alter table public.cota_ia_diaria
  add column if not exists devolucoes integer not null default 0;

-- ⚠️ Os limites moram aqui E em `RecursoIa.limiteGratis` (Dart). O servidor é a
-- autoridade — é ele que recusa. O Dart só desenha o selo "2 de 3 hoje"; se
-- divergir, o selo mente mas ninguém passa do limite. Mudar um, mudar o outro.
--
-- `calibracao` é novo: a calibração da mão usa visão e não tinha cota nenhuma.
-- Sem entrada aqui, bastaria mandar `recurso: calibracao` para ter visão livre.
create or replace function public.limite_gratis_de_ia(p_recurso text)
 returns integer
 language sql
 immutable
 set search_path to 'public', 'pg_temp'
as $function$
  select case p_recurso
    when 'foto'       then 1
    when 'texto'      then 3
    when 'treino'     then 1
    when 'dieta'      then 1
    when 'calibracao' then 3
  end;
$function$;

-- Devolve 'pro' (não conta), 'reservada' (contou uma) ou 'esgotada'.
--
-- Recebe o usuário por parâmetro porque quem chama é o proxy com a service
-- role, depois de validar o JWT. Por isso NÃO pode ser executável pelo cliente:
-- com `p_user_id` livre, alguém gastaria a cota de outra pessoa.
create or replace function public.reservar_cota_ia(p_user_id uuid, p_recurso text)
 returns text
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v_limite integer := public.limite_gratis_de_ia(p_recurso);
  v_usos   integer;
begin
  if p_user_id is null then
    raise exception 'usuario ausente';
  end if;
  if v_limite is null then
    raise exception 'recurso invalido: %', p_recurso;
  end if;

  if exists (select 1 from public.assinaturas
              where user_id = p_user_id and expira_em > now()) then
    return 'pro';
  end if;

  -- Upsert CONDICIONAL: o `where` do do-update faz o limite valer dentro da
  -- mesma operação que incrementa. Duas chamadas simultâneas não passam juntas
  -- pelo último saldo.
  insert into public.cota_ia_diaria (user_id, dia, recurso, usos)
  values (p_user_id, app_today()::date, p_recurso, 1)
  on conflict (user_id, dia, recurso) do update
    set usos = public.cota_ia_diaria.usos + 1
    where public.cota_ia_diaria.usos < v_limite
  returning usos into v_usos;

  return case when v_usos is null then 'esgotada' else 'reservada' end;
end;
$function$;

-- 'falha'          → a Groq não entregou (rede, 5xx, 429 persistente, 4xx).
--                    Sempre devolve: nenhum token foi gasto.
-- 'nao_reconheceu' → a Groq entregou, mas o modelo disse que não conseguiu.
--                    Devolve no máximo UMA vez por dia por recurso.
create or replace function public.devolver_cota_ia(
  p_user_id uuid, p_recurso text, p_motivo text)
 returns void
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
begin
  if p_motivo = 'falha' then
    update public.cota_ia_diaria
       set usos = greatest(usos - 1, 0)
     where user_id = p_user_id and dia = app_today()::date and recurso = p_recurso;
  elsif p_motivo = 'nao_reconheceu' then
    update public.cota_ia_diaria
       set usos = greatest(usos - 1, 0), devolucoes = devolucoes + 1
     where user_id = p_user_id and dia = app_today()::date and recurso = p_recurso
       and devolucoes < 1;
  else
    raise exception 'motivo invalido: %', p_motivo;
  end if;
end;
$function$;

-- ⚠️ `revoke from public` NÃO basta: o Supabase concede EXECUTE a anon e
-- authenticated por default privileges, com grants explícitos por papel (ver
-- 20260901_chave_brevo_no_vault.sql). Tem que revogar de cada um pelo nome.
revoke all on function public.reservar_cota_ia(uuid, text) from public, anon, authenticated;
revoke all on function public.devolver_cota_ia(uuid, text, text) from public, anon, authenticated;
grant execute on function public.reservar_cota_ia(uuid, text) to service_role;
grant execute on function public.devolver_cota_ia(uuid, text, text) to service_role;

revoke all on function public.limite_gratis_de_ia(text) from public, anon;
grant execute on function public.limite_gratis_de_ia(text) to authenticated, service_role;

-- `consumir_cota_ia` vira no-op. Não some: quem estiver com o bundle antigo
-- aberto ainda a chama depois do sucesso, e com o proxy já cobrando isso seria
-- cobrança dobrada — o único uso de foto do dia contaria duas vezes. Devolve o
-- saldo atual para não quebrar quem lê o retorno. Pode sair depois que nenhum
-- cliente antigo restar.
create or replace function public.consumir_cota_ia(p_recurso text)
 returns integer
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
begin
  if auth.uid() is null then
    raise exception 'nao autenticado';
  end if;
  return coalesce((select usos from public.cota_ia_diaria
                    where user_id = auth.uid()
                      and dia = app_today()::date
                      and recurso = p_recurso), 0);
end;
$function$;
