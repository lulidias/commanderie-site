-- =====================================================================
-- fin_resumo(ano) — números do Financeiro calculados no banco
-- (31/10/2026)
--
-- Fonte única dos números financeiros do Painel de Indicadores
-- (painel-bi.html). Reproduz EXATAMENTE as regras do Financeiro do
-- Painel do Conselho (painel-conselho.html?sec=financeiro):
--
--   * Anuidade do ciclo atual (parametros.ciclo_anuidade) vem do
--     cadastro dos membros: cotizado = soma de anuidade_valor de todos,
--     recebido = soma dos que têm anuidade_paga  (carregarFinanceiro).
--   * Anos anteriores em atraso (membros.anuidade_atrasos) entram como
--     "a receber" no ano deles                     (ATR_ANO / renderAno).
--   * Demais receitas = tabela `receitas`, categoria normalizada como no
--     catNorm(); as linhas "Eventos" (lançadas por lancar_receita_rsvp)
--     NÃO são somadas, porque o evento é calculado pelas reservas —
--     somar as duas coisas contaria o evento em dobro.
--   * Eventos = reservas (evento_rsvp) valorizadas como em valorRsvpFin():
--     recebido = Confirmado, a receber = Aguardando pagamento; eventos
--     com sem_receita ficam de fora                          (evCalc).
--   * Despesas: previsto = valor; pago = valor se pago, senão a parte já
--     paga (valor_pago)                                      (despPg).
--   * Caixa = anuidades recebidas do ciclo + receitas recebidas (menos
--     Eventos) de todos os anos + eventos recebidos − despesas pagas
--                                                         (renderCaixa).
--   * Anuidade das importadoras é em EUROS e não entra (igual à tela).
--
-- Se mudar uma regra no Financeiro (valorRsvpFin, evCalc, catNorm,
-- despPg, renderAno, renderCaixa), mude aqui também.
--
-- Uso: select fin_resumo(2026);  select fin_resumo(null);  -- null = todos
-- Só o Conselho (is_conselho()) recebe dados; os demais recebem {"erro":"negado"}.
-- =====================================================================

-- Valor de uma reserva — espelho de valorRsvpFin(x, ev)
create or replace function public.fin_valor_rsvp(
  p_pago_valor numeric, p_categoria text, p_convidado_nome text, p_convidados int,
  p_titulo text, p_valor numeric)
returns numeric language sql immutable set search_path = public as $$
  select case
    when coalesce(p_pago_valor,0) > 0 then p_pago_valor
    when coalesce(p_categoria,'') in ('produtor','conselho','cortesia') then 0
    when coalesce(p_titulo,'') ~* '1\s*ano' then
      case coalesce(p_categoria,'')
        when 'mestre' then 475
        when 'futuro-membro' then 950
        when 'convidado-externo' then 1250
        when 'convidado-produtor' then 1250
        when 'importador' then 0
        else case when coalesce(p_categoria,'') = '' and btrim(coalesce(p_convidado_nome,''), E' \t\r\n') <> '' then 2200 else 950 end
      end
    when coalesce(p_valor,0) = 0 then 0
    when p_categoria = 'mestre' then round(p_valor/2)
    when p_categoria = 'importador' then p_valor * (case when coalesce(p_convidados,0) = 0 then 1 else p_convidados end)
    when coalesce(p_categoria,'') = '' and btrim(coalesce(p_convidado_nome,''), E' \t\r\n') <> '' then p_valor * 2
    else p_valor
  end;
$$;

-- Categoria normalizada — espelho de catNorm(c)
create or replace function public.fin_cat_norm(p text)
returns text language sql immutable set search_path = public as $$
  select case
    when btrim(coalesce(p,'')) = '' then 'Outro'
    when lower(btrim(p)) like 'anuidade%' then 'Anuidade'
    when lower(btrim(p)) like 'evento%' then 'Eventos'
    when lower(btrim(p)) like 'doa%' then 'Doação'
    when lower(btrim(p)) like 'contribui%' then 'Contribuições'
    when lower(btrim(p)) like 'viage%' then 'Viagem'
    else btrim(p)
  end;
$$;

-- Período (um ano, ou todos se p_ano for null) — espelho de renderAno(ano)
create or replace function public._fin_periodo(p_ano int)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_ciclo int := coalesce((select valor::int from parametros where chave='ciclo_anuidade'), extract(year from now())::int);
  anu_c numeric; anu_p numeric; atr numeric;
  cats jsonb := '{}'::jsonb; ev jsonb; ev_r numeric; ev_a numeric;
  rc numeric; rp numeric; dc numeric; dp numeric; dcat jsonb;
  r record;
