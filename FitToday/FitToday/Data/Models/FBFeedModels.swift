//
//  FBFeedModels.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Feed Post DTO

struct FBFeedPost: Codable {
    @DocumentID var id: String?
    var authorId: String
    var authorName: String
    var authorPhotoURL: String?
    var mediaURL: String?
    var mediaType: String // "photo" | "video"
    var caption: String?
    var workoutTitle: String
    var workoutDurationMinutes: Int
    var exerciseCount: Int
    var totalVolume: Double?
    var likeCount: Int
    var commentCount: Int
    var likedBy: [String]
    var groupId: String
    @ServerTimestamp var createdAt: Timestamp?

    init(from post: FeedPost) {
        self.id = post.id
        self.authorId = post.authorId
        self.authorName = post.authorName
        self.authorPhotoURL = post.authorPhotoURL?.absoluteString
        self.mediaURL = post.mediaURL?.absoluteString
        self.mediaType = post.mediaType.rawValue
        self.caption = post.caption
        self.workoutTitle = post.workoutTitle
        self.workoutDurationMinutes = post.workoutDurationMinutes
        self.exerciseCount = post.exerciseCount
        self.totalVolume = post.totalVolume
        self.likeCount = post.likeCount
        self.commentCount = post.commentCount
        self.likedBy = post.likedBy
        self.groupId = post.groupId
        self.createdAt = Timestamp(date: post.createdAt)
    }

    func toDomain() -> FeedPost? {
        guard let id else { return nil }

        return FeedPost(
            id: id,
            authorId: authorId,
            authorName: authorName,
            authorPhotoURL: authorPhotoURL.flatMap(URL.init),
            mediaURL: mediaURL.flatMap(URL.init),
            mediaType: FeedMediaType(rawValue: mediaType) ?? .photo,
            caption: caption,
            workoutTitle: workoutTitle,
            workoutDurationMinutes: workoutDurationMinutes,
            exerciseCount: exerciseCount,
            totalVolume: totalVolume,
            likeCount: likeCount,
            commentCount: commentCount,
            likedBy: likedBy,
            groupId: groupId,
            createdAt: createdAt?.dateValue() ?? Date()
        )
    }
}

// MARK: - Feed Comment DTO

struct FBFeedComment: Codable {
    @DocumentID var id: String?
    var postId: String
    var authorId: String
    var authorName: String
    var authorPhotoURL: String?
    var text: String
    @ServerTimestamp var createdAt: Timestamp?

    init(from comment: FeedComment) {
        self.id = comment.id
        self.postId = comment.postId
        self.authorId = comment.authorId
        self.authorName = comment.authorName
        self.authorPhotoURL = comment.authorPhotoURL?.absoluteString
        self.text = comment.text
        self.createdAt = Timestamp(date: comment.createdAt)
    }

    func toDomain() -> FeedComment? {
        guard let id else { return nil }

        return FeedComment(
            id: id,
            postId: postId,
            authorId: authorId,
            authorName: authorName,
            authorPhotoURL: authorPhotoURL.flatMap(URL.init),
            text: text,
            createdAt: createdAt?.dateValue() ?? Date()
        )
    }
}
