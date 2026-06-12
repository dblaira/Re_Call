import Foundation

enum ReminderGenerationProviderKind: String, CaseIterable, Equatable {
    case appleFoundationModels = "apple-foundation-models"
    case applePrivateCloudCompute = "apple-private-cloud-compute"
    case openAI = "openai"
    case graphOnlyFallback = "graph-only-fallback"
}

struct ReminderGenerationFrame: Equatable {
    let id: String
    let intent: String
    let mustInclude: [String]
    let mustAvoid: [String]
}

struct ReminderCopyRequest: Equatable {
    let sourceTemplateId: String
    let sourceTemplateLabel: String
    let recommendationText: String
    let generationFrame: ReminderGenerationFrame?
}

struct ReminderCopyDraft: Equatable {
    let title: String
    let body: String
    let why: String
    let variants: [String]
    let provider: ReminderGenerationProviderKind
}

protocol ReminderGenerationProvider {
    var kind: ReminderGenerationProviderKind { get }
    var isAvailable: Bool { get }

    func draftReminderCopy(for request: ReminderCopyRequest) async throws -> ReminderCopyDraft
}

enum ReminderGenerationProviderError: Error, Equatable {
    case providerUnavailable(ReminderGenerationProviderKind)
}

struct ReminderGenerationProviderRegistry {
    private let providers: [ReminderGenerationProvider]

    init(providers: [ReminderGenerationProvider]) {
        self.providers = providers
    }

    func preferredProvider() -> ReminderGenerationProvider? {
        let priority: [ReminderGenerationProviderKind] = [
            .appleFoundationModels,
            .applePrivateCloudCompute,
            .openAI,
            .graphOnlyFallback
        ]

        return priority
            .compactMap { kind in providers.first { $0.kind == kind && $0.isAvailable } }
            .first
    }
}

struct AppleFoundationModelsReminderProvider: ReminderGenerationProvider {
    let kind = ReminderGenerationProviderKind.appleFoundationModels
    let isAvailable = false

    func draftReminderCopy(for request: ReminderCopyRequest) async throws -> ReminderCopyDraft {
        throw ReminderGenerationProviderError.providerUnavailable(kind)
    }
}
