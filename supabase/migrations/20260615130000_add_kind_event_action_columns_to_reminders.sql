-- supabase/migrations/20260615130000_add_kind_event_action_columns_to_reminders.sql
-- Typed items: a reminder row can now be a Reminder, an Action, or an Event (`kind`), and the
-- new Action/Event "parts" from the entry form get their own columns so they sync like the rest.
--   * kind         — reminder | action | event
--   * end_time     — Event end (pairs with due_time as the start); time-only
--   * outcome      — Action: what "done" looks like
--   * effort       — Action: rough time estimate (none/5m/15m/30m/1h/2h+)
--   * energy       — Action: gas needed (none/low/medium/high)
--   * context      — Action: GTD-style context (none/home/work/errands/calls/computer)
--   * defer_date   — Action: earliest start / defer date
--   * waiting_on   — Action: delegated-to / waiting-on person
-- Additive and idempotent; existing rows default to a plain Reminder.
alter table recall.reminders
  add column if not exists kind       text not null default 'reminder'
    check (kind in ('reminder','action','event')),
  add column if not exists end_time   time without time zone,
  add column if not exists outcome    text not null default '',
  add column if not exists effort     text not null default 'none'
    check (effort in ('none','m5','m15','m30','h1','h2plus')),
  add column if not exists energy     text not null default 'none'
    check (energy in ('none','low','medium','high')),
  add column if not exists context    text not null default 'none'
    check (context in ('none','home','work','errands','calls','computer')),
  add column if not exists defer_date date,
  add column if not exists waiting_on text not null default '';
