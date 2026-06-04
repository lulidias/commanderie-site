-- Painel do Importador: campos extras na indicacao de Embaixada (restaurante)
-- Formulario "Indicar Embaixadas": categoria (Ouro/Prata/Bronze), endereco,
-- nome, responsavel e telefone do responsavel.
-- Roda no SQL Editor do Supabase. 100% ASCII.

alter table public.importadora_restaurantes
  add column if not exists endereco text,
  add column if not exists responsavel text,
  add column if not exists telefone text;
