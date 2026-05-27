import { getReminderRecommendations } from "./reminder-recommendation-engine.js";
import { draftReminderRecommendationCopy } from "./openai-reminder-copy.js";

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
