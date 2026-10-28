-- Complemento de espelhar_no_banco_de_teste.sql: o que vive fora do schema
-- public e por isso não sai no gerar_schema.sql. Copiado de produção em
-- 28/10/2026. NUNCA rode isto em produção.

-- Perfil criado no cadastro
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Bucket de fotos de perfil
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do nothing;

drop policy if exists "Avatar owner delete" on storage.objects;
drop policy if exists "Avatar owner insert" on storage.objects;
drop policy if exists "Avatar owner list"   on storage.objects;
drop policy if exists "Avatar owner update" on storage.objects;

create policy "Avatar owner delete" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Avatar owner insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Avatar owner list" on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Avatar owner update" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
