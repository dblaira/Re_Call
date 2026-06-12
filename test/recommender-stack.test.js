import assert from "node:assert/strict";
import test from "node:test";
import { GenerationProviderKind, OpenAIModelTier } from "../src/model-policy.js";
import { draftReminderRecommendationCopy } from "../src/openai-reminder-copy.js";
import { getReminderRecommendationStack, getPersonalizedRecommendationStack } from "../src/recommender-stack.js";
import { ReminderFeedback, ReminderTemplate } from "../src/reminder-recommendation-engine.js";
import { LEVERAGE_GOAL_WEIGHTS } from "../src/goal-weights.js";

test("recommender stack returns graph-only result when no OpenAI key is configured", async () => {
  const previousKey = process.env.OPENAI_API_KEY;
  delete process.env.OPENAI_API_KEY;

  try {
    const result = await getReminderRecommendationStack({
      templateId: ReminderTemplate.ScanCalendar,
      rating: ReminderFeedback.Positive
    });

    assert.equal(result.graph.decision, "rdf-graph-match");
    assert.equal(result.copy, null);
    assert.equal(result.copyStatus, "missing-openai-api-key");
  } finally {
    if (previousKey) {
      process.env.OPENAI_API_KEY = previousKey;
    }
  }
});

test("iOS copy layer prefers Apple Foundation Models before OpenAI", async () => {
  const calls = [];
  const appleProvider = {
    kind: GenerationProviderKind.AppleFoundationModels,
    draftReminderCopy: async (graph) => {
      calls.push({ provider: "apple", frame: graph.generationFrame?.id });
      return {
        title: "Run a readiness bet",
        body: "Try a 30-second check before the first shot, then keep it only if it changes the first five minutes.",
        why: "The graph asks for a timed test and a keep/kill/replace verdict.",
        variants: ["Three tries, then keep it or kill it."]
      };
    }
  };
  const openAIProvider = {
    kind: GenerationProviderKind.OpenAI,
    draftReminderCopy: async () => {
      calls.push({ provider: "openai" });
      return {
        title: "OpenAI fallback",
        body: "",
        why: "",
        variants: []
      };
    }
  };

  const result = await getReminderRecommendationStack(
    {
      templateId: "HabitStackGymReminder",
      rating: ReminderFeedback.Positive
    },
    {
      runtime: "ios",
      providers: [appleProvider, openAIProvider]
    }
  );

  assert.equal(result.copyStatus, "drafted");
  assert.equal(result.copyProvider, GenerationProviderKind.AppleFoundationModels);
  assert.equal(result.copy.title, "Run a readiness bet");
  assert.deepEqual(calls, [{ provider: "apple", frame: "HabitStackReadinessExperimentFrame" }]);
});

test("iOS copy layer falls back when Apple Foundation Models provider is unavailable", async () => {
  const calls = [];
  const appleProvider = {
    kind: GenerationProviderKind.AppleFoundationModels,
    isAvailable: false,
    draftReminderCopy: async () => {
      calls.push("apple");
      return { title: "Apple", body: "", why: "", variants: [] };
    }
  };
  const openAIProvider = {
    kind: GenerationProviderKind.OpenAI,
    isAvailable: true,
    draftReminderCopy: async () => {
      calls.push("openai");
      return { title: "OpenAI fallback", body: "", why: "", variants: [] };
    }
  };

  const result = await getReminderRecommendationStack(
    {
      templateId: "HabitStackGymReminder",
      rating: ReminderFeedback.Positive
    },
    {
      runtime: "ios",
      providers: [appleProvider, openAIProvider]
    }
  );

  assert.equal(result.copyProvider, GenerationProviderKind.OpenAI);
  assert.equal(result.copy.title, "OpenAI fallback");
  assert.deepEqual(calls, ["openai"]);
});

