-- =====================================================================
-- A ficha de intronizacao preenche automaticamente o cadastro do membro,
-- e o Conselho ganha um RPC com TODOS os membros (cadastro + ficha).
-- 100% ASCII.
-- =====================================================================

-- 1) salvar_ficha (logado): grava a ficha E completa o cadastro
create or replace function public.salvar_ficha(p_ficha jsonb)
returns text language plpgsql security definer set search_path=public as $fn$
declare m record;
begin
  select id,email into m from membros where user_id = auth.uid();
  if m is null then return 'sem_membro'; end if;
  update membros set
    ficha = p_ficha, ficha_em = now(),
    nome      = coalesce(nullif(trim(coalesce(p_ficha->>'nome','')||' '||coalesce(p_ficha->>'sobrenome','')),''), nome),
    nascimento= coalesce(case when (p_ficha->>'nascimento') ~ '^\d{4}-\d{2}-\d{2}$' then (p_ficha->>'nascimento')::date else null end, nascimento),
    endereco  = coalesce(nullif(p_ficha->>'endereco',''), endereco),
    cidade    = coalesce(nullif(p_ficha->>'cidade',''), cidade),
    cep       = coalesce(nullif(p_ficha->>'cep',''), cep),
    telefone  = coalesce(nullif(p_ficha->>'telefone',''), telefone),
    nucleo    = coalesce(nullif(p_ficha->>'nucleo',''), nucleo)
  where id = m.id;
  update indicacoes set status = 'Formul'||chr(225)||'rio enviado'
    where lower(email)=lower(m.email) and status='Aprovado';
  return 'ok';
end $fn$;
grant execute on function public.salvar_ficha(jsonb) to authenticated;

-- 2) intro_salvar_ficha (token, sem login): idem
create or replace function public.intro_salvar_ficha(p_codigo text, p_token text, p_ficha jsonb)
returns text language plpgsql security definer set search_path=public as $fn$
declare m record;
begin
  select id,email into m from membros where codigo=p_codigo and ativacao_token=p_token;
  if m is null then return 'token_invalido'; end if;
  update membros set
    ficha = p_ficha, ficha_em = now(),
    nome      = coalesce(nullif(trim(coalesce(p_ficha->>'nome','')||' '||coalesce(p_ficha->>'sobrenome','')),''), nome),
    nascimento= coalesce(case when (p_ficha->>'nascimento') ~ '^\d{4}-\d{2}-\d{2}$' then (p_ficha->>'nascimento')::date else null end, nascimento),
    endereco  = coalesce(nullif(p_ficha->>'endereco',''), endereco),
    cidade    = coalesce(nullif(p_ficha->>'cidade',''), cidade),
    cep       = coalesce(nullif(p_ficha->>'cep',''), cep),
    telefone  = coalesce(nullif(p_ficha->>'telefone',''), telefone),
    nucleo    = coalesce(nullif(p_ficha->>'nucleo',''), nucleo)
  where id = m.id;
  update indicacoes set status='Formul'||chr(225)||'rio enviado'
    where lower(email)=lower(m.email) and status='Aprovado';
  return 'ok';
end $fn$;
grant execute on function public.intro_salvar_ficha(text,text,jsonb) to anon, authenticated;

-- 3) Lista completa de membros para o Conselho (cadastro + ficha)
create or replace function public.membros_completo()
returns setof membros language sql stable security definer set search_path=public as $fn$
  select * from public.membros
  where public.is_conselho()
  order by nucleo nulls last, nome;
$fn$;
grant execute on function public.membros_completo() to authenticated;
