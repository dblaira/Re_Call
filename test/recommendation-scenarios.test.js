import assert from "node:assert/strict";
import test from "node:test";
import { getReminderRecommendations, loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";
import { getPersonalizedRecommendations } from "../src/personalized-recommendation-engine.js";
import { buildStrengthAdjacency } from "../src/strength-graph.js";
import { expandSignalToEvents } from "../src/user-affinity.js";
import { LEVERAGE_GOAL_WEIGHTS } from "../src/goal-weights.js";

const store = loadReminderRecommendationStore();
const { adjacency, strengths } = buildStrengthAdjacency(store);

function personalizedContext(events = [], goalWeights = {}) {
  return { events, goalWeights, adjacency, strengths, store };
}

// Each trigger template maps to one ontology rule and a known universal top pick.
const UNIVERSAL_TOP_PICKS = [
  { templateId: "ScanCalendarReminder", topPick: "ScanTomorrowForTransitionStress" },
  { templateId: "FindLeveragePointReminder", topPick: "NameSmallInputAndOutcome" },
  { templateId: "ChooseCommunicationFormatReminder", topPick: "ConvertAbstractTalkToInspectableShape" },
  { templateId: "HabitStackGymReminder", topPick: "FoamRollFiveByFive" },
  { templateId: "TranslateAIWeekReminder", topPick: "StandingAIDigestGesture" },
  { templateId: "CaptureMacBookUnlocksReminder", topPick: "TwoWeekVerdictLedger" },
  { templateId: "NameMeaningfulSourceReminder", topPick: "ScheduleElectrifyingSource" },
  { templateId: "PostRunBodyDiscoveryReminder", topPick: "MapLowToHighLine" }
];

for (const { templateId, topPick } of UNIVERSAL_TOP_PICKS) {
  test(`universal: ${templateId} ranks ${topPick} first`, () => {
    const result = getReminderRecommendations(
      { templateId, rating: "PositiveReminderRating" },
      { store, limit: 1 }
    );
    assert.equal(result.decision, "rdf-graph-match");
    assert.equal(result.recommendations[0].id, topPick);
  });
}

test("context boost: transition language lifts transition-stress reminder", () => {
  const baseline = getReminderRecommendations(
    { templateId: "ScanCalendarReminder", rating: "PositiveReminderRating" },
    { store, limit: 5 }
  );
  const boosted = getReminderRecommendations(
    {
      templateId: "ScanCalendarReminder",
      rating: "PositiveReminderRating",
      text: "I need help with transition stress between meetings"
    },
    { store, limit: 5 }
  );

  const baselineTop = baseline.recommendations[0];
  const boostedTop = boosted.recommendations[0];

  assert.equal(baselineTop.id, "ScanTomorrowForTransitionStress");
  assert.equal(boostedTop.id, "ScanTomorrowForTransitionStress");
  assert.ok(boostedTop.score > baselineTop.score, "context should add +0.03 boost");
  assert.ok(Math.abs(boostedTop.score - baselineTop.score - 0.03) < 0.001);
});

test("personalization: repeated edits on execution leverage flip the top pick", () => {
  const events = [];
  for (let i = 0; i < 4; i++) {
    events.push(
      ...expandSignalToEvents({ templateId: "AskForVisibleProcessDraft", signalType: "edit" }, store)
    );
  }

  const universal = getReminderRecommendations(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    { store, limit: 3 }
  );
  const personalized = getPersonalizedRecommendations(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    personalizedContext(events)
  );

  assert.equal(universal.recommendations[0].id, "NameSmallInputAndOutcome");
  assert.equal(personalized.recommendations[0].id, "AskForVisibleProcessDraft");
  assert.ok(personalized.recommendations[0].personalScore > universal.recommendations[0].score);
});

test("goal weights: leverage aspiration lifts leverage templates without history", () => {
  const neutral = getPersonalizedRecommendations(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    personalizedContext()
  );
  const aspirational = getPersonalizedRecommendations(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    personalizedContext([], LEVERAGE_GOAL_WEIGHTS)
  );

  // Universal order is unchanged at cold start without events.
  assert.deepEqual(
    neutral.recommendations.map((r) => r.id),
    aspirational.recommendations.map((r) => r.id)
  );

  // But multipliers reflect declared leverage priority.
  const leveragePick = aspirational.recommendations.find((r) => r.id === "NameSmallInputAndOutcome");
  assert.ok(leveragePick.personalMultiplier > 1, "leverage goal weight should amplify leverage strengths");
});

test("negative feedback: unmodeled rating returns explicit fallback", () => {
  const result = getReminderRecommendations(
    { templateId: "ScanCalendarReminder", rating: "NegativeReminderRating" },
    { store }
  );
  assert.equal(result.decision, "fallback");
  assert.deepEqual(result.recommendations, []);
});

test("every universal pick shares at least one revealed strength with its source", () => {
  for (const { templateId } of UNIVERSAL_TOP_PICKS) {
    const result = getReminderRecommendations(
      { templateId, rating: "PositiveReminderRating" },
      { store, limit: 4 }
    );
    for (const rec of result.recommendations) {
      assert.ok(
        rec.sharedGraphFeatures.length >= 1,
        `${templateId} → ${rec.id} violates deeper-not-broader doctrine`
      );
    }
  }
});
