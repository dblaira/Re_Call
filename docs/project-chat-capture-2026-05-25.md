# Re_Call Project Chat Capture - 2026-05-25

This note captures the working decisions and artifacts from the Codex thread that turned Re_Call from a loose app idea into a more defined product, PRD, ontology, and prototype direction.

## Origin

The project began from a conversation with Stephanie about building something real and shippable together.

The first product framing was a personalized reminder system, but the idea quickly sharpened:

> Re_Call is not really a reminders app. The reminder is the delivery mechanism. The real product is a personalization system that helps people pick up where they left off with themselves.

The app should not force generic sequential productivity advice. It should support different minds, different purposes, and different reminder jobs.

## Core Product Signal

The perfect user reaction is not passive approval.

The perfect reaction is:

> Interesting. I like these templates, but I have a better custom version for my life.

This became the guiding product behavior:

> Template sparks personalization. Personalization becomes a rule. The rule improves the next reminder.

## Judgment Model

The project captured an important Adam-specific decision rule:

> Maybe means no. Yes means yes.

More specifically:

> The bottleneck is treating great ideas and good ideas as if they belong on the same list. From past experience, great ideas are worth more than all good ideas combined.

Neutral is different from Maybe. Neutral belongs to `Circling`: watch before moving.

## Working Prototype

A small browser lab was built to test the feeling of the loop:

```text
capture_context -> classify_signal -> suggest_template -> request_human_feedback
```

The lab includes:

- deterministic rule: Maybe means no
- memory step: store why a template was liked, disliked, or undecided
- output: a custom reminder template
- hierarchy example: hierarchical wins should use a mind map

Original prototype location:

```text
/Users/adamblair/Documents/Project_ReCall/labs/recall-crewai-lab/index.html
```

Local server used during the session:

```text
http://localhost:8765/index.html
```

## Behavioral Proof

The lab worked because it triggered immediate user behavior.

Adam saw a template, then immediately personalized the answer based on work done in Notion that morning.

This became a major product insight:

> Re_Call should help users distinguish whether something feels wrong because of the content, timing, styling, or format.

## Format Match Engine

The session produced a new product primitive:

> Format Match Engine

The engine should classify the best translation format for a signal, not merely generate reminder text.

Example:

```text
HierarchicalWinSignal -> MindMapFormat
```

The key diagnostic question:

> Is this the best match for describing what just happened?

Adam-specific rule:

> When a win involves hierarchy, use a mind map to preserve structure and reduce styling fixation.

## PRD Learning List

A Notion PRD database was created and expanded:

```text
Project_ReCall - PRD Learning List
https://www.notion.so/51c22ae3adc5409f925f99f302c2a075
```

Important PRD rows added:

- Format Match Engine
- Problem Statement: Wrong Answer Shape
- Success Signal: Inspired to Build
- Personalization Rule: Hierarchy Uses Mind Map
- Acceptance Criteria: Format Match Engine
- User Story: Format Judgment
- Ontology Foundation: RDF/OWL Standards
- Ontology Principle: Interoperability
- Ontology Principle: Reuse
- Ontology Principle: Consistency
- Ontology Principle: Expressiveness
- Ontology Principle: Scalability
- Architecture Decision: Layered Knowledge Graph Stack

The PRD status option `Understood` was renamed to `Landed` to avoid confusion with Understood.app.

Status meanings:

- `To Learn`: concept is still unfamiliar
- `Needs Example`: concept is clear but needs a Re_Call example
- `Drafting`: real idea with evidence, still being shaped
- `Landed`: proven enough to guide product decisions

## RDF / OWL Direction

RDF/OWL became a core architecture idea, not a side experiment.

Best wording:

> RDF/OWL is not extra technical ceremony for Re_Call. It is the hierarchy language that lets meaning survive beyond one app surface.

Reference principles captured:

- Interoperability: shared meaning across systems
- Reuse: one ontology can serve many applications
- Consistency: logical checking catches conflicts
- Expressiveness: richer than schema-only models
- Scalability: workable at large scale with good design

Seed ontology created:

```text
/Users/adamblair/Documents/Project_ReCall/ontology/project-recall-principles.ttl
```

It loaded successfully in Protege.

## Fuseki / Docker Proof

Docker/Fuseki was used to load and query the Re_Call ontology.

Dataset:

```text
http://localhost:3032
dataset: recall
```

Proof query result:

```text
Format Match Engine requirement -> Hierarchical win signal -> Mind map format
```

This established the loop:

```text
PRD in Notion -> OWL in Protege -> triples in Docker/Fuseki -> SPARQL proof queries
```

## Architecture Decision

The landed architecture decision:

> Supabase stores the app. OWL defines the meaning. Neo4j may power graph intelligence. Vercel orchestrates. iOS stays clean.

Expanded version:

- iOS app in Xcode: native user experience
- Vercel API / agent layer: orchestration, API contracts, AI calls, graph adapter boundary
- Supabase: users, auth, reminders, feedback, subscriptions, timestamps, app state
- RDF/OWL + Protege: formal meaning layer and hierarchy language
- Fuseki/Jena: semantic-web proof loop and SPARQL experiments
- Neo4j: candidate graph intelligence layer for traversal, GraphRAG, and knowledge graph product behavior

Do not replace Supabase with Neo4j. Supabase remains the system of record. Neo4j is a serious candidate for graph intelligence later.

## Stephanie Feedback

Stephanie completed feedback on the 100 reminder scenarios.

Archived workbook:

```text
/Users/adamblair/Documents/Project_ReCall/inbox/Stephanie_Project_ReCall_100_Reminder_Scenarios.xlsx
```

Analysis note:

```text
/Users/adamblair/Documents/Project_ReCall/docs/stephanie-feedback-analysis.md
```

Feedback counts:

| Feedback | Count |
|---|---:|
| Like | 62 |
| Undecided | 35 |
| Dislike | 3 |

Strong signal:

`Health / Fitness`, `Personal State`, `Location`, and many `Calendar` reminders look promising.

Weak signal:

`App close` reminders are not strong by default.

Stephanie's clearest note:

> I've have my action - that's why I closed the app :-)

Product rule candidate:

> App-close reminders should not fire just because an app closed. They should fire only when the close implies an unresolved transition, emotional residue, or abandoned thread.

## MindNode Export

The PRD Learning List was exported as a MindNode-friendly OPML file:

```text
/Users/adamblair/Documents/Project_ReCall/exports/Project_ReCall_PRD_Learning_List_MindNode.opml
```

Markdown outline backup:

```text
/Users/adamblair/Documents/Project_ReCall/exports/Project_ReCall_PRD_Learning_List_MindNode.md
```

## Next Session Starting Point

Start with the first API contract:

```text
getBestFormat(userSignal) -> TranslationFormat
```

First proof case:

```text
HierarchicalWinSignal -> MindMapFormat
```

The goal is to connect the browser lab to the graph layer so the format suggestion is not hardcoded.

