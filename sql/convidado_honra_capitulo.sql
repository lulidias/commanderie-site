-- =====================================================================
-- Convidado de Honra: agora com o CAPITULO em que sera entronizado.
-- Define data_intronizacao a partir do evento (capitulo) escolhido.
-- 100% ASCII.
-- =====================================================================

drop function if exists public.criar_convidado_honra(text,text,text);

create or replace function public.criar_convidado_honra(p_nome text, p_email text, p_nucleo text default null, p_evento uuid default null)
returns json language plpgsql security definer set search_path=public as $fn$
declare v_ano text:=to_char(now(),'YYYY'); v_seq int; v_codigo text; v_token text; v_id uuid; e record; v_data date;
begin
  if not exists(select 1 from membros where user_id = auth.uid() and coalesce(pode_honra,false) = true) then
    raise exception 'Apenas o Presidente e o Vice podem cadastrar Convidados de Honra';
  end if;
  if coalesce(trim(p_nome),'')='' then raise exception 'Nome obrigatorio'; end if;
  if coalesce(trim(p_email),'')='' then raise exception 'E-mail obrigatorio'; end if;
  if exists(select 1 from membros where lower(email)=lower(trim(p_email))) then raise exception 'Ja existe um membro com este e-mail'; end if;
  if p_evento is not null then
    select * into e from eventos where id = p_evento;
    if e is not null then v_data := e.data; end if;
  end if;
  select coalesce(max(nullif(regexp_replace(codigo,'^CDB-\d{4}-',''),'')::int),0)+1
    into v_seq from membros where codigo like 'CDB-'||v_ano||'-%';
  v_codigo := 'CDB-'||v_ano||'-'||lpad(v_seq::text,3,'0');
  v_token  := upper(substr(md5(random()::text),1,4))||lpad(((random()*9000)::int+1000)::text,4,'0');
  insert into membros (codigo,nome,email,grau,nucleo,anuidade_valor,anuidade_paga,anuidade_status,ativado,ativacao_token,eleito,anuidade_por,data_intronizacao)
    values (v_codigo,trim(p_nome),lower(trim(p_email)),'Membro de Honra',p_nucleo,0,true,'Isento',false,v_token,false,'indicado',v_data)
    returning id into v_id;
  return json_build_object('codigo',v_codigo,'token',v_token,'nome',trim(p_nome),'membro_id',v_id);
end $fn$;
grant execute on function public.criar_convidado_honra(text,text,text,uuid) to authenticated;
