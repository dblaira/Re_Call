# Personalization Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a personalization layer that re-ranks deeper reminder recommendations per user (learned habit × declared aspiration) and surfaces goal-driven proactive guidance, without ever breaking the deeper-not-broader doctrine.

**Architecture:** Three pure scoring inputs — universal `depthScore` (existing ontology engine), `learnedAffinity` (event-sourced, propagated on a strength graph derived from the ontology), and declared `goalWeight` (leverage/80-20 first). Two channels: reactive re-ranking *within* the revealed strength, and a separate proactive channel where the declared goal leads. The LLM only phrases; Supabase only persists.

**Tech Stack:** Node ESM, `node --test` + `node:assert/strict`, `n3` (RDF store), existing `openai` SDK. No new runtime dependencies for the core (Tasks 1–6).

---

## File Structure

| File | Responsibility |
|---|---|
| `src/ontology-terms.js` (new) | Shared n3 term/lookup helpers (DRY across new modules) |
| `src/strength-graph.js` (new) | Derive weighted strength adjacency + per-template strengths from the ontology |
| `src/user-affinity.js` (new) | Pure: fold signal events → raw affinity → graph-propagated affinity |
| `src/goal-weights.js` (new) | Declared per-strength goal weights (leverage default) |
| `src/personalized-recommendation-engine.js` (new) | Reactive: wrap universal engine, re-rank within deeper set |
| `src/proactive-guidance.js` (new) | Goal-driven ambient nudges with rotation |
| `src/openai-reminder-copy.js` (modify) | Pass personalization context into the copy payload |
| `src/personalization-store.js` (new) | Dependency-injected Supabase repository for events + goal weights |
| `supabase/migrations/*` (new) | `recall.user_strength_events`, `recall.user_goal_weights` |
| `test/*.test.js` (new) | One test file per module |

Existing `src/reminder-recommendation-engine.js` is **not** modified — the personalization engine wraps it. The existing `test/recommendation-stays-deeper.test.js` must stay green throughout.

---

### Task 1: Ontology term helpers + strength graph

**Files:**
- Create: `src/ontology-terms.js`
- Create: `src/strength-graph.js`
- Test: `test/strength-graph.test.js`

- [ ] **Step 1: Write the failing test**

```js
// test/strength-graph.test.js
import assert from "node:assert/strict";
import test from "node:test";
import { buildStrengthAdjacency, templateStrengths } from "../src/strength-graph.js";
import { loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";

test("templateStrengths returns reveals + deepens strengths for a template", () => {
  const store = loadReminderRecommendationStore();
  assert.deepEqual(templateStrengths(store, "ScanCalendarReminder"), ["TimeAwareness"]);
  assert.deepEqual(
    templateStrengths(store, "ClearGoodIdeasForGreatIdea").sort(),
    ["ExecutionLeverage", "LeverageAwareness"]
  );
});

test("buildStrengthAdjacency derives row-normalized neighbors from co-occurrence", () => {
  const { strengths, adjacency } = buildStrengthAdjacency();

  assert.ok(strengths.includes("LeverageAwareness"));
  // TimeAwareness only ever co-occurs with TransitionPreparation -> weight 1
  assert.deepEqual(adjacency.TimeAwareness, { TransitionPreparation: 1 });
  // LeverageAwareness only co-occurs with ExecutionLeverage -> weight 1
  assert.deepEqual(adjacency.LeverageAwareness, { ExecutionLeverage: 1 });
  // ExecutionLeverage co-occurs with LeverageAwareness (2) and EvidenceTrust (1)
  assert.ok(Math.abs(adjacency.ExecutionLeverage.LeverageAwareness - 2 / 3) < 1e-9);
  assert.ok(Math.abs(adjacency.ExecutionLeverage.EvidenceTrust - 1 / 3) < 1e-9);
  // every row sums to 1 (or is empty)
  for (const row of Object.values(adjacency)) {
    const total = Object.values(row).reduce((s, n) => s + n, 0);
    assert.ok(total === 0 || Math.abs(total - 1) < 1e-9);
  }
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/strength-graph.test.js`
Expected: FAIL — `Cannot find module '../src/strength-graph.js'`.

- [ ] **Step 3: Write the helpers and the graph builder**

