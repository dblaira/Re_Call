import { getReminderRecommendations, loadReminderRecommendationStore } from "./reminder-recommendation-engine.js";
import { draftReminderRecommendationCopy } from "./openai-reminder-copy.js";
import { getPersonalizedRecommendations } from "./personalized-recommendation-engine.js";
import { buildStrengthAdjacency } from "./strength-graph.js";

async function attachCopy(graph, options) {
  if (options.draftCopy === false) {
    return { graph, copy: null, copyStatus: "skipped" };
  }

  if (!options.client && !options.apiKey && !process.env.OPENAI_API_KEY) {
    return { graph, copy: null, copyStatus: "missing-openai-api-key" };
  }

  const copy = await draftReminderRecommendationCopy(graph, {
    client: options.client,
    apiKey: options.apiKey,
    model: options.model,
    tier: options.tier,
    modelPolicy: options.modelPolicy,
    needsHardReasoning: options.needsHardReasoning,
    maxOutputTokens: options.maxOutputTokens
  });

  return { graph, copy, copyStatus: "drafted" };
}

export async function getReminderRecommendationStack(input, options = {}) {
  const graph = getReminderRecommendations(input, options.graphOptions);
  return attachCopy(graph, options);
}

export async function getPersonalizedRecommendationStack(input, options = {}) {
  const store = options.store ?? loadReminderRecommendationStore();
  const { strengths, adjacency } = buildStrengthAdjacency(store);
  const graph = getPersonalizedRecommendations(input, {
    events: options.events,
    goalWeights: options.goalWeights,
    adjacency,
    strengths,
    store,
    limit: options.limit
  });
  return attachCopy(graph, options);
}
