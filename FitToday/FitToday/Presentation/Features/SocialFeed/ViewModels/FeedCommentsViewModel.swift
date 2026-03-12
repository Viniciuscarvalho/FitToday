//
//  FeedCommentsViewModel.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation

@MainActor
@Observable
final class FeedCommentsViewModel {
    // MARK: - State

    private(set) var comments: [FeedComment] = []
    private(set) var isLoading = false
    var commentText: String = ""
    var errorMessage: String?

    var canSubmit: Bool { !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    // MARK: - Dependencies

    private let feedRepository: FeedRepository
    private let authRepository: AuthenticationRepository
    private let postId: String
    nonisolated(unsafe) private var observeTask: Task<Void, Never>?

    // MARK: - Init

    init(
        feedRepository: FeedRepository,
        authRepository: AuthenticationRepository,
        postId: String
    ) {
        self.feedRepository = feedRepository
        self.authRepository = authRepository
        self.postId = postId
    }

    // MARK: - Methods

    func startObserving() {
        observeTask?.cancel()
        observeTask = Task { [weak self] in
            guard let self else { return }
            for await newComments in feedRepository.observeComments(postId: postId) {
                self.comments = newComments
                self.isLoading = false
            }
        }
        isLoading = true
    }

    nonisolated func stopObserving() {
        observeTask?.cancel()
        observeTask = nil
    }

    func addComment() async {
        guard canSubmit else { return }

        guard let user = try? await authRepository.currentUser() else {
            errorMessage = FeedError.notAuthenticated.localizedDescription
            return
        }

        let comment = FeedComment(
            postId: postId,
            authorId: user.id,
            authorName: user.displayName,
            authorPhotoURL: user.photoURL,
            text: commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        commentText = ""

        do {
            try await feedRepository.addComment(comment)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    deinit {
        stopObserving()
    }
}
