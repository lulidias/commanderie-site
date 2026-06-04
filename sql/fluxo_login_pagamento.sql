-- =====================================================================
-- Fluxo: aprovado faz login -> ve so Ficha + Pagamentos -> Conselho confirma
-- o pagamento (e-mail de boas-vindas convidando a conhecer o site) -> acesso
-- completo. Acentos do ASSUNTO via chr(); corpos em HTML. 100% ASCII.
-- chr: 224=a-crase 231=c-cedilha 227=a-til 8212=travessao
-- =====================================================================

-- 1) E-mail de aprovacao: cria acesso (login) e explica os 2 passos
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ind_aprovado_candidato',
 'Indicacao - aprovado: crie o acesso (candidato)',
 'Aprovado '||chr(8212)||' crie o seu acesso '||chr(224)||' Commanderie',
 'Voc'||chr(234)||'ce foi aprovado '||chr(8212)||' bem-vindo!',
 '<p>Prezado(a) {nome},</p>'
 '<p>&Eacute; com grande satisfa&ccedil;&atilde;o que comunicamos: a sua indica&ccedil;&atilde;o foi <b>aprovada pelo Conselho Diretor</b> da Commanderie de Bordeaux do Brasil. &#127863;</p>'
 '<p>A sua <b>introniza&ccedil;&atilde;o oficial</b> acontecer&aacute; em:</p>'
 '<p style="background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px 14px;line-height:1.8;"><b>{evento}</b><br><b>Data e hora:</b> {quando}<br><b>Local:</b> {onde}</p>'
 '<p>Crie o seu acesso ao site com o c&oacute;digo abaixo:</p>'
 '<p style="text-align:center;font-family:Georgia,serif;font-size:20px;color:#1e2a56;letter-spacing:2px;background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px;"><b>{codigo}</b></p>'
 '<p>Ao entrar, voc&ecirc; ter&aacute; <b>dois passos</b>: preencher a <b>Ficha de Introniza&ccedil;&atilde;o</b> e acertar a <b>anuidade ({valor})</b> por PIX. O <b>acesso completo ao site</b> &eacute; liberado assim que confirmarmos o seu pagamento.</p>',
 'Criar meu acesso', 13)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 2) E-mail de pagamento confirmado + convite para conhecer o site
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('intro_pagamento_ok',
 'Pagamento confirmado + boas-vindas',
 'Pagamento confirmado '||chr(8212)||' bem-vindo '||chr(224)||' Commanderie!',
 'Pagamento confirmado '||chr(8212)||' bem-vindo!',
 '<p>Prezado(a) {nome},</p>'
 '<p>Confirmamos o <b>recebimento do seu pagamento</b>. Muito obrigado! &#127863;</p>'
 '<p>Seja oficialmente <b>bem-vindo(a) &agrave; Commanderie de Bordeaux do Brasil</b>. A partir de agora voc&ecirc; tem <b>acesso completo ao site</b>.</p>'
 '<p>Convidamos voc&ecirc; a <b>conhecer a Commanderie</b>: a <b>Academia de Bordeaux</b>, os <b>eventos</b> e cap&iacute;tulos, as <b>dicas</b> da regi&atilde;o, o <b>diret&oacute;rio de membros</b> e os benef&iacute;cios dos nossos parceiros.</p>'
 '<p style="font-family:Georgia,serif;font-style:italic;color:#8a6a1f;">Bordeaux, toujours Bordeaux.</p>',
 'Conhecer o site da Commanderie', 18)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 3) aprovar_e_acolher: cria membro (Aguardando pagamento) e manda o e-mail
--    de aprovacao com o LINK DE ACESSO (login), nao a pagina token.
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

-- 4) marcar_anuidade: ao confirmar o pagamento de um eleito, envia o e-mail
--    de boas-vindas (convite para conhecer o site).
create or replace function public.marcar_anuidade(p_codigo text, p_pago boolean)
returns jsonb language plpgsql security definer set search_path=public as $fn$
declare c int; v_ano int; m record;
begin
  if not public.is_conselho() then raise exception 'negado'; end if;
  c := coalesce((select valor::int from public.parametros where chave='ciclo_anuidade'),2026);
  if p_pago then v_ano := c; else v_ano := c-1; end if;
  update public.membros
     set anuidade_paga=p_pago, anuidade_ano=v_ano,
         anuidade_status = case when p_pago then 'Pago' else 'Aguardando pagamento' end
   where codigo=p_codigo;
  if p_pago then
    select * into m from public.membros where codigo=p_codigo;
    if m.eleito and coalesce(m.email,'')<>'' then
      perform public.enviar_modelo(m.email,'intro_pagamento_ok',
        jsonb_build_object('nome',m.nome,'link','https://commanderiedebordeaux.com.br/'));
    end if;
  end if;
  return jsonb_build_object('codigo',p_codigo,'pago',p_pago,'ano',v_ano);
end $fn$;
grant execute on function public.marcar_anuidade(text,boolean) to authenticated;
