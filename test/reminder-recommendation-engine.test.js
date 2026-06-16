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

test("positive leverage reminder rating recommends deeper leverage templates from RDF triples", () => {
  const result = getReminderRecommendations({
    templateId: ReminderTemplate.FindLeveragePoint,
    rating: ReminderFeedback.Positive,
    text: "Before adding another feature, help me find the smallest move that changes the most outcomes."
  });

  assert.equal(result.decision, "rdf-graph-match");
  assert.equal(result.confidence, "high");
  assert.equal(result.sourceTemplate.id, "FindLeveragePointReminder");
  assert.deepEqual(result.revealedStrengths.map((strength) => strength.id), [
    "LeverageAwareness",
    "ExecutionLeverage"
  ]);
  assert.match(result.reason, /leverage awareness/i);
  assert.equal(result.recommendations.length, 4);
  assert.equal(result.recommendations[0].id, "NameSmallInputAndOutcome");
  assert.match(result.recommendations[0].text, /small input/i);
  assert.ok(result.recommendations.some((recommendation) => recommendation.id === "ClearGoodIdeasForGreatIdea"));
  assert.deepEqual(result.graphTrace.matchedRuleIds, ["LeverageDepthRecommendationRule"]);
});

test("positive communication-format reminder rating recommends deeper format templates from RDF triples", () => {
  const result = getReminderRecommendations({
    templateId: ReminderTemplate.ChooseCommunicationFormat,
    rating: ReminderFeedback.Positive,
    text: "Before replying, choose whether this should be a table, short note, tree, or call."
  });

  assert.equal(result.decision, "rdf-graph-match");
  assert.equal(result.confidence, "high");
  assert.equal(result.sourceTemplate.id, "ChooseCommunicationFormatReminder");
  assert.deepEqual(result.revealedStrengths.map((strength) => strength.id), [
    "FormatJudgment",
    "CommunicationFit"
  ]);
  assert.match(result.reason, /format judgment/i);
  assert.equal(result.recommendations.length, 4);
  assert.equal(result.recommendations[0].id, "ConvertAbstractTalkToInspectableShape");
  assert.match(result.recommendations[0].text, /table, node tree, route, or test path/i);
  assert.ok(result.recommendations.some((recommendation) => recommendation.id === "ChooseTableMatrixTreeOrNote"));
  assert.deepEqual(result.graphTrace.matchedRuleIds, ["CommunicationFormatDepthRecommendationRule"]);
});

test("story-driven recommendations produce non-echo feedback hooks", () => {
  const cases = [
    {
      templateId: ReminderTemplate.HabitStackGym,
      expected: [/readiness bet/i, /kill it or replace it/i, /score the first five minutes/i, /change the anchor/i]
    },
    {
      templateId: ReminderTemplate.TranslateAIWeek,
      expected: [/so-what before the news/i, /interesting but not useful/i, /person before the headline/i, /cut the interesting paragraph/i]
    },
    {
      templateId: ReminderTemplate.CaptureMacBookUnlocks,
      expected: [/expensive-tool audit/i, /separate delight from leverage/i, /blocked-by-old-setup receipt/i, /refund the fantasy hour/i]
    },
    {
      templateId: ReminderTemplate.NameMeaningfulSource,
      expected: [/protect the hour after it/i, /spark-to-output chain/i, /timing fingerprint/i, /turn the source into an appointment/i]
    },
    {
      templateId: ReminderTemplate.PostRunBodyDiscovery,
      expected: [/map the low-to-high line/i, /before\/after body signal/i, /repeatable support ritual/i, /scan twenty movement hypotheses/i]
    }
  ];

  for (const { templateId, expected } of cases) {
    const result = getReminderRecommendations({
      templateId,
      rating: ReminderFeedback.Positive
    });
    const text = result.recommendations.map((recommendation) => recommendation.text).join("\n");
    assert.equal(result.recommendations.length, 4, `${templateId} should expose four story-specific recommendations`);
    for (const pattern of expected) {
      assert.match(text, pattern, `${templateId} should include ${pattern}`);
    }
  }
});

test("post-run body discovery exposes a scan field instead of one narrow suggestion", () => {
  const result = getReminderRecommendations(
    {
      templateId: ReminderTemplate.PostRunBodyDiscovery,
      rating: ReminderFeedback.Positive,
      text: "After a run and shower, my right hip felt off. A low-to-high reverse twist with a resistance band made the right hip and shoulder feel stronger, then worked on the left side too."
    },
    { limit: 20 }
  );

  assert.equal(result.sourceTemplate.id, "PostRunBodyDiscoveryReminder");
  assert.equal(result.generationFrame.id, "FeltDiscoveryScanFrame");
  assert.match(result.reason, /discovery converts maintenance into pull/i);
  assert.equal(result.recommendations.length, 20);
  assert.deepEqual(result.revealedStrengths.map((strength) => strength.id), [
    "EmbodiedExperimentation",
    "FeltDiscovery"
  ]);
  assert.ok(result.generationFrame.mustInclude.includes("a body signal before and after the experiment"));
  assert.ok(result.generationFrame.mustAvoid.includes("generic stretching advice"));
  assert.ok(result.recommendations.every((recommendation) => recommendation.id !== "GenericFitnessReminder"));
  assert.ok(result.recommendations.some((recommendation) => /mystery|curiosity|felt/i.test(recommendation.text)));
});

test("story-driven recommendations avoid polite echo patterns", () => {
  const badPositivePatterns = [
    /great job/i,
    /keep foam rolling/i,
    /stay motivated/i,
    /generic/i,
    /nice work/i
  ];

  for (const templateId of [
    ReminderTemplate.HabitStackGym,
    ReminderTemplate.TranslateAIWeek,
    ReminderTemplate.CaptureMacBookUnlocks,
    ReminderTemplate.NameMeaningfulSource
  ]) {
    const result = getReminderRecommendations({
      templateId,
      rating: ReminderFeedback.Positive
    });
    const text = result.recommendations.map((recommendation) => recommendation.text).join("\n");
    for (const pattern of badPositivePatterns) {
      assert.doesNotMatch(text, pattern, `${templateId} should avoid ${pattern}`);
    }
  }
});

test("story-driven recommendations expose graph generation constraints", () => {
  const result = getReminderRecommendations({
    templateId: ReminderTemplate.HabitStackGym,
    rating: ReminderFeedback.Positive
  });

  assert.equal(result.generationFrame.id, "HabitStackReadinessExperimentFrame");
  assert.match(result.generationFrame.intent, /tiny readiness experiment/i);
  assert.deepEqual(result.generationFrame.mustInclude.sort(), [
    "a judgment moment",
    "a keep, kill, or replace branch",
    "a tiny timed experiment"
  ].sort());
  assert.ok(result.generationFrame.mustAvoid.includes("repeating the user's foam-rolling wording"));
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
