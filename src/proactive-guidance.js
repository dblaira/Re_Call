import { loadReminderRecommendationStore } from "./reminder-recommendation-engine.js";
import { term, localName, literal, decimal } from "./ontology-terms.js";
import { DEFAULT_GOAL_WEIGHT } from "./goal-weights.js";

export function getProactiveGuidance({
  goalWeights = {},
  store = loadReminderRecommendationStore(),
  recentNudgeIds = [],
  limit = 1
} = {}) {
  const goalStrengths = topGoalStrengths(goalWeights);
  if (goalStrengths.length === 0) {
    return { decision: "no-goal", goalStrengths: [], nudges: [] };
  }

  const all = templatesDeepening(store, goalStrengths).sort(
    (left, right) => right.depthScore - left.depthScore
  );
  const fresh = all.filter((candidate) => !recentNudgeIds.includes(candidate.id));
  const pool = fresh.length > 0 ? fresh : all; // rotation reset once all shown

  const nudges = pool.slice(0, limit).map((candidate) => ({
    ...candidate,
    reason: `Guiding you toward your priority: ${goalStrengths.join(", ")}.`
  }));

  return { decision: "goal-guidance", goalStrengths, nudges };
}

function topGoalStrengths(goalWeights) {
  const entries = Object.entries(goalWeights || {});
  if (entries.length === 0) {
    return [];
  }
  const max = Math.max(...entries.map(([, weight]) => weight));
  if (max <= DEFAULT_GOAL_WEIGHT) {
    return [];
  }
  return entries.filter(([, weight]) => weight === max).map(([id]) => id);
}

function templatesDeepening(store, strengthIds) {
  const wanted = new Set(strengthIds);
  const seen = new Set();
  const result = [];
  for (const quad of store.getQuads(null, term("deepensStrength"), null, null)) {
    if (!wanted.has(localName(quad.object))) {
      continue;
    }
    const id = localName(quad.subject);
    if (seen.has(id)) {
      continue;
    }
    seen.add(id);
    result.push({
      id,
      text: literal(store, quad.subject, "templateText"),
      depthScore: decimal(store, quad.subject, "depthScore")
    });
  }
  return result;
}
