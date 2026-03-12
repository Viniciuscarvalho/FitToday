//
//  DeleteFeedPostUseCase.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation

struct DeleteFeedPostUseCase: Sendable {
    private let feedRepository: FeedRepository
    private let authRepository: AuthenticationRepository

    init(
        feedRepository: FeedRepository,
        authRepository: AuthenticationRepository
    ) {
        self.feedRepository = feedRepository
        self.authRepository = authRepository
    }

    func execute(postId: String) async throws {
        guard let user = try await authRepository.currentUser() else {
            throw FeedError.notAuthenticated
        }

        try await feedRepository.deletePost(postId, authorId: user.id)
    }
}