```js
// src/ontology-terms.js
import { DataFactory } from "n3";

const { namedNode } = DataFactory;

export const RECALL = "https://understood.app/ontology/project-recall#";
export const term = (id) => namedNode(`${RECALL}${id}`);
export const localName = (node) => node.value.replace(RECALL, "");

export function objects(store, subjectTerm, predicate) {
  return store.getObjects(subjectTerm, term(predicate), null);
}

export function literal(store, subjectTerm, predicate) {
  return objects(store, subjectTerm, predicate)[0]?.value ?? "";
}

export function decimal(store, subjectTerm, predicate) {
  return Number.parseFloat(literal(store, subjectTerm, predicate) || "0");
}
```

```js
// src/strength-graph.js
import { loadReminderRecommendationStore } from "./reminder-recommendation-engine.js";
import { RECALL, term, localName, objects } from "./ontology-terms.js";

const STRENGTH_PREDICATES = ["revealsStrength", "deepensStrength"];

export function templateStrengths(store, templateId) {
  const subject = term(templateId);
  const found = new Set();
  for (const predicate of STRENGTH_PREDICATES) {
    for (const object of objects(store, subject, predicate)) {
      found.add(localName(object));
    }
  }
  return [...found];
}

export function buildStrengthAdjacency(store = loadReminderRecommendationStore()) {
  const cooccur = {};
  const strengthSet = new Set();
  const templateIris = new Set();

  for (const predicate of STRENGTH_PREDICATES) {
    for (const quad of store.getQuads(null, term(predicate), null, null)) {
      templateIris.add(quad.subject.value);
    }
  }

  for (const iri of templateIris) {
    const ids = templateStrengths(store, iri.replace(RECALL, ""));
    ids.forEach((id) => strengthSet.add(id));
    for (let i = 0; i < ids.length; i++) {
      for (let j = i + 1; j < ids.length; j++) {
        bump(cooccur, ids[i], ids[j]);
        bump(cooccur, ids[j], ids[i]);
      }
    }
  }

  const adjacency = {};
  for (const id of strengthSet) {
    const row = cooccur[id] || {};
    const total = Object.values(row).reduce((sum, n) => sum + n, 0);
    adjacency[id] = {};
    if (total > 0) {
      for (const [neighbor, count] of Object.entries(row)) {
        adjacency[id][neighbor] = count / total;
      }
    }
  }

  return { strengths: [...strengthSet], adjacency };
}

function bump(cooccur, a, b) {
  cooccur[a] = cooccur[a] || {};
  cooccur[a][b] = (cooccur[a][b] || 0) + 1;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/strength-graph.test.js`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add src/ontology-terms.js src/strength-graph.js test/strength-graph.test.js
git commit -m "Add strength graph derived from ontology co-occurrence

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: User affinity (event-sourced + graph propagation)

**Files:**
- Create: `src/user-affinity.js`
- Test: `test/user-affinity.test.js`

- [ ] **Step 1: Write the failing test**

```js
// test/user-affinity.test.js
import assert from "node:assert/strict";
import test from "node:test";
import {
  expandSignalToEvents,
  foldRawAffinity,
  computeAffinity
} from "../src/user-affinity.js";
import { buildStrengthAdjacency } from "../src/strength-graph.js";
import { loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";

test("expandSignalToEvents creates one event per touched strength carrying the signal type", () => {
  const store = loadReminderRecommendationStore();
  const events = expandSignalToEvents(
    { templateId: "ClearGoodIdeasForGreatIdea", signalType: "edit" },
    store
  );
  assert.equal(events.length, 2);
  assert.deepEqual(events.map((e) => e.strengthId).sort(), ["ExecutionLeverage", "LeverageAwareness"]);
  // Events carry the durable signal_type, not a frozen numeric delta.
  assert.ok(events.every((e) => e.signalType === "edit"));
  assert.ok(events.every((e) => !("delta" in e)));
});

test("foldRawAffinity starts neutral at 1.0 and adds the config delta for each signal type", () => {
  const raw = foldRawAffinity(
    [{ strengthId: "ExecutionLeverage", signalType: "edit" }],
    ["ExecutionLeverage", "TimeAwareness"]
  );
  assert.ok(Math.abs(raw.ExecutionLeverage - 1.3) < 1e-9); // edit delta = 0.3
  assert.ok(Math.abs(raw.TimeAwareness - 1.0) < 1e-9);
});

test("propagation lifts graph neighbors but not non-neighbors", () => {
  const { adjacency, strengths } = buildStrengthAdjacency();
  const baseline = computeAffinity([], { adjacency, strengths });
  const bumped = computeAffinity(
    [{ strengthId: "LeverageAwareness", signalType: "edit" }],
    { adjacency, strengths }
  );
  // ExecutionLeverage is a graph neighbor of LeverageAwareness -> rises
  assert.ok(bumped.ExecutionLeverage > baseline.ExecutionLeverage);
  // TimeAwareness is NOT a neighbor of LeverageAwareness -> unchanged
  assert.ok(Math.abs(bumped.TimeAwareness - baseline.TimeAwareness) < 1e-9);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/user-affinity.test.js`
