# Re_Call Personalization System Doctrine

This doctrine pairs with two constraint docs that every build references: the [Design Philosophy](../design/design-philosophy.md) (how it should look and feel) and the [Shop / Ship / Undertow product loop](./shop-ship-undertow.md) (how the personalization engine is merchandised to the user).

## Product Center

Re_Call is a personalization system for picking up where a person left off with themselves.

## Latest Strategy: User Zero First

June 13, 2026.

This app is being built for Adam. Adam is the first user but hopefully not the last. Anything that does not resonate with Adam is useless or worse -- destructive. Adam's taste and natural reaction to any wording, component, functionality, API call, font size, color scheme, recommendation engine, ontology, knowledge graph, and any other detail are the bar of success.

Anything Adam does not understand when communicating with an agent is potentially harmful to the project. If Adam wants to add something because it is a good idea and useful for others, that is fine too. But always: the app is designed solely for Adam first.

The reminder is the delivery surface. The deeper product is:

```text
notice the right moment
-> interpret what happened in the right shape
-> turn the user's reaction into a reusable personal rule
```

The short version:

```text
Re_Call is not "remember this later."
Re_Call is "recover the meaning of this moment in the form that lets you act from your own judgment."
```

## Original Spark

The project comes from the `Narrative vs Relational` insight in the Obsidian Main vault:

```text
Memory is narrative.
Life is relational.
```

Human memory compresses life into stories after the fact. Real life is made of delayed, connected effects: sleep changes ambition, learning changes mood, belief changes entertainment later, and combined conditions can produce effects that neither condition produces alone.

Re_Call applies that insight to moments of return. It should help the user re-enter the relational context that narrative memory compressed or lost.

## Product Problem

People do not only need reminders at the right time.

They need the reminder to match the kind of situation they are in:

- A hierarchical win should not be flattened into prose.
- A good-but-not-great idea should not compete with an unmistakable yes.
- An app-close event should not trigger a reminder unless it means unresolved residue or abandoned context.

The system is working when the UI causes the user to feel inspired to build a custom reminder that shares the burden of making relational connections across areas of life.

## Product Loop

```text
Capture a real signal from life or work.
Classify what kind of signal it is.
Choose the best translation format, not just the best text.
Show a template that sparks the user to personalize it.
Capture which articulation the user accepts, edits, or rejects.
Store the personalization as a rule.
Use that rule to make the next reminder more aligned.
```

## Articulation Is Signal

The wording of a reminder is not decoration. The subject tells Re_Call what area of life the reminder belongs to. The articulation tells Re_Call what motive makes that subject come alive for this user.

Example:

```text
baseline: Drink water — 8 glasses, fixed times
performance bend: Hydrate now, so you can push harder later and recover quickly.
```

The baseline version is useful for plain onboarding. The bend is useful for personalization. If a user chooses, edits toward, or rejects harder-driving copy, Re_Call learns sooner whether they respond to performance, recovery, discipline, care, beauty, social duty, or another motive.

Treat title, notes, and body-copy edits as first-class user signals alongside subject, trigger, cadence, location, tags, and ratings.

## First Technical Proof

```text
getBestFormat(userSignal) -> TranslationFormat
HierarchicalWinSignal -> MindMapFormat
```

This proves that Re_Call can preserve answer shape instead of defaulting to generic reminder prose.

## Recommendation Proof

```text
getReminderRecommendations(input) -> ReminderRecommendationResult
ScanCalendarReminder + PositiveReminderRating -> deeper TimeAwareness recommendations
```

This proves that a useful reminder can reveal an attention pattern or strength, then generate deeper nearby branches instead of broader generic reminders.

## Semantic-Web Direction

The ontology and knowledge graph are not decoration. They preserve enough meaning to create a close approximation of the "picking up where we left off" experience close friends provide.

The goal is:

```text
human-readable notes
+ machine-readable semantic claims
+ RDF/OWL meaning layer
+ governed personal rules
+ constrained AI phrasing
```

The graph should reduce AI hallucination by making the model phrase and explain from known relationships instead of inventing context.

## CCO Spine

Common Core Ontologies can sit underneath the personal Re_Call ontology as an interoperability spine.

The role of CCO is to prevent semantic flattening:

```text
Is this a note?
Is this a claim inside a note?
Is this an event that happened?
Is this a person or agent?
Is this a quality/state?
Is this a reminder/template/rule?
Is this about the thing, or is it the thing?
```

The durable pattern:

```text
Obsidian stays readable.
Notion can track review.
RDF/OWL defines meaning.
CCO/BFO gives stable category backbone.
Re_Call keeps Adam-specific meaning on top.
```

Do not replace the personal ontology with CCO.

## Architecture Spine

```text
Supabase stores app state.
OWL/RDF defines meaning.
Fuseki proves semantic queries.
Vercel orchestrates APIs and agents.
iOS stays clean behind API contracts.
Neo4j may later help with graph intelligence.
```

## Implementation Rule

For recommender and reminder APIs:

```text
Graph first.
LLM second.
User correction becomes a rule.
```

The graph decides eligibility, ranking, constraints, and explanation trace. The language model drafts wording from that trace. The user accepts, rejects, edits, or turns the suggestion into a trusted personal rule.
