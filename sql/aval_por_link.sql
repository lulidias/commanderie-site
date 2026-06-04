-- =====================================================================
-- Aval por link (SIM / NAO direto do e-mail).
-- O 2o padrinho (aval) e o Mestre (aprovacao) respondem em um clique.
-- Link seguro por token unico de cada indicacao. 100% ASCII.
-- =====================================================================

-- 1) Token de acao da indicacao
alter table public.indicacoes add column if not exists aval_token text;
update public.indicacoes set aval_token = upper(substr(md5(random()::text||id::text),1,12)) where aval_token is null;
alter table public.indicacoes alter column aval_token set default upper(substr(md5(random()::text),1,12));

-- 2) Variaveis dos modelos: + {link_sim} + {link_nao}
create or replace function public._subst(t text, v jsonb)
returns text language sql immutable as $fn$
  select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(coalesce(t,''),
    '{nome}',      coalesce(v->>'nome','')),
    '{evento}',    coalesce(v->>'evento','')),
    '{quando}',    coalesce(v->>'quando','')),
    '{onde}',      coalesce(v->>'onde','')),
    '{indicado}',  coalesce(v->>'indicado','')),
    '{indicador}', coalesce(v->>'indicador','')),
    '{codigo}',    coalesce(v->>'codigo','')),
    '{valor}',     coalesce(v->>'valor','')),
    '{descricao}', coalesce(v->>'descricao','')),
    '{link_sim}',  coalesce(v->>'link_sim','https://commanderiedebordeaux.com.br/indicacoes.html')),
    '{link_nao}',  coalesce(v->>'link_nao','https://commanderiedebordeaux.com.br/indicacoes.html')),
    '{link}',      coalesce(v->>'link','https://commanderiedebordeaux.com.br'));
$fn$;

-- 3) Modelo ind_avalize com os botoes SIM / NAO
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ind_avalize','Indicacao - pedir aval (SIM/NAO)','Uma indicacao aguarda a sua resposta','Voc&ecirc; apoia esta indica&ccedil;&atilde;o?',
 '<p>Ol&aacute;, {nome}!</p>'
 '<p><b>{indicador}</b> indicou <b>{indicado}</b> e pediu a sua resposta.</p>'
 '<div style="text-align:center;margin:20px 0 6px;">'
 '<a href="{link_sim}" style="background:#2f6b3a;color:#fff;text-decoration:none;border-radius:10px;padding:12px 30px;font-size:16px;display:inline-block;margin:4px;">SIM</a>'
 '<a href="{link_nao}" style="background:#8f1d24;color:#fff;text-decoration:none;border-radius:10px;padding:12px 30px;font-size:16px;display:inline-block;margin:4px;">N&Atilde;O</a>'
 '</div>'
 '<p style="font-size:12.5px;color:#8a8270;text-align:center;">Um clique basta. Voc&ecirc; tamb&eacute;m pode ver os detalhes no Painel do Comendador.</p>',
 '', 11)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 4) RPC que registra a resposta vinda do link (anon, gated por token)
create or replace function public.aval_por_link(p_id uuid, p_papel text, p_dec text, p_token text)
returns text language plpgsql security definer set search_path=public as $fn$
declare ind record; dec text; nova text; p2_ok boolean;
begin
  select * into ind from indicacoes where id = p_id;
  if ind is null then return 'inexistente'; end if;
  if coalesce(ind.aval_token,'') = '' or ind.aval_token <> p_token then return 'token_invalido'; end if;
  if p_papel not in ('padrinho2','mestre') then return 'papel_invalido'; end if;
  dec := case when lower(p_dec) in ('sim','avalizar','avalizado','aprovar') then 'Avalizado'
              when lower(p_dec) in ('nao','recusar','recusado','reprovar') then 'Recusado'
              else null end;
  if dec is null then return 'decisao_invalida'; end if;
  if p_papel = 'padrinho2' and coalesce(ind.padrinho2_ok,'') in ('Avalizado','Recusado') then return 'ja_respondido'; end if;
  if p_papel = 'mestre'    and coalesce(ind.mestre_ok,'')    in ('Avalizado','Recusado') then return 'ja_respondido'; end if;
  if p_papel = 'mestre' and dec = 'Avalizado' and ind.padrinho2_id is not null
     and coalesce(ind.padrinho2_ok,'') <> 'Avalizado' then return 'aguardando_padrinho2'; end if;
  if p_papel = 'padrinho2' then update indicacoes set padrinho2_ok = dec where id = p_id;
  else update indicacoes set mestre_ok = dec where id = p_id; end if;
  select * into ind from indicacoes where id = p_id;
  p2_ok := (ind.padrinho2_id is null) or (coalesce(ind.padrinho2_ok,'') = 'Avalizado');
  if coalesce(ind.padrinho2_ok,'') = 'Recusado' or coalesce(ind.mestre_ok,'') = 'Recusado' then nova := 'Recusado';
  elsif p2_ok and coalesce(ind.mestre_ok,'') = 'Avalizado' then nova := 'Avalizada';
  else nova := 'Aguardando avais'; end if;
  update indicacoes set status = nova where id = p_id;
  return nova;
