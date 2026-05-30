-- supabase/migrations/20260530204343_grant_personalization_schema_access.sql
-- Custom schemas don't inherit the automatic anon/authenticated/service_role grants that
-- public gets, so the recall.* personalization tables were unreachable via the Data API
-- (PostgREST: "permission denied for schema recall") even for the service role — GRANTs are
-- not bypassed by service_role, only RLS is. Grant the base privileges; the RLS policies from
-- 20260528214544 still restrict which ROWS each authenticated user sees. anon is intentionally
-- omitted: the policies are scoped `to authenticated`.

grant usage on schema recall to authenticated, service_role;

-- Append-only signal log: authenticated clients read + insert their own rows (RLS-enforced);
-- the service role (server path) reads + inserts.
grant select, insert on recall.user_strength_events to authenticated, service_role;

-- Goal weights: authenticated clients read their own (RLS); writes are server-side only.
grant select on recall.user_goal_weights to authenticated;
grant select, insert, update on recall.user_goal_weights to service_role;
