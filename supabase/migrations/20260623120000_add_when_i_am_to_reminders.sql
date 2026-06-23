-- Action delegate section: context cue ("When I am... I like to") on its own line.
alter table recall.reminders
  add column if not exists when_i_am text not null default '';
