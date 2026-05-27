import assert from "node:assert/strict";
import test from "node:test";
import {
  getReminderRecommendations,
  ReminderFeedback,
  ReminderTemplate
} from "../src/reminder-recommendation-engine.js";

test("positive calendar reminder rating recommends deeper nearby reminders from RDF triples", () => {
  const result = getReminderRecommendations({
    templateId: ReminderTemplate.ScanCalendar,
    rating: ReminderFeedback.Positive,
    text: "Scan my calendar before the day starts worked because it helped me see transition stress."
  });

  assert.equal(result.decision, "rdf-graph-match");
  assert.equal(result.confidence, "high");
  assert.equal(result.sourceTemplate.id, "ScanCalendarReminder");
  assert.equal(result.revealedStrengths[0].id, "TimeAwareness");
  assert.match(result.reason, /deeper nearby uses/i);
  assert.equal(result.recommendations.length, 4);
  assert.equal(result.recommendations[0].id, "ScanTomorrowForTransitionStress");
  assert.match(result.recommendations[0].text, /transition stress/i);
  assert.equal(result.recommendations[0].sharedGraphFeatures[0].id, "TimeAwareness");
  assert.equal(result.graphTrace.rankingMethod, "depthScore + shared graph feature overlap + small context boost");
  assert.ok(result.recommendations[0].score > result.recommendations.at(-1).score);
  assert.ok(result.recommendations.every((recommendation) => recommendation.id !== "GenericPlanningReminder"));
  assert.deepEqual(result.graphTrace.matchedRuleIds, ["CalendarDepthRecommendationRule"]);
});

test("unmodeled reminder feedback returns an explicit fallback", () => {
  const result = getReminderRecommendations({
    templateId: ReminderTemplate.ScanCalendar,
    rating: "NegativeReminderRating"
  });

  assert.equal(result.decision, "fallback");
  assert.equal(result.confidence, "low");
  assert.deepEqual(result.recommendations, []);
});
