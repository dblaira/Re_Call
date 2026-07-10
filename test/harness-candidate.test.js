import assert from "node:assert/strict";
import test from "node:test";
import {
  buildHarnessCandidate,
  LEVERAGE_RECOMMENDATION_QUESTION
} from "../src/harness-candidate.js";

const REQUIRED_FIELDS = [
  "connection_type",
  "domain_a",
  "domain_b",
  "evidence",
  "id",
  "plain",
  "source",
  "status",
  "strength"
];

function eligibleInput() {
  return {
    aggregates: [
      {
        strengthId: "ExecutionLeverage",
        signalCounts: { edit: 1, positive: 1, accept: 1, dismiss: 0 },
        goalWeight: 3
      }
    ],
    dataClassification: "synthetic",
    evidenceWindow: { start: "2026-06-10", end: "2026-07-10" },
    recommendationQuestion: LEVERAGE_RECOMMENDATION_QUESTION,
    sourceRef: "recall://synthetic/aggregate-snapshots/2026-07-10/leverage"
  };
}

test("eligible aggregate behavior plus a declared goal returns one complete Harness envelope", () => {
  const { candidate, reason } = buildHarnessCandidate(eligibleInput());

  assert.equal(reason, null);
  assert.deepEqual(Object.keys(candidate).sort(), REQUIRED_FIELDS);
  assert.match(candidate.id, /^cand-recall-2026-07-10-/);
  assert.match(candidate.plain, /^AGENT PROPOSAL:/);
  assert.match(candidate.evidence, /^SYNTHETIC — NOT ADAM'S DATA\./);
  assert.equal(candidate.domain_a, "ambition");
  assert.equal(candidate.domain_b, "work");
  assert.equal(candidate.connection_type, "aggregate_goal_alignment");
  assert.ok(candidate.strength >= 0 && candidate.strength <= 1);
});

test("weak evidence returns null with a plain reason", () => {
  const input = eligibleInput();
  input.aggregates[0].signalCounts = { edit: 1 };

  const result = buildHarnessCandidate(input);

  assert.equal(result.candidate, null);
  assert.match(result.reason, /too weak/);
});

test("missing provenance returns no candidate", () => {
  const input = eligibleInput();
  input.sourceRef = "";

  const result = buildHarnessCandidate(input);

  assert.equal(result.candidate, null);
  assert.match(result.reason, /durable source reference/);
});

test("zero or empty input returns no candidate", () => {
  assert.equal(buildHarnessCandidate().candidate, null);
  assert.match(buildHarnessCandidate().reason, /no aggregate Re_Call evidence/);

  const input = eligibleInput();
  input.aggregates = [];
  assert.equal(buildHarnessCandidate(input).candidate, null);
});

test("aggregate counts without a declared goal weight are rejected as count-only evidence", () => {
  const input = eligibleInput();
  delete input.aggregates[0].goalWeight;

  const result = buildHarnessCandidate(input);

  assert.equal(result.candidate, null);
  assert.match(result.reason, /counts alone are not enough/);
});

test("evidence that cannot change the controlled recommendation question is rejected", () => {
  const input = eligibleInput();
  input.recommendationQuestion = "How many aggregate signals exist?";

  const result = buildHarnessCandidate(input);

  assert.equal(result.candidate, null);
  assert.match(result.reason, /one named recommendation question/);
});

test("multiple eligible aggregates still return exactly one, highest-ranked candidate", () => {
  const input = eligibleInput();
  input.aggregates.push({
    strengthId: "LeverageAwareness",
    signalCounts: { edit: 3, positive: 2, accept: 2, dismiss: 0 },
    goalWeight: 3
  });

  const result = buildHarnessCandidate(input);

  assert.ok(result.candidate);
  assert.equal(Array.isArray(result.candidate), false);
  assert.match(result.candidate.id, /leverage-awareness/);
});

test("raw-text fields are refused and never appear in an eligible envelope", () => {
  const unsafe = eligibleInput();
  unsafe.aggregates[0].reminderTitle = "PRIVATE REMINDER TEXT";

  const refused = buildHarnessCandidate(unsafe);
  assert.equal(refused.candidate, null);
  assert.match(refused.reason, /Raw reminder text, names, due dates, and personal notes/);

  const { candidate } = buildHarnessCandidate(eligibleInput());
  const serialized = JSON.stringify(candidate);
  assert.doesNotMatch(serialized, /PRIVATE REMINDER TEXT/);
  assert.deepEqual(Object.keys(candidate).sort(), REQUIRED_FIELDS);
});

test("candidate id is stable across repeated calls and aggregate input order", () => {
  const firstInput = eligibleInput();
  firstInput.aggregates.push({
    strengthId: "LeverageAwareness",
    signalCounts: { edit: 0, positive: 2, accept: 1, dismiss: 0 },
    goalWeight: 2
  });
  const secondInput = eligibleInput();
  secondInput.aggregates.unshift(firstInput.aggregates[1]);

  const first = buildHarnessCandidate(firstInput).candidate;
  const second = buildHarnessCandidate(secondInput).candidate;

  assert.equal(first.id, second.id);
  assert.equal(first.id, "cand-recall-2026-07-10-execution-leverage-ambition-work");
});

test("eligible output status is exactly pending", () => {
  const { candidate } = buildHarnessCandidate(eligibleInput());

  assert.equal(candidate.status, "pending");
  assert.notEqual(candidate.status, "accepted");
});

test("invalid evidence windows and unsupported fields fail closed", () => {
  const invalidDate = eligibleInput();
  invalidDate.evidenceWindow.end = "2026-02-30";
  assert.equal(buildHarnessCandidate(invalidDate).candidate, null);

  const rawNote = eligibleInput();
  rawNote.personalNotes = "must never be accepted";
  const result = buildHarnessCandidate(rawNote);
  assert.equal(result.candidate, null);
  assert.match(result.reason, /unsupported field input\.personalNotes/);
});
