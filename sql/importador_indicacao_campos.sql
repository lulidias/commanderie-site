-- Painel do Importador: campos extras na indicacao de Comendador
-- Alinha o formulario "Indicados" (antes "Comendadores") ao formulario dos comendadores:
-- adiciona a apresentacao do indicado e quem paga a anuidade.
-- Roda no SQL Editor do Supabase. 100% ASCII.

alter table public.importadora_membros
  add column if not exists apresentacao text,
  add column if not exists anuidade_por text;

-- Valor padrao: a importadora paga a 1a anuidade (beneficio incluido).
alter table public.importadora_membros
  alter column anuidade_por set default 'padrinho_primeira';

update public.importadora_membros
  set anuidade_por = 'padrinho_primeira'
  where anuidade_por is null;
