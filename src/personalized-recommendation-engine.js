import { getReminderRecommendations } from "./reminder-recommendation-engine.js";
import { computeAffinity } from "./user-affinity.js";
import { goalWeightFor } from "./goal-weights.js";

export function getPersonalizedRecommendations(input, context = {}) {
  const {
    events = [],
    goalWeights = {},
    adjacency = {},
    strengths = [],
    spread,
    store,
    limit = 4
  } = context;

  // Pull the full universal candidate set first (it is already filtered to
  // "deeper, not broader"), then re-rank within it.
  const universal = getReminderRecommendations(input, { store, limit: 50 });

  if (universal.decision !== "rdf-graph-match") {
    return { ...universal, personalized: false };
  }

  const affinity = computeAffinity(events, { adjacency, strengths, spread });

  const recommendations = universal.recommendations
    .map((rec) => {
      const multiplier = personalMultiplier(rec, affinity, goalWeights);
      return {
        ...rec,
        personalMultiplier: Number(multiplier.toFixed(3)),
        personalScore: Number((rec.score * multiplier).toFixed(3))
      };
    })
    .sort((left, right) => right.personalScore - left.personalScore)
    .slice(0, limit);

  return { ...universal, recommendations, personalized: true };
}

function personalMultiplier(rec, affinity, goalWeights) {
  const ids = rec.deepensStrengths.map((strength) => strength.id);
  if (ids.length === 0) {
    return 1;
  }
  const sum = ids.reduce(
    (acc, id) => acc + (affinity[id] ?? 1) * goalWeightFor(goalWeights, id),
    0
  );
  return sum / ids.length;
}
