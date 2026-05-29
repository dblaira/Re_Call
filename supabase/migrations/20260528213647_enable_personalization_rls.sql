-- supabase/migrations/20260528213647_enable_personalization_rls.sql
-- Match the recall schema convention: RLS enabled, no permissive policies, so the
-- per-user personalization tables are reachable only via the service role (server-side).
-- When/if client-side access is wired with user JWTs, add user-scoped policies
-- (e.g. user_id = auth.uid()) in a follow-up migration.
alter table recall.user_strength_events enable row level security;
alter table recall.user_goal_weights enable row level security;
