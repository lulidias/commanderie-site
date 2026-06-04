-- =====================================================================
-- Painel do Produtor - campos extras nos formularios de visita e evento.
-- Idempotente (add column if not exists). 100% ASCII.
-- =====================================================================

-- Solicitacao de visita: objetivo, voo, chegada/saida (data + por onde)
alter table public.produtor_visitas add column if not exists objetivo      text;
alter table public.produtor_visitas add column if not exists voo           text;
alter table public.produtor_visitas add column if not exists chegada_data  date;
alter table public.produtor_visitas add column if not exists chegada_local text;
alter table public.produtor_visitas add column if not exists saida_data    date;
alter table public.produtor_visitas add column if not exists saida_local   text;

-- Solicitacao de evento: vinhos, quantidade, local, restaurante, estilo de menu
alter table public.produtor_eventos add column if not exists vinhos      text;
alter table public.produtor_eventos add column if not exists quantidade  int;
alter table public.produtor_eventos add column if not exists local       text;
alter table public.produtor_eventos add column if not exists restaurante text;
alter table public.produtor_eventos add column if not exists estilo_menu text;
