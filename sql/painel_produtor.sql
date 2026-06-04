-- =====================================================================
-- Painel do Produtor - schema, RLS e RPCs
-- Rode TUDO de uma vez no SQL Editor do Supabase. Arquivo 100% ASCII.
-- Papeis: Conselho (is_conselho) ve tudo; Produtor ve o painel e os
-- proprios pedidos; tabelas de conteudo (BI, imprensa) so o Conselho edita.
-- =====================================================================

-- 1) PRODUTORES (chateaux / vinicolas de Bordeaux) ---------------------
create table if not exists public.produtores (
  id            uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete set null,
  nome          text not null,
  apelacao      text,
  pais          text default 'Franca',
  responsavel   text,
  email         text,
  telefone      text,
  site          text,
  membro_desde  date,
  created_at    timestamptz default now()
);
alter table public.produtores enable row level security;

-- 2) HELPERS ----------------------------------------------------------
create or replace function public.is_produtor() returns boolean
language sql security definer stable as $$
  select exists(select 1 from public.produtores where owner_user_id = auth.uid());
$$;

create or replace function public.pode_produtor() returns boolean
language sql security definer stable as $$
  select coalesce(public.is_conselho(), false)
      or exists(select 1 from public.produtores where owner_user_id = auth.uid());
$$;

create or replace function public.meus_produtor_ids() returns setof uuid
language sql security definer stable as $$
  select id from public.produtores where owner_user_id = auth.uid();
$$;

-- 3) PEDIDOS DO PRODUTOR ----------------------------------------------
create table if not exists public.produtor_visitas (
  id            uuid primary key default gen_random_uuid(),
  produtor_id   uuid references public.produtores(id) on delete cascade,
  periodo       text,
  cidades       text,
  importadoras  text,
  obs           text,
  status        text default 'Solicitada',
  created_at    timestamptz default now()
);
alter table public.produtor_visitas enable row level security;

create table if not exists public.produtor_eventos (
  id            uuid primary key default gen_random_uuid(),
  produtor_id   uuid references public.produtores(id) on delete cascade,
  tipo          text,
  cidade        text,
  data_desejada date,
  publico       text,
  obs           text,
  status        text default 'Solicitado',
  created_at    timestamptz default now()
);
alter table public.produtor_eventos enable row level security;

create table if not exists public.produtor_beneficios (
  id            uuid primary key default gen_random_uuid(),
  produtor_id   uuid references public.produtores(id) on delete cascade,
  titulo        text not null,
  descricao     text,
  desconto      text,
  validade      text,
  created_at    timestamptz default now()
);
alter table public.produtor_beneficios enable row level security;

-- 4) CONTEUDO MANTIDO PELO CONSELHO -----------------------------------
create table if not exists public.bi_bordeaux_br (
  id         uuid primary key default gen_random_uuid(),
  ano        int,
  indicador  text not null,
  valor      text,
  unidade    text,
  fonte      text,
  obs        text,
  ordem      int default 0,
  created_at timestamptz default now()
);
alter table public.bi_bordeaux_br enable row level security;

create table if not exists public.imprensa_contatos (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null,
  veiculo    text,
  tipo       text default 'Jornalista',
  cidade     text,
  email      text,
  telefone   text,
  instagram  text,
  obs        text,
  created_at timestamptz default now()
);
alter table public.imprensa_contatos enable row level security;

-- 5) POLICIES ----------------------------------------------------------
-- produtores: Conselho ve/edita tudo; o dono ve o seu.
drop policy if exists prod_sel on public.produtores;
create policy prod_sel on public.produtores for select to authenticated
  using (public.is_conselho() or owner_user_id = auth.uid());
drop policy if exists prod_ins on public.produtores;
create policy prod_ins on public.produtores for insert to authenticated
  with check (public.is_conselho());
drop policy if exists prod_upd on public.produtores;
create policy prod_upd on public.produtores for update to authenticated
  using (public.is_conselho()) with check (public.is_conselho());
drop policy if exists prod_del on public.produtores;
create policy prod_del on public.produtores for delete to authenticated
  using (public.is_conselho());

-- helper para policies dos pedidos
-- (Conselho tudo; produtor apenas linhas dos seus produtor_id)
do $$
declare t text;
begin
  foreach t in array array['produtor_visitas','produtor_eventos','produtor_beneficios'] loop
    execute format('drop policy if exists %I_sel on public.%I', t, t);
    execute format($f$create policy %1$s_sel on public.%1$I for select to authenticated
      using (public.is_conselho() or produtor_id in (select public.meus_produtor_ids()))$f$, t);
    execute format('drop policy if exists %I_ins on public.%I', t, t);
    execute format($f$create policy %1$s_ins on public.%1$I for insert to authenticated
      with check (public.is_conselho() or produtor_id in (select public.meus_produtor_ids()))$f$, t);
    execute format('drop policy if exists %I_del on public.%I', t, t);
    execute format($f$create policy %1$s_del on public.%1$I for delete to authenticated
      using (public.is_conselho() or produtor_id in (select public.meus_produtor_ids()))$f$, t);
    execute format('drop policy if exists %I_upd on public.%I', t, t);
    execute format($f$create policy %1$s_upd on public.%1$I for update to authenticated
      using (public.is_conselho()) with check (public.is_conselho())$f$, t);
  end loop;
end $$;

-- conteudo (BI / imprensa): qualquer produtor ou conselho le; so conselho edita.
do $$
declare t text;
begin
  foreach t in array array['bi_bordeaux_br','imprensa_contatos'] loop
    execute format('drop policy if exists %I_sel on public.%I', t, t);
    execute format($f$create policy %1$s_sel on public.%1$I for select to authenticated
      using (public.pode_produtor())$f$, t);
    execute format('drop policy if exists %I_ins on public.%I', t, t);
    execute format($f$create policy %1$s_ins on public.%1$I for insert to authenticated
      with check (public.is_conselho())$f$, t);
    execute format('drop policy if exists %I_upd on public.%I', t, t);
    execute format($f$create policy %1$s_upd on public.%1$I for update to authenticated
      using (public.is_conselho()) with check (public.is_conselho())$f$, t);
    execute format('drop policy if exists %I_del on public.%I', t, t);
    execute format($f$create policy %1$s_del on public.%1$I for delete to authenticated
      using (public.is_conselho())$f$, t);
  end loop;
end $$;

-- 6) MAILING DOS COMENDADORES (RPC, nome+email+nucleo) ----------------
create or replace function public.mailing_comendadores()
returns table(nome text, email text, nucleo text)
language sql security definer stable as $$
  select m.nome, m.email, m.nucleo
  from public.membros m
  where public.pode_produtor()
  order by m.nome;
$$;

grant execute on function public.is_produtor()           to authenticated;
grant execute on function public.pode_produtor()         to authenticated;
grant execute on function public.meus_produtor_ids()     to authenticated;
grant execute on function public.mailing_comendadores()  to authenticated;
