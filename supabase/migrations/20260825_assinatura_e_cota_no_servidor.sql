-- Assinatura e cota de IA saem do aparelho e passam a viver no banco.
--
-- Motivo: SharedPreferences é do APARELHO, não da conta. Quem assinava no
-- celular e abria no PC voltava a ser plano gratuito, e quem usava a foto do
-- dia no celular ganhava outra no navegador. As duas coisas são estado da
-- CONTA e sempre deveriam ter morado aqui.

-- ── Assinatura ──────────────────────────────────────────────────────────────

create table if not exists public.assinaturas (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  plano_id          text        not null,
  expira_em         timestamptz not null,
  em_trial          boolean     not null default false,
  -- Em centavos. Dinheiro nunca em ponto flutuante.
  proxima_cobranca  integer     not null default 0,
  atualizado_em     timestamptz not null default now()
);

alter table public.assinaturas enable row level security;

-- ⚠️ DEMONSTRAÇÃO: o cliente escreve a própria assinatura porque não existe
-- gateway ainda. Isso significa que qualquer pessoa com o token pode se
-- declarar Pro — aceitável enquanto nada é cobrado, inaceitável depois.
--
-- Quando o billing for real: APAGAR as políticas de insert/update abaixo. Só
-- a de select fica. Quem escreve passa a ser o webhook do gateway, com a
-- service role, que ignora RLS. Cliente nunca decide que pagou.
create policy "assinatura: dono lê"
  on public.assinaturas for select
  using (auth.uid() = user_id);

create policy "assinatura: dono cria (DEMO)"
  on public.assinaturas for insert
  with check (auth.uid() = user_id);

create policy "assinatura: dono atualiza (DEMO)"
  on public.assinaturas for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "assinatura: dono cancela (DEMO)"
  on public.assinaturas for delete
  using (auth.uid() = user_id);

-- ── Cota diária de IA ───────────────────────────────────────────────────────

create table if not exists public.cota_ia_diaria (
  user_id  uuid    not null references auth.users(id) on delete cascade,
  dia      date    not null,
  recurso  text    not null,
  usos     integer not null default 0,
  primary key (user_id, dia, recurso)
);

alter table public.cota_ia_diaria enable row level security;

-- Só leitura pelo dono. NÃO existe política de escrita de propósito: sem ela
-- o cliente não consegue zerar o próprio contador nem inventar um dia. Quem
-- grava é a função abaixo, que é SECURITY DEFINER e ignora RLS.
create policy "cota: dono lê"
  on public.cota_ia_diaria for select
  using (auth.uid() = user_id);

-- Registra um uso e devolve o total do dia para aquele recurso.
--
-- A data vem de app_today() — do servidor, no fuso do usuário — e não do
-- aparelho. Antes o contador era local e adiantar o relógio rendia cota nova.
create or replace function public.consumir_cota_ia(p_recurso text)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid   uuid := auth.uid();
  v_dia   date := app_today()::date;
  v_usos  integer;
begin
  if v_uid is null then
    raise exception 'nao autenticado';
  end if;

  -- Lista fechada: sem isto, um recurso inventado criaria linha lixo e ainda
  -- passaria batido no limite, porque o app não o conhece.
  if p_recurso not in ('foto', 'texto', 'treino', 'dieta') then
    raise exception 'recurso invalido: %', p_recurso;
  end if;

  insert into public.cota_ia_diaria (user_id, dia, recurso, usos)
  values (v_uid, v_dia, p_recurso, 1)
  on conflict (user_id, dia, recurso)
    do update set usos = public.cota_ia_diaria.usos + 1
  returning usos into v_usos;

  return v_usos;
end;
$$;

-- Usos de hoje, como um objeto {"foto": 1, "texto": 2}.
--
-- Existe como função, e não como select direto, para o "hoje" ser o mesmo
-- app_today() que a gravação usa. Com o cliente montando a data, virava o dia
-- em momentos diferentes para leitura e escrita.
create or replace function public.get_cota_ia()
returns jsonb
language sql
security definer
set search_path = public, pg_temp
as $$
  select coalesce(jsonb_object_agg(recurso, usos), '{}'::jsonb)
  from public.cota_ia_diaria
  where user_id = auth.uid()
    and dia = app_today()::date;
$$;

-- Zera a cota do dia. Existe só para o modo demonstração poder testar o
-- limite sem esperar a meia-noite; sai junto com o modo demonstração.
create or replace function public.zerar_cota_ia()
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.cota_ia_diaria
  where user_id = auth.uid() and dia = app_today()::date;
$$;

revoke execute on function public.consumir_cota_ia(text) from public, anon;
revoke execute on function public.get_cota_ia()           from public, anon;
revoke execute on function public.zerar_cota_ia()         from public, anon;

grant execute on function public.consumir_cota_ia(text) to authenticated;
grant execute on function public.get_cota_ia()           to authenticated;
grant execute on function public.zerar_cota_ia()         to authenticated;

-- Faxina: a cota de dias passados não serve para nada (o app só pergunta
-- "quanto sobrou hoje"). Sem isto a tabela cresceria para sempre.
create index if not exists idx_cota_ia_dia on public.cota_ia_diaria (dia);
