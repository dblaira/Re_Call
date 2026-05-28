import { getReminderRecommendations } from "./reminder-recommendation-engine.js";
import { draftReminderRecommendationCopy } from "./openai-reminder-copy.js";
import { getPersonalizedRecommendations } from "./personalized-recommendation-engine.js";
import { buildStrengthAdjacency } from "./strength-graph.js";

export async function getReminderRecommendationStack(input, options = {}) {
  const graph = getReminderRecommendations(input, options.graphOptions);

  if (options.draftCopy === false) {
    return {
      graph,
      copy: null,
      copyStatus: "skipped"
    };
  }

  if (!options.client && !options.apiKey && !process.env.OPENAI_API_KEY) {
    return {
      graph,
      copy: null,
      copyStatus: "missing-openai-api-key"
    };
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

  return {
    graph,
    copy,
    copyStatus: "drafted"
  };
}

export async function getPersonalizedRecommendationStack(input, options = {}) {
  const { strengths, adjacency } = buildStrengthAdjacency(options.store);
  const graph = getPersonalizedRecommendations(input, {
    events: options.events,
    goalWeights: options.goalWeights,
    adjacency,
    strengths,
    store: options.store,
    limit: options.limit
  });

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
