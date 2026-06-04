-- =====================================================================
-- Corrige os ASSUNTOS dos e-mails (texto puro -> acentos reais).
-- O assunto nao e HTML, entao &mdash;/&ccedil; apareciam literais e os
-- em ASCII saiam sem acento. Acentos via chr() para o arquivo seguir ASCII.
-- chr: 231=c-cedilha 227=a-til 233=e-agudo 8212=travessao 183=ponto-medio
-- UPDATE em chave inexistente e' no-op (seguro).
-- =====================================================================

update public.email_modelos set assunto='Indica'||chr(231)||chr(227)||'o registrada'
  where chave in ('ind_registrada','ind_registrada_unico');

update public.email_modelos set assunto='Uma indica'||chr(231)||chr(227)||'o aguarda a sua resposta'
  where chave='ind_avalize';

update public.email_modelos set assunto='Uma indica'||chr(231)||chr(227)||'o aguarda a sua aprova'||chr(231)||chr(227)||'o'
  where chave='ind_aprovar';

update public.email_modelos set assunto='Aprovado '||chr(8212)||' ficha de introniza'||chr(231)||chr(227)||'o e anuidade'
  where chave='ind_aprovado_candidato';

update public.email_modelos set assunto='Pagamento confirmado '||chr(8212)||' bem-vindo!'
  where chave='intro_pagamento_ok';

update public.email_modelos set assunto='Convite '||chr(183)||' {evento}'
  where chave='evento_convite';
