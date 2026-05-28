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
