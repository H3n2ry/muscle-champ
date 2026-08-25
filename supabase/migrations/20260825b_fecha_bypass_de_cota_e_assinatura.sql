-- Fecha dois bypasses abertos pela migração anterior.
--
-- A ideia é a mesma nos dois casos: o CLIENTE PARA DE ESCREVER DIREITO DE
-- ACESSO. Ele pede; quem decide é o servidor.
--
-- 1) `zerar_cota_ia()` estava liberada para qualquer usuário autenticado.
--    Blindar a tabela e depois publicar uma RPC que limpa o contador anulava
--    a cota inteira: bastava chamar /rest/v1/rpc/zerar_cota_ia.
--
-- 2) `assinaturas` tinha políticas de INSERT/UPDATE/DELETE para o dono.
--    Qualquer um podia se declarar Pro, com a data de expiração que quisesse.

-- ── Contas de teste ─────────────────────────────────────────────────────────

create table if not exists public.contas_de_teste (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nota    text
);

alter table public.contas_de_teste enable row level security;

-- Nenhuma política, de propósito: sem uma, o PostgREST não devolve nada para
-- ninguém. Só funções SECURITY DEFINER (e a service role) enxergam a lista.
-- Quem está nela não pode ser descoberto de fora.

insert into public.contas_de_teste (user_id, nota)
values ('60a81999-2f38-475b-968d-40cb6acb5124', 'dono do app')
on conflict (user_id) do nothing;

create or replace function public.sou_conta_de_teste()
returns boolean
language sql
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.contas_de_teste where user_id = auth.uid()
  );
$$;

-- ── 1) Zerar cota: só conta de teste ────────────────────────────────────────

create or replace function public.zerar_cota_ia()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Sem esta trava a função é o bypass da cota inteira. Ela existe só para o
  -- desenvolvimento testar o limite sem esperar a meia-noite, e some junto
  -- com o modo demonstração.
  if not sou_conta_de_teste() then
    raise exception 'nao autorizado';
  end if;

  delete from public.cota_ia_diaria
  where user_id = auth.uid() and dia = app_today()::date;
end;
$$;

-- ── 2) Assinatura: cliente não escreve mais a tabela ────────────────────────

drop policy if exists "assinatura: dono cria (DEMO)"     on public.assinaturas;
drop policy if exists "assinatura: dono atualiza (DEMO)" on public.assinaturas;
drop policy if exists "assinatura: dono cancela (DEMO)"  on public.assinaturas;

-- Sobra só a de leitura. A partir daqui, escrever em `assinaturas` pelo
-- PostgREST é impossível para qualquer usuário — inclusive o dono da linha.

-- Concede a assinatura de DEMONSTRAÇÃO.
--
-- Continua aberta a qualquer usuário autenticado, porque o paywall precisa
-- ser percorrível por quem estiver testando o app. O que mudou é o TETO do
-- abuso: o servidor decide as datas e o modo. Antes dava para gravar
-- "Pro até 2099"; agora o máximo que alguém consegue é o mesmo trial de 14
-- dias que a tela oferece.
--
-- ⚠️ APAGAR quando o billing for real. Quem grava passa a ser o webhook do
-- gateway, com a service role. O nome tem "demo" para não dar para esquecer.
create or replace function public.assinar_demo(
  p_plano_id         text,
  p_proxima_cobranca integer
)
returns public.assinaturas
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid  uuid := auth.uid();
  v_linha public.assinaturas;
begin
  if v_uid is null then
    raise exception 'nao autenticado';
  end if;

  -- Lista fechada: sem isto entra plano inventado e a tela mostra lixo.
  if p_plano_id not in ('mensal', 'trimestral', 'anual', 'lancamento') then
    raise exception 'plano invalido: %', p_plano_id;
  end if;

  -- Preço é só informativo na demo (na vida real vem do Play Billing), mas
  -- fica limitado para não gravar valor absurdo na tela de cobrança.
  if p_proxima_cobranca < 0 or p_proxima_cobranca > 100000 then
    raise exception 'valor invalido';
  end if;

  insert into public.assinaturas
    (user_id, plano_id, expira_em, em_trial, proxima_cobranca, atualizado_em)
  values (
    v_uid,
    p_plano_id,
    -- Sempre 14 dias, sempre trial. O cliente não escolhe.
    (app_today()::date + 14)::timestamptz,
    true,
    p_proxima_cobranca,
    now()
  )
  on conflict (user_id) do update set
    plano_id         = excluded.plano_id,
    expira_em        = excluded.expira_em,
    em_trial         = excluded.em_trial,
    proxima_cobranca = excluded.proxima_cobranca,
    atualizado_em    = excluded.atualizado_em
  returning * into v_linha;

  return v_linha;
end;
$$;

-- Cancela a própria assinatura.
--
-- Fica aberta a qualquer usuário e assim continua depois do billing: cancelar
-- é direito do assinante (CDC, e o Google Play exige). Só apaga a linha de
-- quem chamou.
create or replace function public.cancelar_assinatura()
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.assinaturas where user_id = auth.uid();
$$;

revoke execute on function public.sou_conta_de_teste()            from public, anon;
revoke execute on function public.assinar_demo(text, integer)     from public, anon;
revoke execute on function public.cancelar_assinatura()           from public, anon;

grant execute on function public.sou_conta_de_teste()             to authenticated;
grant execute on function public.assinar_demo(text, integer)      to authenticated;
grant execute on function public.cancelar_assinatura()            to authenticated;
