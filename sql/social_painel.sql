-- Painel "Redes sociais" do Conselho (31/10/2026): revisão do Manu, edição, reordenação, fotos novas e pedidos ao Claude.
-- O robô publica sozinho (status 'aprovado'); a revisão é paralela e não trava nada. 'pausado' tira da fila.
alter table public.social_posts drop constraint if exists social_posts_status_check;
alter table public.social_posts add constraint social_posts_status_check
  check (status in ('aguardando','aprovado','pausado','ajuste','recusado','publicando','publicado','erro'));
alter table public.social_posts add column if not exists revisao text not null default 'pendente'
  check (revisao in ('pendente','ok','ajuste'));
alter table public.social_posts add column if not exists revisao_obs text;
alter table public.social_posts add column if not exists revisado_por text;
alter table public.social_posts add column if not exists revisado_em timestamptz;
alter table public.social_posts add column if not exists editado_em timestamptz;

create table if not exists public.social_pedidos (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.social_posts(id) on delete set null,
  texto text not null, autor text, criado_em timestamptz not null default now(),
  status text not null default 'aberto' check (status in ('aberto','feito')), resposta text, feito_em timestamptz
);
alter table public.social_pedidos enable row level security;
drop policy if exists social_ped_sel on public.social_pedidos;
create policy social_ped_sel on public.social_pedidos for select to authenticated using (public.social_eh_aprovador());
grant select on public.social_pedidos to authenticated;

create or replace function public._social_quem() returns text language sql stable security definer set search_path=public as $$
  select coalesce((select u.email from auth.users u where u.id = auth.uid()), 'desconhecido')
$$;

create or replace function public.social_revisar(p_id uuid, p_acao text, p_obs text default null)
returns public.social_posts language plpgsql security definer set search_path = public as $$
declare r public.social_posts;
begin
  if not public.social_eh_aprovador() then raise exception 'Só o Conselho pode revisar os posts'; end if;
  if p_acao = 'ok' then
    update public.social_posts set revisao='ok', revisao_obs=null, revisado_por=_social_quem(), revisado_em=now() where id=p_id returning * into r;
  elsif p_acao = 'ajuste' then
    if coalesce(trim(p_obs),'') = '' then raise exception 'Escreva o que precisa mudar'; end if;
    update public.social_posts set revisao='ajuste', revisao_obs=trim(p_obs), revisado_por=_social_quem(), revisado_em=now() where id=p_id returning * into r;
    insert into public.social_pedidos(post_id, texto, autor) values (p_id, trim(p_obs), _social_quem());
  elsif p_acao = 'pendente' then
    update public.social_posts set revisao='pendente' where id=p_id returning * into r;
  else raise exception 'Ação inválida'; end if;
  if r.id is null then raise exception 'Post não encontrado'; end if;
  return r;
end $$;

create or replace function public.social_atualizar(p_id uuid, p_legenda text, p_quando timestamptz, p_imagens text[], p_status text)
returns public.social_posts language plpgsql security definer set search_path = public as $$
declare r public.social_posts;
begin
  if not public.social_eh_aprovador() then raise exception 'Só o Conselho pode editar os posts'; end if;
  select * into r from public.social_posts where id=p_id for update;
  if r.id is null then raise exception 'Post não encontrado'; end if;
  if r.status in ('publicando','publicado') then raise exception 'Este post já foi publicado e não pode mais ser alterado aqui'; end if;
  if p_status not in ('aprovado','pausado','recusado') then raise exception 'Situação inválida'; end if;
  update public.social_posts set legenda=p_legenda, quando=p_quando,
    imagens=coalesce(p_imagens, imagens),
    fb_video_url = case when p_imagens is distinct from imagens then null else fb_video_url end,   -- fotos mudaram: o Facebook usa as fotos
    status=p_status, tentativas=case when p_status='aprovado' then 0 else tentativas end, erro=null, editado_em=now()
  where id=p_id returning * into r;
  return r;
end $$;

create or replace function public.social_trocar(p_a uuid, p_b uuid)
returns void language plpgsql security definer set search_path = public as $$
declare qa timestamptz; qb timestamptz; sa text; sb text;
begin
  if not public.social_eh_aprovador() then raise exception 'Só o Conselho pode mudar a ordem'; end if;
  select quando, status into qa, sa from public.social_posts where id=p_a for update;
  select quando, status into qb, sb from public.social_posts where id=p_b for update;
  if qa is null or qb is null then raise exception 'Post não encontrado'; end if;
  if sa in ('publicando','publicado') or sb in ('publicando','publicado') then raise exception 'Não dá para trocar um post já publicado'; end if;
  update public.social_posts set quando=qb, editado_em=now() where id=p_a;
  update public.social_posts set quando=qa, editado_em=now() where id=p_b;
end $$;

create or replace function public.social_novo(p_tipo text, p_quando timestamptz, p_titulo text, p_quadro text, p_legenda text, p_imagens text[], p_video text)
returns public.social_posts language plpgsql security definer set search_path = public as $$
declare r public.social_posts;
begin
  if not public.social_eh_aprovador() then raise exception 'Só o Conselho pode criar posts'; end if;
  if p_tipo not in ('carrossel','reel','story') then raise exception 'Tipo inválido'; end if;
  if p_tipo in ('carrossel') and coalesce(array_length(p_imagens,1),0) < 1 then raise exception 'Envie pelo menos uma foto'; end if;
  if p_tipo = 'reel' and coalesce(p_video,'') = '' then raise exception 'Envie o vídeo'; end if;
  insert into public.social_posts(quando, quadro, tipo, titulo, legenda, imagens, video_url, status, revisao, revisado_por, revisado_em)
  values (p_quando, coalesce(nullif(trim(p_quadro),''),'Conselho'), p_tipo, p_titulo, p_legenda, p_imagens, nullif(p_video,''), 'aprovado', 'ok', _social_quem(), now())
  returning * into r;
  return r;
end $$;

create or replace function public.social_pedir(p_post uuid, p_texto text)
returns public.social_pedidos language plpgsql security definer set search_path = public as $$
declare r public.social_pedidos;
begin
  if not public.social_eh_aprovador() then raise exception 'Só o Conselho pode fazer pedidos'; end if;
  if coalesce(trim(p_texto),'') = '' then raise exception 'Escreva o pedido'; end if;
  insert into public.social_pedidos(post_id, texto, autor) values (p_post, trim(p_texto), _social_quem()) returning * into r;
  return r;
end $$;
grant execute on function public.social_revisar(uuid,text,text), public.social_atualizar(uuid,text,timestamptz,text[],text),
  public.social_trocar(uuid,uuid), public.social_novo(text,timestamptz,text,text,text,text[],text), public.social_pedir(uuid,text) to authenticated;

-- Fotos novas pelo painel: só o Conselho sobe/troca arquivos no bucket social (SELECT junto, senão o upsert dá 403)
drop policy if exists social_obj_sel on storage.objects;
create policy social_obj_sel on storage.objects for select to authenticated using (bucket_id='social' and public.social_eh_aprovador());
drop policy if exists social_obj_ins on storage.objects;
create policy social_obj_ins on storage.objects for insert to authenticated with check (bucket_id='social' and public.social_eh_aprovador());
drop policy if exists social_obj_upd on storage.objects;
create policy social_obj_upd on storage.objects for update to authenticated using (bucket_id='social' and public.social_eh_aprovador());
