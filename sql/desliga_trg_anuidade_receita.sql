-- 31/10/2026: desligado a pedido do Luli — o Financeiro já conta a anuidade pelo cadastro do membro;
-- a receita criada por este gatilho contava em dobro.
alter table public.membros disable trigger trg_membro_anuidade_receita;
