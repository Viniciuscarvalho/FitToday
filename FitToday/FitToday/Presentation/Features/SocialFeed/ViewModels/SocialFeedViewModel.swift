//
//  SocialFeedViewModel.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation

@MainActor
@Observable
final class SocialFeedViewModel {
    // MARK: - State

    private(set) var posts: [FeedPost] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let feedRepository: FeedRepository
    private let authRepository: AuthenticationRepository
    private let deleteFeedPostUseCase: DeleteFeedPostUseCase
    private var currentUserId: String?
    private var currentGroupId: String?
    nonisolated(unsafe) private var observeTask: Task<Void, Never>?

    // MARK: - Init

    init(
        feedRepository: FeedRepository,
        authRepository: AuthenticationRepository,
        deleteFeedPostUseCase: DeleteFeedPostUseCase
    ) {
        self.feedRepository = feedRepository
        self.authRepository = authRepository
        self.deleteFeedPostUseCase = deleteFeedPostUseCase
    }

    // MARK: - Load

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let user = try await authRepository.currentUser() else {
                errorMessage = FeedError.notAuthenticated.localizedDescription
                return
            }
            currentUserId = user.id
            currentGroupId = user.currentGroupId

            guard let groupId = user.currentGroupId else {
                errorMessage = FeedError.notInGroup.localizedDescription
                return
            }

            posts = try await feedRepository.getPosts(groupId: groupId, limit: 50, after: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Real-time Observation

    func startObserving() {
        observeTask?.cancel()
        observeTask = Task { [weak self] in
            guard let self else { return }

            do {
                guard let user = try await authRepository.currentUser(),
                      let groupId = user.currentGroupId else { return }
                currentUserId = user.id
                currentGroupId = groupId

                for await newPosts in feedRepository.observePosts(groupId: groupId) {
                    self.posts = newPosts
                    self.isLoading = false
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
        isLoading = true
    }

    nonisolated func stopObserving() {
        observeTask?.cancel()
        observeTask = nil
    }

    // MARK: - Actions

    func toggleLike(postId: String) async {
        guard let userId = currentUserId else { return }

        do {
            let isLiked = try await feedRepository.toggleLike(postId: postId, userId: userId)

            // Optimistic update
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                var post = posts[index]
                if isLiked {
                    post.likedBy.append(userId)
                    post.likeCount += 1
                } else {
                    post.likedBy.removeAll { $0 == userId }
                    post.likeCount = max(0, post.likeCount - 1)
                }
                posts[index] = post
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deletePost(_ postId: String) async {
        do {
            try await deleteFeedPostUseCase.execute(postId: postId)
            posts.removeAll { $0.id == postId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isCurrentUser(_ authorId: String) -> Bool {
        currentUserId == authorId
    }

    func isPostLiked(_ post: FeedPost) -> Bool {
        guard let userId = currentUserId else { return false }
        return post.isLiked(by: userId)
    }

    deinit {
        stopObserving()
    }
}
