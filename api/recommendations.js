import {
  getReminderRecommendationStack,
  getPersonalizedRecommendationStack
} from "../src/recommender-stack.js";
import { loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";
import { loadUserAffinityInputs } from "../src/personalization-store.js";

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
    const draftCopy = input?.draftCopy === true;

    // Personalized path: opt-in by sending a userId. We load this user's signal history and
    // declared goal weights from Supabase, then re-rank within the deeper set. Without a userId
    // the request stays on the universal graph path below — unchanged behavior.
    if (input?.userId) {
      const result = await personalizedResult(request, input, draftCopy);
      response.status(200).json(result);
      return;
    }

    const result = await getReminderRecommendationStack(input, { draftCopy });
    response.status(200).json(result);
  } catch (error) {
    response.status(400).json({
      error: error instanceof Error ? error.message : "Could not generate recommendation."
    });
  }
}

async function personalizedResult(request, input, draftCopy) {
  // Dynamic import keeps @supabase/supabase-js out of the universal (no-userId) code path.
  const { createSupabaseClient, bearerTokenFrom } = await import("../src/supabase-client.js");
  const { createSupabaseDb } = await import("../src/supabase-personalization-db.js");

  // A user JWT (anon key + RLS) when the client is authenticated; service role otherwise.
  const client = createSupabaseClient({ accessToken: bearerTokenFrom(request) });
  const db = createSupabaseDb(client);
  const store = loadReminderRecommendationStore();

  const { events, goalWeights } = await loadUserAffinityInputs(db, input.userId);

  return getPersonalizedRecommendationStack(input, {
    events,
    goalWeights,
    store,
    draftCopy
  });
}
