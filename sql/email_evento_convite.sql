-- =====================================================================
-- Convite automatico de evento aos Comendadores.
-- Ao criar um evento (futuro, nao realizado) com nucleo marcado, envia
-- e-mail com TODOS os dados aos membros daquele nucleo. Nucleo "Brasil"
-- envia a todos (Comendadores + Convidados de Honra + Mesa). 100% ASCII.
-- =====================================================================

-- 1) Ampliar variaveis dos modelos: + {valor} + {descricao}
create or replace function public._subst(t text, v jsonb)
returns text language sql immutable as $fn$
  select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(coalesce(t,''),
    '{nome}',      coalesce(v->>'nome','')),
    '{evento}',    coalesce(v->>'evento','')),
    '{quando}',    coalesce(v->>'quando','')),
    '{onde}',      coalesce(v->>'onde','')),
    '{indicado}',  coalesce(v->>'indicado','')),
    '{indicador}', coalesce(v->>'indicador','')),
    '{codigo}',    coalesce(v->>'codigo','')),
    '{valor}',     coalesce(v->>'valor','')),
    '{descricao}', coalesce(v->>'descricao','')),
    '{link}',      coalesce(v->>'link','https://commanderiedebordeaux.com.br'));
$fn$;

-- 2) Modelo do convite (editavel depois no painel de e-mails)
insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('evento_convite','Evento - convite (Comendadores)','Convite &middot; {evento}','Voc&ecirc; est&aacute; convidado',
 '<p>Prezado(a) {nome},</p><p>&Eacute; com grande prazer que convidamos voc&ecirc; para o pr&oacute;ximo encontro da Commanderie de Bordeaux do Brasil:</p><p style="background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px 14px;line-height:1.8;"><b>{evento}</b><br><b>Data e hora:</b> {quando}<br><b>Local:</b> {onde}<br><b>Valor:</b> {valor}</p><p>{descricao}</p><p>Confirme a sua presen&ccedil;a pelo Painel do Comendador &mdash; as vagas s&atilde;o limitadas.</p>',
 'Confirmar presen&ccedil;a',5)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;

-- 3) Gatilho: ao inserir um evento, dispara o convite ao nucleo certo
create or replace function public.evento_convites()
returns trigger language plpgsql security definer set search_path=public as $fn$
declare m record; v_evento text; v_quando text; v_onde text; v_valor text; v_desc text;
begin
  -- so eventos futuros, ainda nao realizados e COM nucleo definido
  if coalesce(NEW.realizado,false) then return NEW; end if;
  if NEW.data is not null and NEW.data < current_date then return NEW; end if;
  if coalesce(NEW.nucleo,'') = '' then return NEW; end if;

  v_evento := coalesce(NEW.tipo,'Evento')||coalesce(' '||NEW.numero,'')||' &middot; '||coalesce(NEW.titulo,'');
  v_quando := to_char(NEW.data,'DD/MM/YYYY')||coalesce(' &agrave;s '||NEW.hora,'');
  v_onde   := nullif(concat_ws(' &middot; ', NEW.local, NEW.endereco, NEW.bairro, NEW.cidade), '');
  v_valor  := case when coalesce(NEW.valor,0) > 0
                   then 'R$ '||replace(to_char(NEW.valor,'FM999990.00'),'.',',')
                   else 'Gratuito' end;
  v_desc   := coalesce(NEW.descricao,'');

  for m in
    select nome, email from public.membros
    where email is not null
      and (NEW.nucleo = 'Brasil' or nucleo = NEW.nucleo)
  loop
    perform public.enviar_modelo(m.email,'evento_convite',
      jsonb_build_object(
        'nome', coalesce(m.nome,'Comendador'),
        'evento', v_evento,
        'quando', v_quando,
        'onde', coalesce(v_onde,'a confirmar'),
        'valor', v_valor,
        'descricao', v_desc,
        'link', 'https://commanderiedebordeaux.com.br/eventos.html'));
  end loop;
  return NEW;
end $fn$;

drop trigger if exists trg_evento_convites on public.eventos;
create trigger trg_evento_convites after insert on public.eventos
for each row execute function public.evento_convites();
