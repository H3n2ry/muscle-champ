-- Os gatilhos de pontos viraram SECURITY DEFINER em 20260930b. O linter do
-- Supabase passou a marcá-los como executáveis por anon e authenticated via
-- /rest/v1/rpc — porque herdaram o EXECUTE que o Supabase concede em toda
-- função nova.
--
-- Chamar uma função que devolve `trigger` fora de um gatilho já é recusado pelo
-- Postgres. Mas "já é recusado" não é o padrão aqui: o resto do banco revoga
-- EXECUTE de tudo que o cliente não deve chamar, e um aviso a mais na lista do
-- linter esconde o aviso que importa.
--
-- Revogar é seguro porque o Postgres só confere EXECUTE da função de gatilho
-- quando o gatilho é CRIADO, não quando dispara. Verificado em 30/09/2026:
-- depois deste revoke, registrar refeição como usuário autenticado continua
-- pontuando.
--
-- ⚠️ `revoke from public` não basta — o Supabase concede a anon e
-- authenticated por papel (ver 20260901_chave_brevo_no_vault.sql).
revoke all on function public.fn_award_diet_points()        from public, anon, authenticated;
revoke all on function public.fn_award_load_progression()   from public, anon, authenticated;
revoke all on function public.fn_award_weight_progression() from public, anon, authenticated;
revoke all on function public.fn_award_workout_points()     from public, anon, authenticated;
