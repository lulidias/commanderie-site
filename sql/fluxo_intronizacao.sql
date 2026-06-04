-- =====================================================================
-- Fluxo de Intronizacao (fase entre o e-mail e o acesso ao site).
-- 1) Aprovacao -> e-mail leva a ficha-intronizacao.html?ac=..&at=.. (sem conta)
-- 2) Candidato preenche a FICHA (obrigatoria) e avisa o PIX (obrigatorio)
-- 3) Conselho confirma o pagamento -> e-mail de boas-vindas com o ACESSO
-- 4) 1o acesso: cadastro obrigatorio (no front)
-- RPCs protegidos por codigo+token (anon). 100% ASCII.
-- =====================================================================

-- 1) Dados para a pagina de intronizacao (sem login)
create or replace function public.intro_dados(p_codigo text, p_token text)
returns jsonb language plpgsql security definer set search_path=public as $fn$
declare m record; e record; v_evento text:=''; v_quando text:=''; v_onde text:='a confirmar';
begin
  select * into m from membros where codigo=p_codigo and ativacao_token=p_token;
  if m is null then return jsonb_build_object('erro','token_invalido'); end if;
  select * into e from eventos where tipo='Cap'||chr(237)||'tulo' and data=m.data_intronizacao order by data limit 1;
  if e is not null then
    v_evento := trim(both ' ' from coalesce(e.tipo,'')||coalesce(' '||e.numero,'')||coalesce(' - '||e.titulo,''));
    v_quando := to_char(e.data,'DD/MM/YYYY')||coalesce(' '||chr(224)||'s '||e.hora,'');
    v_onde   := coalesce(nullif(concat_ws(' - ', e.local, e.endereco, e.cidade),''),'a confirmar');
  end if;
  return jsonb_build_object(
    'nome', m.nome, 'sobrenome','', 'nucleo', coalesce(m.nucleo,''), 'email', coalesce(m.email,''),
    'anuidade', coalesce(m.anuidade_valor,1200),
    'ficha_enviada', (m.ficha is not null),
    'pagamento_avisado', (coalesce(m.anuidade_status,'') = 'Comprovante enviado' or coalesce(m.anuidade_paga,false)),
    'pago', coalesce(m.anuidade_paga,false),
    'ativado', coalesce(m.ativado,false),
    'evento', v_evento, 'quando', v_quando, 'onde', v_onde);
end $fn$;
grant execute on function public.intro_dados(text,text) to anon, authenticated;

-- 2) Salvar a ficha (gated por token)
create or replace function public.intro_salvar_ficha(p_codigo text, p_token text, p_ficha jsonb)
returns text language plpgsql security definer set search_path=public as $fn$
declare m record;
begin
  select id,email into m from membros where codigo=p_codigo and ativacao_token=p_token;
  if m is null then return 'token_invalido'; end if;
  update membros set ficha=p_ficha, ficha_em=now() where id=m.id;
  update indicacoes set status='Formul'||chr(225)||'rio enviado'
    where lower(email)=lower(m.email) and status='Aprovado';
  return 'ok';
end $fn$;
grant execute on function public.intro_salvar_ficha(text,text,jsonb) to anon, authenticated;

-- 3) Candidato avisa que pagou (gated por token)
create or replace function public.intro_marcar_pagamento(p_codigo text, p_token text)
returns text language plpgsql security definer set search_path=public as $fn$
declare m record;
begin
  select id into m from membros where codigo=p_codigo and ativacao_token=p_token;
  if m is null then return 'token_invalido'; end if;
  update membros set anuidade_status='Comprovante enviado' where id=m.id and coalesce(anuidade_paga,false)=false;
  return 'ok';
end $fn$;
grant execute on function public.intro_marcar_pagamento(text,text) to anon, authenticated;

