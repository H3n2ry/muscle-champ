-- Prepara a assinatura para ser cobrada de verdade.
--
-- Dois canais vão vender a MESMA assinatura: o app Android pelo Google Play e
-- o site pelo Asaas. Quem decide que alguém pagou é sempre o servidor (Edge
-- Functions com a service role), depois de conferir com o Google ou o Asaas.
-- O cliente só lê.
--
-- Esta migração ainda NÃO desliga o modo demonstração (`assinar_demo`): ele
-- sai num PR próprio, quando os dois canais estiverem testados. Até lá as
-- linhas criadas pela demo ficam marcadas com origem 'demo'.

-- ── Colunas novas em `assinaturas` ─────────────────────────────────────────

alter table public.assinaturas
  add column if not exists origem text not null default 'demo',
  add column if not exists status text not null default 'ativa',
  -- Identificador da assinatura do lado de quem cobra: o purchaseToken do
  -- Google ou o id `sub_...` do Asaas. É por ele que os avisos chegam.
  add column if not exists id_externo text,
  -- false depois que a pessoa cancela: o acesso segue até `expira_em`, mas
  -- não há próxima cobrança.
  add column if not exists renova boolean not null default true;

alter table public.assinaturas
  drop constraint if exists assinaturas_origem_check,
  add constraint assinaturas_origem_check
    check (origem in ('demo', 'play', 'asaas'));

alter table public.assinaturas
  drop constraint if exists assinaturas_status_check,
  add constraint assinaturas_status_check
    check (status in ('trial', 'ativa', 'em_atraso', 'cancelada', 'expirada'));

alter table public.assinaturas
  drop constraint if exists assinaturas_plano_id_check,
  add constraint assinaturas_plano_id_check
    check (plano_id in ('mensal', 'trimestral', 'anual', 'lancamento')) not valid;
-- `not valid`: antes de 20260825b o cliente gravava o plano que quisesse, e
-- uma linha antiga fora da lista não pode travar a migração. Vale para o que
-- for gravado daqui em diante.

-- As linhas que já existem vieram todas da demo, que sempre dá trial.
update public.assinaturas
   set status = case when em_trial then 'trial' else 'ativa' end
 where origem = 'demo';

-- Um mesmo purchaseToken ou id do Asaas nunca pode ativar duas contas.
create unique index if not exists assinaturas_id_externo_unico
  on public.assinaturas (origem, id_externo)
  where id_externo is not null;

-- ── Avaliação gratuita: uma por conta, somando os dois canais ──────────────

-- Fica fora de `assinaturas` porque a linha da assinatura pode sumir (demo
-- cancelada) e a marca de "já testou" não pode sumir junto.
create table if not exists public.trial_usado (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  origem   text not null check (origem in ('demo', 'play', 'asaas')),
  usado_em timestamptz not null default now()
);

alter table public.trial_usado enable row level security;
-- Sem política: o cliente pergunta por `ja_usei_trial()`.

create or replace function public.ja_usei_trial()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.trial_usado where user_id = auth.uid());
$$;

revoke execute on function public.ja_usei_trial() from public, anon;
grant  execute on function public.ja_usei_trial() to authenticated;

-- ── Registro dos avisos do Google e do Asaas ───────────────────────────────

-- Os dois mandam o mesmo aviso mais de uma vez (retentativa). A chave única
-- (origem, id_evento) faz o segundo cair no `on conflict do nothing` e não
-- estender a assinatura duas vezes. Também serve de histórico para suporte.
create table if not exists public.eventos_pagamento (
  id            bigint generated always as identity primary key,
  origem        text not null check (origem in ('play', 'asaas')),
  id_evento     text not null,
  tipo          text not null,
  user_id       uuid references auth.users(id) on delete set null,
  payload       jsonb not null,
  recebido_em   timestamptz not null default now(),
  processado_em timestamptz,
  erro          text,
  unique (origem, id_evento)
);

alter table public.eventos_pagamento enable row level security;
-- Sem política, de propósito: só a service role lê e escreve.

create index if not exists idx_eventos_pagamento_user
  on public.eventos_pagamento (user_id, recebido_em desc);

-- ── A única porta de escrita de uma assinatura paga ────────────────────────

-- Chamada só pelas Edge Functions (service role), depois de confirmar o
-- pagamento com quem cobrou. Grava o estado inteiro que o canal informou: o
-- Google e o Asaas são a fonte da verdade, nós só espelhamos.
create or replace function public.gravar_assinatura(
  p_user_id          uuid,
  p_origem           text,
  p_id_externo       text,
  p_plano_id         text,
  p_status           text,
  p_expira_em        timestamptz,
  p_em_trial         boolean,
  p_proxima_cobranca integer,
  p_renova           boolean
)
returns public.assinaturas
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_atual public.assinaturas;
  v_linha public.assinaturas;
