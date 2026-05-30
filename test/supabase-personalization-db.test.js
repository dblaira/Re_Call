// test/supabase-personalization-db.test.js
import assert from "node:assert/strict";
import test from "node:test";
import { createSupabaseDb } from "../src/supabase-personalization-db.js";
import { recordSignal, loadUserAffinityInputs } from "../src/personalization-store.js";
import { loadReminderRecommendationStore } from "../src/reminder-recommendation-engine.js";

// Minimal fake of the supabase-js v2 query builder: client.schema(s).from(t).insert/select/eq/upsert.
// insert/upsert/eq resolve to { data, error }; select returns the builder for chaining to eq.
function fakeClient({ selectData = {}, failTable = null } = {}) {
  const calls = { schema: [], from: [], insert: [], select: [], eq: [], upsert: [] };

  function resolve(tableName, data = null) {
    return Promise.resolve({
      data,
      error: failTable === tableName ? { message: "boom" } : null
    });
  }

  function builder(tableName) {
    const b = {
      insert(rows) {
        calls.insert.push({ tableName, rows });
        return resolve(tableName);
      },
      upsert(rows, options) {
        calls.upsert.push({ tableName, rows, options });
        return resolve(tableName);
      },
      select(columns) {
        calls.select.push({ tableName, columns });
        return b;
      },
      eq(column, value) {
        calls.eq.push({ tableName, column, value });
        return resolve(tableName, selectData[tableName] ?? []);
      }
    };
    return b;
  }

  return {
    calls,
    schema(name) {
      calls.schema.push(name);
      return {
        from(tableName) {
          calls.from.push(tableName);
          return builder(tableName);
        }
      };
    }
  };
}

test("createSupabaseDb requires a v2 client with .schema()", () => {
  assert.throws(() => createSupabaseDb(null), /requires a supabase-js client/);
  assert.throws(() => createSupabaseDb({}), /requires a supabase-js client/);
});

test("targets the recall schema and inserts events", async () => {
  const client = fakeClient();
  const db = createSupabaseDb(client);
  await db.insertEvents([{ user_id: "u1", strength_id: "ExecutionLeverage", signal_type: "edit" }]);

  assert.deepEqual(client.calls.schema, ["recall"]);
  assert.deepEqual(client.calls.from, ["user_strength_events"]);
  assert.equal(client.calls.insert[0].rows.length, 1);
});

test("insertEvents is a no-op for empty rows (no write issued)", async () => {
  const client = fakeClient();
  const db = createSupabaseDb(client);
  await db.insertEvents([]);
  assert.equal(client.calls.insert.length, 0);
});

test("selectEvents / selectGoalWeights filter by user_id and return rows", async () => {
  const client = fakeClient({
    selectData: {
      user_strength_events: [{ strength_id: "ExecutionLeverage", signal_type: "accept", template_id: "t" }],
      user_goal_weights: [{ strength_id: "LeverageAwareness", weight: 3 }]
    }
  });
  const db = createSupabaseDb(client);

  const events = await db.selectEvents("u1");
  const goals = await db.selectGoalWeights("u1");

  assert.equal(events[0].strength_id, "ExecutionLeverage");
  assert.equal(goals[0].weight, 3);
  assert.ok(client.calls.eq.every((c) => c.column === "user_id" && c.value === "u1"));
});

test("upsertGoalWeights writes rows with the composite-key conflict target", async () => {
  const client = fakeClient();
  const db = createSupabaseDb(client);
  await db.upsertGoalWeights("u1", { LeverageAwareness: 3, ExecutionLeverage: 3 });

  assert.equal(client.calls.upsert[0].rows.length, 2);
  assert.equal(client.calls.upsert[0].options.onConflict, "user_id,strength_id");
});

test("Supabase errors propagate as thrown errors", async () => {
  const db = createSupabaseDb(fakeClient({ failTable: "user_strength_events" }));
  await assert.rejects(() => db.insertEvents([{ user_id: "u1" }]), /insertEvents failed: boom/);
});

test("satisfies the injected db contract used by personalization-store", async () => {
  const store = loadReminderRecommendationStore();
  const client = fakeClient({
    selectData: { user_goal_weights: [{ strength_id: "LeverageAwareness", weight: 3 }] }
  });
  const db = createSupabaseDb(client);

  const rows = await recordSignal(
    db,
    { userId: "u1", templateId: "ClearGoodIdeasForGreatIdea", signalType: "edit" },
    store
  );
  assert.equal(rows.length, 2);
  assert.ok(client.calls.insert[0].rows.every((r) => r.user_id === "u1" && r.signal_type === "edit"));

  const { events, goalWeights } = await loadUserAffinityInputs(db, "u1");
  assert.ok(Array.isArray(events));
  assert.equal(goalWeights.LeverageAwareness, 3);
});
