export const OpenAIModelTier = Object.freeze({
  Tiny: "tiny",
  Standard: "standard",
  Reasoning: "reasoning"
});

export const defaultOpenAIModelPolicy = Object.freeze({
  [OpenAIModelTier.Tiny]: process.env.RECALL_OPENAI_TINY_MODEL || "gpt-5-nano",
  [OpenAIModelTier.Standard]: process.env.RECALL_OPENAI_STANDARD_MODEL || "gpt-5-mini",
  [OpenAIModelTier.Reasoning]: process.env.RECALL_OPENAI_REASONING_MODEL || "gpt-5"
});

export function selectOpenAIModel({ tier = OpenAIModelTier.Standard, policy = defaultOpenAIModelPolicy } = {}) {
  if (!policy[tier]) {
    throw new RangeError(`Unknown OpenAI model tier: ${tier}`);
  }

  return policy[tier];
}

export function chooseReminderCopyTier({ graphDecision, needsHardReasoning = false } = {}) {
  if (needsHardReasoning) {
    return OpenAIModelTier.Reasoning;
  }

  if (graphDecision === "fallback") {
    return OpenAIModelTier.Tiny;
  }

  return OpenAIModelTier.Standard;
}