Expected: FAIL — `Cannot find module '../src/user-affinity.js'`.

- [ ] **Step 3: Write the implementation**

```js
// src/user-affinity.js
import { templateStrengths } from "./strength-graph.js";

export const SIGNAL_DELTAS = Object.freeze({
  edit: 0.3,      // user rewrote a template into a custom version (strongest)
  positive: 0.15, // positive rating
  accept: 0.1,    // accepted a recommendation
  dismiss: -0.1   // dismissed / skipped
});

export const NEUTRAL_AFFINITY = 1.0;
export const DEFAULT_SPREAD = 0.3;

export function expandSignalToEvents({ templateId, signalType }, store) {
  if (SIGNAL_DELTAS[signalType] === undefined) {
    throw new Error(`Unknown signal type: ${signalType}`);
  }
  // Events carry the durable signal type, never the numeric delta. The delta is derived
  // from SIGNAL_DELTAS at compute time so re-tuning a weight re-scores all history.
  return templateStrengths(store, templateId).map((strengthId) => ({
    strengthId,
    signalType,
    templateId
  }));
}

export function foldRawAffinity(events, strengths = []) {
  const raw = {};
  for (const id of strengths) {
    raw[id] = NEUTRAL_AFFINITY;
  }
  for (const event of events) {
    const delta = SIGNAL_DELTAS[event.signalType];
    if (delta === undefined) {
      throw new Error(`Unknown signal type: ${event.signalType}`);
    }
    if (!(event.strengthId in raw)) {
      raw[event.strengthId] = NEUTRAL_AFFINITY;
    }
    raw[event.strengthId] += delta;
  }
  return raw;
}

export function propagateAffinity(raw, adjacency, spread = DEFAULT_SPREAD) {
  const propagated = {};
  for (const [id, value] of Object.entries(raw)) {
    let neighborSum = 0;
    for (const [neighbor, weight] of Object.entries(adjacency[id] || {})) {
      neighborSum += weight * (raw[neighbor] ?? NEUTRAL_AFFINITY);
    }
    propagated[id] = value + spread * neighborSum;
  }
  return propagated;
}

export function computeAffinity(events, { adjacency, strengths, spread = DEFAULT_SPREAD }) {
  const raw = foldRawAffinity(events, strengths);
  return propagateAffinity(raw, adjacency, spread);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/user-affinity.test.js`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add src/user-affinity.js test/user-affinity.test.js
git commit -m "Add event-sourced user affinity with graph propagation

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Declared goal weights

**Files:**
- Create: `src/goal-weights.js`
- Test: `test/goal-weights.test.js`

- [ ] **Step 1: Write the failing test**

```js
// test/goal-weights.test.js
import assert from "node:assert/strict";
import test from "node:test";
import { DEFAULT_GOAL_WEIGHT, goalWeightFor, LEVERAGE_GOAL_WEIGHTS } from "../src/goal-weights.js";

test("goalWeightFor returns the declared weight or the default", () => {
  assert.equal(goalWeightFor(LEVERAGE_GOAL_WEIGHTS, "LeverageAwareness"), 3);
  assert.equal(goalWeightFor(LEVERAGE_GOAL_WEIGHTS, "TimeAwareness"), DEFAULT_GOAL_WEIGHT);
  assert.equal(goalWeightFor(undefined, "Anything"), DEFAULT_GOAL_WEIGHT);
});

test("leverage / 80-20 is the first user's top priority", () => {
  assert.equal(LEVERAGE_GOAL_WEIGHTS.LeverageAwareness, 3);
  assert.equal(LEVERAGE_GOAL_WEIGHTS.ExecutionLeverage, 3);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/goal-weights.test.js`
Expected: FAIL — `Cannot find module '../src/goal-weights.js'`.

- [ ] **Step 3: Write the implementation**

