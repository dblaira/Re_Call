-- supabase/migrations/20260616020000_repurpose_context_to_success_step.sql
-- The `context` column no longer holds GTD @contexts; it now stores a step of Adam's 8-step
-- success architecture (the "Adam Pattern"). Reset stale values, then swap the CHECK constraint.
update recall.reminders set context = 'none'
  where context not in ('none','context','circle','closeGap','chooseSuccess','codePattern','killSwitch','clearSign','compound');

alter table recall.reminders drop constraint if exists reminders_context_check;
alter table recall.reminders add constraint reminders_context_check
  check (context in ('none','context','circle','closeGap','chooseSuccess','codePattern','killSwitch','clearSign','compound'));