test("OpenAI copy layer uses standard tier by default and preserves graph facts", async () => {
  const calls = [];
  const fakeClient = {
    responses: {
      create: async (request) => {
        calls.push(request);
        return {
          output_text: JSON.stringify({
            title: "Scan tomorrow for transition stress",
            body: "Try a sharper calendar scan before the day starts.",
            why: "Your calendar reminder revealed TimeAwareness.",
            variants: ["Find the meeting that needs emotional preparation."]
          })
        };
      }
    }
  };

  const result = await getReminderRecommendationStack(
    {
      templateId: ReminderTemplate.ScanCalendar,
      rating: ReminderFeedback.Positive
    },
    {
      client: fakeClient,
      modelPolicy: {
        [OpenAIModelTier.Tiny]: "tiny-test-model",
        [OpenAIModelTier.Standard]: "standard-test-model",
        [OpenAIModelTier.Reasoning]: "reasoning-test-model"
      }
    }
  );

  assert.equal(result.copyStatus, "drafted");
  assert.equal(result.copy.model, "standard-test-model");
  assert.equal(result.copy.parsed.why, "Your calendar reminder revealed TimeAwareness.");
  assert.equal(calls[0].store, false);
  assert.deepEqual(calls[0].reasoning, { effort: "minimal" });
  assert.match(JSON.stringify(calls[0].input), /TimeAwareness/);
});

test("copy layer can be explicitly escalated to reasoning tier", async () => {
  const fakeClient = {
    responses: {
      create: async () => ({ output_text: "{\"title\":\"Hard case\",\"body\":\"\",\"why\":\"\",\"variants\":[]}" })
    }
  };

  const copy = await draftReminderRecommendationCopy(
    {
      decision: "rdf-graph-match",
      sourceTemplate: { id: "Example" },
      revealedStrengths: [],
      recommendations: [],
      reason: "Ambiguous feedback requires deeper interpretation.",
      graphTrace: {}
    },
    {
      client: fakeClient,
      needsHardReasoning: true,
      modelPolicy: {
        [OpenAIModelTier.Tiny]: "tiny-test-model",
        [OpenAIModelTier.Standard]: "standard-test-model",
        [OpenAIModelTier.Reasoning]: "reasoning-test-model"
      }
    }
  );

  assert.equal(copy.model, "reasoning-test-model");
  assert.equal(copy.tier, OpenAIModelTier.Reasoning);
});

test("copy layer allows enough output budget for GPT-5 reasoning models", async () => {
  const calls = [];
  const fakeClient = {
    responses: {
      create: async (request) => {
        calls.push(request);
        return {
          output_text:
            "```json\n{\"title\":\"Enough room\",\"body\":\"Done\",\"why\":\"Graph facts preserved.\",\"variants\":[]}\n```"
        };
      }
    }
  };

  const copy = await draftReminderRecommendationCopy(
    {
      decision: "rdf-graph-match",
      sourceTemplate: { id: "Example" },
      revealedStrengths: [],
      recommendations: [],
      reason: "Budget test.",
      graphTrace: {}
    },
    {
      client: fakeClient,
      modelPolicy: {
        [OpenAIModelTier.Tiny]: "tiny-test-model",
        [OpenAIModelTier.Standard]: "standard-test-model",
        [OpenAIModelTier.Reasoning]: "reasoning-test-model"
      }
    }
  );

  assert.equal(calls[0].max_output_tokens, 800);
  assert.equal(copy.parsed.title, "Enough room");
});

test("personalized stack returns a personalized graph and skips copy without a key", async () => {
  const result = await getPersonalizedRecommendationStack(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    { goalWeights: LEVERAGE_GOAL_WEIGHTS, events: [], draftCopy: false }
  );
  assert.equal(result.graph.personalized, true);
  assert.equal(result.copyStatus, "skipped");
});

test("personalized stack drafts copy via an injected client with real events", async () => {
  const fakeClient = {
    responses: {
      create: async () => ({ output_text: '{"title":"t","body":"b","why":"w","variants":[]}' })
    }
  };
  const result = await getPersonalizedRecommendationStack(
    { templateId: "FindLeveragePointReminder", rating: "PositiveReminderRating" },
    {
      goalWeights: LEVERAGE_GOAL_WEIGHTS,
      events: [
        { strengthId: "ExecutionLeverage", signalType: "edit", templateId: "AskForVisibleProcessDraft" }
      ],
      client: fakeClient
    }
  );
  assert.equal(result.graph.personalized, true);
  assert.equal(result.copyStatus, "drafted");
  assert.ok(result.graph.recommendations.length > 0);
});
