import assert from "node:assert/strict";
import test from "node:test";
import { getPersonalizedRecommendations } from "../src/personalized-recommendation-engine.js";
import { buildStrengthAdjacency } from "../src/strength-graph.js";
import { expandSignalToEvents } from "../src/user-affinity.js";
import { loadReminderRecommendationStore, getReminderRecommendations } from "../src/reminder-recommendation-engine.js";

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
  const universal = getReminderRecommendations(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    { store, limit: 4 }
  );
  assert.deepEqual(
    result.recommendations.map((r) => r.id),
    universal.recommendations.map((r) => r.id)
  );
});

test("strong execution-leverage history re-ranks an execution move to the top", () => {
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

test("floor prevents multiplier inversion under heavy dismiss history", () => {
  const events = [];
  for (let i = 0; i < 6; i++) {
    events.push(...expandSignalToEvents(
      { templateId: "AskForVisibleProcessDraft", signalType: "dismiss" },
      store
    ));
  }
  const result = getPersonalizedRecommendations(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    context(events)
  );
  assert.ok(result.recommendations.every((r) => r.personalMultiplier >= 0.05));
  const scores = result.recommendations.map((r) => r.personalScore);
  for (let i = 1; i < scores.length; i++) assert.ok(scores[i] <= scores[i - 1]);
});
