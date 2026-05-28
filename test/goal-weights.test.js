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