```js
// src/goal-weights.js
export const DEFAULT_GOAL_WEIGHT = 1.0;

export function goalWeightFor(goalWeights, strengthId) {
  return goalWeights?.[strengthId] ?? DEFAULT_GOAL_WEIGHT;
}

// First user's declared aspiration: live more by the 80/20 (leverage) principle.
export const LEVERAGE_GOAL_WEIGHTS = Object.freeze({
  LeverageAwareness: 3.0,
  ExecutionLeverage: 3.0
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/goal-weights.test.js`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add src/goal-weights.js test/goal-weights.test.js
git commit -m "Add declared goal weights with leverage as first-user priority

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Reactive personalized recommendation engine

**Files:**
- Create: `src/personalized-recommendation-engine.js`
- Test: `test/personalized-recommendation-engine.test.js`

- [ ] **Step 1: Write the failing test**

```js
// test/personalized-recommendation-engine.test.js
import assert from "node:assert/strict";
import test from "node:test";
import { getPersonalizedRecommendations } from "../src/personalized-recommendation-engine.js";
import { buildStrengthAdjacency } from "../src/strength-graph.js";
import { expandSignalToEvents } from "../src/user-affinity.js";
import { loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";

const store = loadReminderRecommendationStore();
const { adjacency, strengths } = buildStrengthAdjacency(store);

function context(events = []) {
  return { events, goalWeights: {}, adjacency, strengths, store };
}

test("with no history, top pick matches the universal depth order", () => {
  const result = getPersonalizedRecommendations(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    context()
  );
  assert.equal(result.personalized, true);
  assert.equal(result.recommendations[0].id, "NameSmallInputAndOutcome");
});

test("strong execution-leverage history re-ranks an execution move to the top", () => {
  // four edits on an ExecutionLeverage-only template
  const events = [];
  for (let i = 0; i < 4; i++) {
    events.push(...expandSignalToEvents(
      { templateId: "AskForVisibleProcessDraft", signalType: "edit" },
      store
    ));
  }
  const result = getPersonalizedRecommendations(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    context(events)
  );
  assert.equal(result.recommendations[0].id, "AskForVisibleProcessDraft");
});

test("personalization never breaks the doctrine: every pick stays deeper", () => {
  const events = expandSignalToEvents(
    { templateId: "AskForVisibleProcessDraft", signalType: "edit" },
    store
  );
  const result = getPersonalizedRecommendations(
    { templateId: "ScanCalendarReminder", rating: "PositiveReminderRating" },
    context(events)
  );
  for (const rec of result.recommendations) {
    assert.ok(rec.sharedGraphFeatures.length >= 1, `${rec.id} is not deeper`);
  }
  assert.ok(result.recommendations.every((r) => r.id !== "GenericPlanningReminder"));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/personalized-recommendation-engine.test.js`
Expected: FAIL — `Cannot find module '../src/personalized-recommendation-engine.js'`.

- [ ] **Step 3: Write the implementation**

```js
// src/personalized-recommendation-engine.js
import { getReminderRecommendations } from "./reminder-recommendation-engine.js";
import { computeAffinity } from "./user-affinity.js";
import { goalWeightFor } from "./goal-weights.js";

export function getPersonalizedRecommendations(input, context = {}) {
  const {
    events = [],
    goalWeights = {},
    adjacency = {},
    strengths = [],
    spread,
    store,
    limit = 4
  } = context;

  // Pull the full universal candidate set first (it is already filtered to
  // "deeper, not broader"), then re-rank within it.
  const universal = getReminderRecommendations(input, { store, limit: 50 });

  if (universal.decision !== "rdf-graph-match") {
    return { ...universal, personalized: false };
  }

  const affinity = computeAffinity(events, { adjacency, strengths, spread });

  const recommendations = universal.recommendations
    .map((rec) => {
      const multiplier = personalMultiplier(rec, affinity, goalWeights);
      return {
        ...rec,
        personalMultiplier: Number(multiplier.toFixed(3)),
        personalScore: Number((rec.score * multiplier).toFixed(3))
      };
    })
    .sort((left, right) => right.personalScore - left.personalScore)
    .slice(0, limit);

  return { ...universal, recommendations, personalized: true };
}

function personalMultiplier(rec, affinity, goalWeights) {
  const ids = rec.deepensStrengths.map((strength) => strength.id);
  if (ids.length === 0) {
    return 1;
  }
  const sum = ids.reduce(
    (acc, id) => acc + (affinity[id] ?? 1) * goalWeightFor(goalWeights, id),
    0
  );
  return sum / ids.length;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/personalized-recommendation-engine.test.js`
Expected: PASS (3 tests).

- [ ] **Step 5: Run the full suite to confirm the doctrine test still passes**

