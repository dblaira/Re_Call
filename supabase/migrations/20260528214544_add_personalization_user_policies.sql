-- supabase/migrations/20260528214544_add_personalization_user_policies.sql
-- Follow-up to 20260528213647_enable_personalization_rls, which turned RLS on for the
-- per-user personalization tables but added no policies (server/service-role-only access).
--
-- This adds user-scoped policies so an authenticated client (anon key + user JWT) can
-- reach only its own rows (user_id = auth.uid()). The service-role key keeps bypassing
-- RLS for server-side code.
--
-- The two tables get DIFFERENT policy sets because their writes originate in different
-- places:
--   user_strength_events  -- client-generated, append-only signal log. Read + insert your
--     own rows; no UPDATE/DELETE policy, so the log is never mutated in place (per the
--     personalization-layer design). Backfills/corrections run through the service role.
--   user_goal_weights     -- declared aspiration, currently SEEDED server-side from a code
--     constant (LEVERAGE_GOAL_WEIGHTS); "learned goal weights" are out of scope and there
--     is no client edit path. Clients only READ their own weights; writes stay server-side
--     via the service-role key. Add a write policy here if a user-facing "edit my goals"
--     surface is built later.
--
-- create-policy statements are guarded with drop-if-exists so the migration is re-runnable.

-- user_strength_events: read + append your own rows.
drop policy if exists user_strength_events_select_own on recall.user_strength_events;
create policy user_strength_events_select_own
  on recall.user_strength_events
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists user_strength_events_insert_own on recall.user_strength_events;
create policy user_strength_events_insert_own
  on recall.user_strength_events
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- user_goal_weights: read-only for clients; writes are server-side.
drop policy if exists user_goal_weights_select_own on recall.user_goal_weights;
create policy user_goal_weights_select_own
  on recall.user_goal_weights
  for select
  to authenticated
  using (user_id = auth.uid());
