export const DEFAULT_GOAL_WEIGHT = 1.0;

export function goalWeightFor(goalWeights, strengthId) {
  return goalWeights?.[strengthId] ?? DEFAULT_GOAL_WEIGHT;
}

// First user's declared aspiration: live more by the 80/20 (leverage) principle.
export const LEVERAGE_GOAL_WEIGHTS = Object.freeze({
  LeverageAwareness: 3.0,
  ExecutionLeverage: 3.0
});
