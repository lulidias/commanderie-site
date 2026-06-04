-- =====================================================================
-- Confirmacao ao INDICADOR tambem clara para indicacoes de Comendador.
-- "enviada para o aval de {padrinho} e a aprovacao de {aprovador}".
-- Adiciona {padrinho} ao _subst, atualiza ind_registrada e re-cria o
-- gatilho (autoritativo). 100% ASCII.
-- =====================================================================

-- 1) _subst com {padrinho} (alem de {aprovador} e as demais)
create or replace function public._subst(t text, v jsonb)
returns text language sql immutable as $fn$
  select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(coalesce(t,''),
    '{nome}',      coalesce(v->>'nome','')),
    '{evento}',    coalesce(v->>'evento','')),
    '{quando}',    coalesce(v->>'quando','')),
    '{onde}',      coalesce(v->>'onde','')),
    '{indicado}',  coalesce(v->>'indicado','')),
    '{indicador}', coalesce(v->>'indicador','')),
    '{codigo}',    coalesce(v->>'codigo','')),
    '{valor}',     coalesce(v->>'valor','')),
    '{descricao}', coalesce(v->>'descricao','')),
    '{aprovador}', coalesce(v->>'aprovador','')),
    '{padrinho}',  coalesce(v->>'padrinho','')),
    '{link_sim}',  coalesce(v->>'link_sim','https://commanderiedebordeaux.com.br/indicacoes.html')),
    '{link_nao}',  coalesce(v->>'link_nao','https://commanderiedebordeaux.com.br/indicacoes.html')),
    '{link}',      coalesce(v->>'link','https://commanderiedebordeaux.com.br'));
$fn$;

-- 2) Texto claro da confirmacao do Comendador (2o padrinho + Mestre)
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ind_registrada','Indicacao - registrada (indicador)','Indicacao registrada','Indica&ccedil;&atilde;o registrada',
 '<p>Ol&aacute;, {nome}!</p><p>Recebemos a sua indica&ccedil;&atilde;o de <b>{indicado}</b>. Ela foi <b>enviada para o aval de {padrinho}</b> e, em seguida, para a <b>aprova&ccedil;&atilde;o de {aprovador}</b>.</p><p>Voc&ecirc; ser&aacute; avisado a cada etapa.</p>',
 'Abrir o Painel do Comendador', 10)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 3) Gatilho completo (autoritativo)
create or replace function public.indicacao_emails()
returns trigger language plpgsql security definer set search_path=public as $fn$
declare v_ind text; v_p2 text; v_me text;
  base text := 'https://commanderiedebordeaux.com.br/aval.html';
  painel text := 'https://commanderiedebordeaux.com.br/indicacoes.html';
  v_aprovador text; v_padrinho text;
begin
  if TG_OP = 'INSERT' then
    v_aprovador := coalesce(nullif(split_part(coalesce(NEW.mestre_nome,''), ' '||chr(183)||' ', 1),''), 'o aprovador');
    v_padrinho  := coalesce(nullif(split_part(coalesce(NEW.padrinho2_nome,''), ' '||chr(183)||' ', 1),''), 'o 2o padrinho');
    select email into v_ind from membros where user_id = NEW.indicado_por;
    if v_ind is not null then
      if NEW.padrinho2_id is null then
        perform enviar_modelo(v_ind,'ind_registrada_unico', jsonb_build_object('nome',NEW.indicado_por_nome,'indicado',NEW.nome,'aprovador',v_aprovador));
      else
        perform enviar_modelo(v_ind,'ind_registrada', jsonb_build_object('nome',NEW.indicado_por_nome,'indicado',NEW.nome,'padrinho',v_padrinho,'aprovador',v_aprovador));
      end if;
    end if;
    if NEW.padrinho2_id is not null then
      select email into v_p2 from membros where id = NEW.padrinho2_id;
      if v_p2 is not null then perform enviar_modelo(v_p2,'ind_avalize', jsonb_build_object(
        'nome',NEW.padrinho2_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',painel,
        'link_sim',base||'?id='||NEW.id||'&p=padrinho2&d=sim&t='||NEW.aval_token,
        'link_nao',base||'?id='||NEW.id||'&p=padrinho2&d=nao&t='||NEW.aval_token)); end if;
    elsif NEW.mestre_id is not null then
      select email into v_me from membros where id = NEW.mestre_id;
      if v_me is not null then perform enviar_modelo(v_me,'ind_aprovar', jsonb_build_object(
        'nome',NEW.mestre_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',painel)); end if;
    end if;
    return NEW;
  end if;

  if TG_OP = 'UPDATE' then
    if NEW.padrinho2_ok = 'Avalizado'
       and coalesce(OLD.padrinho2_ok,'') <> 'Avalizado'
       and coalesce(NEW.mestre_ok,'Pendente') not in ('Avalizado','Recusado') then
      select email into v_me from membros where id = NEW.mestre_id;
      if v_me is not null then perform enviar_modelo(v_me,'ind_aprovar', jsonb_build_object(
        'nome',NEW.mestre_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',painel)); end if;
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
