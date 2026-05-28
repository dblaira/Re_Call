import assert from "node:assert/strict";
import test from "node:test";
import {
  getReminderRecommendations,
  ReminderFeedback,
  ReminderTemplate
} from "../src/reminder-recommendation-engine.js";

// The product doctrine: recommend DEEPER uses of the strength a reminder revealed,
// never BROADER reminders in the same category.
//
// These tests don't check specific picks (that's what the regression tests do).
// They check that the rule itself is never violated, for every modeled template.

const everyTemplate = Object.values(ReminderTemplate);

for (const templateId of everyTemplate) {
  test(`${templateId}: every recommendation goes deeper, not broader`, () => {
    const result = getReminderRecommendations({
      templateId,
      rating: ReminderFeedback.Positive
    });

    assert.equal(result.decision, "rdf-graph-match");
    assert.ok(result.recommendations.length > 0, "expected at least one recommendation");

    for (const recommendation of result.recommendations) {
      // Deeper = shares at least one of the strengths the source reminder revealed.
      assert.ok(
        recommendation.sharedGraphFeatures.length >= 1,
        `${recommendation.id} shares no strength with ${templateId} — that's a broader pick, not a deeper one`
      );
    }
  });

  test(`${templateId}: never recommends the explicitly-broad template`, () => {
    const result = getReminderRecommendations({
      templateId,
      rating: ReminderFeedback.Positive
    });

    assert.ok(
      result.recommendations.every((recommendation) => recommendation.id !== "GenericPlanningReminder"),
      "GenericPlanningReminder is the broad anti-example and must never be recommended"
    );
  });
}
