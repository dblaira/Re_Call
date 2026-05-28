// src/user-affinity.js
import { templateStrengths } from "./strength-graph.js";

export const SIGNAL_DELTAS = Object.freeze({
  edit: 0.3,      // user rewrote a template into a custom version (strongest)
  positive: 0.15, // positive rating
  accept: 0.1,    // accepted a recommendation
  dismiss: -0.1   // dismissed / skipped
});

// Bumped when the SIGNAL_DELTAS weights change, so persisted events record which delta
// config they were written under (derived deltas re-score history; this preserves an audit trail).
export const CONFIG_VERSION = "v1";

export const NEUTRAL_AFFINITY = 1.0;
export const DEFAULT_SPREAD = 0.3;

function deltaForSignal(signalType) {
  const delta = SIGNAL_DELTAS[signalType];
  if (delta === undefined) {
    throw new Error(`Unknown signal type: ${signalType}`);
  }
  return delta;
}

export function expandSignalToEvents({ templateId, signalType }, store) {
  deltaForSignal(signalType);
  // Events carry the durable signal type, never the numeric delta. The delta is derived
  // from SIGNAL_DELTAS at compute time so re-tuning a weight re-scores all history.
  return templateStrengths(store, templateId).map((strengthId) => ({
    strengthId,
    signalType,
    templateId
  }));
}

export function foldRawAffinity(events, strengths = []) {
  const raw = {};
  for (const id of strengths) {
    raw[id] = NEUTRAL_AFFINITY;
  }
  for (const event of events) {
    const delta = deltaForSignal(event.signalType);
    if (!(event.strengthId in raw)) {
      raw[event.strengthId] = NEUTRAL_AFFINITY;
    }
    raw[event.strengthId] += delta;
  }
  return raw;
}

export function propagateAffinity(raw, adjacency, spread = DEFAULT_SPREAD) {
  const propagated = {};
  for (const [id, value] of Object.entries(raw)) {
    let neighborSum = 0;
    for (const [neighbor, weight] of Object.entries(adjacency[id] || {})) {
      neighborSum += weight * (raw[neighbor] ?? NEUTRAL_AFFINITY);
    }
    propagated[id] = value + spread * neighborSum;
  }
  return propagated;
}

export function computeAffinity(events, { adjacency, strengths, spread = DEFAULT_SPREAD }) {
  const raw = foldRawAffinity(events, strengths);
  return propagateAffinity(raw, adjacency, spread);
}
