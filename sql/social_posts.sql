-- Redes sociais da Commanderie ("O Comendador"): posts, aprovação e publicação (30/10/2026)
create table if not exists public.social_posts (
  id uuid primary key default gen_random_uuid(),
  quando timestamptz not null,
  quadro text not null,
  tipo text not null check (tipo in ('reel','carrossel','story','threads')),
  video_url text, imagens text[], capa_url text,
  legenda_pt text, legenda_fr text, legenda text, threads_texto text,
  titulo text,
  status text not null default 'aguardando'
    check (status in ('aguardando','aprovado','ajuste','recusado','publicando','publicado','erro')),
  ajuste_pedido text, aprovado_por uuid, aprovado_em timestamptz,
  ig_link text, fb_link text, th_link text, story_ok boolean default false,
  erro text, tentativas int not null default 0, criado_em timestamptz not null default now()
);
create index if not exists social_posts_quando on public.social_posts(quando);
create table if not exists public.social_config (chave text primary key, valor text);
insert into public.social_config values ('aprovador_email','lulidias@me.com') on conflict (chave) do nothing;
alter table public.social_posts enable row level security;
alter table public.social_config enable row level security;

create or replace function public.social_eh_aprovador() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from auth.users u join public.social_config c on c.chave = 'aprovador_email'
                where u.id = auth.uid() and lower(u.email) = lower(c.valor))
      or public.is_conselho();
$$;
grant execute on function public.social_eh_aprovador() to authenticated;

drop policy if exists social_sel on public.social_posts;
create policy social_sel on public.social_posts for select to authenticated using (public.social_eh_aprovador());
drop policy if exists social_cfg_sel on public.social_config;
create policy social_cfg_sel on public.social_config for select to authenticated using (public.social_eh_aprovador());
grant select on public.social_posts, public.social_config to authenticated;

-- Única porta de escrita do painel: aprovar / pedir ajuste / recusar / voltar para aguardando
create or replace function public.social_decidir(p_id uuid, p_acao text, p_obs text default null)
returns public.social_posts language plpgsql security definer set search_path = public as $$
declare r public.social_posts;
begin
  if not public.social_eh_aprovador() then raise exception 'Sem permissão para aprovar posts'; end if;
  select * into r from public.social_posts where id = p_id for update;
  if r.id is null then raise exception 'Post não encontrado'; end if;
  if r.status in ('publicando','publicado') then raise exception 'Este post já foi publicado'; end if;
  if p_acao = 'aprovar' then
    update public.social_posts set status='aprovado', aprovado_por=auth.uid(), aprovado_em=now(), ajuste_pedido=null, erro=null where id=p_id returning * into r;
  elsif p_acao = 'ajuste' then
    if coalesce(trim(p_obs),'') = '' then raise exception 'Escreva o que precisa ajustar'; end if;
    update public.social_posts set status='ajuste', ajuste_pedido=trim(p_obs) where id=p_id returning * into r;
  elsif p_acao = 'recusar' then
    update public.social_posts set status='recusado', ajuste_pedido=nullif(trim(coalesce(p_obs,'')),'') where id=p_id returning * into r;
  elsif p_acao = 'reabrir' then
    update public.social_posts set status='aguardando' where id=p_id returning * into r;
  else raise exception 'Ação inválida';
  end if;
  return r;
end $$;
grant execute on function public.social_decidir(uuid,text,text) to authenticated;

insert into storage.buckets (id, name, public) values ('social','social',true) on conflict (id) do nothing;
