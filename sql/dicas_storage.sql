-- =====================================================================
-- Storage do bucket "dicas" - politicas RLS (fotos das Dicas de Bordeaux)
-- Corrige "new row violates row-level security policy" ao subir foto.
-- Leitura publica; escrita apenas para o Conselho. Arquivo 100% ASCII.
-- =====================================================================

-- Garante o bucket (publico para leitura das fotos)
insert into storage.buckets (id, name, public)
values ('dicas','dicas', true)
on conflict (id) do update set public = true;

-- Leitura publica das fotos
drop policy if exists dicas_read on storage.objects;
create policy dicas_read on storage.objects for select
  using (bucket_id = 'dicas');

-- Upload (insert) - somente Conselho
drop policy if exists dicas_insert on storage.objects;
create policy dicas_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'dicas' and public.is_conselho());

-- Substituir (update/upsert) - somente Conselho
drop policy if exists dicas_update on storage.objects;
create policy dicas_update on storage.objects for update to authenticated
  using (bucket_id = 'dicas' and public.is_conselho())
  with check (bucket_id = 'dicas' and public.is_conselho());

-- Remover - somente Conselho
drop policy if exists dicas_delete on storage.objects;
create policy dicas_delete on storage.objects for delete to authenticated
  using (bucket_id = 'dicas' and public.is_conselho());
