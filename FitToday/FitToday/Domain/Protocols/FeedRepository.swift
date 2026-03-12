//
//  FeedRepository.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation

// MARK: - Feed Repository

protocol FeedRepository: Sendable {
    /// Creates a new feed post with optional media upload.
    func createPost(_ post: FeedPost, mediaData: Data?) async throws -> FeedPost

    /// Deletes a feed post and its media.
    func deletePost(_ postId: String, authorId: String) async throws

    /// Fetches feed posts for a group with pagination.
    func getPosts(groupId: String, limit: Int, after: Date?) async throws -> [FeedPost]

    /// Observes feed posts for a group in real-time.
    func observePosts(groupId: String) -> AsyncStream<[FeedPost]>

    /// Toggles like on a post. Returns true if now liked, false if unliked.
    func toggleLike(postId: String, userId: String) async throws -> Bool

    /// Adds a comment to a post.
    func addComment(_ comment: FeedComment) async throws

    /// Fetches comments for a post.
    func getComments(postId: String, limit: Int) async throws -> [FeedComment]

    /// Observes comments for a post in real-time.
    func observeComments(postId: String) -> AsyncStream<[FeedComment]>
}
