-- =====================================================================
-- E-mail da Ficha de Intronizacao (candidato aprovado).
-- Chave: ind_aprovado_candidato - enviado por aprovar_e_acolher() no
-- momento em que o Mestre clica "Aprovar e acolher" e escolhe o capitulo.
-- Inclui TODOS os dados do capitulo (evento, data/hora, local) + codigo de
-- acesso para preencher a ficha. Idempotente (upsert). 100% ASCII.
-- =====================================================================

insert into public.email_modelos (chave,nome,assunto,titulo,corpo,cta_label,ordem) values
('ind_aprovado_candidato',
 'Indicacao - aprovado: preencher ficha (candidato)',
 'Aprovado &mdash; preencha sua Ficha de Introniza&ccedil;&atilde;o',
 'Voc&ecirc; foi aprovado &mdash; preencha sua ficha',
 '<p>Prezado(a) {nome},</p>'
 '<p>&Eacute; com grande satisfa&ccedil;&atilde;o que comunicamos: a sua indica&ccedil;&atilde;o foi <b>aprovada pelo Conselho Diretor</b> da Commanderie de Bordeaux do Brasil. &#127863;</p>'
 '<p>A sua <b>introniza&ccedil;&atilde;o oficial</b> acontecer&aacute; em:</p>'
 '<p style="background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px 14px;line-height:1.8;"><b>{evento}</b><br><b>Data e hora:</b> {quando}<br><b>Local:</b> {onde}</p>'
 '<p>O pr&oacute;ximo passo &eacute; <b>preencher a sua Ficha de Introniza&ccedil;&atilde;o</b>. Crie o seu acesso ao site com o c&oacute;digo abaixo e complete a ficha:</p>'
 '<p style="text-align:center;font-family:Georgia,serif;font-size:20px;color:#1e2a56;letter-spacing:2px;background:#faf6ea;border:1px solid #e6d9b3;border-radius:10px;padding:12px;"><b>{codigo}</b></p>'
 '<p style="font-size:13px;color:#8a6a1f;">Leve ao seu cap&iacute;tulo uma garrafa de um bom Bordeaux para a introniza&ccedil;&atilde;o.</p>',
 'Criar acesso e preencher a ficha',
 13)
on conflict (chave) do update set
  nome=excluded.nome, assunto=excluded.assunto, titulo=excluded.titulo,
  corpo=excluded.corpo, cta_label=excluded.cta_label;
