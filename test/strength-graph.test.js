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
