# Re_Call Deployment

## Vercel

Project: `adam-blairs-projects/re-call`

The Vercel surface is intentionally small:

- `GET /api/health`
- `POST /api/recommendations`

The build command is `npm test`, so deployment fails if the deterministic graph contracts fail.

Production environment variables currently expected by the stack:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`
- `RECALL_OPENAI_TINY_MODEL`
- `RECALL_OPENAI_STANDARD_MODEL`
- `RECALL_OPENAI_REASONING_MODEL`

`OPENAI_API_KEY` is required only for model-written reminder copy. If it is absent, `/api/recommendations` still returns the deterministic RDF graph result and marks copy as skipped or missing.

## Supabase

Project: `Re_Call`

- Project ref: `vzaceoipwimphdvdxcpa`
- Project URL: `https://vzaceoipwimphdvdxcpa.supabase.co`
- Edge Function: `recommendations`
- Edge Function auth: JWT required
- Current production row counts: `recall.rdf_prefixes` 9, `recall.rdf_terms` 56, `recall.rdf_triples` 107, `recall.neo4j_edges` 77, `recall.neo4j_node_properties` 30.
- Supabase does not currently have a GitHub repository connected. That is expected for now; see `docs/supabase-github-connection.md`.

## RDF And Neo4j Shape

Supabase stores the recommendation graph in three layers:

1. Domain tables for reminder templates, strengths, and recommendation rules.
2. RDF tables with full IRIs:
   - `recall.rdf_prefixes`
   - `recall.rdf_terms`
   - `recall.rdf_triples`
3. Neo4j projection views:
   - `recall.neo4j_edges`
   - `recall.neo4j_node_properties`

The RDF layer uses full subject-predicate-object rows instead of app-only foreign keys, so it can move toward SPARQL, OWL tooling, or Neo4j/n10s import without rewriting the meaning model.

## BFO / CCO Alignment

Re_Call terms remain domain-level extensions. They do not replace BFO or CCO terms.

Current formal alignment:

| Re_Call class | Formal parent |
| --- | --- |
| `recall:ReminderTemplate` | `cco:DirectiveInformationContentEntity` |
| `recall:ReminderRecommendationRule` | `cco:DirectiveInformationContentEntity` |
| `recall:FeedbackSignal` | `cco:InformationContentEntity` |
| `recall:UserStrength` | `bfo:BFO_0000016` disposition |

The Supabase RDF layer also stores `rdfs:subClassOf` and `owl:imports` triples so the formal alignment is queryable as graph data.

## Namespace Notes

CCO v2 uses opaque IRIs under:

```text
https://www.commoncoreontologies.org/
```

The older CCO namespace is also recorded as `cco_legacy` for interoperability with older CCO material:

```text
http://www.ontologyrepository.com/CommonCoreOntologies/
```

BFO terms use OBO-style IRIs:

```text
http://purl.obolibrary.org/obo/BFO_0000001
```
