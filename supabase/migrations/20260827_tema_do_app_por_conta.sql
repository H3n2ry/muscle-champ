-- Cor de acento do app, escolhida pelo usuário.
--
-- Aplicada em produção como `tema_do_app_por_conta` (2026-08-27).
--
-- Fica na CONTA e não no aparelho: quem escolhe rosa no celular espera abrir o
-- PC em rosa. Mesmo motivo que levou assinatura e cota para o servidor.
--
-- `profiles` já tem política de UPDATE do dono (auth.uid() = id) e nenhuma
-- política nova é necessária. Diferente de assinatura, tema não é direito
-- adquirido — deixar o cliente escrever direto é o comportamento certo.
--
-- ⚠️ `profiles` tem SELECT liberado para todo autenticado (o ranking depende
-- disso), então a cor escolhida é legível por qualquer usuário logado. É
-- preferência cosmética, sem nada sensível.

alter table public.profiles
  add column if not exists tema text not null default 'limao';

-- Lista fechada. O app já cai no limão diante de um id desconhecido, mas o
-- banco não deve aceitar lixo em primeiro lugar — e é aqui que uma paleta
-- removida no futuro vai aparecer como erro em vez de virar tela sem cor.
alter table public.profiles
  drop constraint if exists profiles_tema_valido;

alter table public.profiles
  add constraint profiles_tema_valido
  check (tema in ('limao', 'roxo', 'ciano', 'ambar', 'coral', 'azul', 'rosa'));

comment on column public.profiles.tema is
  'Id da paleta de acento (lib/core/theme/paleta.dart). Cosmético.';
