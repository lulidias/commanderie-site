-- =====================================================================
-- bi_dados(): participação do Painel de Indicadores (01/11/2026)
-- Antes: "Quem mais participa" contava só inscrições no site — quem foi como
-- Grão-Mestre/Mestre sem inscrição, ou só com presença marcada, ficava de fora.
-- Agora: eventos distintos por membro = inscrição confirmada/aguardando de
-- qualquer categoria OU presença marcada (evento_presenca.presente).
-- O resto da função é igual à versão que estava no banco.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.bi_dados()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r jsonb;
begin
  if not public.is_conselho() then return '{"erro":"negado"}'::jsonb; end if;
  -- Participação = eventos em que o membro esteve: inscrição confirmada (ou aguardando
  -- pagamento) de qualquer categoria — membro, Mestre, Conselho, cortesia — OU presença
  -- marcada no evento. Cada evento conta uma vez por membro. (01/11/2026)
  select jsonb_build_object(
    'membros', jsonb_build_object(
      'total',     (select count(*) from membros),
      'eleitos',   (select count(*) from membros where eleito),
      'ativados',  (select count(*) from membros where ativado),
      'por_nucleo',(select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select coalesce(nucleo,'Sem nucleo') k, count(*) v from membros group by 1) t),
      'por_grau',  (select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select coalesce(grau,'-') k, count(*) v from membros group by 1) t),
      'crescimento',(select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select to_char(created_at,'YYYY-MM') k, count(*) v from membros where created_at is not null group by 1) t),
      'anuidade_a_receber',(select coalesce(sum(anuidade_valor),0) from membros where coalesce(anuidade_paga,false)=false and lower(coalesce(grau,'')) not like '%honra%' and lower(coalesce(grau,'')) not like '%mestre%'),
      'anuidade_por_nucleo',(select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select coalesce(nucleo,'-') k, sum(anuidade_valor) v from membros where coalesce(anuidade_paga,false)=false and lower(coalesce(grau,'')) not like '%honra%' and lower(coalesce(grau,'')) not like '%mestre%' group by 1) t),
      'anuidade_em_dia',  (select count(*) from membros where coalesce(anuidade_paga,false)=true  and lower(coalesce(grau,'')) not like '%honra%' and lower(coalesce(grau,'')) not like '%mestre%'),
      'anuidade_a_vencer',(select count(*) from membros where coalesce(anuidade_paga,false)=false and lower(coalesce(grau,'')) not like '%honra%' and lower(coalesce(grau,'')) not like '%mestre%'),
      'isentos',   (select count(*) from membros where lower(coalesce(grau,'')) like '%honra%' or lower(coalesce(grau,'')) like '%mestre%')
    ),
    'eventos', jsonb_build_object(
      'total',     (select count(*) from eventos),
      'realizados',(select count(*) from eventos where realizado),
      'futuros',   (select count(*) from eventos where not realizado),
      'por_tipo',  (select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select coalesce(tipo,'-') k, count(*) v from eventos group by 1) t),
      'lista',     (select coalesce(jsonb_agg(jsonb_build_object('nome',trim(coalesce(numero,'')||' '||coalesce(titulo,'')),'tipo',tipo,'ano',extract(year from data)::int,'data',to_char(data,'DD/MM/YYYY'),'lugares',lugares,'valor',coalesce(valor,0),'realizado',realizado,'confirmados',(select count(*) from evento_rsvp rs where rs.evento_id=e.id and rs.status in ('Confirmado','Aguardando pagamento'))) order by data),'[]'::jsonb) from eventos e)
    ),
    'participacao', jsonb_build_object(
      'total_confirmacoes',(select count(*) from evento_rsvp where status in ('Confirmado','Aguardando pagamento')),
      'por_membro',(select coalesce(jsonb_agg(jsonb_build_object('nome',nome,'n',n) order by n desc, nome),'[]'::jsonb) from (select nome, count(distinct evento_id) n from (select m.id, m.nome, m.nucleo, rs.evento_id from evento_rsvp rs join membros m on m.user_id = rs.user_id where rs.status in ('Confirmado','Aguardando pagamento') union select m.id, m.nome, m.nucleo, p.evento_id from evento_presenca p join membros m on m.id = p.membro_id where p.presente) u group by id, nome order by n desc, nome limit 15) t),
      'por_nucleo',(select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select coalesce(nucleo,'-') k, count(*) v from (select distinct id, nucleo, evento_id from (select m.id, m.nome, m.nucleo, rs.evento_id from evento_rsvp rs join membros m on m.user_id = rs.user_id where rs.status in ('Confirmado','Aguardando pagamento') union select m.id, m.nome, m.nucleo, p.evento_id from evento_presenca p join membros m on m.id = p.membro_id where p.presente) u) d group by 1) t)
    ),
    'receitas', jsonb_build_object(
      'por_ano',      (select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select ano::text k, sum(valor) v from receitas group by 1) t),
      'por_categoria',(select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select coalesce(categoria,'-') k, sum(valor) v from receitas group by 1) t),
      'recebido',     (select coalesce(sum(valor),0) from receitas where pago),
      'a_receber',    (select coalesce(sum(valor),0) from receitas where not pago)
    ),
    'indicacoes', jsonb_build_object(
      'total',     (select count(*) from indicacoes),
      'por_status',(select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select coalesce(status,'-') k, count(*) v from indicacoes group by 1) t)
    ),
    'parceiros', jsonb_build_object('total',(select count(*) from parceiros),'por_cidade',(select coalesce(jsonb_object_agg(k,v),'{}'::jsonb) from (select coalesce(cidade,'-') k,count(*) v from parceiros group by 1) t)),
    'dicas',     jsonb_build_object('total',(select count(*) from dicas)),
    'gerado_em', to_char(now() at time zone 'America/Sao_Paulo','DD/MM/YYYY HH24:MI')
  ) into r;
  return r;
end $function$;
