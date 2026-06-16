-- supabase/migrations/20260615120001_harden_set_updated_at_search_path.sql
-- Pin the trigger function's search_path (clears the function_search_path_mutable security
-- advisor). now() resolves from pg_catalog, which is always implicitly first, so '' is safe.
alter function recall.set_updated_at() set search_path = '';
