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
