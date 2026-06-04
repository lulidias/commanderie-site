-- =====================================================================
-- Correcao do fluxo de avais das indicacoes.
-- Problema: a coluna padrinho2_ok/mestre_ok nasce como 'Pendente', mas as
-- funcoes verificavam string vazia ('') -> o card "Avais pendentes" do 2o
-- padrinho ficava VAZIO, e o aprovar_e_acolher rodava sem avais (mandando
-- e-mail ao indicado cedo demais).
-- Correcao: tratar 'Pendente' como pendente; so aprovar/acolher (e mandar
-- e-mail ao indicado) quando a indicacao estiver AVALIZADA. 100% ASCII.
-- =====================================================================

-- 1) meus_avais(): mostra ao avalista enquanto o aval estiver pendente
--    (vazio OU 'Pendente'). Mestre so ve depois do 2o padrinho (ou sem 2o).
create or replace function public.meus_avais()
returns setof indicacoes language sql stable security definer set search_path=public as $fn$
  select i.* from public.indicacoes i, public.membros m
  where m.user_id = auth.uid()
    and coalesce(i.status,'') = 'Aguardando avais'
    and (
      (i.padrinho2_id = m.id and coalesce(i.padrinho2_ok,'') in ('','Pendente'))
      or (i.mestre_id = m.id and coalesce(i.mestre_ok,'') in ('','Pendente')
          and (i.padrinho2_id is null or coalesce(i.padrinho2_ok,'') = 'Avalizado'))
    );
$fn$;
grant execute on function public.meus_avais() to authenticated;

-- 2) avalizar(): robusto a 'Pendente'. Mestre so avaliza depois do 2o
--    padrinho (exceto indicacao sem 2o padrinho, ex.: do Grao-Mestre).
create or replace function public.avalizar(p_id uuid, p_decisao text)
returns text language plpgsql security definer set search_path=public as $fn$
declare ind record; meu uuid; papel text; dec text; nova text; p2_ok boolean;
begin
  select id into meu from membros where user_id = auth.uid();
  if meu is null then return 'sem_membro'; end if;
  select * into ind from indicacoes where id = p_id;
  if ind is null then return 'inexistente'; end if;
  if ind.padrinho2_id = meu then papel := 'padrinho2';
  elsif ind.mestre_id = meu then papel := 'mestre';
  else return 'nao_autorizado'; end if;
  dec := case when lower(p_decisao) in ('avalizar','avalizado','aprovar') then 'Avalizado'
              when lower(p_decisao) in ('recusar','recusado') then 'Recusado'
              else null end;
  if dec is null then return 'decisao_invalida'; end if;
  if papel = 'mestre' and dec = 'Avalizado'
     and ind.padrinho2_id is not null
     and coalesce(ind.padrinho2_ok,'') <> 'Avalizado' then
    return 'aguardando_padrinho2';
  end if;
  if papel = 'padrinho2' then update indicacoes set padrinho2_ok = dec where id = p_id;
  else update indicacoes set mestre_ok = dec where id = p_id; end if;
  select * into ind from indicacoes where id = p_id;
  p2_ok := (ind.padrinho2_id is null) or (coalesce(ind.padrinho2_ok,'') = 'Avalizado');
  if coalesce(ind.padrinho2_ok,'') = 'Recusado' or coalesce(ind.mestre_ok,'') = 'Recusado' then nova := 'Recusado';
  elsif p2_ok and coalesce(ind.mestre_ok,'') = 'Avalizado' then nova := 'Avalizada';
  else nova := 'Aguardando avais'; end if;
  update indicacoes set status = nova where id = p_id;
  return nova;
end $fn$;
grant execute on function public.avalizar(uuid,text) to authenticated;

-- 3) aprovar_e_acolher(): SO depois de AVALIZADA (avais completos).
--    Antes disso nao cria membro nem envia e-mail ao indicado.
create or replace function public.aprovar_e_acolher(p_indicacao uuid, p_evento uuid)
returns json language plpgsql security definer set search_path=public as $fn$
declare i record; e record; v_codigo text; v_token text; v_id uuid; v_ano text:=to_char(now(),'YYYY'); v_seq int; v_data text; link text; v_ind_email text; v_evento text; v_quando text; v_onde text;
begin
  if not public.is_conselho() then raise exception 'Apenas o Conselho pode aprovar'; end if;
  select * into i from indicacoes where id=p_indicacao;
  if i is null then raise exception 'Indicacao inexistente'; end if;
  if coalesce(i.status,'') <> 'Avalizada' then
    raise exception 'A indicacao precisa estar AVALIZADA (avais do 2o padrinho e do Mestre) antes de aprovar e acolher.';
  end if;
  select * into e from eventos where id=p_evento;
  if e is null then raise exception 'Capitulo inexistente'; end if;
  if coalesce(i.email,'')='' then raise exception 'A indicacao nao tem e-mail'; end if;
  if exists(select 1 from membros where lower(email)=lower(i.email)) then raise exception 'Ja existe membro com este e-mail'; end if;
  select coalesce(max(nullif(regexp_replace(codigo,'^CDB-\d{4}-',''),'')::int),0)+1 into v_seq from membros where codigo like 'CDB-'||v_ano||'-%';
  v_codigo := 'CDB-'||v_ano||'-'||lpad(v_seq::text,3,'0');
  v_token  := upper(substr(md5(random()::text),1,4))||lpad(((random()*9000)::int+1000)::text,4,'0');
  insert into membros (codigo,nome,email,grau,nucleo,eleito,data_intronizacao,ativado,ativacao_token,anuidade_valor,anuidade_paga,anuidade_status)
    values (v_codigo,i.nome,lower(i.email),'Commandeur',i.nucleo,true,e.data,false,v_token,1200,true,'Introniza&ccedil;&atilde;o')
    returning id into v_id;
  v_data   := to_char(e.data,'DD/MM/YYYY');
  v_evento := trim(both ' ' from coalesce(e.tipo,'')||coalesce(' '||e.numero,'')||coalesce(' - '||e.titulo,''));
  v_quando := v_data || coalesce(' '||chr(224)||'s '||e.hora, '');
  v_onde   := nullif(concat_ws(' - ', e.local, e.endereco, e.cidade), '');
  link := 'https://commanderiedebordeaux.com.br/?ac='||v_codigo||'&at='||v_token;
  perform public.enviar_modelo(i.email,'ind_aprovado_candidato',
    jsonb_build_object('nome',i.nome,'data',v_data,'evento',v_evento,'quando',v_quando,'onde',coalesce(v_onde,'a confirmar'),'codigo',v_codigo,'link',link));
  select email into v_ind_email from membros where user_id=i.indicado_por;
  if v_ind_email is not null then perform public.enviar_modelo(v_ind_email,'ind_aprovado_indicador', jsonb_build_object('nome',i.indicado_por_nome,'indicado',i.nome)); end if;
  update indicacoes set status='Aprovado', codigo_acesso=v_codigo where id=p_indicacao;
  return json_build_object('codigo',v_codigo,'token',v_token,'membro_id',v_id,'data',v_data,'nome',i.nome);
end $fn$;
grant execute on function public.aprovar_e_acolher(uuid,uuid) to authenticated;
