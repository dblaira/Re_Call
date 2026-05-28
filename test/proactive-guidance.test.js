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

test("rotation resets to the full pool once every nudge has been shown", () => {
  const allIds = [
    "NameSmallInputAndOutcome",
    "ClearGoodIdeasForGreatIdea",
    "AskForVisibleProcessDraft",
    "FindBottleneckBlockingOutcomes",
    "DefineSmallestProofTest"
  ];
  const result = getProactiveGuidance({
    goalWeights: LEVERAGE_GOAL_WEIGHTS,
    recentNudgeIds: allIds
  });
  // All recently shown -> reset to the full ranked pool rather than returning nothing.
  assert.equal(result.decision, "goal-guidance");
  assert.equal(result.nudges[0].id, "NameSmallInputAndOutcome");
});

test("limit larger than the pool returns the whole pool without undefined entries", () => {
  const result = getProactiveGuidance({
    goalWeights: LEVERAGE_GOAL_WEIGHTS,
    limit: 99
  });
  assert.ok(result.nudges.length > 0);
  assert.ok(result.nudges.length <= 5);
  assert.ok(result.nudges.every((n) => n && typeof n.id === "string"));
});
