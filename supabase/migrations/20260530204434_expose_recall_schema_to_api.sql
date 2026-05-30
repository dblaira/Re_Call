-- supabase/migrations/20260530204434_expose_recall_schema_to_api.sql
-- Expose the recall schema through the PostgREST Data API. By default only
-- `public, graphql_public` are served, so supabase-js `.schema("recall")` calls fail with
-- PGRST205/404 until recall is added. Required for every key (service role and user JWT alike).
--
-- NOTE: Supabase's dashboard (Project Settings -> API -> Exposed schemas) is the platform
-- source of truth; a later "Save" there can overwrite this role-level setting. Mirror `recall`
-- in the dashboard so the setting is durable.
alter role authenticator set pgrst.db_schemas = 'public, graphql_public, recall';
notify pgrst, 'reload config';
notify pgrst, 'reload schema';
