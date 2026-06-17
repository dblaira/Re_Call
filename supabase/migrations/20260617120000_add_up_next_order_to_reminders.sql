-- Manual Up Next card order within pinned/unpinned blocks.
alter table recall.reminders
  add column if not exists up_next_order integer;
