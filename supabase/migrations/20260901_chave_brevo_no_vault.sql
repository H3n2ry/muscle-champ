-- Leitura da chave da API do Brevo, guardada no Vault.
--
-- Espelha `get_groq_api_key`: mesma forma, mesmos grants, mesma razão. A chave
-- nunca aparece no repositório nem no cliente — só a Edge Function
-- `enviar-email-auth` a lê, com a service_role.
--
-- ⚠️ `revoke from public` NÃO BASTA, e isto foi verificado na prática: com
-- apenas essa linha, a ACL saiu
--   postgres=X | anon=X | authenticated=X | service_role=X
-- ou seja, qualquer anônimo leria a chave por
-- `/rest/v1/rpc/get_brevo_api_key` e mandaria e-mail assinado pelo domínio.
--
-- O motivo: o Supabase concede EXECUTE a `anon` e `authenticated` por default
-- privileges em toda função nova do schema public. Esses são grants
-- EXPLÍCITOS por papel — `revoke from public` mexe só no pseudo-papel PUBLIC e
-- não encosta neles. Tem que revogar de cada papel pelo nome.
--
-- Conferir depois de aplicar (tem que dar só postgres e service_role):
--   select proname, array_to_string(proacl, ' | ')
--     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
--    where n.nspname = 'public' and proname = 'get_brevo_api_key';
--
-- Antes de aplicar, gravar o segredo (uma vez, pelo SQL Editor):
--   select vault.create_secret('xkeysib-...', 'brevo_api_key');
-- Para girar depois:
--   select vault.update_secret(
--     (select id from vault.secrets where name = 'brevo_api_key'), 'xkeysib-...');
-- Girar exige redeploy da função: ela cacheia a chave por instância.

create or replace function public.get_brevo_api_key()
  returns text
  language sql
  security definer
  set search_path to ''
as $function$
  select decrypted_secret from vault.decrypted_secrets where name = 'brevo_api_key' limit 1;
$function$;

revoke all on function public.get_brevo_api_key() from anon;
revoke all on function public.get_brevo_api_key() from authenticated;
revoke all on function public.get_brevo_api_key() from public;
grant execute on function public.get_brevo_api_key() to service_role;
