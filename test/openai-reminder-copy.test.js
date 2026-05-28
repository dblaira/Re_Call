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
