# Leverage as a Disposition (BFO/CCO stub)

Stub ontology: [`ontology/leverage-disposition.ttl`](../../ontology/leverage-disposition.ttl)

## The pattern

Re_Call already names two leverage-related user strengths in
[`reminder-recommendation.ttl`](../../ontology/reminder-recommendation.ttl):
`recall:LeverageAwareness` and `recall:ExecutionLeverage`. This stub gives the
*thing* those strengths notice a formal home.

We model **Leverage** as a **Disposition** (`bfo:BFO_0000016`):

```text
bearer  --recall:hasLeverage-->  LeverageDisposition  --recall:realizedIn-->  Process
                                                       Process --recall:amplifiesOutcomeOf--> Outcome
```

- The **bearer** is an independent continuant — a habit stack, a decision
  point, a bottleneck.
- The **LeverageDisposition** is its latent tendency to produce outsized
  change. It can sit unrealized.
- The **process** is where the disposition is *realized* (`bfo:BFO_0000054`).
- That process is **causally upstream of** an outcome whose probability or
  magnitude it raises.

### Function vs Disposition vs Role (why Disposition)

| Realizable | Grounding | Re_Call fit |
|---|---|---|
| **Function** (`BFO_0000034`) | bearer was selected/designed for the effect | No — we don't claim leverage was teleologically designed |
| **Role** (`BFO_0000023`) | externally assigned by context; optional | No — leverage is grounded in how the bearer is actually structured |
| **Disposition** (`BFO_0000016`) | internally grounded; may stay latent until realized | **Yes** — a tendency to amplify outcomes when acted on |

## Why bother (keep leverage formal, not a loose tag)

A string tag `"high leverage"` cannot be reasoned over. Modeling leverage as a
disposition lets the graph:

- distinguish a *latent* leverage point from one *realized this week*,
- chain a realized process to the concrete outcome it amplified, and
- carry a `recall:leverageScore` that ranking and explanation can use.

This follows the doctrine in
[`personalization-system-doctrine.md`](../product/personalization-system-doctrine.md):
**graph first, LLM second.** The graph decides what amplified what; the model
only phrases the trace.

## Example query (in prose)

> Which dispositions, realized in a process this week, were most
> causally upstream of `recall:ProtectedTransitionTime`?

In SPARQL terms: find every `recall:LeverageDisposition` that is
`recall:realizedIn` a process dated this week, where that process
`recall:amplifiesOutcomeOf` an outcome whose `recall:hasOutput` is
`recall:ProtectedTransitionTime`, then sort by `recall:leverageScore`
descending. The result is a ranked list of the small inputs that protected the
most valuable time — exactly what the `recall:NameSmallInputAndOutcome` and
`recall:FindBottleneckBlockingOutcomes` templates ask the user to surface.

## IRIs used (and ones flagged for verification)

| Term | IRI used | Status |
|---|---|---|
| disposition | `bfo:BFO_0000016` | confirmed (BFO 2020) |
| realized in | `bfo:BFO_0000054` | confirmed (BFO 2020) |
| process | `bfo:BFO_0000015` | confirmed (BFO 2020) |
| has disposition (bearer rel.) | `obo:RO_0000091` | **flagged** — prompt suggested `BFO_0000186`, which is a continuant-part relation, not "has disposition". Used RO_0000091; verify against your RO build |
| causally upstream of or within | `obo:RO_0002418` | **flagged** — prompt cited `RO_0002506` (`causal relation between processes`); used the more precise RO_0002418, confirm before reasoning |
| CCO `has_input` / `has_output` | `recall:hasInput` / `recall:hasOutput` aliases | **flagged placeholders** — CCO publishes these under opaque `ont…` IRIs; declared as local aliases with `rdfs:seeAlso` placeholders rather than inventing real-looking CCO IRIs |

## Sources Adam cited

1. **BFO Function / Role / Disposition** — the realizable-entity distinctions in
   Basic Formal Ontology (Arp, Smith & Spear, *Building Ontologies with Basic
   Formal Ontology*, MIT Press 2015; and the BFO 2020 / ISO 21838-2 spec).
2. **Common Core Ontologies (CCO) overview** — the mid-level interoperability
   spine (`commoncoreontologies.org`) used as the CCO spine in the doctrine doc.
3. **Grounding Realizable Entities** — arXiv:2405.00197, on giving realizables
   (dispositions, functions, roles) precise grounding so they can be reasoned
   over rather than left as informal labels.
