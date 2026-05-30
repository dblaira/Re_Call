import { loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";
import { recordSignal } from "../src/personalization-store.js";

const ALLOWED_METHODS = "POST, OPTIONS";

// Records a single feedback signal (edit / positive / accept / dismiss) on a reminder template.
// The signal is expanded into one append-only event row per strength the template touches, and
// written to recall.user_strength_events. The numeric delta is never stored — only the durable
// signal_type — so re-tuning weights re-scores history without migrating rows.
//
// Auth: forwards a Bearer JWT to Supabase when present (RLS enforces user_id = auth.uid()),
// otherwise writes via the service role (single-user verification path).
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
    const { userId, templateId, signalType } = input ?? {};

    if (!userId || !templateId || !signalType) {
      response.status(400).json({ error: "userId, templateId, and signalType are required." });
      return;
    }

    const { createSupabaseClient, bearerTokenFrom } = await import("../src/supabase-client.js");
    const { createSupabaseDb } = await import("../src/supabase-personalization-db.js");

    const client = createSupabaseClient({ accessToken: bearerTokenFrom(request) });
    const db = createSupabaseDb(client);
    const store = loadReminderRecommendationStore();

    const rows = await recordSignal(db, { userId, templateId, signalType }, store);

    response.status(200).json({
      recorded: rows.length,
      strengths: rows.map((row) => row.strength_id)
    });
  } catch (error) {
    response.status(400).json({
      error: error instanceof Error ? error.message : "Could not record signal."
    });
  }
}
