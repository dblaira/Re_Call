import {
  getReminderRecommendationStack,
  getPersonalizedRecommendationStack
} from "../src/recommender-stack.js";
import { loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";
import { loadUserAffinityInputs } from "../src/personalization-store.js";
import { applyCors, sendError } from "./_lib.js";

const ALLOWED_METHODS = "POST, OPTIONS";

export default async function handler(request, response) {
  applyCors(response);

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

    // Personalized path is opt-in (the client asks for it via `personalized: true`, or by
    // sending a userId hint). The identity is then taken from the auth token / SINGLE_USER_ID,
    // NOT the body — so the request can only ever load its own history. Without opt-in, the
    // request stays on the universal graph path below — unchanged behavior.
    if (input?.personalized === true || input?.userId) {
      const result = await personalizedResult(request, input, draftCopy);
      response.status(200).json(result);
      return;
    }

    const result = await getReminderRecommendationStack(input, { draftCopy });
    response.status(200).json(result);
  } catch (error) {
    sendError(response, error, "Could not generate recommendation.");
  }
}

async function personalizedResult(request, input, draftCopy) {
  // Dynamic import keeps @supabase/supabase-js out of the universal (no-userId) code path.
  const { createSupabaseClient, bearerTokenFrom, resolveAuthedUserId } = await import("../src/supabase-client.js");
  const { createSupabaseDb } = await import("../src/supabase-personalization-db.js");

  // A user JWT (anon key + RLS) when the client is authenticated; service role otherwise.
  const client = createSupabaseClient({ accessToken: bearerTokenFrom(request) });
  const userId = await resolveAuthedUserId(request, client); // identity from token, not body
  const db = createSupabaseDb(client);
  const store = loadReminderRecommendationStore();

  const { events, goalWeights } = await loadUserAffinityInputs(db, userId);

  return getPersonalizedRecommendationStack(input, {
    events,
    goalWeights,
    store,
    draftCopy
  });
}
