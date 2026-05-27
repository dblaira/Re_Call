import assert from "node:assert/strict";
import test from "node:test";
import { getBestFormat, SignalType, TranslationFormatType } from "../src/format-match-engine.js";

test("HierarchicalWinSignal resolves to MindMapFormat", () => {
  const result = getBestFormat({
    type: SignalType.HierarchicalWin,
    text: "The win was building a hierarchy that preserved the advantage of AI while avoiding downside consequences."
  });

  assert.equal(result.format.id, TranslationFormatType.MindMap);
  assert.equal(result.format.shape, "mind_map");
  assert.equal(result.decision, "semantic-rule-match");
  assert.equal(result.confidence, "high");
  assert.match(result.reason, /hierarchy/i);
  assert.equal(result.matchedRule.id, "FormatMatchEngineRequirement");
});

test("unknown signals return an explicit fallback format", () => {
  const result = getBestFormat({
    type: "UnknownSignal",
    text: "A signal without a modeled format rule yet."
  });

  assert.equal(result.format.id, "ReminderCardFormat");
  assert.equal(result.decision, "fallback");
  assert.equal(result.confidence, "low");
  assert.equal(result.matchedRule, null);
});
