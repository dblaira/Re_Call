# Supabase Migrations

Remote migrations applied to project `vzaceoipwimphdvdxcpa`:

- `20260527205832_create_recall_recommendation_graph`
- `20260527210247_add_rdf_and_neo4j_projection`
- `20260527210414_add_bfo_cco_alignment`
- `20260528120000_add_personalization_tables` — `recall.user_strength_events` and `recall.user_goal_weights` for the personalization layer

The local Supabase CLI is not installed in this workspace, so these migrations were applied through the Supabase app connector and verified with SQL queries.

The important contract is:

- Domain recommendation data lives in the `recall` schema.
- RDF-compatible rows live in `recall.rdf_terms` and `recall.rdf_triples`.
- Neo4j import-friendly projections live in `recall.neo4j_edges` and `recall.neo4j_node_properties`.
- Formal alignment to BFO/CCO is represented with `rdfs:subClassOf` triples.
