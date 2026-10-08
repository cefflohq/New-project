-- CEFFLO Content Engine V2 (n8n). Isolated schema in the n8n Postgres.
-- Apply only with Founder approval:  psql -v ON_ERROR_STOP=1 -f 20261008_content_engine_v2.sql
create schema if not exists cefflo_ce2;

create table if not exists cefflo_ce2.content (
  id            uuid primary key default gen_random_uuid(),
  run_date      date not null default (now() at time zone 'Asia/Kuala_Lumpur')::date,
  slot          int  not null,
  type          text not null check (type in ('video','text')),
  platforms     text[] not null,
  funnel        text not null check (funnel in ('TOFU','MOFU','BOFU')),
  format        text, world text, pain text, angle text, hook text,
  recycle_of    uuid references cefflo_ce2.content(id),
  brief         jsonb not null,
  script        jsonb,
  qa            jsonb,
  status        text not null default 'NEW' check (status in
                ('NEW','SCRIPTED','QA_FAIL','HOLD','PRODUCING','PRODUCE_FAIL','READY',
                 'AWAITING_APPROVAL','REVISE','APPROVED','REJECTED','PUBLISHING','PUBLISHED','FAILED','CLOSED')),
  revise_note   text,
  revisions     int not null default 0,
  media_url     text,
  scheduled_at  timestamptz,
  tg_message_id bigint,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (run_date, slot, revisions)
);

create table if not exists cefflo_ce2.asset (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references cefflo_ce2.content(id) on delete cascade,
  shot int, kind text not null,            -- keyframe | shot | vo | talking | final
  provider text, provider_task_id text, url text, status text not null default 'PENDING',
  meta jsonb, created_at timestamptz not null default now()
);

create table if not exists cefflo_ce2.publication (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references cefflo_ce2.content(id),
  platform text not null check (platform in ('tiktok','facebook','instagram','threads')),
  platform_post_id text, url text, status text not null default 'PENDING', error text,
  published_at timestamptz, unique (content_id, platform)
);

create table if not exists cefflo_ce2.metric (
  id bigserial primary key,
  publication_id uuid not null references cefflo_ce2.publication(id),
  checkpoint text not null check (checkpoint in ('24h','72h','7d')),
  views int, reach int, avg_watch_s numeric, completion numeric, hold_3s numeric,
  likes int, comments int, shares int, saves int, clicks int, raw jsonb,
  collected_at timestamptz not null default now(), unique (publication_id, checkpoint)
);

create table if not exists cefflo_ce2.learning (
  id bigserial primary key, week date not null, observation text not null,
  confidence text not null check (confidence in ('LOW','MEDIUM','HIGH')),
  action text, evidence jsonb, created_at timestamptz not null default now()
);

create table if not exists cefflo_ce2.recycle_candidate (
  content_id uuid primary key references cefflo_ce2.content(id),
  score numeric not null, reason text, used boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists cefflo_ce2.cost (
  id bigserial primary key, content_id uuid references cefflo_ce2.content(id),
  provider text not null, units numeric, usd numeric not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists content_status_idx on cefflo_ce2.content(status, scheduled_at);
create index if not exists cost_day_idx on cefflo_ce2.cost(created_at);
