-- supabase/migrations/20260528120000_add_personalization_tables.sql
create table if not exists recall.user_strength_events (
  id             bigint generated always as identity primary key,
  user_id        uuid not null,
  strength_id    text not null,
  signal_type    text not null,
  template_id    text,
  config_version text not null default 'v1',
  created_at     timestamptz not null default now()
);
-- The numeric delta is intentionally NOT stored: it is derived from the signal-delta
-- config at compute time, so re-tuning weights re-scores history without migrating rows.
-- config_version records which delta config a row was written under, for auditability.

create index if not exists user_strength_events_user_idx
  on recall.user_strength_events (user_id, created_at);

create table if not exists recall.user_goal_weights (
  user_id      uuid not null,
  strength_id  text not null,
  weight       numeric not null default 1.0,
  updated_at   timestamptz not null default now(),
  primary key (user_id, strength_id)
);
