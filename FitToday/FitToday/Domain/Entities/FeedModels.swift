//
//  FeedModels.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation

// MARK: - Feed Post

struct FeedPost: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let authorId: String
    var authorName: String
    var authorPhotoURL: URL?
    var mediaURL: URL?
    var mediaType: FeedMediaType
    var caption: String?

    // Auto-pulled workout data
    var workoutTitle: String
    var workoutDurationMinutes: Int
    var exerciseCount: Int
    var totalVolume: Double?

    // Social engagement
    var likeCount: Int
    var commentCount: Int
    var likedBy: [String] // Array of userIds who liked

    // Scoping
    var groupId: String

    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        authorId: String,
        authorName: String,
        authorPhotoURL: URL? = nil,
        mediaURL: URL? = nil,
        mediaType: FeedMediaType = .photo,
        caption: String? = nil,
        workoutTitle: String,
        workoutDurationMinutes: Int,
        exerciseCount: Int,
        totalVolume: Double? = nil,
        likeCount: Int = 0,
        commentCount: Int = 0,
        likedBy: [String] = [],
        groupId: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.authorPhotoURL = authorPhotoURL
        self.mediaURL = mediaURL
        self.mediaType = mediaType
        self.caption = caption
        self.workoutTitle = workoutTitle
        self.workoutDurationMinutes = workoutDurationMinutes
        self.exerciseCount = exerciseCount
        self.totalVolume = totalVolume
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.likedBy = likedBy
        self.groupId = groupId
        self.createdAt = createdAt
    }

    func isLiked(by userId: String) -> Bool {
        likedBy.contains(userId)
    }
}

// MARK: - Feed Media Type

enum FeedMediaType: String, Codable, Sendable {
    case photo
    case video
}

// MARK: - Feed Comment

struct FeedComment: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let postId: String
    let authorId: String
    var authorName: String
    var authorPhotoURL: URL?
    var text: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        postId: String,
        authorId: String,
        authorName: String,
        authorPhotoURL: URL? = nil,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.authorName = authorName
        self.authorPhotoURL = authorPhotoURL
        self.text = text
        self.createdAt = createdAt
    }
}

// MARK: - Feed Errors

enum FeedError: Error, LocalizedError {
    case notAuthenticated
    case notInGroup
    case postNotFound
    case mediaUploadFailed(underlying: Error)
    case mediaCompressionFailed
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Você precisa estar logado para usar o feed"
        case .notInGroup:
            return "Você precisa estar em um grupo para postar"
        case .postNotFound:
            return "Post não encontrado"
        case .mediaUploadFailed:
            return "Falha ao enviar mídia. Tente novamente."
        case .mediaCompressionFailed:
            return "Falha ao comprimir mídia"
        case .unauthorized:
            return "Você não tem permissão para esta ação"
        }
    }
}

// MARK: - Constants

extension FeedPost {
    static let maxVideoBytes = 5_000_000 // 5MB
    static let maxPhotoBytes = 1_000_000 // 1MB
}
