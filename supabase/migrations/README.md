# Supabase Migrations

Remote migrations applied to project `vzaceoipwimphdvdxcpa`:

- `20260527205832_create_recall_recommendation_graph`
- `20260527210247_add_rdf_and_neo4j_projection`
- `20260527210414_add_bfo_cco_alignment`
- `20260528213640_add_personalization_tables` — `recall.user_strength_events` and `recall.user_goal_weights` for the personalization layer
- `20260528213647_enable_personalization_rls` — enables row-level security on the two per-user personalization tables. Matches the schema convention (RLS on, no permissive policies), so they are reachable only via the service role (server-side). Add user-scoped policies (`user_id = auth.uid()`) in a follow-up migration if/when client-side access with user JWTs is wired.
- `20260528214544_add_personalization_user_policies` — adds user-scoped policies on top of the RLS above so an authenticated client (anon key + user JWT) reaches only its own rows. `user_strength_events`: `select` + `insert` own rows (append-only — no `update`/`delete`). `user_goal_weights`: `select` own rows only — writes stay server-side via the service-role key. The service role still bypasses RLS everywhere.
- `20260528215109_optimize_personalization_rls_initplan` — rewrites the policies above to use `(select auth.uid())` instead of `auth.uid()` so it is evaluated once per query (initPlan) rather than per row. Clears the `auth_rls_initplan` performance advisor; policy semantics are unchanged.

The local Supabase CLI is not installed in this workspace, so these migrations were applied through the Supabase app connector and verified with SQL queries.

The important contract is:

- Domain recommendation data lives in the `recall` schema.
- RDF-compatible rows live in `recall.rdf_terms` and `recall.rdf_triples`.
- Neo4j import-friendly projections live in `recall.neo4j_edges` and `recall.neo4j_node_properties`.
- Formal alignment to BFO/CCO is represented with `rdfs:subClassOf` triples.
