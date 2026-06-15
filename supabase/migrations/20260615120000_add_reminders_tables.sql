-- supabase/migrations/20260615120000_add_reminders_tables.sql
-- The user's reminders, captured natively in the iOS app and synced here. The 16 "parts"
-- from the entry form map to columns + two child tables:
--   * scalar parts (title, notes, url, image, date, time, urgent, repeat, early reminder,
--     list, flag, priority, location, when-messaging) are columns on recall.reminders
--   * relational parts (tags, subtasks) are child tables so they project cleanly to
--     RDF/Neo4j edges later (matching the rdf_terms/rdf_triples + neo4j projection design).
-- seeded_from_template_id links a reminder back into the existing recommendation graph
-- (recall.reminder_templates), closing the "deeper, not broader" loop.
-- Completed reminders are RETAINED (status='completed'), never deleted.
create table if not exists recall.reminders (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid not null default auth.uid(),
  -- Core
  title                   text not null default '',
  notes                   text not null default '',
  url                     text not null default '',
  image_path              text,                              -- Supabase Storage path (1.0.1); null for now
  -- Date & Time
  due_date                date,
  due_time                time,
  urgent                  boolean not null default false,
  repeat_rule             text not null default 'none',
  early_reminder          text not null default 'none',
  -- Organization
  list_name               text not null default 'Reminders',
  flag                    boolean not null default false,
  priority                text not null default 'none',
  -- Places & People
  location_name           text not null default '',
  when_messaging_person   text not null default '',
  -- Graph link + lifecycle
  seeded_from_template_id text references recall.reminder_templates(id),
  status                  text not null default 'active',
  completed_at            timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  constraint reminders_status_check   check (status in ('active','completed','deleted')),
  constraint reminders_priority_check check (priority in ('none','low','medium','high')),
  constraint reminders_repeat_check   check (repeat_rule in ('none','daily','weekdays','weekly','monthly','yearly')),
  constraint reminders_early_check    check (early_reminder in ('none','5m','10m','30m','1h','1d'))
);

create index if not exists reminders_user_status_idx on recall.reminders (user_id, status, created_at desc);
create index if not exists reminders_template_idx     on recall.reminders (seeded_from_template_id);

-- keep updated_at fresh
create or replace function recall.set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists reminders_set_updated_at on recall.reminders;
create trigger reminders_set_updated_at
  before update on recall.reminders
  for each row execute function recall.set_updated_at();

-- Tags edge: (:Reminder)-[:TAGGED]->(:Tag)
create table if not exists recall.reminder_tags (
  reminder_id uuid not null references recall.reminders(id) on delete cascade,
  tag         text not null,
  primary key (reminder_id, tag)
);
create index if not exists reminder_tags_tag_idx on recall.reminder_tags (tag);

-- Subtasks edge: (:Reminder)-[:HAS_SUBTASK]->(:Subtask)
create table if not exists recall.reminder_subtasks (
  id          uuid primary key default gen_random_uuid(),
  reminder_id uuid not null references recall.reminders(id) on delete cascade,
  title       text not null default '',
  done        boolean not null default false,
  position    integer not null default 0
);
create index if not exists reminder_subtasks_reminder_idx on recall.reminder_subtasks (reminder_id, position);

-- RLS: own-rows only for authenticated clients (anonymous sign-in carries the authenticated
-- role). initPlan-optimized (select auth.uid()), matching the personalization-table convention.
alter table recall.reminders         enable row level security;
alter table recall.reminder_tags     enable row level security;
alter table recall.reminder_subtasks enable row level security;

drop policy if exists reminders_select_own on recall.reminders;
create policy reminders_select_own on recall.reminders for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists reminders_insert_own on recall.reminders;
create policy reminders_insert_own on recall.reminders for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists reminders_update_own on recall.reminders;
create policy reminders_update_own on recall.reminders for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists reminders_delete_own on recall.reminders;
create policy reminders_delete_own on recall.reminders for delete to authenticated using (user_id = (select auth.uid()));

drop policy if exists reminder_tags_all_own on recall.reminder_tags;
create policy reminder_tags_all_own on recall.reminder_tags for all to authenticated
  using (exists (select 1 from recall.reminders r where r.id = reminder_id and r.user_id = (select auth.uid())))
  with check (exists (select 1 from recall.reminders r where r.id = reminder_id and r.user_id = (select auth.uid())));

drop policy if exists reminder_subtasks_all_own on recall.reminder_subtasks;
create policy reminder_subtasks_all_own on recall.reminder_subtasks for all to authenticated
  using (exists (select 1 from recall.reminders r where r.id = reminder_id and r.user_id = (select auth.uid())))
  with check (exists (select 1 from recall.reminders r where r.id = reminder_id and r.user_id = (select auth.uid())));

-- Grants: custom schemas don't inherit role grants; RLS still gates rows.
grant usage on schema recall to authenticated;
grant select, insert, update, delete on recall.reminders, recall.reminder_tags, recall.reminder_subtasks to authenticated;
grant select, insert, update, delete on recall.reminders, recall.reminder_tags, recall.reminder_subtasks to service_role;
