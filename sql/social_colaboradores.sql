-- 11/11/2026 — collab no Instagram: o robô manda convite de colaboração para estes perfis (até 3) ao publicar.
alter table social_posts add column if not exists colaboradores text[];
notify pgrst, 'reload schema';
