-- supabase/migrations/20260615140000_add_pinned_to_reminders.sql
-- Pinned reminders sort to the top of the list (and the "Up next" cards).
-- Additive and idempotent; existing rows default to unpinned.
alter table recall.reminders
  add column if not exists pinned boolean not null default false;
