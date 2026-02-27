//
//  AIChatViewModel.swift
//  FitToday
//
//  ViewModel for the AI FitOrb chat feature.
//

import Foundation
import Swinject

@MainActor
@Observable
final class AIChatViewModel: ErrorPresenting {

    // MARK: - Properties

    var messages: [AIChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var isTyping: Bool = false
    var errorMessage: ErrorMessage?
    private(set) var quickActions: [String] = []

    // MARK: - Private

    private let chatService: AIChatService?
    private let chatRepository: ChatRepository?
    private let featureGating: FeatureGating?
    private let usageTracker: AIUsageTracking?
    private let profileRepository: UserProfileRepository?
    private let statsRepository: UserStatsRepository?
    private var typingTask: Task<Void, Never>?

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.chatService = resolver.resolve(AIChatService.self)
        self.chatRepository = resolver.resolve(ChatRepository.self)
        self.featureGating = resolver.resolve(FeatureGating.self)
        self.usageTracker = resolver.resolve(AIUsageTracking.self)
        self.profileRepository = resolver.resolve(UserProfileRepository.self)
        self.statsRepository = resolver.resolve(UserStatsRepository.self)
        // Set default quick actions
        self.quickActions = Self.defaultQuickActions
    }

    // MARK: - Computed

    var isChatAvailable: Bool {
        chatService != nil
    }

    // MARK: - Actions

    func loadHistory() async {
        guard let repo = chatRepository else { return }
        do {
            messages = try await repo.loadMessages(limit: 50)
        } catch {
            handleError(error)
        }
        await loadQuickActions()
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading, !isTyping else { return }

        guard chatService != nil else {
            errorMessage = ErrorMessage(
                title: "error.openai.not_configured.title".localized,
                message: "fitorb.error_no_api_key".localized,
                action: .dismiss
            )
            return
        }

        // Cancel any ongoing typing animation
        typingTask?.cancel()
        typingTask = nil

        let userMessage = AIChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        Task {
            // Check message limit for free users
            if let gating = featureGating {
                let access = await gating.checkAccess(to: .aiChat)
                guard access.isAllowed else {
                    isLoading = false
                    // Remove the user message we just appended
                    if messages.last?.role == .user {
                        messages.removeLast()
                    }
                    handleError(DomainError.chatMessageLimitReached)
                    return
                }
            }

            // Save user message
            try? await chatRepository?.saveMessage(userMessage)

            do {
                let response = try await chatService!.sendMessage(text, history: messages)

                // Register chat usage
                await usageTracker?.registerChatUsage()

                // Animate typing effect
                await animateTyping(response: response)
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }

    func clearHistory() async {
        typingTask?.cancel()
        typingTask = nil
        isTyping = false
        messages.removeAll()
        try? await chatRepository?.clearHistory()
        await chatService?.invalidatePromptCache()
        await loadQuickActions()
    }

    // MARK: - Typing Animation

    private func animateTyping(response: String) async {
        // Create assistant message with empty content
        let messageId = UUID()
        let placeholder = AIChatMessage(id: messageId, role: .assistant, content: "")
        messages.append(placeholder)
        isLoading = false
        isTyping = true

        let chunkSize = 5
        var currentIndex = response.startIndex

        typingTask = Task { [weak self] in
            while currentIndex < response.endIndex && !Task.isCancelled {
                let nextIndex = response.index(currentIndex, offsetBy: chunkSize, limitedBy: response.endIndex) ?? response.endIndex
                let partialContent = String(response[response.startIndex..<nextIndex])
                currentIndex = nextIndex

                await MainActor.run {
                    guard let self else { return }
                    // Replace last message with updated content
                    if let lastIndex = self.messages.lastIndex(where: { $0.id == messageId }) {
                        self.messages[lastIndex] = AIChatMessage(
                            id: messageId,
                            role: .assistant,
                            content: partialContent,
                            timestamp: placeholder.timestamp
                        )
                    }
                }

                try? await Task.sleep(nanoseconds: 15_000_000) // 15ms
            }

            // Save final message after animation
            let finalMessage = AIChatMessage(
                id: messageId,
                role: .assistant,
                content: response,
                timestamp: placeholder.timestamp
            )

            await MainActor.run { [weak self] in
                guard let self else { return }
                if let lastIndex = self.messages.lastIndex(where: { $0.id == messageId }) {
                    self.messages[lastIndex] = finalMessage
                }
                self.isTyping = false
            }

            try? await self?.chatRepository?.saveMessage(finalMessage)
        }
    }

    // MARK: - Quick Actions

    private static var defaultQuickActions: [String] {
        [
            "fitorb.quick.plan_workout".localized,
            "fitorb.quick.suggest_exercises".localized,
            "fitorb.quick.warmup".localized,
            "fitorb.quick.recovery".localized
        ]
    }

    private func loadQuickActions() async {
        var actions: [String] = []

        let profile = try? await profileRepository?.loadProfile()
        let stats = try? await statsRepository?.getCurrentStats()

        let hour = Calendar.current.component(.hour, from: Date())

        // Time-based suggestions
        if hour < 12 {
            actions.append("fitorb.quick.morning_warmup".localized)
        } else if hour >= 20 {
            actions.append("fitorb.quick.evening_stretch".localized)
        }

        // Workout status today
        if let lastDate = stats?.lastWorkoutDate,
           Calendar.current.isDateInToday(lastDate) {
            actions.append("fitorb.quick.recovery".localized)
        } else {
            actions.append("fitorb.quick.suggest_today".localized)
        }

        // Goal-specific suggestions
        if let goal = profile?.mainGoal {
            switch goal {
            case .hypertrophy:
                actions.append("fitorb.quick.muscle_tips".localized)
            case .weightLoss:
                actions.append("fitorb.quick.fat_burn_tips".localized)
            case .endurance:
                actions.append("fitorb.quick.endurance_tips".localized)
            case .conditioning, .performance:
                actions.append("fitorb.quick.performance_tips".localized)
            }
        }

        // Always include a generic option
        actions.append("fitorb.quick.plan_workout".localized)

        // Limit to 4 chips
        quickActions = Array(actions.prefix(4))

        // Fallback if empty
        if quickActions.isEmpty {
            quickActions = Self.defaultQuickActions
        }
    }
}