begin
  if p_user_id is null then
    raise exception 'usuario ausente';
  end if;
  if p_origem not in ('play', 'asaas') then
    raise exception 'origem invalida: %', p_origem;
  end if;
  if p_id_externo is null or length(p_id_externo) = 0 then
    raise exception 'id externo ausente';
  end if;
  if p_proxima_cobranca < 0 or p_proxima_cobranca > 100000 then
    raise exception 'valor invalido';
  end if;

  select * into v_atual from public.assinaturas
   where user_id = p_user_id for update;

  -- Uma assinatura paga por conta. Se a pessoa já paga por um canal (ou já
  -- pagava por outra assinatura do mesmo canal) e ela ainda vale, a segunda
  -- não substitui a primeira: quem chamou devolve erro e não ativa nada.
  -- Avisos da MESMA assinatura (mesmo id externo) sempre passam.
  if found
     and v_atual.origem <> 'demo'
     and v_atual.expira_em > now()
     and v_atual.status in ('trial', 'ativa', 'em_atraso')
     and (v_atual.origem <> p_origem or v_atual.id_externo <> p_id_externo) then
    raise exception 'assinatura_ativa_em_outro_canal'
      using detail = v_atual.origem;
  end if;

  insert into public.assinaturas
    (user_id, plano_id, expira_em, em_trial, proxima_cobranca, atualizado_em,
     origem, status, id_externo, renova)
  values
    (p_user_id, p_plano_id, p_expira_em, p_em_trial, p_proxima_cobranca, now(),
     p_origem, p_status, p_id_externo, p_renova)
  on conflict (user_id) do update set
    plano_id         = excluded.plano_id,
    expira_em        = excluded.expira_em,
    em_trial         = excluded.em_trial,
    proxima_cobranca = excluded.proxima_cobranca,
    atualizado_em    = excluded.atualizado_em,
    origem           = excluded.origem,
    status           = excluded.status,
    id_externo       = excluded.id_externo,
    renova           = excluded.renova
  returning * into v_linha;

  if p_em_trial then
    insert into public.trial_usado (user_id, origem)
    values (p_user_id, p_origem)
    on conflict (user_id) do nothing;
  end if;

  return v_linha;
end;
$$;

revoke execute on function public.gravar_assinatura(
  uuid, text, text, text, text, timestamptz, boolean, integer, boolean)
  from public, anon, authenticated;
grant execute on function public.gravar_assinatura(
  uuid, text, text, text, text, timestamptz, boolean, integer, boolean)
  to service_role;

-- ── A demo não pode mais pisar numa assinatura paga ────────────────────────

-- Mesmo corpo de 20260825b, com duas travas novas: não sobrescreve assinatura
-- paga e não dá um segundo trial a quem já usou o seu.
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

  if p_plano_id not in ('mensal', 'trimestral', 'anual', 'lancamento') then
    raise exception 'plano invalido: %', p_plano_id;
  end if;

  if p_proxima_cobranca < 0 or p_proxima_cobranca > 100000 then
    raise exception 'valor invalido';
  end if;

  if exists (select 1 from public.assinaturas
              where user_id = v_uid and origem <> 'demo') then
    raise exception 'assinatura_ativa_em_outro_canal';
  end if;

  insert into public.assinaturas
    (user_id, plano_id, expira_em, em_trial, proxima_cobranca, atualizado_em,
     origem, status, id_externo, renova)
  values (
    v_uid,
    p_plano_id,
    (app_today()::date + 14)::timestamptz,
    true,
    p_proxima_cobranca,
    now(),
    'demo',
    'trial',
    null,
    true
  )
  on conflict (user_id) do update set
    plano_id         = excluded.plano_id,
    expira_em        = excluded.expira_em,
    em_trial         = excluded.em_trial,
    proxima_cobranca = excluded.proxima_cobranca,
    atualizado_em    = excluded.atualizado_em,
    status           = excluded.status
  returning * into v_linha;

  return v_linha;
end;
$$;

-- ── Cancelar: a demo apaga; assinatura paga se cancela no canal ────────────

-- Apagar a linha de uma assinatura paga não para a cobrança no Google nem no
-- Asaas: a pessoa perderia o acesso e continuaria pagando. Por isso esta RPC
-- só vale para a demo. O cancelamento real vai pela Edge Function do Asaas ou
-- pela tela de assinaturas do Google Play.
create or replace function public.cancelar_assinatura()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_origem text;
begin
  select origem into v_origem from public.assinaturas where user_id = auth.uid();
  if v_origem is not null and v_origem <> 'demo' then
    raise exception 'cancelar_pelo_canal'
      using detail = v_origem;
  end if;
  delete from public.assinaturas where user_id = auth.uid() and origem = 'demo';
end;
$$;

revoke execute on function public.cancelar_assinatura() from public, anon;
grant  execute on function public.cancelar_assinatura() to authenticated;
