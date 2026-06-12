import assert from "node:assert/strict";
import test from "node:test";
import { draftReminderRecommendationCopy } from "../src/openai-reminder-copy.js";

function fakeClient(capture) {
  return {
    responses: {
      create: async (request) => {
        capture.request = request;
        return { output_text: '{"title":"t","body":"b","why":"w","variants":[]}' };
      }
    }
  };
}

test("copy payload carries personalization signals when present", async () => {
  const capture = {};
  const graphResult = {
    decision: "rdf-graph-match",
    personalized: true,
    sourceTemplate: { id: "FindLeveragePointReminder", label: "x", iri: "y", comment: "" },
    revealedStrengths: [],
    recommendations: [
      {
        id: "AskForVisibleProcessDraft",
        text: "Ask for the full ordered draft.",
        score: 0.95,
        personalScore: 2.375,
        personalMultiplier: 2.5,
        sharedGraphFeatures: [{ id: "ExecutionLeverage" }],
        deepensStrengths: [{ id: "ExecutionLeverage" }]
      }
    ],
    reason: "r",
    graphTrace: {}
  };

  const result = await draftReminderRecommendationCopy(graphResult, { client: fakeClient(capture) });

  assert.equal(result.parsed.title, "t");
  const userText = capture.request.input.find((m) => m.role === "user").content[0].text;
  const payload = JSON.parse(userText);
  assert.equal(payload.personalized, true);
  assert.equal(payload.recommendations[0].personalScore, 2.375);
});

test("copy payload carries graph generation constraints", async () => {
  const capture = {};
  const graphResult = {
    decision: "rdf-graph-match",
    personalized: false,
    sourceTemplate: { id: "HabitStackGymReminder", label: "Habit stack at the gym", iri: "y", comment: "" },
    revealedStrengths: [{ id: "HabitStacking", label: "Habit stacking" }],
    generationFrame: {
      id: "HabitStackReadinessExperimentFrame",
      intent: "Generate feedback that turns the gym habit stack into a tiny readiness experiment with a verdict.",
      mustInclude: ["a tiny timed experiment", "a judgment moment", "a keep, kill, or replace branch"],
      mustAvoid: ["repeating the user's foam-rolling wording", "generic fitness advice"]
    },
    recommendations: [
      {
        id: "FoamRollFiveByFive",
        text: "Run a readiness bet.",
        score: 1,
        sharedGraphFeatures: [{ id: "HabitStacking" }],
        deepensStrengths: [{ id: "HabitStacking" }]
      }
    ],
    reason: "r",
    graphTrace: {}
  };

  await draftReminderRecommendationCopy(graphResult, { client: fakeClient(capture) });

  const developerText = capture.request.input.find((m) => m.role === "developer").content[0].text;
  assert.match(developerText, /mustInclude/i);
  assert.match(developerText, /mustAvoid/i);

  const userText = capture.request.input.find((m) => m.role === "user").content[0].text;
  const payload = JSON.parse(userText);
  assert.equal(payload.generationFrame.id, "HabitStackReadinessExperimentFrame");
  assert.deepEqual(payload.generationFrame.mustInclude, [
    "a tiny timed experiment",
    "a judgment moment",
    "a keep, kill, or replace branch"
  ]);
  assert.ok(payload.generationFrame.mustAvoid.includes("generic fitness advice"));
});
