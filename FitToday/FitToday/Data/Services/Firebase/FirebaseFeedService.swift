//
//  FirebaseFeedService.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Firebase Feed Service

actor FirebaseFeedService {
    private let db = Firestore.firestore()

    private var postsCollection: CollectionReference {
        db.collection("feed_posts")
    }

    // MARK: - Posts

    func createPost(_ fbPost: FBFeedPost) async throws -> FBFeedPost {
        let docRef = postsCollection.document(fbPost.id ?? UUID().uuidString)
        try docRef.setData(from: fbPost)
        let snapshot = try await docRef.getDocument()
        guard let created = try? snapshot.data(as: FBFeedPost.self) else {
            throw FeedError.postNotFound
        }
        return created
    }

    func deletePost(_ postId: String) async throws {
        // Delete comments subcollection first
        let commentsSnap = try await postsCollection.document(postId)
            .collection("comments").getDocuments()
        let batch = db.batch()
        for doc in commentsSnap.documents {
            batch.deleteDocument(doc.reference)
        }
        batch.deleteDocument(postsCollection.document(postId))
        try await batch.commit()
    }

    func getPosts(groupId: String, limit: Int, after: Date?) async throws -> [FBFeedPost] {
        var query = postsCollection
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let after {
            query = query.whereField("createdAt", isLessThan: Timestamp(date: after))
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FBFeedPost.self) }
    }

    func observePosts(groupId: String) -> AsyncStream<[FBFeedPost]> {
        AsyncStream { continuation in
            let listener = postsCollection
                .whereField("groupId", isEqualTo: groupId)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot else { return }
                    let posts = snapshot.documents.compactMap {
                        try? $0.data(as: FBFeedPost.self)
                    }
                    continuation.yield(posts)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Likes

    func toggleLike(postId: String, userId: String) async throws -> Bool {
        let docRef = postsCollection.document(postId)

        let result: Any? = try await db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard var likedBy = snapshot.data()?["likedBy"] as? [String] else {
                return NSNumber(value: false)
            }

            let isNowLiked: Bool
            if likedBy.contains(userId) {
                likedBy.removeAll { $0 == userId }
                isNowLiked = false
            } else {
                likedBy.append(userId)
                isNowLiked = true
            }

            transaction.updateData([
                "likedBy": likedBy,
                "likeCount": likedBy.count
            ], forDocument: docRef)

            return NSNumber(value: isNowLiked)
        })

        return (result as? NSNumber)?.boolValue ?? false
    }

    // MARK: - Comments

    func addComment(_ fbComment: FBFeedComment) async throws {
        let postRef = postsCollection.document(fbComment.postId)
        let commentRef = postRef.collection("comments").document(fbComment.id ?? UUID().uuidString)

        let batch = db.batch()
        try batch.setData(from: fbComment, forDocument: commentRef)
        batch.updateData(["commentCount": FieldValue.increment(Int64(1))], forDocument: postRef)
        try await batch.commit()
    }

    func getComments(postId: String, limit: Int) async throws -> [FBFeedComment] {
        let snapshot = try await postsCollection.document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: FBFeedComment.self) }
    }

    func observeComments(postId: String) -> AsyncStream<[FBFeedComment]> {
        AsyncStream { continuation in
            let listener = postsCollection.document(postId)
                .collection("comments")
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot else { return }
                    let comments = snapshot.documents.compactMap {
                        try? $0.data(as: FBFeedComment.self)
                    }
                    continuation.yield(comments)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}
