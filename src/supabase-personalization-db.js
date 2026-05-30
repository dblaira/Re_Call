// src/supabase-personalization-db.js
//
// Live `db` adapter for the personalization store. It satisfies the dependency-injected
// interface that src/personalization-store.js expects:
//   insertEvents(rows) / selectEvents(userId) / selectGoalWeights(userId)
// plus upsertGoalWeights(userId, weights) for server-side goal seeding.
//
// It is PURE over an injected supabase-js client — it never imports @supabase/supabase-js
// itself, so it stays unit-testable offline with a fake client and is auth-model-agnostic:
// hand it a service-role client (server path, bypasses RLS) or a user-JWT client (anon key
// + the end user's access token, so the recall.* RLS policies enforce per-user access).
// The adapter code is identical either way — which client it gets decides the security model.

const SCHEMA = "recall";

export function createSupabaseDb(client) {
  if (!client || typeof client.schema !== "function") {
    throw new TypeError("createSupabaseDb requires a supabase-js client (v2, with .schema()).");
  }

  const table = (name) => client.schema(SCHEMA).from(name);

  return {
    // Append-only signal log. RLS: insert own rows (user-JWT) or service role.
    async insertEvents(rows) {
      if (!rows || rows.length === 0) {
        return;
      }
      const { error } = await table("user_strength_events").insert(rows);
      if (error) {
        throw new Error(`Supabase insertEvents failed: ${error.message}`);
      }
    },

    async selectEvents(userId) {
      const { data, error } = await table("user_strength_events")
        .select("strength_id, signal_type, template_id, config_version")
        .eq("user_id", userId);
      if (error) {
        throw new Error(`Supabase selectEvents failed: ${error.message}`);
      }
      return data ?? [];
    },

    async selectGoalWeights(userId) {
      const { data, error } = await table("user_goal_weights")
        .select("strength_id, weight")
        .eq("user_id", userId);
      if (error) {
        throw new Error(`Supabase selectGoalWeights failed: ${error.message}`);
      }
      return data ?? [];
    },

    // Goal weights are declared/seeded server-side (RLS gives clients SELECT only), so this
    // is expected to run under a service-role client until a user-facing "edit goals" surface
    // and a matching write policy exist.
    async upsertGoalWeights(userId, weights) {
      const rows = Object.entries(weights ?? {}).map(([strength_id, weight]) => ({
        user_id: userId,
        strength_id,
        weight
      }));
      if (rows.length === 0) {
        return;
      }
      const { error } = await table("user_goal_weights").upsert(rows, {
        onConflict: "user_id,strength_id"
      });
      if (error) {
        throw new Error(`Supabase upsertGoalWeights failed: ${error.message}`);
      }
    }
  };
}