begin
  -- anuidade do ciclo (cadastro dos membros)
  select coalesce(sum(coalesce(anuidade_valor,0)),0),
         coalesce(sum(coalesce(anuidade_valor,0)) filter (where coalesce(anuidade_paga,false)),0)
    into anu_c, anu_p from membros;
  -- atrasos de anos anteriores
  select coalesce(sum(coalesce(m.anuidade_valor,0)),0) into atr
    from membros m cross join lateral unnest(coalesce(m.anuidade_atrasos,'{}')) u(aa)
   where u.aa::int <> v_ciclo and (p_ano is null or u.aa::int = p_ano);

  if (p_ano is null or p_ano = v_ciclo) and anu_c > 0 then
    cats := jsonb_build_object('Anuidade', jsonb_build_object('cotizado', anu_c, 'recebido', anu_p));
  end if;
  if atr > 0 then
    cats := jsonb_set(cats, '{Anuidade}', jsonb_build_object(
      'cotizado', coalesce((cats#>>'{Anuidade,cotizado}')::numeric,0) + atr,
      'recebido', coalesce((cats#>>'{Anuidade,recebido}')::numeric,0)), true);
  end if;

  -- demais receitas (sem Eventos)
  for r in
    select fin_cat_norm(categoria) cat, sum(coalesce(valor,0)) c,
           sum(case when coalesce(pago,false) then coalesce(valor,0) else 0 end) p
      from receitas
     where (p_ano is null or ano = p_ano) and fin_cat_norm(categoria) <> 'Eventos'
     group by 1
  loop
    cats := jsonb_set(cats, array[r.cat], jsonb_build_object(
      'cotizado', coalesce((cats->r.cat->>'cotizado')::numeric,0) + r.c,
      'recebido', coalesce((cats->r.cat->>'recebido')::numeric,0) + r.p), true);
  end loop;

  -- eventos pelas reservas
  with v as (
    select e.id, e.data, e.nucleo, e.tipo,
           trim(coalesce(e.numero,'')||' '||coalesce(e.titulo,'')) nome,
           x.status,
           fin_valor_rsvp(x.pago_valor, x.categoria, x.convidado_nome, x.convidados, e.titulo, e.valor) val
      from eventos e join evento_rsvp x on x.evento_id = e.id
     where not coalesce(e.sem_receita,false)
       and (p_ano is null or (e.data is not null and extract(year from e.data)::int = p_ano))
  ), l as (
    select id, data, nucleo, tipo, nome,
           sum(val) filter (where status='Confirmado' and val<>0) rec,
           count(*) filter (where status='Confirmado' and val<>0) nrec,
           sum(val) filter (where status='Aguardando pagamento' and val<>0) arec,
           count(*) filter (where status='Aguardando pagamento' and val<>0) narec
      from v group by 1,2,3,4,5
  )
  select coalesce(jsonb_agg(jsonb_build_object('id',id,'nome',nome,'tipo',tipo,'nucleo',nucleo,
            'ano',extract(year from data)::int,'data',to_char(data,'DD/MM/YYYY'),
            'recebido',coalesce(rec,0),'a_receber',coalesce(arec,0),'n_recebido',nrec,'n_a_receber',narec) order by data),'[]'::jsonb),
         coalesce(sum(rec),0), coalesce(sum(arec),0)
    into ev, ev_r, ev_a
    from l where coalesce(rec,0) <> 0 or coalesce(arec,0) <> 0;

  if ev_r + ev_a > 0 then
    cats := cats || jsonb_build_object('Eventos', jsonb_build_object('cotizado', ev_r + ev_a, 'recebido', ev_r));
  end if;

  select coalesce(sum((value->>'cotizado')::numeric),0), coalesce(sum((value->>'recebido')::numeric),0)
    into rc, rp from jsonb_each(cats);

  -- despesas
  select coalesce(sum(coalesce(valor,0)),0),
         coalesce(sum(case when coalesce(pago,false) then coalesce(valor,0)
                           else least(coalesce(valor,0), greatest(0, coalesce(valor_pago,0))) end),0)
    into dc, dp from despesas where p_ano is null or ano = p_ano;
  select coalesce(jsonb_object_agg(cat, jsonb_build_object('previsto', c, 'pago', p)), '{}'::jsonb) into dcat
    from (select coalesce(nullif(btrim(categoria),''),'Outro') cat, sum(coalesce(valor,0)) c,
                 sum(case when coalesce(pago,false) then coalesce(valor,0)
                          else least(coalesce(valor,0), greatest(0, coalesce(valor_pago,0))) end) p
            from despesas where p_ano is null or ano = p_ano group by 1) t;

  return jsonb_build_object(
    'ano', p_ano,
    'receitas', jsonb_build_object('cotizado', rc, 'recebido', rp, 'a_receber', rc - rp, 'por_categoria', cats),
    'eventos', jsonb_build_object('recebido', ev_r, 'a_receber', ev_a, 'lista', ev),
    'despesas', jsonb_build_object('previsto', dc, 'pago', dp, 'a_pagar', dc - dp, 'por_categoria', dcat),
    'saldo', rp - dp);
end $$;

create or replace function public.fin_resumo(p_ano int default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_ciclo int := coalesce((select valor::int from parametros where chave='ciclo_anuidade'), extract(year from now())::int);
  anu jsonb; nuc jsonb; atr jsonb; anos jsonb; por_ano jsonb := '{}'::jsonb;
  anu_p numeric; outras numeric; anu_rec_outras numeric; ev_tot numeric; said numeric; y int;
  ult timestamptz;
begin
  if not public.is_conselho() then return '{"erro":"negado"}'::jsonb; end if;

  -- anuidade do ciclo atual (quadro "Anuidades dos membros")
  select jsonb_build_object(
           'ciclo', v_ciclo,
           'membros', count(*),
           'cotizado', coalesce(sum(coalesce(anuidade_valor,0)),0),
           'recebido', coalesce(sum(coalesce(anuidade_valor,0)) filter (where coalesce(anuidade_paga,false)),0),
           'a_receber', coalesce(sum(coalesce(anuidade_valor,0)) filter (where not coalesce(anuidade_paga,false)),0),
           'isentos', count(*) filter (where grau ilike '%honra%' or grau ilike '%mestre%' or anuidade_status ~* '^isento'),
           'em_dia',  count(*) filter (where not (coalesce(grau,'') ilike '%honra%' or coalesce(grau,'') ilike '%mestre%' or coalesce(anuidade_status,'') ~* '^isento') and coalesce(anuidade_paga,false)),
           'a_pagar', count(*) filter (where not (coalesce(grau,'') ilike '%honra%' or coalesce(grau,'') ilike '%mestre%' or coalesce(anuidade_status,'') ~* '^isento') and not coalesce(anuidade_paga,false))),
         coalesce(sum(coalesce(anuidade_valor,0)) filter (where coalesce(anuidade_paga,false)),0)
    into anu, anu_p from membros;

  select coalesce(jsonb_object_agg(n, jsonb_build_object('membros', q, 'cotizado', c, 'recebido', p, 'a_receber', c - p)), '{}'::jsonb) into nuc
    from (select coalesce(nullif(nucleo,''),'Sem núcleo') n, count(*) q, sum(coalesce(anuidade_valor,0)) c,
                 coalesce(sum(coalesce(anuidade_valor,0)) filter (where coalesce(anuidade_paga,false)),0) p
            from membros group by 1) t;

  select coalesce(jsonb_object_agg(t.aa, jsonb_build_object('valor', t.v, 'membros', t.n)), '{}'::jsonb) into atr
    from (select u.aa::int aa, sum(coalesce(m.anuidade_valor,0)) v, count(*) n
            from membros m cross join lateral unnest(coalesce(m.anuidade_atrasos,'{}')) u(aa) group by 1) t;

  anu := anu || jsonb_build_object('por_nucleo', nuc, 'atrasos', atr);

  -- anos do seletor do Financeiro (ciclo + anos com receitas/despesas)
  select coalesce(jsonb_agg(a order by a), '[]'::jsonb) into anos from (
    select v_ciclo a union select ano from receitas where ano is not null union select ano from despesas where ano is not null) t;
  for y in select (jsonb_array_elements_text(anos))::int loop
    por_ano := por_ano || jsonb_build_object(y::text, public._fin_periodo(y) - 'ano');
  end loop;

  -- caixa acumulado (renderCaixa)
  select coalesce(sum(coalesce(valor,0)) filter (where coalesce(pago,false) and fin_cat_norm(categoria) <> 'Eventos'),0),
         coalesce(sum(coalesce(valor,0)) filter (where coalesce(pago,false) and fin_cat_norm(categoria) = 'Anuidade'),0)
    into outras, anu_rec_outras from receitas;
  select (public._fin_periodo(null)#>>'{eventos,recebido}')::numeric into ev_tot;
  select coalesce(sum(case when coalesce(pago,false) then coalesce(valor,0)
                           else least(coalesce(valor,0), greatest(0, coalesce(valor_pago,0))) end),0) into said from despesas;

  select greatest(
    (select max(created_at) from receitas), (select max(created_at) from despesas),
    (select max(anuidade_pago_em) from membros), (select max(comprovante_em) from evento_rsvp),
    (select max(created_at) from anuidade_comprovantes),
    (select atualizado_em from parametros where chave='ciclo_anuidade')) into ult;

  return public._fin_periodo(p_ano) || jsonb_build_object(
    'ciclo', v_ciclo,
    'anuidade', anu,
    'anos', anos,
    'por_ano', por_ano,
    'caixa', jsonb_build_object(
       'entradas', anu_p + outras + ev_tot,
       'saidas', said,
       'caixa', anu_p + outras + ev_tot - said,
       'anuidades_recebidas', anu_p + anu_rec_outras,
       'eventos_recebidos', ev_tot,
       'outras_recebidas', outras - anu_rec_outras),
    'atualizado_em', to_char(now() at time zone 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),
    'ultimo_lancamento', to_char(ult at time zone 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'));
end $$;

revoke all on function public._fin_periodo(int) from public, anon, authenticated;
revoke all on function public.fin_resumo(int) from public, anon;
grant execute on function public.fin_resumo(int) to authenticated;
grant execute on function public.fin_valor_rsvp(numeric,text,text,int,text,numeric) to authenticated;
grant execute on function public.fin_cat_norm(text) to authenticated;
