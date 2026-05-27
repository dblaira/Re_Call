# API Contract: `getBestFormat(userSignal) -> TranslationFormat`

## Purpose

`getBestFormat` is the first Format Match Engine contract. It chooses the answer shape that best preserves the meaning of a user signal before Re_Call writes reminder copy.

The first proof case is:

```text
HierarchicalWinSignal -> MindMapFormat
```

## Contract

```ts
getBestFormat(userSignal: UserSignal) -> FormatMatchResult
```

### Request

```ts
type UserSignal = {
  type: "HierarchicalWinSignal" | string;
  text?: string;
  source?: "manual" | "reminder_feedback" | "review" | "graph";
  occurredAt?: string;
  metadata?: Record<string, unknown>;
};
```

### Response

```ts
type FormatMatchResult = {
  format: TranslationFormat;
  confidence: "high" | "medium" | "low";
  decision: "semantic-rule-match" | "fallback";
  reason: string;
  matchedRule: null | {
    id: string;
    label: string;
    acceptanceCriterion: string;
    source: {
      kind: "ontology" | "fixture" | "manual";
      path?: string;
      predicate?: string;
    };
  };
  diagnosticQuestion: string;
};

type TranslationFormat = {
  id: "MindMapFormat" | "ReminderCardFormat" | string;
  label: string;
  shape: "mind_map" | "card" | string;
};
```

## First Proof Case

Input:

```json
{
  "type": "HierarchicalWinSignal",
  "text": "The win was building a hierarchy that preserved the advantage of AI while avoiding downside consequences."
}
```

Expected output:

```json
{
  "format": {
    "id": "MindMapFormat",
    "label": "Mind map format",
    "shape": "mind_map"
  },
  "confidence": "high",
  "decision": "semantic-rule-match",
  "diagnosticQuestion": "Is this the best match for describing what just happened?"
}
```

## Deterministic Rule

When `userSignal.type` is `HierarchicalWinSignal`, Re_Call must return `MindMapFormat`.

Reason:

```text
When a win involves hierarchy, use a mind map to preserve structure and reduce styling fixation.
```

## Source Of Truth

The rule is represented in `data/format-match-rules.json` as a portable fixture for the first API proof.

The source ontology triple from the earlier Project_ReCall proof is:

```text
FormatMatchEngineRequirement
  triggeredBySignal HierarchicalWinSignal
  prefersFormat MindMapFormat
```

The contract keeps the API boundary stable while the graph layer evolves from fixture-backed rules to Fuseki or another semantic adapter.

## Acceptance Criteria

- Given a `HierarchicalWinSignal`, the function returns `MindMapFormat`.
- The response includes a plain-English reason that mentions hierarchy.
- The response includes the diagnostic question: `Is this the best match for describing what just happened?`
- Unknown signals return an explicit fallback instead of silently inventing a semantic match.
