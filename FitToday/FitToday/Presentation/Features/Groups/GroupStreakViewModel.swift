//
//  GroupStreakViewModel.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import Foundation
import Swinject

// MARK: - GroupStreakViewModel

@MainActor
@Observable final class GroupStreakViewModel {
    // MARK: - Properties

    private(set) var streakStatus: GroupStreakStatus?
    private(set) var isLoading = false
    private(set) var error: GroupStreakError?
    private(set) var showMilestoneOverlay = false
    private(set) var reachedMilestone: StreakMilestone?
    private(set) var isPausingStreak = false

    nonisolated(unsafe) private var observeTask: Task<Void, Never>?
    private let resolver: Resolver
    private var lastMilestone: StreakMilestone?

    // MARK: - Computed Properties

    var currentUserStatus: MemberWeeklyStatus? {
        // Returns the first member's status as a simple implementation
        // In a real app, we'd track the current user ID separately
        streakStatus?.currentWeek?.memberCompliance.first
    }

    var membersAtRisk: [MemberWeeklyStatus] {
        guard let members = streakStatus?.currentWeek?.memberCompliance else {
            return []
        }
        return members.filter { !$0.isCompliant && $0.workoutCount > 0 }
    }

    var hasActiveStreak: Bool {
        streakStatus?.hasActiveStreak ?? false
    }

    var isPaused: Bool {
        streakStatus?.isPaused ?? false
    }

    var canPause: Bool {
        guard let status = streakStatus else { return false }
        return status.hasActiveStreak && !status.isPaused && !status.pauseUsedThisMonth
    }

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: - Public Methods

    func startObserving(groupId: String) {
        guard let repo = resolver.resolve(GroupStreakRepository.self) else {
            error = GroupStreakError.unknownError(
                underlying: NSError(domain: "GroupStreak", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Repository not available"
                ])
            )
            return
        }

        isLoading = true
        error = nil

        observeTask = Task {
            for await status in repo.observeStreakStatus(groupId: groupId) {
                await MainActor.run {
                    self.handleStatusUpdate(status)
                }
            }
        }
    }

    func stopObserving() {
        observeTask?.cancel()
        observeTask = nil
    }

    func pauseStreak(days: Int) async {
        guard let status = streakStatus else { return }
        guard let pauseUseCase = resolver.resolve(PauseGroupStreakUseCaseProtocol.self) else {
            error = GroupStreakError.unknownError(
                underlying: NSError(domain: "GroupStreak", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Pause use case not available"
                ])
            )
            return
        }

        isPausingStreak = true
        error = nil

        do {
            try await pauseUseCase.pause(groupId: status.groupId, days: days)
            isPausingStreak = false
        } catch let streakError as GroupStreakError {
            error = streakError
            isPausingStreak = false
        } catch {
            self.error = GroupStreakError.unknownError(underlying: error)
            isPausingStreak = false
        }
    }

    func resumeStreak() async {
        guard let status = streakStatus else { return }
        guard let pauseUseCase = resolver.resolve(PauseGroupStreakUseCaseProtocol.self) else {
            return
        }

        isPausingStreak = true
        error = nil

        do {
            try await pauseUseCase.resume(groupId: status.groupId)
            isPausingStreak = false
        } catch let streakError as GroupStreakError {
            error = streakError
            isPausingStreak = false
        } catch {
            self.error = GroupStreakError.unknownError(underlying: error)
            isPausingStreak = false
        }
    }

    func dismissMilestoneOverlay() {
        showMilestoneOverlay = false
        reachedMilestone = nil
    }

    func dismissError() {
        error = nil
    }

    // MARK: - Private Methods

    private func handleStatusUpdate(_ status: GroupStreakStatus) {
        let previousStatus = self.streakStatus
        self.streakStatus = status
        self.isLoading = false

        // Detect newly achieved milestone
        if let newMilestone = status.justAchievedMilestone,
           lastMilestone != newMilestone {
            // Check if this is a new milestone (not just re-observing the same one)
            if previousStatus?.lastMilestone != newMilestone {
                reachedMilestone = newMilestone
                showMilestoneOverlay = true
            }
        }
        lastMilestone = status.lastMilestone
    }

    // MARK: - Deinit

    deinit {
        observeTask?.cancel()
    }
}
