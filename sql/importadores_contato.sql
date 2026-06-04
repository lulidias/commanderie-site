-- =====================================================================
-- Contatos dos importadores no Painel do Produtor.
-- A tabela importadoras nao tinha e-mail/telefone proprios; o contato do
-- responsavel vem de membros (via owner_user_id). Cria colunas de contato
-- e um RPC que junta tudo, liberado a produtores e Conselho. 100% ASCII.
-- =====================================================================

alter table public.importadoras add column if not exists email     text;
alter table public.importadoras add column if not exists telefone  text;
alter table public.importadoras add column if not exists instagram text;

-- Lista de contatos (produtor e Conselho podem ver)
create or replace function public.contatos_importadores()
returns table(id uuid, nome text, responsavel text, cidade text, email text, telefone text, instagram text)
language sql security definer stable set search_path=public as $$
  select i.id, i.nome,
         coalesce(i.responsavel_nome, m.nome)                                   as responsavel,
         i.cidade,
         coalesce(nullif(i.email,''), m.email)                                  as email,
         coalesce(nullif(i.telefone,''), nullif(trim(concat_ws(' ', m.telefone_ddi, m.telefone)),'')) as telefone,
         i.instagram
  from public.importadoras i
  left join public.membros m on m.user_id = i.owner_user_id
  where public.pode_produtor()
  order by i.nome;
$$;
grant execute on function public.contatos_importadores() to authenticated;

-- Conselho edita o contato de uma importadora
create or replace function public.set_importadora_contato(p_id uuid, p_email text, p_tel text, p_insta text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_conselho() then raise exception 'negado'; end if;
  update public.importadoras
     set email     = nullif(p_email,''),
         telefone  = nullif(p_tel,''),
         instagram = nullif(p_insta,'')
   where id = p_id;
end $$;
grant execute on function public.set_importadora_contato(uuid,text,text,text) to authenticated;
