-- Grao-Mestre / Conselho pode indicar embaixadas sem vinculo a uma importadora
-- (importadora_id nulo) e sem limite de cota.
-- Roda no SQL Editor do Supabase. 100% ASCII. Re-rodavel.

-- 1) Permite embaixada sem importadora vinculada
alter table public.importadora_restaurantes
  alter column importadora_id drop not null;

-- 2) Garante que o Conselho pode inserir/editar/remover (inclusive com importadora_id nulo)
drop policy if exists "conselho gerencia importadora_restaurantes" on public.importadora_restaurantes;
create policy "conselho gerencia importadora_restaurantes" on public.importadora_restaurantes
  for all to authenticated
  using (public.is_conselho())
  with check (public.is_conselho());
