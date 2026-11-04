-- Inscrição de importadora: só se finaliza com o comprovante do PIX  · 04/11/2026
-- Motivo: inscrições aprovadas sem pagamento (ex.: Médoc). Agora, depois de
-- preencher, a importadora paga o PIX e ENVIA O COMPROVANTE na própria página.
-- O Conselho vê "Pago · conferir" com o comprovante e o valor, confere no banco
-- e aprova. Sem comprovante a inscrição aparece como "Aguardando pagamento".
-- O status no banco continua 'Nova' (a aprovação existente não muda).

alter table public.importadora_inscricoes add column if not exists comprovante_path text;
alter table public.importadora_inscricoes add column if not exists comprovante_em   timestamptz;
alter table public.importadora_inscricoes add column if not exists valor_brl        numeric;

-- Pasta privada dos comprovantes: quem se inscreve pode enviar; só o Conselho pode ver.
insert into storage.buckets (id, name, public) values ('imp-comprovantes','imp-comprovantes', false)
on conflict (id) do nothing;
drop policy if exists "imp comprovante envia" on storage.objects;
create policy "imp comprovante envia" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'imp-comprovantes');
drop policy if exists "imp comprovante conselho le" on storage.objects;
create policy "imp comprovante conselho le" on storage.objects for select to authenticated
  using (bucket_id = 'imp-comprovantes' and public.is_conselho());

-- Liga o comprovante à inscrição mais recente desse e-mail (ainda não aprovada/recusada).
create or replace function public.importadora_insc_comprovante(p_email text, p_path text, p_valor numeric)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if coalesce(btrim(p_email),'') = '' or coalesce(p_path,'') not like 'insc/%' then return false; end if;
  select id into v_id from importadora_inscricoes
   where lower(btrim(email)) = lower(btrim(p_email)) and status = 'Nova'
   order by created_at desc limit 1;
  if v_id is null then return false; end if;
  update importadora_inscricoes
     set comprovante_path = p_path, comprovante_em = now(), valor_brl = nullif(p_valor,0)
   where id = v_id;
  return true;
end $$;
revoke all on function public.importadora_insc_comprovante(text,text,numeric) from public;
grant execute on function public.importadora_insc_comprovante(text,text,numeric) to anon, authenticated;
