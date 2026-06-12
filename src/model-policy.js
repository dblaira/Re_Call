export const OpenAIModelTier = Object.freeze({
  Tiny: "tiny",
  Standard: "standard",
  Reasoning: "reasoning"
});

export const GenerationProviderKind = Object.freeze({
  AppleFoundationModels: "apple-foundation-models",
  ApplePrivateCloudCompute: "apple-private-cloud-compute",
  OpenAI: "openai",
  GraphOnlyFallback: "graph-only-fallback"
});

const IOS_PROVIDER_PRIORITY = Object.freeze([
  GenerationProviderKind.AppleFoundationModels,
  GenerationProviderKind.ApplePrivateCloudCompute,
  GenerationProviderKind.OpenAI,
  GenerationProviderKind.GraphOnlyFallback
]);

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

export function selectGenerationProvider({ runtime = "server", providers = [] } = {}) {
  if (providers.length === 0) {
    return null;
  }

  if (runtime === "ios") {
    return IOS_PROVIDER_PRIORITY
      .map((kind) =>
        providers.find(
          (provider) => provider.kind === kind && provider.draftReminderCopy && provider.isAvailable !== false
        )
      )
      .find(Boolean) ?? null;
  }

  return providers.find((provider) => provider.draftReminderCopy && provider.isAvailable !== false) ?? null;
}
