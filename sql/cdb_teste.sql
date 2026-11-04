-- "CDB Teste": pagamentos de TESTE feitos no próprio site entram no Financeiro  · 04/11/2026
-- Motivo: os PIX de teste (ex.: R$ 1,00 da inscrição de importadora em modo teste)
-- caem de verdade na conta. Para o caixa bater com o banco, eles são lançados
-- sozinhos como receita na categoria "CDB Teste" (já recebida), separados do resto.
-- fonte = 'teste:insc:<id>' → não lança duas vezes. Remover a inscrição de teste
-- NÃO apaga a receita (o dinheiro continua na conta).

create or replace function public.importadora_insc_comprovante(p_email text, p_path text, p_valor numeric)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_nome text;
begin
  if coalesce(btrim(p_email),'') = '' or coalesce(p_path,'') not like 'insc/%' then return false; end if;
  select id, nome into v_id, v_nome from importadora_inscricoes
   where lower(btrim(email)) = lower(btrim(p_email)) and status = 'Nova'
   order by created_at desc limit 1;
  if v_id is null then return false; end if;
  update importadora_inscricoes
     set comprovante_path = p_path, comprovante_em = now(), valor_brl = nullif(p_valor,0)
   where id = v_id;
  -- inscrição de TESTE com valor: lança no Financeiro como "CDB Teste"
  if coalesce(v_nome,'') like '[TESTE]%' and coalesce(p_valor,0) > 0
     and not exists (select 1 from receitas where fonte = 'teste:insc:' || v_id) then
    insert into receitas (ano, categoria, descricao, valor, pago, fonte)
    values (extract(year from now())::int, 'CDB Teste', 'PIX de teste · ' || v_nome, p_valor, true, 'teste:insc:' || v_id);
  end if;
  return true;
end $$;
revoke all on function public.importadora_insc_comprovante(text,text,numeric) from public;
grant execute on function public.importadora_insc_comprovante(text,text,numeric) to anon, authenticated;

-- Lança agora os testes já feitos (ex.: o R$ 1,00 de hoje)
insert into public.receitas (ano, categoria, descricao, valor, pago, fonte)
select extract(year from coalesce(i.comprovante_em, now()))::int, 'CDB Teste', 'PIX de teste · ' || i.nome,
       coalesce(i.valor_brl, 1), true, 'teste:insc:' || i.id
  from public.importadora_inscricoes i
 where i.nome like '[TESTE]%' and i.comprovante_path is not null
   and not exists (select 1 from public.receitas r where r.fonte = 'teste:insc:' || i.id)
returning descricao, valor;
