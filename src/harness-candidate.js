import { SIGNAL_DELTAS } from "./user-affinity.js";

export const LEVERAGE_RECOMMENDATION_QUESTION =
  "What should I prioritize next to create more meaningful leverage?";

const MIN_SUPPORTING_SIGNALS = 3;
const MIN_AFFINITY_DELTA = 0.3;
const NEUTRAL_GOAL_WEIGHT = 1;
const CONNECTION_TYPE = "aggregate_goal_alignment";

const ROOT_FIELDS = new Set([
  "aggregates",
  "dataClassification",
  "evidenceWindow",
  "recommendationQuestion",
  "sourceRef"
]);
const AGGREGATE_FIELDS = new Set(["goalWeight", "signalCounts", "strengthId"]);
const WINDOW_FIELDS = new Set(["end", "start"]);
const SIGNAL_TYPES = Object.freeze(Object.keys(SIGNAL_DELTAS));
const SIGNAL_FIELDS = new Set(SIGNAL_TYPES);

const SUPPORTED_STRENGTHS = Object.freeze({
  ExecutionLeverage: Object.freeze({
    claim:
      "Re_Call's repeated execution-leverage signals align with a declared goal above neutral; work recommendations should apply the stated principle: “Lift — meaningful. Leverage — multiply differently. Automation — delegate taste.”",
    domainA: "ambition",
    domainB: "work",
    slug: "execution-leverage"
  }),
  LeverageAwareness: Object.freeze({
    claim:
      "Re_Call's repeated leverage-awareness signals align with a declared goal above neutral; work recommendations should apply the stated principle: “Lift — meaningful. Leverage — multiply differently. Automation — delegate taste.”",
    domainA: "ambition",
    domainB: "work",
    slug: "leverage-awareness"
  })
});

/**
 * Convert privacy-safe Re_Call aggregates into at most one Harness proposal.
 *
 * The input is deliberately narrow: aggregate signal counts, a declared goal
 * weight, an evidence window, a controlled recommendation question, and a
 * durable source reference. Raw reminder rows and their text are not accepted.
 *
 * @returns {{ candidate: object | null, reason: string | null }}
 */
export function buildHarnessCandidate(input = {}) {
  const shapeReason = inputShapeReason(input);
  if (shapeReason) {
    return noCandidate(shapeReason);
  }

  if (!Array.isArray(input.aggregates) || input.aggregates.length === 0) {
    return noCandidate("No candidate: no aggregate Re_Call evidence was provided.");
  }

  const sourceRef = typeof input.sourceRef === "string" ? input.sourceRef.trim() : "";
  if (!isDurableSourceReference(sourceRef)) {
    return noCandidate("No candidate: a durable source reference is required.");
  }

  if (!validEvidenceWindow(input.evidenceWindow)) {
    return noCandidate("No candidate: a complete ISO-date evidence window is required.");
  }

  if (input.recommendationQuestion !== LEVERAGE_RECOMMENDATION_QUESTION) {
    return noCandidate(
      "No candidate: the evidence must be able to change one named recommendation question."
    );
  }

  if (!["private-aggregate", "synthetic"].includes(input.dataClassification)) {
    return noCandidate(
      "No candidate: data classification must be either private-aggregate or synthetic."
    );
  }

  const ranked = [];
  let hasSupportedStrength = false;
  let hasCountOnlyEvidence = false;

  for (const aggregate of input.aggregates) {
    const strength = SUPPORTED_STRENGTHS[aggregate.strengthId];
    if (!strength) {
      continue;
    }

    hasSupportedStrength = true;
    if (aggregate.goalWeight === undefined) {
      hasCountOnlyEvidence = true;
      continue;
    }

    const counts = normalizedCounts(aggregate.signalCounts);
    const supportingCount = counts.edit + counts.positive + counts.accept;
    const affinityDelta = SIGNAL_TYPES.reduce(
      (total, signalType) => total + counts[signalType] * SIGNAL_DELTAS[signalType],
      0
    );

    if (
      supportingCount < MIN_SUPPORTING_SIGNALS ||
      affinityDelta < MIN_AFFINITY_DELTA ||
      aggregate.goalWeight <= NEUTRAL_GOAL_WEIGHT
    ) {
      continue;
    }

    ranked.push({
      affinityDelta,
      counts,
      goalWeight: aggregate.goalWeight,
      strength,
      strengthId: aggregate.strengthId,
      supportingCount,
      score: evidenceStrength(supportingCount, affinityDelta, aggregate.goalWeight)
    });
  }

  if (ranked.length === 0) {
    if (!hasSupportedStrength) {
      return noCandidate(
        "No candidate: the aggregates do not use a supported Re_Call strength."
      );
    }
    if (hasCountOnlyEvidence) {
      return noCandidate(
        "No candidate: aggregate counts alone are not enough; an above-neutral declared goal weight is required."
      );
    }
    return noCandidate(
      "No candidate: aggregate evidence is too weak to support a meaningful proposal."
    );
  }

  ranked.sort(compareRankedEvidence);
  const selected = ranked[0];
  const syntheticMark =
    input.dataClassification === "synthetic" ? "SYNTHETIC — NOT ADAM'S DATA. " : "";
  const { start, end } = input.evidenceWindow;

  const candidate = {
    id: `cand-recall-${end}-${selected.strength.slug}-${selected.strength.domainA}-${selected.strength.domainB}`,
    status: "pending",
    plain: `AGENT PROPOSAL: ${syntheticMark}${selected.strength.claim}`,
    evidence:
      `${syntheticMark}Re_Call aggregate evidence from ${start} through ${end}: ` +
      `${selected.strengthId} has ${formatCounts(selected.counts)}, ` +
      `a weighted affinity delta of ${selected.affinityDelta.toFixed(2)}, ` +
      `and a declared goal weight of ${selected.goalWeight.toFixed(2)}. ` +
      `Provenance: ${sourceRef}.`,
    source: `Re_Call — ${sourceRef}`,
    domain_a: selected.strength.domainA,
    domain_b: selected.strength.domainB,
    strength: selected.score,
    connection_type: CONNECTION_TYPE
  };

  return { candidate, reason: null };
}

