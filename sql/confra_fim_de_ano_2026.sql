-- 14/11/2026 — Jantar de Fim de Ano (02/12/2026, Casa Comitê, 18h30). R$ 800 por pessoa; o Comendador pode levar
-- um acompanhante (R$ 1.600 os dois). Mestres e Grão-Mestre NÃO pagam (o acompanhante deles paga R$ 800).
-- Inscrição pelos dois caminhos: com login (auth.uid) ou sem login — aí o e-mail é cruzado com membros.

alter table eventos add column if not exists mestre_gratis boolean default false;

insert into eventos (tipo, titulo, data, hora, local, cidade, nucleo, endereco, bairro, cep, valor, descricao, realizado, adesao, entra_caixa, lugares)
select 'Jantar', 'Jantar de Fim de Ano', '2026-12-02', '18:30', 'Casa Comitê', 'São Paulo', 'Brasil',
       'Rua Magalhães de Araújo, 84', 'Jardim Guedala', '05611-020', 800,
       'Jantar de fim de ano com acompanhante. Cada Comendador leva uma magnum de Bordeaux ou duas garrafas de 750 ml iguais (mesmo château, mesma safra).',
       false, true, true, 60
where not exists (select 1 from eventos where titulo = 'Jantar de Fim de Ano' and data = '2026-12-02');
update eventos set mestre_gratis = true where titulo = 'Jantar de Fim de Ano' and data = '2026-12-02';

create or replace function public.rsvp_confra(
  p_evento uuid, p_nome text, p_email text, p_telefone text,
  p_acompanhante text default null, p_restricao text default null,
  p_restricao_acomp text default null, p_obs text default null)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v_ev eventos; m membros; v_email text; v_cat text; v_id uuid; v_uid uuid;
        v_acomp text; v_devido numeric; v_mestre boolean; v_status text;
begin
  if coalesce(trim(p_nome),'') = '' then raise exception 'Informe o seu nome'; end if;
  v_email := nullif(lower(trim(p_email)),'');
  if v_email is null or v_email not like '%_@_%.__%' then raise exception 'Informe um e-mail válido'; end if;
  if coalesce(trim(p_telefone),'') = '' then raise exception 'Informe um telefone'; end if;
  select * into v_ev from eventos where id = p_evento and coalesce(realizado,false) = false;
  if v_ev.id is null then raise exception 'Evento indisponível'; end if;

  -- quem é: pelo login, senão pelo e-mail do cadastro
  if auth.uid() is not null then select * into m from membros where user_id = auth.uid() limit 1; end if;
  if m.id is null then select * into m from membros where lower(email) = v_email limit 1; end if;
  v_mestre := m.id is not null and coalesce(m.grau,'') ~* '(mestre|ma.tre)';
  v_cat := case when v_mestre then 'mestre' when m.id is not null then 'comendador' else 'nao-identificado' end;
  v_uid := m.user_id;
  v_acomp := nullif(trim(coalesce(p_acompanhante,'')),'');
  v_devido := case when v_mestre and coalesce(v_ev.mestre_gratis,false) then (case when v_acomp is null then 0 else v_ev.valor end)
                   else v_ev.valor * (case when v_acomp is null then 1 else 2 end) end;
  v_status := case when v_devido = 0 then 'Confirmado' else 'Aguardando pagamento' end;

  -- uma inscrição por pessoa: acha pela conta ou pelo e-mail
  select id into v_id from evento_rsvp
   where evento_id = p_evento and ((v_uid is not null and user_id = v_uid) or lower(convidado_email) = v_email) limit 1;

  if v_id is null then
    insert into evento_rsvp (evento_id, user_id, categoria, status, convidados, convidado_nome, convidado_email,
                             convidado_telefone, restricao, restricao_convidado, convidado_obs)
    values (p_evento, v_uid, v_cat, v_status, case when v_acomp is null then 1 else 2 end, v_acomp, v_email,
            trim(p_telefone), nullif(trim(coalesce(p_restricao,'')),''), nullif(trim(coalesce(p_restricao_acomp,'')),''),
            trim(both ' ·' from concat_ws(' · ', 'Inscrito: '||trim(p_nome), case when m.id is null then 'e-mail não está no cadastro' end, nullif(trim(coalesce(p_obs,'')),''))))
    returning id into v_id;
  else
    update evento_rsvp set user_id = coalesce(user_id, v_uid), categoria = v_cat,
      status = case when status = 'Confirmado' and v_devido <= coalesce(pago_valor,0) then 'Confirmado' else v_status end,
      convidados = case when v_acomp is null then 1 else 2 end, convidado_nome = v_acomp, convidado_email = v_email,
      convidado_telefone = trim(p_telefone), restricao = nullif(trim(coalesce(p_restricao,'')),''),
      restricao_convidado = nullif(trim(coalesce(p_restricao_acomp,'')),''),
      convidado_obs = trim(both ' ·' from concat_ws(' · ', 'Inscrito: '||trim(p_nome), case when m.id is null then 'e-mail não está no cadastro' end, nullif(trim(coalesce(p_obs,'')),'')))
    where id = v_id;
  end if;
  return jsonb_build_object('id', v_id, 'categoria', v_cat, 'devido', v_devido, 'nome_cadastro', m.nome,
                            'pago', (select coalesce(pago_valor,0) from evento_rsvp where id = v_id));
end $$;
grant execute on function public.rsvp_confra(uuid,text,text,text,text,text,text,text) to anon, authenticated;
notify pgrst, 'reload schema';
