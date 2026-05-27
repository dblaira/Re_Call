import { getReminderRecommendationStack } from "../src/recommender-stack.js";

const ALLOWED_METHODS = "POST, OPTIONS";

export default async function handler(request, response) {
  response.setHeader("Access-Control-Allow-Methods", ALLOWED_METHODS);
  response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (request.method === "OPTIONS") {
    response.status(204).end();
    return;
  }

  if (request.method !== "POST") {
    response.setHeader("Allow", ALLOWED_METHODS);
    response.status(405).json({ error: "Method not allowed. Use POST." });
    return;
  }

  try {
    const input = typeof request.body === "string" ? JSON.parse(request.body) : request.body;
    const result = await getReminderRecommendationStack(input, {
      draftCopy: input?.draftCopy === true
    });

    response.status(200).json(result);
  } catch (error) {
    response.status(400).json({
      error: error instanceof Error ? error.message : "Could not generate recommendation."
    });
  }
}