end $fn$;
grant execute on function public.aval_por_link(uuid,text,text,text) to anon, authenticated;

-- 5) Gatilho de e-mails: envia ind_avalize com links SIM/NAO por papel
create or replace function public.indicacao_emails()
returns trigger language plpgsql security definer set search_path=public as $fn$
declare v_ind text; v_p2 text; v_me text;
  base text := 'https://commanderiedebordeaux.com.br/aval.html';
  painel text := 'https://commanderiedebordeaux.com.br/indicacoes.html';
begin
  if TG_OP = 'INSERT' then
    select email into v_ind from membros where user_id = NEW.indicado_por;
    if v_ind is not null then perform enviar_modelo(v_ind,'ind_registrada', jsonb_build_object('nome',NEW.indicado_por_nome,'indicado',NEW.nome)); end if;
    if NEW.padrinho2_id is not null then
      select email into v_p2 from membros where id = NEW.padrinho2_id;
      if v_p2 is not null then perform enviar_modelo(v_p2,'ind_avalize', jsonb_build_object(
        'nome',NEW.padrinho2_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',painel,
        'link_sim',base||'?id='||NEW.id||'&p=padrinho2&d=sim&t='||NEW.aval_token,
        'link_nao',base||'?id='||NEW.id||'&p=padrinho2&d=nao&t='||NEW.aval_token)); end if;
    elsif NEW.mestre_id is not null then
      select email into v_me from membros where id = NEW.mestre_id;
      if v_me is not null then perform enviar_modelo(v_me,'ind_avalize', jsonb_build_object(
        'nome',NEW.mestre_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',painel,
        'link_sim',base||'?id='||NEW.id||'&p=mestre&d=sim&t='||NEW.aval_token,
        'link_nao',base||'?id='||NEW.id||'&p=mestre&d=nao&t='||NEW.aval_token)); end if;
    end if;
    return NEW;
  end if;

  if TG_OP = 'UPDATE' then
    if NEW.padrinho2_ok = 'Avalizado'
       and coalesce(OLD.padrinho2_ok,'') <> 'Avalizado'
       and coalesce(NEW.mestre_ok,'Pendente') not in ('Avalizado','Recusado') then
      select email into v_me from membros where id = NEW.mestre_id;
      if v_me is not null then perform enviar_modelo(v_me,'ind_avalize', jsonb_build_object(
        'nome',NEW.mestre_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',painel,
        'link_sim',base||'?id='||NEW.id||'&p=mestre&d=sim&t='||NEW.aval_token,
        'link_nao',base||'?id='||NEW.id||'&p=mestre&d=nao&t='||NEW.aval_token)); end if;
    end if;

    if NEW.status is distinct from OLD.status then
      select email into v_ind from membros where user_id = NEW.indicado_por;
      if NEW.status = 'Recusado' then
        if v_ind is not null then perform enviar_modelo(v_ind,'ind_recusado', jsonb_build_object('nome',NEW.indicado_por_nome,'indicado',NEW.nome)); end if;
      elsif NEW.status like 'Formul_rio enviado' then
        if NEW.email is not null then perform enviar_modelo(NEW.email,'ind_ficha_recebida', jsonb_build_object('nome',NEW.nome)); end if;
      elsif NEW.status = 'Membro' then
        if v_ind is not null then perform enviar_modelo(v_ind,'ind_membro_indicador', jsonb_build_object('nome',NEW.indicado_por_nome,'indicado',NEW.nome)); end if;
      end if;
    end if;
    return NEW;
  end if;

  return NEW;
end $fn$;
