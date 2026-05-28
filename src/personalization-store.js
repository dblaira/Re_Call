import { expandSignalToEvents } from "./user-affinity.js";

// `db` is injected and must provide:
//   insertEvents(rows)        -> Promise<void>
//   selectEvents(userId)      -> Promise<Array<{ strength_id, signal_type, template_id }>>
//   selectGoalWeights(userId) -> Promise<Array<{ strength_id, weight }>>
export async function recordSignal(db, { userId, templateId, signalType }, store) {
  const expanded = expandSignalToEvents({ templateId, signalType }, store);
  const rows = expanded.map((event) => ({
    user_id: userId,
    strength_id: event.strengthId,
    signal_type: event.signalType,
    template_id: event.templateId
  }));
  await db.insertEvents(rows);
  return rows;
}

export async function loadUserAffinityInputs(db, userId) {
  const [eventRows, goalRows] = await Promise.all([
    db.selectEvents(userId),
    db.selectGoalWeights(userId)
  ]);

  const events = eventRows.map((row) => ({
    strengthId: row.strength_id,
    signalType: row.signal_type,
    templateId: row.template_id
  }));

  const goalWeights = {};
  for (const row of goalRows) {
    goalWeights[row.strength_id] = Number(row.weight);
  }

  return { events, goalWeights };
}
