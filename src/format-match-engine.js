import defaultRules from "../data/format-match-rules.json" with { type: "json" };

export const SignalType = Object.freeze({
  HierarchicalWin: "HierarchicalWinSignal"
});

export const TranslationFormatType = Object.freeze({
  MindMap: "MindMapFormat"
});

export function getBestFormat(userSignal, options = {}) {
  if (!userSignal || typeof userSignal !== "object") {
    throw new TypeError("getBestFormat requires a userSignal object.");
  }

  const rules = options.rules || defaultRules;
  const signalType = userSignal.type;
  const matchingRule = rules.find((rule) => rule.triggeredBySignal === signalType);

  if (!matchingRule) {
    return {
      format: {
        id: "ReminderCardFormat",
        label: "Reminder card",
        shape: "card"
      },
      confidence: "low",
      decision: "fallback",
      reason: "No semantic format rule matched this signal yet.",
      matchedRule: null,
      diagnosticQuestion: "Is this the best match for describing what just happened?"
    };
  }

  return {
    format: toTranslationFormat(matchingRule.prefersFormat),
    confidence: "high",
    decision: "semantic-rule-match",
    reason: matchingRule.reason,
    matchedRule: {
      id: matchingRule.id,
      label: matchingRule.label,
      acceptanceCriterion: matchingRule.acceptanceCriterion,
      source: matchingRule.source
    },
    diagnosticQuestion: "Is this the best match for describing what just happened?"
  };
}

function toTranslationFormat(formatId) {
  if (formatId === TranslationFormatType.MindMap) {
    return {
      id: TranslationFormatType.MindMap,
      label: "Mind map format",
      shape: "mind_map"
    };
  }

  return {
    id: formatId,
    label: formatId,
    shape: "unknown"
  };
}