Run: `npm test`
Expected: PASS — including `test/recommendation-stays-deeper.test.js`.

- [ ] **Step 6: Commit**

```bash
git add src/personalized-recommendation-engine.js test/personalized-recommendation-engine.test.js
git commit -m "Add reactive personalized re-ranking within the deeper set

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: Proactive goal-driven guidance

**Files:**
- Create: `src/proactive-guidance.js`
- Test: `test/proactive-guidance.test.js`

- [ ] **Step 1: Write the failing test**

```js
// test/proactive-guidance.test.js
import assert from "node:assert/strict";
import test from "node:test";
import { getProactiveGuidance } from "../src/proactive-guidance.js";
import { LEVERAGE_GOAL_WEIGHTS } from "../src/goal-weights.js";

test("aspiration beats habit: leverage goal nudges with zero history", () => {
  const result = getProactiveGuidance({ goalWeights: LEVERAGE_GOAL_WEIGHTS });
  assert.equal(result.decision, "goal-guidance");
  assert.deepEqual(result.goalStrengths.sort(), ["ExecutionLeverage", "LeverageAwareness"]);
  // highest depthScore leverage move
  assert.equal(result.nudges[0].id, "NameSmallInputAndOutcome");
});

test("rotation skips recently shown nudges", () => {
  const result = getProactiveGuidance({
    goalWeights: LEVERAGE_GOAL_WEIGHTS,
    recentNudgeIds: ["NameSmallInputAndOutcome"]
  });
  assert.equal(result.nudges[0].id, "ClearGoodIdeasForGreatIdea");
});

