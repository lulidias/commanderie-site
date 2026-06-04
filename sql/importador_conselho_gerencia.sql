-- Presidente/Vice (Conselho) podem indicar em nome de qualquer importadora pelo painel.
-- Adiciona policy permissiva para is_conselho() nas tabelas de indicacao do programa.
-- E-combinada com as policies de dono existentes (nao as substitui).
-- Roda no SQL Editor do Supabase. 100% ASCII. Re-rodavel.

drop policy if exists "conselho gerencia importadora_membros" on public.importadora_membros;
create policy "conselho gerencia importadora_membros" on public.importadora_membros
  for all to authenticated
  using (public.is_conselho())
  with check (public.is_conselho());

drop policy if exists "conselho gerencia importadora_restaurantes" on public.importadora_restaurantes;
create policy "conselho gerencia importadora_restaurantes" on public.importadora_restaurantes
  for all to authenticated
  using (public.is_conselho())
  with check (public.is_conselho());
