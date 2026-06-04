-- =====================================================================
-- Indicacoes: (C) e-mail de aval leva direto a pagina de indicacoes
--             (D) indicacao do Grao-Mestre precisa de aval de so 1 Mestre
-- Recria avalizar(), meus_avais() e o trigger de e-mails. 100% ASCII.
-- =====================================================================

-- (D) avalizar(): trata indicacao SEM 2o padrinho (ex.: do Grao-Mestre).
-- Nesse caso basta o aval do Mestre para ficar "Avalizada".
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
  -- Mestre so avaliza depois do 2o padrinho - exceto quando nao ha 2o padrinho
  if papel = 'mestre' and dec = 'Avalizado'
     and ind.padrinho2_id is not null
     and coalesce(ind.padrinho2_ok,'') <> 'Avalizado' then
    return 'aguardando_padrinho2';
  end if;
  if papel = 'padrinho2' then update indicacoes set padrinho2_ok = dec where id = p_id;
  else update indicacoes set mestre_ok = dec where id = p_id; end if;
  select * into ind from indicacoes where id = p_id;
  -- padrinho2 satisfeito se avalizou OU se a indicacao nao tem 2o padrinho
  p2_ok := (ind.padrinho2_id is null) or (ind.padrinho2_ok = 'Avalizado');
  if ind.padrinho2_ok = 'Recusado' or ind.mestre_ok = 'Recusado' then nova := 'Recusado';
  elsif p2_ok and ind.mestre_ok = 'Avalizado' then nova := 'Avalizada';
  else nova := 'Aguardando avais'; end if;
  update indicacoes set status = nova where id = p_id;
  return nova;
end $fn$;
grant execute on function public.avalizar(uuid,text) to authenticated;

-- (D) meus_avais(): o Mestre ve a indicacao mesmo quando nao ha 2o padrinho.
create or replace function public.meus_avais()
returns setof indicacoes language sql stable security definer set search_path=public as $fn$
  select i.* from public.indicacoes i, public.membros m
  where m.user_id = auth.uid()
    and coalesce(i.status,'') <> 'Recusado'
    and (
      (i.padrinho2_id = m.id and coalesce(i.padrinho2_ok,'') = '')
      or (i.mestre_id = m.id and coalesce(i.mestre_ok,'') = ''
          and (i.padrinho2_id is null or coalesce(i.padrinho2_ok,'') = 'Avalizado'))
    );
$fn$;
grant execute on function public.meus_avais() to authenticated;

-- (C)+(D) trigger de e-mails: link de aval -> pagina de indicacoes;
-- se nao houver 2o padrinho, avisa o Mestre direto no INSERT.
create or replace function public.indicacao_emails()
returns trigger language plpgsql security definer set search_path=public as $fn$
declare v_ind text; v_p2 text; v_me text;
  link_aval text := 'https://commanderiedebordeaux.com.br/indicacoes.html';
begin
  if TG_OP = 'INSERT' then
    select email into v_ind from membros where user_id = NEW.indicado_por;
    if v_ind is not null then perform enviar_modelo(v_ind,'ind_registrada', jsonb_build_object('nome',NEW.indicado_por_nome,'indicado',NEW.nome)); end if;
    if NEW.padrinho2_id is not null then
      -- fluxo normal: pedido de aval ao 2o padrinho (Mestre vem depois)
      select email into v_p2 from membros where id = NEW.padrinho2_id;
      if v_p2 is not null then perform enviar_modelo(v_p2,'ind_avalize', jsonb_build_object('nome',NEW.padrinho2_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',link_aval)); end if;
    elsif NEW.mestre_id is not null then
      -- sem 2o padrinho (indicacao do Grao-Mestre): avisa o Mestre direto
      select email into v_me from membros where id = NEW.mestre_id;
      if v_me is not null then perform enviar_modelo(v_me,'ind_avalize', jsonb_build_object('nome',NEW.mestre_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',link_aval)); end if;
    end if;
    return NEW;
  end if;

  if TG_OP = 'UPDATE' then
    if NEW.padrinho2_ok = 'Avalizado'
       and coalesce(OLD.padrinho2_ok,'') <> 'Avalizado'
       and coalesce(NEW.mestre_ok,'Pendente') not in ('Avalizado','Recusado') then
      select email into v_me from membros where id = NEW.mestre_id;
      if v_me is not null then perform enviar_modelo(v_me,'ind_avalize', jsonb_build_object('nome',NEW.mestre_nome,'indicado',NEW.nome,'indicador',NEW.indicado_por_nome,'link',link_aval)); end if;
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
