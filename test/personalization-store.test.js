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
