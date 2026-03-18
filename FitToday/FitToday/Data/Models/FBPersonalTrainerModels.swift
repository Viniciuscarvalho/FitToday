//
//  FBPersonalTrainerModels.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Firebase Personal Trainer DTO

/// Firebase DTO for personal trainer data.
///
/// Matches Firestore collection: `/personalTrainers/{id}`
struct FBPersonalTrainer: Codable {
    /// Document ID (populated by Firestore).
    @DocumentID var id: String?

    /// Display name shown to students.
    var displayName: String

    /// Trainer's email address.
    var email: String?

    /// URL string to the trainer's profile photo.
    var photoURL: String?

    /// Areas of expertise (e.g., ["strength", "weight_loss"]).
    var specializations: [String]?

    /// Short biography or description.
    var bio: String?

    /// Whether the trainer is currently accepting new students.
    var isActive: Bool?

    /// Unique invite code students can use to connect.
    var inviteCode: String?

    /// Maximum number of students this trainer can manage.
    var maxStudents: Int?

    /// Current number of connected students.
    var currentStudentCount: Int?

    /// When the trainer profile was created.
    @ServerTimestamp var createdAt: Timestamp?

    /// When the trainer profile was last updated.
    @ServerTimestamp var updatedAt: Timestamp?
}

// MARK: - Firebase Trainer Student DTO

/// Firebase DTO for trainer-student relationship data.
///
/// Matches Firestore collection: `/trainerStudents/{id}`
///
/// Actual Firestore document structure:
/// ```
/// {
///   "trainerId": "...",
///   "studentId": "...",
///   "status": "pending|active|paused|cancelled",
///   "source": "app_request",
///   "message": String?,
///   "createdAt": Timestamp,
///   "updatedAt": Timestamp,
///   "respondedAt": Timestamp?
/// }
/// ```
struct FBTrainerStudent: Codable {
    @DocumentID var id: String?

    var trainerId: String?
    var studentId: String?
    var status: String?

    /// How the connection was initiated (e.g. "app_request").
    var source: String?

    /// Optional message from the student.
    var message: String?

    @ServerTimestamp var createdAt: Timestamp?

    /// When the document was last updated.
    @ServerTimestamp var updatedAt: Timestamp?

    /// When the trainer responded (accepted/rejected).
    var respondedAt: Timestamp?
}
