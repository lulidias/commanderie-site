-- =====================================================================
-- Troca "Intronizacao/intronizado" por "Entronizacao/entronizado" nos
-- modelos de e-mail (assunto, titulo, corpo). Nenhum corpo usa o filename
-- ficha-intronizacao.html, entao o replace e' seguro. 100% ASCII.
-- =====================================================================
update public.email_modelos set
  assunto = replace(replace(assunto,'Introniza','Entroniza'),'introniza','entroniza'),
  titulo  = replace(replace(replace(titulo,'Introniza','Entroniza'),'introniza&ccedil;','entroniza&ccedil;'),'intronizado','entronizado'),
  corpo   = replace(replace(replace(corpo,'Introniza','Entroniza'),'introniza&ccedil;','entroniza&ccedil;'),'intronizado','entronizado')
where assunto like '%ntroniza%' or titulo like '%ntroniza%' or corpo like '%ntroniza%';
