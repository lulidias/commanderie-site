-- =====================================================================
-- ATUALIZAR TUDO - rode este arquivo inteiro de uma vez (Run).
-- Reune, na ordem certa: comprovante+e-mails, padrinhos na ficha,
-- quem paga a anuidade e a troca Intronizacao->Entronizacao nos e-mails.
-- Idempotente (pode rodar de novo sem problema).
-- =====================================================================

-- ############ 1) comprovante + e-mails (pagamento / aviso ao Mestre) ############
-- =====================================================================
-- Comprovante de pagamento anexado a Ficha de Intronizacao (obrigatorio) +
-- e-mails que faltavam: pagamento confirmado (candidato) e ficha enviada
-- (aviso ao Mestre/Grao-Mestre que aprovou). 100% ASCII.
-- chr: 224=a-crase 231=c-cedilha 227=a-til 234=e-circ 8212=travessao 183=ponto
-- =====================================================================

-- 0) Coluna do comprovante + bucket de storage
alter table public.membros add column if not exists comprovante_url text;

insert into storage.buckets (id, name, public) values ('comprovantes','comprovantes', true)
on conflict (id) do update set public = true;

drop policy if exists comp_read on storage.objects;
create policy comp_read on storage.objects for select using (bucket_id='comprovantes');
drop policy if exists comp_insert on storage.objects;
create policy comp_insert on storage.objects for insert to authenticated with check (bucket_id='comprovantes');
drop policy if exists comp_update on storage.objects;
create policy comp_update on storage.objects for update to authenticated using (bucket_id='comprovantes') with check (bucket_id='comprovantes');
drop policy if exists comp_delete on storage.objects;
create policy comp_delete on storage.objects for delete to authenticated using (bucket_id='comprovantes' and public.is_conselho());

-- 1) E-mail de aprovacao: passo a passo (PIX + comprovante na ficha)
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ind_aprovado_candidato',
 'Indicacao - aprovado: passo a passo (candidato)',
 'Aprovado '||chr(8212)||' crie o seu acesso '||chr(224)||' Commanderie',
 'Voc'||chr(234)||' foi aprovado '||chr(8212)||' bem-vindo!',
 '<p>Prezado(a) {nome},</p>'
 '<p>&Eacute; com grande satisfa&ccedil;&atilde;o que comunicamos: a sua indica&ccedil;&atilde;o foi <b>aprovada pelo Conselho Diretor</b>. &#127863;</p>'
 '<p>A sua <b>introniza&ccedil;&atilde;o oficial</b> acontecer&aacute; em:</p>'
 '<p style="background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px 14px;line-height:1.8;"><b>{evento}</b><br><b>Data e hora:</b> {quando}<br><b>Local:</b> {onde}</p>'
 '<p><b>Passo a passo para concluir a sua introniza&ccedil;&atilde;o:</b></p>'
 '<ol style="line-height:1.7;">'
 '<li>Fa&ccedil;a o <b>PIX da anuidade ({valor})</b> para a chave <b>010.091.449-79</b> (Manuel Roberto Brand&atilde;o &middot; Bradesco). Guarde o <b>comprovante</b>.</li>'
 '<li>Crie o seu acesso ao site com o c&oacute;digo: <b>{codigo}</b>.</li>'
 '<li>Preencha a <b>Ficha de Introniza&ccedil;&atilde;o</b> e, ao final, <b>anexe o comprovante</b> do PIX (obrigat&oacute;rio para enviar).</li>'
 '<li>Envie. Assim que confirmarmos o pagamento, voc&ecirc; ter&aacute; <b>acesso completo ao site</b>.</li>'
 '</ol>',
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
 '<p>Convidamos voc&ecirc; a <b>conhecer a Commanderie</b>: a <b>Academia de Bordeaux</b>, os <b>eventos</b> e cap&iacute;tulos, as <b>dicas</b> da regi&atilde;o e o <b>diret&oacute;rio de membros</b>.</p>'
 '<p style="font-family:Georgia,serif;font-style:italic;color:#8a6a1f;">Bordeaux, toujours Bordeaux.</p>',
 'Conhecer o site da Commanderie', 18)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 3) E-mail ao Mestre/Grao-Mestre: ficha enviada
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ficha_enviada_mestre',
 'Ficha enviada - aviso ao Mestre que aprovou',
 'Ficha de introniza'||chr(231)||chr(227)||'o recebida',
 'Ficha de introniza&ccedil;&atilde;o recebida',
 '<p>Ol&aacute;, {nome}!</p>'
 '<p><b>{indicado}</b> preencheu e enviou a <b>Ficha de Introniza&ccedil;&atilde;o</b>, com o <b>comprovante de pagamento</b> anexado.</p>'
 '<p>Acesse o <b>Painel do Conselho &rarr; Membros</b> para revisar a ficha e confirmar o pagamento.</p>',
 'Abrir o Painel do Conselho', 19)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 4) salvar_ficha: grava ficha+comprovante, completa cadastro, avisa o Mestre