test("no declared priority yields no guidance", () => {
  const result = getProactiveGuidance({ goalWeights: {} });
  assert.equal(result.decision, "no-goal");
  assert.deepEqual(result.nudges, []);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/proactive-guidance.test.js`
Expected: FAIL — `Cannot find module '../src/proactive-guidance.js'`.

- [ ] **Step 3: Write the implementation**

```js
// src/proactive-guidance.js
import { loadReminderRecommendationStore } from "./reminder-recommendation-engine.js";
import { term, localName, literal, decimal } from "./ontology-terms.js";
import { DEFAULT_GOAL_WEIGHT } from "./goal-weights.js";

export function getProactiveGuidance({
  goalWeights = {},
  store = loadReminderRecommendationStore(),
  recentNudgeIds = [],
  limit = 1
} = {}) {
  const goalStrengths = topGoalStrengths(goalWeights);
  if (goalStrengths.length === 0) {
    return { decision: "no-goal", goalStrengths: [], nudges: [] };
  }

  const all = templatesDeepening(store, goalStrengths).sort(
    (left, right) => right.depthScore - left.depthScore
  );
  const fresh = all.filter((candidate) => !recentNudgeIds.includes(candidate.id));
  const pool = fresh.length > 0 ? fresh : all; // rotation reset once all shown

  const nudges = pool.slice(0, limit).map((candidate) => ({
    ...candidate,
    reason: `Guiding you toward your priority: ${goalStrengths.join(", ")}.`
  }));

  return { decision: "goal-guidance", goalStrengths, nudges };
}

function topGoalStrengths(goalWeights) {
  const entries = Object.entries(goalWeights || {});
  if (entries.length === 0) {
    return [];
  }
  const max = Math.max(...entries.map(([, weight]) => weight));
  if (max <= DEFAULT_GOAL_WEIGHT) {
    return [];
  }
  return entries.filter(([, weight]) => weight === max).map(([id]) => id);
}

function templatesDeepening(store, strengthIds) {
  const wanted = new Set(strengthIds);
  const seen = new Set();
  const result = [];
  for (const quad of store.getQuads(null, term("deepensStrength"), null, null)) {
    if (!wanted.has(localName(quad.object))) {
      continue;
    }
    const id = localName(quad.subject);
    if (seen.has(id)) {
      continue;
    }
    seen.add(id);
    result.push({
      id,
      text: literal(store, quad.subject, "templateText"),
      depthScore: decimal(store, quad.subject, "depthScore")
    });
  }
  return result;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/proactive-guidance.test.js`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add src/proactive-guidance.js test/proactive-guidance.test.js
git commit -m "Add proactive goal-driven guidance channel with rotation

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Make the LLM copy layer personalization-aware

**Files:**
- Modify: `src/openai-reminder-copy.js:69-84` (the `toCopyPromptPayload` function) and `src/openai-reminder-copy.js:29-34` (the developer prompt lines)
- Test: `test/openai-reminder-copy.test.js`

The copy drafter only *phrases* — it must not reorder. This task surfaces the per-user
ranking signals in the payload so the model can explain *why* a pick fits this person,
and adds one instruction line. It is tested with an injected fake client (no network).

- [ ] **Step 1: Write the failing test**

```js
// test/openai-reminder-copy.test.js
import assert from "node:assert/strict";
import test from "node:test";
import { draftReminderRecommendationCopy } from "../src/openai-reminder-copy.js";

function fakeClient(capture) {
  return {
    responses: {
      create: async (request) => {
        capture.request = request;
        return { output_text: '{"title":"t","body":"b","why":"w","variants":[]}' };
      }
    }
  };
}

test("copy payload carries personalization signals when present", async () => {
  const capture = {};
  const graphResult = {
    decision: "rdf-graph-match",
    personalized: true,
    sourceTemplate: { id: "FindLeveragePointReminder", label: "x", iri: "y", comment: "" },
    revealedStrengths: [],
    recommendations: [
      {
        id: "AskForVisibleProcessDraft",
        text: "Ask for the full ordered draft.",
        score: 0.95,
        personalScore: 2.375,
        personalMultiplier: 2.5,
        sharedGraphFeatures: [{ id: "ExecutionLeverage" }],
        deepensStrengths: [{ id: "ExecutionLeverage" }]
      }
    ],
    reason: "r",
    graphTrace: {}
  };

  const result = await draftReminderRecommendationCopy(graphResult, { client: fakeClient(capture) });

  assert.equal(result.parsed.title, "t");
  const userText = capture.request.input.find((m) => m.role === "user").content[0].input_text;
  const payload = JSON.parse(userText);
  assert.equal(payload.personalized, true);
  assert.equal(payload.recommendations[0].personalScore, 2.375);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/openai-reminder-copy.test.js`
Expected: FAIL — `payload.personalized` is `undefined` (current payload omits it).

- [ ] **Step 3: Edit `toCopyPromptPayload` to include personalization signals**

Replace the body of `toCopyPromptPayload` (currently `src/openai-reminder-copy.js:69-84`) with:

```js
function toCopyPromptPayload(graphResult) {
  return {
    decision: graphResult.decision,
    personalized: graphResult.personalized ?? false,
    sourceTemplate: graphResult.sourceTemplate,
    revealedStrengths: graphResult.revealedStrengths,
    recommendations: graphResult.recommendations.map((recommendation) => ({
      id: recommendation.id,
      text: recommendation.text,
      score: recommendation.score,
      personalScore: recommendation.personalScore,
      personalMultiplier: recommendation.personalMultiplier,
      sharedGraphFeatures: recommendation.sharedGraphFeatures,
      deepensStrengths: recommendation.deepensStrengths
    })),
    reason: graphResult.reason,
    graphTrace: graphResult.graphTrace
  };
}
```

- [ ] **Step 4: Add one instruction line to the developer prompt**

In the developer-role `text` array (currently `src/openai-reminder-copy.js:29-34`), add this string as a new array element after the "Use calm iOS reminder language..." line:

```js
"When personalized is true, the order reflects this user's own priorities; reflect that in 'why' without inventing scores.",
```

- [ ] **Step 5: Run test to verify it passes**

Run: `node --test test/openai-reminder-copy.test.js`
Expected: PASS (1 test).

- [ ] **Step 6: Commit**

```bash
git add src/openai-reminder-copy.js test/openai-reminder-copy.test.js
git commit -m "Surface personalization signals in reminder copy payload

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: Supabase persistence (schema + DI repository)

**Files:**
- Create: `supabase/migrations/20260528120000_add_personalization_tables.sql`
- Create: `src/personalization-store.js`
- Modify: `supabase/migrations/README.md` (append the new migration to the list)
- Test: `test/personalization-store.test.js`

The repository is dependency-injected: callers pass a `db` object exposing the two
methods used below, so it is unit-tested with a fake and stays decoupled from any specific
Supabase SDK. Wiring a live Supabase client into the Vercel/edge entry points is follow-up
work, noted in "Out of scope."

- [ ] **Step 1: Write the migration SQL**

```sql
-- supabase/migrations/20260528120000_add_personalization_tables.sql
create table if not exists recall.user_strength_events (
  id             bigint generated always as identity primary key,
  user_id        uuid not null,
  strength_id    text not null,
  signal_type    text not null,
  template_id    text,
  config_version text not null default 'v1',
  created_at     timestamptz not null default now()
);
-- The numeric delta is intentionally NOT stored: it is derived from the signal-delta
-- config at compute time, so re-tuning weights re-scores history without migrating rows.
-- config_version records which delta config a row was written under, for auditability.

create index if not exists user_strength_events_user_idx
  on recall.user_strength_events (user_id, created_at);

create table if not exists recall.user_goal_weights (
  user_id      uuid not null,
  strength_id  text not null,
  weight       numeric not null default 1.0,
  updated_at   timestamptz not null default now(),
  primary key (user_id, strength_id)
);
```

- [ ] **Step 2: Append the migration to the migrations README**

Add this bullet to the list in `supabase/migrations/README.md`:

```markdown
- `20260528120000_add_personalization_tables` — `recall.user_strength_events` and `recall.user_goal_weights` for the personalization layer
```

- [ ] **Step 3: Write the failing test**

```js
// test/personalization-store.test.js
import assert from "node:assert/strict";
import test from "node:test";
import { recordSignal, loadUserAffinityInputs } from "../src/personalization-store.js";
import { loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";

function fakeDb() {
  const events = [];
  const goalWeights = [
    { user_id: "u1", strength_id: "LeverageAwareness", weight: 3 },
    { user_id: "u1", strength_id: "ExecutionLeverage", weight: 3 }
  ];
  return {
    rows: { events, goalWeights },
    insertEvents: async (toInsert) => { events.push(...toInsert); },
    selectEvents: async (userId) => events.filter((e) => e.user_id === userId),
    selectGoalWeights: async (userId) => goalWeights.filter((g) => g.user_id === userId)
  };
}

test("recordSignal expands a signal into per-strength rows and inserts them", async () => {
  const db = fakeDb();
  const store = loadReminderRecommendationStore();
  await recordSignal(db, {
    userId: "u1",
    templateId: "ClearGoodIdeasForGreatIdea",
    signalType: "edit"
  }, store);
  assert.equal(db.rows.events.length, 2);
  assert.ok(db.rows.events.every((e) => e.user_id === "u1" && e.signal_type === "edit"));
});

test("loadUserAffinityInputs returns events and a goalWeights map", async () => {
  const db = fakeDb();
  const store = loadReminderRecommendationStore();
  await recordSignal(db, { userId: "u1", templateId: "AskForVisibleProcessDraft", signalType: "accept" }, store);

  const { events, goalWeights } = await loadUserAffinityInputs(db, "u1");
  assert.equal(events.length, 1);
  assert.equal(events[0].strengthId, "ExecutionLeverage");
  assert.equal(events[0].signalType, "accept");
  assert.equal(goalWeights.LeverageAwareness, 3);
});
```

- [ ] **Step 4: Run test to verify it fails**

Run: `node --test test/personalization-store.test.js`
Expected: FAIL — `Cannot find module '../src/personalization-store.js'`.

- [ ] **Step 5: Write the repository**

```js
// src/personalization-store.js
import { expandSignalToEvents } from "./user-affinity.js";

// `db` is injected and must provide:
//   insertEvents(rows)        -> Promise<void>
//   selectEvents(userId)      -> Promise<Array<{ strength_id, signal_type, template_id }>>
//   selectGoalWeights(userId) -> Promise<Array<{ strength_id, weight }>>
export async function recordSignal(db, { userId, templateId, signalType }, store) {
  const expanded = expandSignalToEvents({ templateId, signalType }, store);
  const rows = expanded.map((event) => ({
    user_id: userId,
    strength_id: event.strengthId,
    signal_type: event.signalType,
    template_id: event.templateId
  }));
  await db.insertEvents(rows);
  return rows;
}

export async function loadUserAffinityInputs(db, userId) {
  const [eventRows, goalRows] = await Promise.all([
    db.selectEvents(userId),
    db.selectGoalWeights(userId)
  ]);

  const events = eventRows.map((row) => ({
    strengthId: row.strength_id,
    signalType: row.signal_type,
    templateId: row.template_id
  }));

  const goalWeights = {};
  for (const row of goalRows) {
    goalWeights[row.strength_id] = Number(row.weight);
  }

  return { events, goalWeights };
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `node --test test/personalization-store.test.js`
Expected: PASS (2 tests).

- [ ] **Step 7: Apply the migration to the remote project**

The local Supabase CLI is not installed (see `supabase/migrations/README.md`). Apply the
SQL from Step 1 through the Supabase connector / MCP `apply_migration` against project
`vzaceoipwimphdvdxcpa`, then verify with:

```sql
select table_name from information_schema.tables
where table_schema = 'recall'
  and table_name in ('user_strength_events', 'user_goal_weights');
```
Expected: both rows returned.

- [ ] **Step 8: Commit**

```bash
git add src/personalization-store.js test/personalization-store.test.js \
        supabase/migrations/20260528120000_add_personalization_tables.sql \
        supabase/migrations/README.md
git commit -m "Add Supabase persistence for personalization signals and goals

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 8: Wire the layer together and document it

**Files:**
- Modify: `src/recommender-stack.js` (add a personalized entry point)
- Modify: `README.md` (add pointers under the implementation list)
- Test: `test/recommender-stack.test.js` (extend)

- [ ] **Step 1: Write the failing test**

```js
// test/recommender-stack.test.js  (add this test; keep existing ones)
import assert from "node:assert/strict";
import test from "node:test";
import { getPersonalizedRecommendationStack } from "../src/recommender-stack.js";
import { LEVERAGE_GOAL_WEIGHTS } from "../src/goal-weights.js";

test("personalized stack returns a personalized graph and skips copy without a key", async () => {
  const result = await getPersonalizedRecommendationStack(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    { goalWeights: LEVERAGE_GOAL_WEIGHTS, events: [], draftCopy: false }
  );
  assert.equal(result.graph.personalized, true);
  assert.equal(result.copyStatus, "skipped");
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/recommender-stack.test.js`
Expected: FAIL — `getPersonalizedRecommendationStack` is not exported.

- [ ] **Step 3: Add the personalized entry point to `recommender-stack.js`**

Add these imports at the top of `src/recommender-stack.js`:

```js
import { getPersonalizedRecommendations } from "./personalized-recommendation-engine.js";
import { buildStrengthAdjacency } from "./strength-graph.js";
```

Add this exported function below the existing `getReminderRecommendationStack`:

```js
export async function getPersonalizedRecommendationStack(input, options = {}) {
  const { strengths, adjacency } = buildStrengthAdjacency(options.store);
  const graph = getPersonalizedRecommendations(input, {
    events: options.events,
    goalWeights: options.goalWeights,
    adjacency,
    strengths,
    store: options.store,
    limit: options.limit
  });

  if (options.draftCopy === false) {
    return { graph, copy: null, copyStatus: "skipped" };
  }

  if (!options.client && !options.apiKey && !process.env.OPENAI_API_KEY) {
    return { graph, copy: null, copyStatus: "missing-openai-api-key" };
  }

  const copy = await draftReminderRecommendationCopy(graph, {
    client: options.client,
    apiKey: options.apiKey,
    model: options.model,
    tier: options.tier,
    modelPolicy: options.modelPolicy,
    needsHardReasoning: options.needsHardReasoning,
    maxOutputTokens: options.maxOutputTokens
  });

  return { graph, copy, copyStatus: "drafted" };
}
```

- [ ] **Step 4: Run the full suite**

Run: `npm test`
Expected: PASS — all test files, including `test/recommendation-stays-deeper.test.js`.

- [ ] **Step 5: Add README pointers**

Under the implementation bullet list in `README.md`, add:

```markdown
- [Strength graph](./src/strength-graph.js)
- [User affinity](./src/user-affinity.js)
- [Personalized recommendation engine](./src/personalized-recommendation-engine.js)
- [Proactive guidance](./src/proactive-guidance.js)
- [Personalization design spec](./docs/design/2026-05-28-personalization-layer-design.md)
```

- [ ] **Step 6: Commit**

```bash
git add src/recommender-stack.js test/recommender-stack.test.js README.md
git commit -m "Wire personalized recommendation stack and document it

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Out of scope (deferred to a follow-up plan)

- Wiring a live Supabase client (`@supabase/supabase-js` or the edge runtime client) into
  `api/recommendations.js` / `supabase/functions/recommendations` — Task 7 ships a DI
  repository and the schema; the live adapter is separate.
- Multi-hop diffusion beyond one propagation step (personalized PageRank).
- Learned/decaying goal weights — goal weights stay declared and fixed for now.
- Explicit `recall:relatedStrength` ontology edges — adjacency stays derived.
- Frequency/timing budget for *when* to deliver proactive nudges — `getProactiveGuidance`
  supplies the next nudge and rotation; scheduling cadence is a caller/UI concern.
