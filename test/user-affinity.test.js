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

test("unknown signal types are rejected", () => {
  const store = loadReminderRecommendationStore();
  assert.throws(
    () => expandSignalToEvents({ templateId: "ScanCalendarReminder", signalType: "bogus" }, store),
    /Unknown signal type: bogus/
  );
  assert.throws(
    () => foldRawAffinity([{ strengthId: "TimeAwareness", signalType: "bogus" }], ["TimeAwareness"]),
    /Unknown signal type: bogus/
  );
});
