//
//  CreateFeedPostUseCase.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation

struct CreateFeedPostUseCase: Sendable {
    private let feedRepository: FeedRepository
    private let authRepository: AuthenticationRepository
    private let imageCompressor: ImageCompressing

    init(
        feedRepository: FeedRepository,
        authRepository: AuthenticationRepository,
        imageCompressor: ImageCompressing
    ) {
        self.feedRepository = feedRepository
        self.authRepository = authRepository
        self.imageCompressor = imageCompressor
    }

    func execute(
        mediaData: Data?,
        mediaType: FeedMediaType,
        caption: String?,
        workoutTitle: String,
        workoutDurationMinutes: Int,
        exerciseCount: Int,
        totalVolume: Double?
    ) async throws -> FeedPost {
        guard let user = try await authRepository.currentUser() else {
            throw FeedError.notAuthenticated
        }

        guard let groupId = user.currentGroupId else {
            throw FeedError.notInGroup
        }

        // Compress media if present
        var compressedData: Data?
        if let data = mediaData {
            switch mediaType {
            case .photo:
                compressedData = try imageCompressor.compress(
                    data: data,
                    maxBytes: FeedPost.maxPhotoBytes,
                    quality: 0.8
                )
            case .video:
                // Video data passed as-is (compressed upstream by AVFoundation)
                guard data.count <= FeedPost.maxVideoBytes else {
                    throw FeedError.mediaCompressionFailed
                }
                compressedData = data
            }
        }

        let post = FeedPost(
            authorId: user.id,
            authorName: user.displayName,
            authorPhotoURL: user.photoURL,
            mediaType: mediaType,
            caption: caption,
            workoutTitle: workoutTitle,
            workoutDurationMinutes: workoutDurationMinutes,
            exerciseCount: exerciseCount,
            totalVolume: totalVolume,
            groupId: groupId
        )

        return try await feedRepository.createPost(post, mediaData: compressedData)
    }
}
