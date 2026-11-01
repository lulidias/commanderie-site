-- 31/10/2026 — tokens dos robôs das redes (hoje: Threads, que vence a cada 60 dias e é renovado pelo próprio robô).
-- Sem nenhuma política: só a service key (robôs no GitHub Actions) lê e grava. Ninguém do site enxerga.
create table if not exists social_tokens (
  nome text primary key,
  valor text not null,
  expira_em timestamptz,
  atualizado_em timestamptz default now()
);
alter table social_tokens enable row level security;