create or replace function public.salvar_ficha(p_ficha jsonb)
returns text language plpgsql security definer set search_path=public as $fn$
declare m record; v_mid uuid; v_mnome text; v_memail text;
begin
  select id,email,nome into m from membros where user_id = auth.uid();
  if m is null then return 'sem_membro'; end if;
  update membros set
    ficha = p_ficha, ficha_em = now(),
    comprovante_url = coalesce(nullif(p_ficha->>'comprovante_url',''), comprovante_url),
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
  select i.mestre_id, i.mestre_nome into v_mid, v_mnome
    from indicacoes i where lower(i.email)=lower(m.email) order by i.created_at desc limit 1;
  if v_mid is not null then
    select email into v_memail from membros where id = v_mid;
    if v_memail is not null then
      perform enviar_modelo(v_memail,'ficha_enviada_mestre',
        jsonb_build_object('nome', split_part(coalesce(v_mnome,'Mestre'),' '||chr(183)||' ',1), 'indicado', m.nome));
    end if;
  end if;
  return 'ok';
end $fn$;
grant execute on function public.salvar_ficha(jsonb) to authenticated;

-- 5) marcar_anuidade: confirma pagamento de eleito -> e-mail de boas-vindas
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

-- ############ 2) padrinhos pre-preenchidos na ficha ############
-- =====================================================================
-- Padrinhos + Mestre da indicacao para pre-preencher a ficha (logado).
-- 100% ASCII.
-- =====================================================================
create or replace function public.meus_padrinhos()
returns jsonb language sql stable security definer set search_path=public as $fn$
  select jsonb_build_object(
    'padrinho1', i.indicado_por_nome,
    'padrinho2', i.padrinho2_nome,
    'mestre',    i.mestre_nome
  )
  from public.indicacoes i, public.membros m
  where m.user_id = auth.uid()
    and lower(i.email) = lower(m.email)
  order by i.created_at desc
  limit 1;
$fn$;
grant execute on function public.meus_padrinhos() to authenticated;

-- ############ 3) quem paga a anuidade (financeiro) ############
-- =====================================================================
-- Fluxo financeiro de "quem paga a anuidade".
-- Leva da indicacao para o membro: anuidade_por (indicado/padrinho_primeira/
-- padrinho_sempre) e o nome do padrinho. aprovar_e_acolher carrega esses dados.
-- 100% ASCII. chr: 224 a-crase, 231 c-ced, 227 a-til, 234 e-circ, 8212 travessao
-- =====================================================================

alter table public.membros add column if not exists anuidade_por text default 'indicado';
alter table public.membros add column if not exists anuidade_padrinho text;
alter table public.membros add column if not exists comprovante_url text;

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
  insert into membros (codigo,nome,email,grau,nucleo,eleito,data_intronizacao,ativado,ativacao_token,anuidade_valor,anuidade_paga,anuidade_status,anuidade_por,anuidade_padrinho)
    values (v_codigo,i.nome,lower(i.email),'Commandeur',i.nucleo,true,e.data,false,v_token,v_anuidade,false,'Aguardando pagamento',
            coalesce(i.anuidade_por,'indicado'),
            case when coalesce(i.anuidade_por,'indicado') in ('padrinho_primeira','padrinho_sempre','padrinho') then i.indicado_por_nome else null end)
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

-- ############ 4) troca Intronizacao -> Entronizacao nos e-mails ############
-- =====================================================================
-- Troca "Intronizacao/intronizado" por "Entronizacao/entronizado" nos
-- modelos de e-mail (assunto, titulo, corpo). Nenhum corpo usa o filename
-- ficha-intronizacao.html, entao o replace e' seguro. 100% ASCII.
-- =====================================================================
update public.email_modelos set
  assunto = replace(replace(assunto,'Introniza','Entroniza'),'introniza','entroniza'),
  titulo  = replace(replace(replace(titulo,'Introniza','Entroniza'),'introniza&ccedil;','entroniza&ccedil;'),'intronizado','entronizado'),
  corpo   = replace(replace(replace(corpo,'Introniza','Entroniza'),'introniza&ccedil;','entroniza&ccedil;'),'intronizado','entronizado')
where assunto like '%ntroniza%' or titulo like '%ntroniza%' or corpo like '%ntroniza%';
