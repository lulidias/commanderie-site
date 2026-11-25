-- =====================================================================
-- 2026-11-24 · Página Manu (Épice · Maison Louis Roederer)
-- Acesso de convidados SEM cadastro na Commanderie: o Manu (ou a Luli)
-- autoriza um e-mail; a pessoa digita o e-mail na página e recebe um
-- link pessoal de entrada (válido 30 dias, pode ser revogado).
-- Rodar 1 vez no SQL Editor do Supabase. 100% reexecutável.
-- =====================================================================

create table if not exists public.manu_acesso (
  email          text primary key,
  nome           text,
  empresa        text,
  ativo          boolean not null default true,
  token          uuid,
  token_exp      timestamptz,
  pedido_em      timestamptz,
  ultimo_acesso  timestamptz,
  criado_em      timestamptz not null default now()
);
alter table public.manu_acesso enable row level security;
-- sem policies: ninguém lê a tabela direto; tudo passa pelas funções abaixo
revoke all on public.manu_acesso from anon, authenticated;

-- quem administra: Grão-Mestre (Manu) e Luli
create or replace function public.manu_admin()
returns boolean language sql stable security definer set search_path=public as $fn$
  select exists(select 1 from public.membros m
    where m.user_id = auth.uid()
      and (lower(coalesce(m.grau,'')) like 'gr%o%mestre%' or lower(coalesce(m.nome,'')) like 'luli%'));
$fn$;

-- modelo do e-mail com o link
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('manu_link','Épice · link de acesso (convidados)','Seu acesso &middot; &Eacute;pice &middot; Maison Louis Roederer','Seu link de acesso',
 '<p>Ol&aacute; {nome},</p><p>Clique no bot&atilde;o abaixo para abrir o painel <b>&Eacute;pice &middot; Maison Louis Roederer</b>. O link &eacute; pessoal e vale por 30 dias.</p><p>Bonjour {nome}, cliquez sur le bouton ci-dessous pour ouvrir le tableau de bord. Ce lien est personnel et valable 30 jours.</p><p style="font-size:12px;color:#7d7461;word-break:break-all;">{link}</p>',
 'Abrir o painel &middot; Ouvrir',90)
on conflict (chave) do update set nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo, corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 1) convidado pede o link (público). Responde sempre "ok" para não revelar quem está autorizado.
create or replace function public.manu_pedir_link(p_email text)
returns boolean language plpgsql security definer set search_path=public as $fn$
declare a public.manu_acesso; v_tok uuid;
begin
  select * into a from public.manu_acesso where email = lower(trim(p_email)) and ativo;
  if not found then return true; end if;
  if a.pedido_em is not null and a.pedido_em > now() - interval '1 minute' then return true; end if;
  v_tok := gen_random_uuid();
  update public.manu_acesso set token=v_tok, token_exp=now()+interval '30 days', pedido_em=now() where email=a.email;
  perform public.enviar_modelo(a.email,'manu_link', jsonb_build_object(
    'nome', coalesce(nullif(a.nome,''),'convidado(a)'),
    'link', 'https://commanderiedebordeaux.com.br/manu.html?k='||v_tok::text));
  return true;
end $fn$;

-- 2) a página confere o link (público)
create or replace function public.manu_entrar(p_token uuid)
returns jsonb language plpgsql security definer set search_path=public as $fn$
declare a public.manu_acesso;
begin
  select * into a from public.manu_acesso where token=p_token and ativo and token_exp > now();
  if not found then return null; end if;
  update public.manu_acesso set ultimo_acesso=now() where email=a.email;
  return jsonb_build_object('email',a.email,'nome',a.nome,'empresa',a.empresa);
end $fn$;

-- 3) administração (só Manu / Luli logados)
create or replace function public.manu_lista()
returns setof public.manu_acesso language plpgsql security definer set search_path=public as $fn$
begin
  if not public.manu_admin() then raise exception 'sem permissao'; end if;
  return query select * from public.manu_acesso order by criado_em desc;
end $fn$;

create or replace function public.manu_salvar(p_email text, p_nome text, p_empresa text, p_ativo boolean)
returns void language plpgsql security definer set search_path=public as $fn$
begin
  if not public.manu_admin() then raise exception 'sem permissao'; end if;
  insert into public.manu_acesso(email,nome,empresa,ativo) values (lower(trim(p_email)),p_nome,p_empresa,coalesce(p_ativo,true))
  on conflict (email) do update set nome=excluded.nome, empresa=excluded.empresa, ativo=excluded.ativo,
    token = case when excluded.ativo then public.manu_acesso.token else null end;
end $fn$;

create or replace function public.manu_excluir(p_email text)
returns void language plpgsql security definer set search_path=public as $fn$
begin
  if not public.manu_admin() then raise exception 'sem permissao'; end if;
  delete from public.manu_acesso where email=lower(trim(p_email));
end $fn$;

-- envia o link na hora (o Manu clica "Enviar link" no painel)
create or replace function public.manu_enviar_link(p_email text)
returns void language plpgsql security definer set search_path=public as $fn$
begin
  if not public.manu_admin() then raise exception 'sem permissao'; end if;
  update public.manu_acesso set pedido_em=null where email=lower(trim(p_email));
  perform public.manu_pedir_link(p_email);
end $fn$;

grant execute on function public.manu_pedir_link(text), public.manu_entrar(uuid) to anon, authenticated;
grant execute on function public.manu_lista(), public.manu_salvar(text,text,text,boolean), public.manu_excluir(text), public.manu_enviar_link(text), public.manu_admin() to authenticated;

select 'ok: acesso de convidados da página Manu pronto' as resultado;
