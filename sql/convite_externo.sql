-- Convite para quem ainda NÃO é Comendador (importadores, sobretudo).
--
-- O problema que isto resolve: o jantar tem lugares que queremos vender a
-- importadores que ainda não foram entronizados. Eles não têm login e não
-- devem ter acesso à plataforma — então o caminho normal (entrar no painel,
-- confirmar, enviar comprovante) não serve. Precisam de um link que se cola
-- no WhatsApp e resolve tudo numa página só.
--
-- Reaproveita `evento_rsvp` em vez de criar tabela nova: o Conselho já vê a
-- lista de presença ali, o robô do comprovante já escreve ali, e uma segunda
-- tabela faria a lista do jantar existir em dois lugares — que é como se
-- perde gente na porta do restaurante.
--
-- 03/10/2026

-- 1) Os campos que o convidado externo preenche e o Comendador não precisa:
--    ele não está cadastrado em lado nenhum, então o que ele digitar aqui é
--    tudo o que vamos ter dele.
alter table public.evento_rsvp
  add column if not exists convidado_nascimento date,
  add column if not exists convidado_empresa    text,
  add column if not exists convidado_doc        text,
  add column if not exists convidado_obs        text;

comment on column public.evento_rsvp.convidado_nascimento is
  'Data de nascimento do convidado externo. Opcional — serve para o brinde de aniversário e para o cadastro, se ele vier a ser entronizado.';

-- 2) O cadastro em si. SECURITY DEFINER porque quem chama é anônimo: não há
--    login, e não vamos abrir INSERT direto na tabela para o mundo.
create or replace function public.rsvp_convite_externo(
  p_evento     uuid,
  p_nome       text,
  p_email      text,
  p_telefone   text,
  p_empresa    text default null,
  p_doc        text default null,
  p_nascimento date default null,
  p_restricao  text default null,
  p_obs        text default null
) returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare v_id uuid; v_email text;
begin
  -- Os três obrigatórios, e só eles. Pedir mais afasta quem ia pagar.
  if coalesce(trim(p_nome),'') = '' then
    raise exception 'Informe o seu nome';
  end if;
  v_email := nullif(lower(trim(p_email)),'');
  if v_email is null or v_email not like '%_@_%.__%' then
    raise exception 'Informe um e-mail válido';
  end if;
  if coalesce(trim(p_telefone),'') = '' then
    raise exception 'Informe um telefone';
  end if;

  if not exists (select 1 from eventos
                 where id = p_evento and coalesce(realizado,false) = false) then
    raise exception 'Evento indisponível';
  end if;

  -- Um e-mail, um lugar. Se a pessoa recarregar a página ou se inscrever duas
  -- vezes, atualizamos o cadastro em vez de duplicar a lista de presença.
  select id into v_id
    from evento_rsvp
   where evento_id = p_evento
     and categoria = 'convidado-externo'
     and lower(convidado_email) = v_email
   limit 1;

  if v_id is null then
    insert into evento_rsvp (
      evento_id, user_id, categoria, status, convidados,
      convidado_nome, convidado_email, convidado_telefone,
      convidado_empresa, convidado_doc, convidado_nascimento,
      restricao, convidado_obs)
    values (
      p_evento, null, 'convidado-externo', 'Aguardando pagamento', 1,
      trim(p_nome), v_email, trim(p_telefone),
      nullif(trim(p_empresa),''), nullif(trim(p_doc),''), p_nascimento,
      nullif(trim(p_restricao),''), nullif(trim(p_obs),''))
    returning id into v_id;
  else
    update evento_rsvp set
      convidado_nome       = trim(p_nome),
      convidado_telefone   = trim(p_telefone),
      convidado_empresa    = coalesce(nullif(trim(p_empresa),''),    convidado_empresa),
      convidado_doc        = coalesce(nullif(trim(p_doc),''),        convidado_doc),
      convidado_nascimento = coalesce(p_nascimento,                  convidado_nascimento),
      restricao            = coalesce(nullif(trim(p_restricao),''),  restricao),
      convidado_obs        = coalesce(nullif(trim(p_obs),''),        convidado_obs)
    where id = v_id;
  end if;

  return v_id;
end $$;

-- Policy não basta: sem o GRANT a chamada anônima falha com 42501 e a página
-- não tem como dizer por quê. Já nos custou caro mais de uma vez.
grant execute on function public.rsvp_convite_externo(
  uuid, text, text, text, text, text, date, text, text) to anon, authenticated;

-- 3) A contabilidade entra sozinha quando o pagamento é aprovado.
--    `fonte` guarda de qual inscrição veio, e o índice único impede que rodar
--    o robô duas vezes lance a mesma receita duas vezes.
create unique index if not exists receitas_fonte_rsvp_uk
  on public.receitas (fonte)
  where fonte like 'rsvp:%';

create or replace function public.lancar_receita_rsvp(
  p_rsvp uuid, p_valor numeric, p_descricao text
) returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if p_rsvp is null or coalesce(p_valor,0) <= 0 then return; end if;
  insert into receitas (ano, categoria, descricao, valor, pago, fonte)
  values (extract(year from now())::int, 'Eventos', p_descricao, p_valor, true,
          'rsvp:' || p_rsvp::text)
  on conflict do nothing;
end $$;

grant execute on function public.lancar_receita_rsvp(uuid, numeric, text) to service_role;
