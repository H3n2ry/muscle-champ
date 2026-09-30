-- Amizade só nasce de pedido pendente, e só quem recebeu o pedido o aceita.
--
-- ## O que estava aberto
--
-- `friendships` tinha quatro políticas permissivas, que o Postgres soma com OR.
-- A pior era "Acesso próprias amizades": FOR ALL, sem WITH CHECK — e sem WITH
-- CHECK o Postgres usa o USING como checagem de escrita. O USING era
-- `auth.uid() = user_id OR auth.uid() = friend_id`, então:
--
--   * dava para INSERIR `user_id = qualquer pessoa, friend_id = eu`: um pedido
--     forjado EM NOME de outra pessoa, já `accepted` se quisesse;
--   * `friendships_insert` não restringia `status`: dava para criar o pedido já
--     aceito, sem o outro lado nunca ter concordado;
--   * quem ENVIOU o pedido podia aceitá-lo sozinho (update por `id`, e o
--     remetente passa no USING).
--
-- `get_perfil_publico` libera dados a amigos aceitos, e amizade aceita põe a
-- pessoa no ranking de amigos do outro. As duas coisas ficavam ao alcance de
-- qualquer conta.
--
-- ## O desenho
--
--   ler      → quem participa
--   inserir  → só em nome próprio, só `pending`, nunca consigo mesmo
--   atualizar→ só o DESTINATÁRIO, só de `pending` para `accepted`/`rejected`
--   apagar   → qualquer participante (recusar, cancelar, desfazer amizade)
--
-- ⚠️ A política de UPDATE sozinha não basta: WITH CHECK não enxerga o valor
-- antigo, então o destinatário poderia aceitar trocando o `user_id` no mesmo
-- UPDATE — e forjar a amizade de uma terceira pessoa. Por isso o UPDATE é
-- concedido POR COLUNA: só `status` é atualizável.

drop policy if exists "Acesso próprias amizades" on public.friendships;
drop policy if exists friendships_select on public.friendships;
drop policy if exists friendships_insert on public.friendships;
drop policy if exists friendships_delete on public.friendships;

create policy "amizade: participantes leem" on public.friendships
  for select to authenticated
  using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "amizade: pedido pendente em nome proprio" on public.friendships
  for insert to authenticated
  with check (auth.uid() = user_id
              and status = 'pending'
              and friend_id <> auth.uid());

create policy "amizade: so o destinatario responde" on public.friendships
  for update to authenticated
  using (auth.uid() = friend_id and status = 'pending')
  with check (auth.uid() = friend_id and status in ('accepted', 'rejected'));

create policy "amizade: participante desfaz" on public.friendships
  for delete to authenticated
  using (auth.uid() = user_id or auth.uid() = friend_id);

-- UPDATE por coluna. `revoke` da tabela inteira e `grant` só de `status`.
revoke update on public.friendships from anon, authenticated;
grant update (status) on public.friendships to authenticated;

-- anon não participa de amizade nenhuma.
revoke insert, update, delete on public.friendships from anon;
