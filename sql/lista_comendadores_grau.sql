-- 15/11/2026 — a lista do seletor (Jantar de Fim de Ano) passa a trazer o grau, para o cartão "Eu vou"
-- sair com Comendador / Mestre / Grão-Mestre. Só nome, núcleo e grau: nada de e-mail ou telefone (o link é aberto).
drop function if exists public.lista_comendadores();
create function public.lista_comendadores()
returns table(id uuid, nome text, nucleo text, mestre boolean, grau text)
language sql stable security definer set search_path to 'public' as $$
  select m.id, m.nome, coalesce(m.nucleo,''), coalesce(m.grau,'') ~* '(mestre|ma.tre)', coalesce(m.grau,'Commandeur')
    from membros m
   where coalesce(m.grau,'') <> 'Membro de Honra' and coalesce(trim(m.nome),'') <> ''
   order by (coalesce(m.nucleo,'') <> 'São Paulo'), m.nome;
$$;
grant execute on function public.lista_comendadores() to anon, authenticated;
notify pgrst, 'reload schema';
