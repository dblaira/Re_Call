# Re_Call

Re_Call is a personalized transition and meaning-recovery system.

The first working insight from the project:

> The reminder is not the product. The reminder is the delivery mechanism. The product is a personalization system that helps a user notice the right moment, interpret it in the right format, and build better custom reminders from there.

## Current Product Thesis

Re_Call succeeds when a template triggers the user to personalize it.

The ideal reaction is:

> Interesting. I like these templates, but I have a better custom version for my life.

## Current Architecture Spine

- Supabase stores app truth.
- OWL/RDF defines meaning.
- Fuseki/Jena proves semantic-web queries.
- Neo4j may power graph intelligence later.
- Vercel orchestrates APIs and agents.
- iOS stays clean behind API contracts.

## Familiar Stack Direction

This project can grow along the same path as `understood-app`: Next.js App Router, TypeScript, Tailwind CSS, Supabase/Postgres, Anthropic API, Vercel, and Playwright. The current repo starts smaller on purpose: a deterministic contract, fixture-backed rules, ontology notes, and a phone-flow wireframe.

## Next Technical Starting Point

Two first API contracts are now defined:

```text
getBestFormat(userSignal) -> TranslationFormat
getReminderRecommendations(input) -> ReminderRecommendationResult
```

First proof case:

```text
HierarchicalWinSignal -> MindMapFormat
ScanCalendarReminder + PositiveReminderRating -> deeper TimeAwareness recommendations
```

See:

- [Product doctrine](./docs/product/personalization-system-doctrine.md)
- [API contract: getBestFormat](./docs/api/get-best-format.md)
- [API contract: getReminderRecommendations](./docs/api/get-reminder-recommendations.md)
- [Rule fixture](./data/format-match-rules.json)
- [Implementation](./src/format-match-engine.js)
- [Recommendation implementation](./src/reminder-recommendation-engine.js)
- [OpenAI copy layer](./src/openai-reminder-copy.js)
- [Practical recommender stack](./src/recommender-stack.js)
- [Strength graph](./src/strength-graph.js)
- [User affinity](./src/user-affinity.js)
- [Personalized recommendation engine](./src/personalized-recommendation-engine.js)
- [Proactive guidance](./src/proactive-guidance.js)
- [Personalization design spec](./docs/design/2026-05-28-personalization-layer-design.md)
- [Proof test](./test/format-match-engine.test.js)
- [Recommendation proof test](./test/reminder-recommendation-engine.test.js)

Run the proof:

```bash
npm test
```

## Chat Capture

See:

[Project chat capture - 2026-05-25](./docs/project-chat-capture-2026-05-25.md)
