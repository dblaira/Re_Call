# API contract: getReminderRecommendations

## Purpose

Recommend deeper nearby reminder templates from a user-rated reminder.

This is the first Re_Call recommendation algorithm that uses RDF triples as the source of meaning. It implements the product doctrine in [Personalization System Doctrine](../product/personalization-system-doctrine.md): graph first, LLM second, user correction becomes a rule.

The product rule is:

```text
Do not recommend broader reminders in the same category.
Recommend deeper uses of the strength the reminder revealed.
```

## Function

```text
getReminderRecommendations(input) -> ReminderRecommendationResult
```

## Input

```ts
type ReminderRecommendationInput = {
  templateId: string;
  rating: string;
  text?: string;
  context?: string;
  note?: string;
};
```

## Output

```ts
type ReminderRecommendationResult = {
  decision: "rdf-graph-match" | "fallback";
  confidence: "high" | "low";
  sourceTemplate: GraphNode;
  feedback?: GraphNode;
  revealedStrengths: GraphNode[];
  recommendations: ReminderRecommendation[];
  reason: string;
  graphTrace?: {
    matchedRuleIds: string[];
    sourceTriple: string;
    recommendationTriplePattern: string;
    rankingMethod: string;
  };
};
```

## First proof case

```text
ScanCalendarReminder + PositiveReminderRating
-> reveals TimeAwareness
-> recommends deeper time-awareness templates
```

Example recommendation:

```text
Scan tomorrow's calendar for transition stress.
```

## RDF source

The triples live in:

```text
ontology/reminder-recommendation.ttl
```

The proof query is:

```text
ontology/queries/02-reminder-recommendations.rq
```

## Product rule encoded

From the Obsidian/Re_Call note:

```text
Reminder created
-> attention/preference revealed
-> reminder experience rated
-> strength/domain inferred
-> deeper recommendation branch suggested
-> custom reminder created
-> personal rule learned
```

## Linked-data recommender pattern

The ranking follows the linked-data recommender idea from OpenHPI's "Exploratory Search and Recommender Systems":

```text
candidate score = depth score + shared graph feature overlap + small context boost
```

For the first proof case, the shared graph feature is:

```text
ScanCalendarReminder -> revealsStrength -> TimeAwareness
CandidateReminder -> deepensStrength -> TimeAwareness
```

That gives the app an inspectable explanation:

```text
Recommended because the original reminder revealed TimeAwareness and this candidate deepens TimeAwareness.
```

## Practical LLM stack

The recommender stack keeps decisions deterministic and uses OpenAI only for wording:

```text
RDF graph + deterministic rules
-> decide eligibility, ranking, and explanation trace

OpenAI standard tier
-> draft calm user-facing reminder copy from the graph result

OpenAI reasoning tier
-> reserved for ambiguous feedback, rule discovery, or ontology reasoning
```

The default model policy is:

| Tier | Default model | Re_Call use |
|---|---|---|
| tiny | `gpt-5-nano` | fallback labels, tiny rewrites |
| standard | `gpt-5-mini` | normal recommendation copy |
| reasoning | `gpt-5` | hard reasoning only |

Override with environment variables:

```bash
RECALL_OPENAI_TINY_MODEL=gpt-5-nano
RECALL_OPENAI_STANDARD_MODEL=gpt-5-mini
RECALL_OPENAI_REASONING_MODEL=gpt-5
OPENAI_API_KEY=...
```
