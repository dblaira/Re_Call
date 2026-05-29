-- supabase/migrations/20260528215109_optimize_personalization_rls_initplan.sql
-- Performance follow-up to 20260528214544_add_personalization_user_policies.
--
-- The policies there called auth.uid() directly, which Postgres re-evaluates once PER ROW.
-- Wrapping it as (select auth.uid()) lets the planner evaluate it once per query (initPlan)
-- and reuse the result, which matters as the event log grows. This resolves the Supabase
-- `auth_rls_initplan` performance advisor:
--   https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select
--
-- Policy semantics are unchanged — same commands, same roles, same ownership predicate.
-- Statements are guarded with drop-if-exists so the migration is re-runnable.

-- user_strength_events: read + append your own rows.
drop policy if exists user_strength_events_select_own on recall.user_strength_events;
create policy user_strength_events_select_own
  on recall.user_strength_events
  for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists user_strength_events_insert_own on recall.user_strength_events;
create policy user_strength_events_insert_own
  on recall.user_strength_events
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

-- user_goal_weights: read-only for clients; writes are server-side.
drop policy if exists user_goal_weights_select_own on recall.user_goal_weights;
create policy user_goal_weights_select_own
  on recall.user_goal_weights
  for select
  to authenticated
  using (user_id = (select auth.uid()));
