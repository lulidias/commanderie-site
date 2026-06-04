-- =====================================================================
-- Aprovacao do Mestre/Grao-Mestre exige escolher o capitulo.
-- O 2o padrinho continua dando o aval por SIM/NAO (ind_avalize).
-- O APROVADOR (Mestre/GM) recebe um e-mail que leva ao painel, onde
-- aprova E escolhe o capitulo num passo so. 100% ASCII.
-- =====================================================================

-- 1) Modelo do aprovador (leva ao painel; sem SIM/NAO de um clique)
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ind_aprovar','Indicacao - aprovacao do Mestre/GM (com capitulo)','Uma indicacao aguarda a sua aprovacao','A sua aprova&ccedil;&atilde;o &eacute; necess&aacute;ria',
 '<p>Ol&aacute;, {nome}!</p><p><b>{indicador}</b> indicou <b>{indicado}</b> e a sua <b>aprova&ccedil;&atilde;o</b> &eacute; necess&aacute;ria.</p><p>Abra o Painel do Comendador para <b>aprovar e escolher o cap&iacute;tulo de introniza&ccedil;&atilde;o</b> (ou reprovar). A escolha do cap&iacute;tulo &eacute; obrigat&oacute;ria na aprova&ccedil;&atilde;o.</p>',
 'Aprovar no painel', 11)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 2) Gatilho: 2o padrinho -> ind_avalize (SIM/NAO); aprovador -> ind_aprovar
create or replace function public.indicacao_emails()
returns trigger language plpgsql security definer set search_path=public as $fn$
declare v_ind text; v_p2 text; v_me text;
  base text := 'https://commanderiedebordeaux.com.br/aval.html';
  painel text := 'https://commanderiedebordeaux.com.br/indicacoes.html';
begin
  if TG_OP = 'INSERT' then
    select email into v_ind from membros where user_id = NEW.indicado_por;
    if v_ind is not null then
      if NEW.padrinho2_id is null then
        perform enviar_modelo(v_ind,'ind_registrada_unico', jsonb_build_object('nome',NEW.indicado_por_nome,'indicado',NEW.nome,'aprovador',coalesce(NEW.mestre_nome,'a aprova'||chr(231)||chr(227)||'o')));
      else
        perform enviar_modelo(v_ind,'ind_registrada', jsonb_build_object('nome',NEW.indicado_por_nome,'indicado',NEW.nome));
      end if;
    end if;
    if NEW.padrinho2_id is not null then
      -- 2o padrinho: aval por SIM/NAO
      select email into v_p2 from membros where id = NEW.padrinho2_id;
      if v_p2 is not null then perform enviar_modelo(v_p2,'ind_avalize', jsonb_build_object(
        'nome',NEW.padrinho2_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',painel,
        'link_sim',base||'?id='||NEW.id||'&p=padrinho2&d=sim&t='||NEW.aval_token,
        'link_nao',base||'?id='||NEW.id||'&p=padrinho2&d=nao&t='||NEW.aval_token)); end if;
    elsif NEW.mestre_id is not null then
      -- sem 2o padrinho: aprovador decide direto (com capitulo, no painel)
      select email into v_me from membros where id = NEW.mestre_id;
      if v_me is not null then perform enviar_modelo(v_me,'ind_aprovar', jsonb_build_object(
        'nome',NEW.mestre_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',painel)); end if;
    end if;
    return NEW;
  end if;

  if TG_OP = 'UPDATE' then
    -- 2o padrinho avalizou -> agora o aprovador (com capitulo)
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
