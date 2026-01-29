//
//  CheckInFeedViewModel.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import Foundation

// MARK: - CheckInFeedViewModel

/// ViewModel for managing the check-in feed with real-time updates.
@MainActor
@Observable
final class CheckInFeedViewModel {
    // MARK: - State

    private(set) var checkIns: [CheckIn] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let checkInRepository: CheckInRepository
    private let groupId: String
    nonisolated(unsafe) private var observeTask: Task<Void, Never>?

    // MARK: - Init

    init(checkInRepository: CheckInRepository, groupId: String) {
        self.checkInRepository = checkInRepository
        self.groupId = groupId
    }

    // MARK: - Methods

    func startObserving() {
        observeTask?.cancel()
        observeTask = Task { [weak self] in
            guard let self else { return }
            for await newCheckIns in checkInRepository.observeCheckIns(groupId: groupId) {
                self.checkIns = newCheckIns
                self.isLoading = false
            }
        }
        isLoading = true
    }

    nonisolated func stopObserving() {
        observeTask?.cancel()
        observeTask = nil
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            checkIns = try await checkInRepository.getCheckIns(
                groupId: groupId,
                limit: 50,
                after: nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    deinit {
        stopObserving()
    }
}
