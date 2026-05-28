import { getReminderRecommendations } from "./reminder-recommendation-engine.js";
import { computeAffinity, NEUTRAL_AFFINITY } from "./user-affinity.js";
import { goalWeightFor } from "./goal-weights.js";

// Pull the full deeper set before re-ranking. The ontology yields only a few candidates
// per rule today; this ceiling is generous headroom so personalization sees them all.
const UNRANKED_CANDIDATE_CEILING = 50;

// A multiplier floor keeps strongly-disliked picks ranked low without inverting their
// order relative to universal score (a negative multiplier would flip score-based ordering).
const MIN_PERSONAL_MULTIPLIER = 0.05;

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
  const universal = getReminderRecommendations(input, { store, limit: UNRANKED_CANDIDATE_CEILING });

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
  // The design formula is per-strength (depthScore × affinity × goalWeight). A candidate can
  // deepen several strengths, so we aggregate the (affinity × goalWeight) signal across them by
  // mean — identical to the formula for single-strength candidates, a balanced blend otherwise.
  const ids = rec.deepensStrengths.map((strength) => strength.id);
  if (ids.length === 0) {
    return 1;
  }
  const sum = ids.reduce(
    (acc, id) => acc + (affinity[id] ?? NEUTRAL_AFFINITY) * goalWeightFor(goalWeights, id),
    0
  );
  return Math.max(MIN_PERSONAL_MULTIPLIER, sum / ids.length);
}
