-- =====================================================================
-- E-mail do candidato aprovado: parabens + capitulo + ficha + PAGAMENTO.
-- aprovar_e_acolher passa o valor da anuidade ao modelo. So roda quando a
-- indicacao esta AVALIZADA. 100% ASCII (acentos por entidades/chr).
-- =====================================================================

-- 1) Modelo com a secao de pagamento (usa {valor})
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ind_aprovado_candidato',
 'Indicacao - aprovado: ficha + pagamento (candidato)',
 'Aprovado &mdash; ficha de introniza&ccedil;&atilde;o e anuidade',
 'Voc&ecirc; foi aprovado &mdash; bem-vindo!',
 '<p>Prezado(a) {nome},</p>'
 '<p>&Eacute; com grande satisfa&ccedil;&atilde;o que comunicamos: a sua indica&ccedil;&atilde;o foi <b>aprovada pelo Conselho Diretor</b> da Commanderie de Bordeaux do Brasil. &#127863;</p>'
 '<p>A sua <b>introniza&ccedil;&atilde;o oficial</b> acontecer&aacute; em:</p>'
 '<p style="background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px 14px;line-height:1.8;"><b>{evento}</b><br><b>Data e hora:</b> {quando}<br><b>Local:</b> {onde}</p>'
 '<p>O pr&oacute;ximo passo &eacute; <b>preencher a sua Ficha de Introniza&ccedil;&atilde;o</b>. Crie o seu acesso ao site com o c&oacute;digo abaixo:</p>'
 '<p style="text-align:center;font-family:Georgia,serif;font-size:20px;color:#1e2a56;letter-spacing:2px;background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px;"><b>{codigo}</b></p>'
 '<p><b>Anuidade:</b> {valor}. Ap&oacute;s criar o seu acesso, voc&ecirc; acerta o pagamento na se&ccedil;&atilde;o <b>Pagamentos</b> do painel (PIX).</p>'
 '<p style="font-size:13px;color:#8a6a1f;">Leve ao seu cap&iacute;tulo uma garrafa de um bom Bordeaux para a introniza&ccedil;&atilde;o.</p>',
 'Criar acesso e preencher a ficha',
 13)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 2) aprovar_e_acolher() passando {valor}; exige status AVALIZADA
create or replace function public.aprovar_e_acolher(p_indicacao uuid, p_evento uuid)
returns json language plpgsql security definer set search_path=public as $fn$
declare i record; e record; v_codigo text; v_token text; v_id uuid; v_ano text:=to_char(now(),'YYYY'); v_seq int; v_data text; link text; v_ind_email text; v_evento text; v_quando text; v_onde text; v_anuidade int:=1200; v_valor text;
begin
  if not public.is_conselho() then raise exception 'Apenas o Conselho pode aprovar'; end if;
  select * into i from indicacoes where id=p_indicacao;
  if i is null then raise exception 'Indicacao inexistente'; end if;
  if coalesce(i.status,'') <> 'Avalizada' then
    raise exception 'A indicacao precisa estar AVALIZADA (avais completos) antes de aprovar.';
  end if;
  select * into e from eventos where id=p_evento;
  if e is null then raise exception 'Capitulo inexistente'; end if;
  if coalesce(i.email,'')='' then raise exception 'A indicacao nao tem e-mail'; end if;
  if exists(select 1 from membros where lower(email)=lower(i.email)) then raise exception 'Ja existe membro com este e-mail'; end if;
  select coalesce(max(nullif(regexp_replace(codigo,'^CDB-\d{4}-',''),'')::int),0)+1 into v_seq from membros where codigo like 'CDB-'||v_ano||'-%';
  v_codigo := 'CDB-'||v_ano||'-'||lpad(v_seq::text,3,'0');
  v_token  := upper(substr(md5(random()::text),1,4))||lpad(((random()*9000)::int+1000)::text,4,'0');
  insert into membros (codigo,nome,email,grau,nucleo,eleito,data_intronizacao,ativado,ativacao_token,anuidade_valor,anuidade_paga,anuidade_status)
    values (v_codigo,i.nome,lower(i.email),'Commandeur',i.nucleo,true,e.data,false,v_token,v_anuidade,false,'Aguardando pagamento')
    returning id into v_id;
  v_data   := to_char(e.data,'DD/MM/YYYY');
  v_evento := trim(both ' ' from coalesce(e.tipo,'')||coalesce(' '||e.numero,'')||coalesce(' - '||e.titulo,''));
  v_quando := v_data || coalesce(' '||chr(224)||'s '||e.hora, '');
  v_onde   := nullif(concat_ws(' - ', e.local, e.endereco, e.cidade), '');
  v_valor  := 'R$ '||translate(to_char(v_anuidade,'FM999G990D00'),',.','.,');
  link := 'https://commanderiedebordeaux.com.br/?ac='||v_codigo||'&at='||v_token;
  perform public.enviar_modelo(i.email,'ind_aprovado_candidato',
    jsonb_build_object('nome',i.nome,'data',v_data,'evento',v_evento,'quando',v_quando,'onde',coalesce(v_onde,'a confirmar'),'codigo',v_codigo,'valor',v_valor,'link',link));
  select email into v_ind_email from membros where user_id=i.indicado_por;
  if v_ind_email is not null then perform public.enviar_modelo(v_ind_email,'ind_aprovado_indicador', jsonb_build_object('nome',i.indicado_por_nome,'indicado',i.nome)); end if;
  update indicacoes set status='Aprovado', codigo_acesso=v_codigo where id=p_indicacao;
  return json_build_object('codigo',v_codigo,'token',v_token,'membro_id',v_id,'data',v_data,'nome',i.nome);
end $fn$;
grant execute on function public.aprovar_e_acolher(uuid,uuid) to authenticated;