function inputShapeReason(input) {
  if (!isPlainObject(input)) {
    return "No candidate: input must be a privacy-safe aggregate object.";
  }

  const rootUnexpected = unexpectedField(input, ROOT_FIELDS, "input");
  if (rootUnexpected) {
    return privacyReason(rootUnexpected);
  }

  if (input.evidenceWindow !== undefined) {
    if (!isPlainObject(input.evidenceWindow)) {
      return "No candidate: evidenceWindow must contain start and end ISO dates.";
    }
    const windowUnexpected = unexpectedField(
      input.evidenceWindow,
      WINDOW_FIELDS,
      "input.evidenceWindow"
    );
    if (windowUnexpected) {
      return privacyReason(windowUnexpected);
    }
  }

  if (input.aggregates !== undefined && !Array.isArray(input.aggregates)) {
    return "No candidate: aggregates must be an array.";
  }

  for (const [index, aggregate] of (input.aggregates ?? []).entries()) {
    const path = `input.aggregates[${index}]`;
    if (!isPlainObject(aggregate)) {
      return `No candidate: ${path} must be an aggregate object.`;
    }
    const aggregateUnexpected = unexpectedField(aggregate, AGGREGATE_FIELDS, path);
    if (aggregateUnexpected) {
      return privacyReason(aggregateUnexpected);
    }
    if (typeof aggregate.strengthId !== "string" || aggregate.strengthId.length === 0) {
      return `No candidate: ${path}.strengthId is required.`;
    }
    if (!isPlainObject(aggregate.signalCounts)) {
      return `No candidate: ${path}.signalCounts must be an aggregate count object.`;
    }
    const signalUnexpected = unexpectedField(
      aggregate.signalCounts,
      SIGNAL_FIELDS,
      `${path}.signalCounts`
    );
    if (signalUnexpected) {
      return privacyReason(signalUnexpected);
    }
    for (const [signalType, count] of Object.entries(aggregate.signalCounts)) {
      if (!Number.isInteger(count) || count < 0) {
        return `No candidate: ${path}.signalCounts.${signalType} must be a non-negative integer.`;
      }
    }
    if (
      aggregate.goalWeight !== undefined &&
      (!Number.isFinite(aggregate.goalWeight) || aggregate.goalWeight < 0)
    ) {
      return `No candidate: ${path}.goalWeight must be a non-negative number.`;
    }
  }

  return null;
}

function noCandidate(reason) {
  return { candidate: null, reason };
}

function privacyReason(field) {
  return (
    `No candidate: unsupported field ${field}. ` +
    "Raw reminder text, names, due dates, and personal notes are not accepted."
  );
}

function unexpectedField(object, allowedFields, path) {
  const key = Object.keys(object).find((candidate) => !allowedFields.has(candidate));
  return key ? `${path}.${key}` : null;
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isDurableSourceReference(value) {
  return (
    typeof value === "string" &&
    (/^[a-z][a-z0-9+.-]*:\/\//i.test(value) || value.startsWith("/"))
  );
}

function validEvidenceWindow(window) {
  return (
    isPlainObject(window) &&
    isISODate(window.start) &&
    isISODate(window.end) &&
    window.start <= window.end
  );
}

function isISODate(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(date.valueOf()) && date.toISOString().slice(0, 10) === value;
}

function normalizedCounts(signalCounts) {
  return Object.fromEntries(
    SIGNAL_TYPES.map((signalType) => [signalType, signalCounts[signalType] ?? 0])
  );
}

function evidenceStrength(supportingCount, affinityDelta, goalWeight) {
  const countConfidence = Math.min(1, supportingCount / 5);
  const affinityConfidence = Math.min(1, Math.max(0, affinityDelta));
  const goalConfidence = Math.min(1, Math.max(0, (goalWeight - 1) / 2));
  return roundToThree((countConfidence + affinityConfidence + goalConfidence) / 3);
}

function roundToThree(value) {
  return Math.round(value * 1000) / 1000;
}

function compareRankedEvidence(left, right) {
  if (left.score !== right.score) {
    return right.score - left.score;
  }
  if (left.strengthId === right.strengthId) {
    return 0;
  }
  return left.strengthId < right.strengthId ? -1 : 1;
}

function formatCounts(counts) {
  return SIGNAL_TYPES.map((signalType) => `${signalType}=${counts[signalType]}`).join(", ");
}