-- 4) E-mail de pagamento confirmado + acesso ao site
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('intro_pagamento_ok','Intronizacao - pagamento confirmado + acesso','Pagamento confirmado '||chr(8212)||' bem-vindo!','Pagamento confirmado!',
 '<p>Prezado(a) {nome},</p>'
 '<p>Confirmamos o <b>recebimento do seu pagamento</b>. Muito obrigado &mdash; &eacute; uma alegria t&ecirc;-lo(a) na Commanderie de Bordeaux do Brasil! &#127863;</p>'
 '<p>Agora &eacute; s&oacute; <b>criar o seu acesso ao site</b>. No primeiro acesso vamos pedir que voc&ecirc; <b>complete o seu cadastro</b>.</p>',
 'Criar meu acesso ao site', 18)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 5) marcar_anuidade: ao confirmar pagamento de eleito que ainda nao ativou,
--    envia o e-mail de boas-vindas com o acesso.
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
    if m.eleito and not coalesce(m.ativado,false) and coalesce(m.email,'')<>'' then
      perform public.enviar_modelo(m.email,'intro_pagamento_ok',
        jsonb_build_object('nome',m.nome,'link','https://commanderiedebordeaux.com.br/?ac='||m.codigo||'&at='||m.ativacao_token));
    end if;
  end if;
  return jsonb_build_object('codigo',p_codigo,'pago',p_pago,'ano',v_ano);
end $fn$;
grant execute on function public.marcar_anuidade(text,boolean) to authenticated;

-- 6) E-mail de aprovacao -> leva a pagina de intronizacao (ficha + pagamento)
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ind_aprovado_candidato',
 'Indicacao - aprovado: ficha + pagamento (candidato)',
 'Aprovado '||chr(8212)||' sua introniza'||chr(231)||chr(227)||'o na Commanderie',
 'Voc&ecirc; foi aprovado &mdash; bem-vindo!',
 '<p>Prezado(a) {nome},</p>'
 '<p>&Eacute; com grande satisfa&ccedil;&atilde;o que comunicamos: a sua indica&ccedil;&atilde;o foi <b>aprovada pelo Conselho Diretor</b> da Commanderie de Bordeaux do Brasil. &#127863;</p>'
 '<p>A sua <b>introniza&ccedil;&atilde;o oficial</b> acontecer&aacute; em:</p>'
 '<p style="background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px 14px;line-height:1.8;"><b>{evento}</b><br><b>Data e hora:</b> {quando}<br><b>Local:</b> {onde}</p>'
 '<p>Para confirmar a sua participa&ccedil;&atilde;o, h&aacute; <b>dois passos</b> nesta p&aacute;gina: preencher a sua <b>Ficha de Introniza&ccedil;&atilde;o</b> e acertar a <b>anuidade ({valor})</b> por PIX.</p>'
 '<p>O acesso completo ao site &eacute; liberado assim que confirmarmos o seu pagamento.</p>',
 'Preencher ficha e pagamento',
 13)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 7) aprovar_e_acolher: link do e-mail -> ficha-intronizacao.html (ficha+pagamento)
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
  link := 'https://commanderiedebordeaux.com.br/ficha-intronizacao.html?ac='||v_codigo||'&at='||v_token;
  perform public.enviar_modelo(i.email,'ind_aprovado_candidato',
    jsonb_build_object('nome',i.nome,'data',v_data,'evento',v_evento,'quando',v_quando,'onde',coalesce(v_onde,'a confirmar'),'codigo',v_codigo,'valor',v_valor,'link',link));
  select email into v_ind_email from membros where user_id=i.indicado_por;
  if v_ind_email is not null then perform public.enviar_modelo(v_ind_email,'ind_aprovado_indicador', jsonb_build_object('nome',i.indicado_por_nome,'indicado',i.nome)); end if;
  update indicacoes set status='Aprovado', codigo_acesso=v_codigo where id=p_indicacao;
  return json_build_object('codigo',v_codigo,'token',v_token,'membro_id',v_id,'data',v_data,'nome',i.nome);
end $fn$;
grant execute on function public.aprovar_e_acolher(uuid,uuid) to authenticated;
