//
//  FirebaseFeedRepository.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation

// MARK: - Firebase Feed Repository

final class FirebaseFeedRepository: FeedRepository, @unchecked Sendable {
    private let feedService: FirebaseFeedService
    private let storageService: StorageServicing

    init(feedService: FirebaseFeedService, storageService: StorageServicing) {
        self.feedService = feedService
        self.storageService = storageService
    }

    func createPost(_ post: FeedPost, mediaData: Data?) async throws -> FeedPost {
        var updatedPost = post

        // Upload media if present
        if let mediaData {
            let ext = post.mediaType == .video ? "mp4" : "jpg"
            let path = "feed/\(post.authorId)/\(post.id).\(ext)"
            let url = try await storageService.uploadImage(data: mediaData, path: path)
            updatedPost = FeedPost(
                id: post.id,
                authorId: post.authorId,
                authorName: post.authorName,
                authorPhotoURL: post.authorPhotoURL,
                mediaURL: url,
                mediaType: post.mediaType,
                caption: post.caption,
                workoutTitle: post.workoutTitle,
                workoutDurationMinutes: post.workoutDurationMinutes,
                exerciseCount: post.exerciseCount,
                totalVolume: post.totalVolume,
                groupId: post.groupId,
                createdAt: post.createdAt
            )
        }

        let fbPost = FBFeedPost(from: updatedPost)
        let created = try await feedService.createPost(fbPost)
        guard let domain = created.toDomain() else {
            throw FeedError.postNotFound
        }
        return domain
    }

    func deletePost(_ postId: String, authorId: String) async throws {
        // Delete media from storage (best effort)
        let jpgPath = "feed/\(authorId)/\(postId).jpg"
        let mp4Path = "feed/\(authorId)/\(postId).mp4"
        try? await storageService.deleteImage(path: jpgPath)
        try? await storageService.deleteImage(path: mp4Path)

        try await feedService.deletePost(postId)
    }

    func getPosts(groupId: String, limit: Int, after: Date?) async throws -> [FeedPost] {
        let fbPosts = try await feedService.getPosts(groupId: groupId, limit: limit, after: after)
        return fbPosts.compactMap { $0.toDomain() }
    }

    func observePosts(groupId: String) -> AsyncStream<[FeedPost]> {
        AsyncStream { continuation in
            let task = Task {
                for await fbPosts in await feedService.observePosts(groupId: groupId) {
                    let posts = fbPosts.compactMap { $0.toDomain() }
                    continuation.yield(posts)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func toggleLike(postId: String, userId: String) async throws -> Bool {
        try await feedService.toggleLike(postId: postId, userId: userId)
    }

    func addComment(_ comment: FeedComment) async throws {
        let fbComment = FBFeedComment(from: comment)
        try await feedService.addComment(fbComment)
    }

    func getComments(postId: String, limit: Int) async throws -> [FeedComment] {
        let fbComments = try await feedService.getComments(postId: postId, limit: limit)
        return fbComments.compactMap { $0.toDomain() }
    }

    func observeComments(postId: String) -> AsyncStream<[FeedComment]> {
        AsyncStream { continuation in
            let task = Task {
                for await fbComments in await feedService.observeComments(postId: postId) {
                    let comments = fbComments.compactMap { $0.toDomain() }
                    continuation.yield(comments)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
