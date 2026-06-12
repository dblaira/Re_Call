import OpenAI from "openai";
import { chooseReminderCopyTier, selectOpenAIModel } from "./model-policy.js";

export async function draftReminderRecommendationCopy(graphResult, options = {}) {
  if (!graphResult || typeof graphResult !== "object") {
    throw new TypeError("draftReminderRecommendationCopy requires a graph recommendation result.");
  }

  const client = options.client || createOpenAIClient(options);
  const tier = options.tier || chooseReminderCopyTier({
    graphDecision: graphResult.decision,
    needsHardReasoning: options.needsHardReasoning
  });
  const model = options.model || selectOpenAIModel({ tier, policy: options.modelPolicy });

  const response = await client.responses.create({
    model,
    store: false,
    max_output_tokens: options.maxOutputTokens || 800,
    reasoning: {
      effort: options.reasoningEffort || "minimal"
    },
    input: [
      {
        role: "developer",
        content: [
          {
            type: "input_text",
            text: [
              "You write short Re_Call reminder recommendation copy.",
              "The RDF graph is the authority. Do not invent eligibility, scores, or graph facts.",
              "If generationFrame is present, treat it as the output contract: follow generationFrame.intent, satisfy mustInclude, and avoid mustAvoid.",
              "Do not merely rewrite the recommended template text; generate fresh feedback that obeys the frame.",
              "Use calm iOS reminder language. Avoid productivity coaching.",
              "When personalized is true, the order reflects this user's own priorities; reflect that in 'why' without inventing scores.",
              "Return raw JSON only, with no markdown, using keys: title, body, why, variants."
            ].join(" ")
          }
        ]
      },
      {
        role: "user",
        content: [
          {
            type: "input_text",
            text: JSON.stringify(toCopyPromptPayload(graphResult), null, 2)
          }
        ]
      }
    ]
  });

  return {
    provider: "openai",
    model,
    tier,
    text: response.output_text,
    parsed: parseJsonObject(response.output_text)
  };
}

export function createOpenAIClient(options = {}) {
  const apiKey = options.apiKey || process.env.OPENAI_API_KEY;

  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is required to draft reminder recommendation copy.");
  }

  return new OpenAI({ apiKey });
}

function toCopyPromptPayload(graphResult) {
  return {
    decision: graphResult.decision,
    personalized: graphResult.personalized ?? false,
    sourceTemplate: graphResult.sourceTemplate,
    revealedStrengths: graphResult.revealedStrengths,
    generationFrame: graphResult.generationFrame ?? null,
    recommendations: graphResult.recommendations.map((recommendation) => ({
      id: recommendation.id,
      text: recommendation.text,
      score: recommendation.score,
      personalScore: recommendation.personalScore,
      personalMultiplier: recommendation.personalMultiplier,
      sharedGraphFeatures: recommendation.sharedGraphFeatures,
      deepensStrengths: recommendation.deepensStrengths
    })),
    reason: graphResult.reason,
    graphTrace: graphResult.graphTrace
  };
}

function parseJsonObject(text) {
  if (!text) {
    return null;
  }

  try {
    return JSON.parse(text);
  } catch {
    const fencedJson = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
    const candidate = fencedJson?.[1] || text.slice(text.indexOf("{"), text.lastIndexOf("}") + 1);

    if (!candidate) {
      return null;
    }

    try {
      return JSON.parse(candidate);
    } catch {
      return null;
    }
  }
}
