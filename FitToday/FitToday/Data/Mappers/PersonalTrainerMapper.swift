//
//  PersonalTrainerMapper.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import FirebaseFirestore
import Foundation

// MARK: - Personal Trainer Mapper

/// Maps between Firebase DTOs and domain models for personal trainer entities.
struct PersonalTrainerMapper {

    // MARK: - Trainer Mapping

    /// Converts a Firebase personal trainer DTO to a domain model.
    ///
    /// - Parameters:
    ///   - fb: The Firebase DTO to convert.
    ///   - id: The document ID from Firestore.
    /// - Returns: A domain `PersonalTrainer` model.
    static func toDomain(_ fb: FBPersonalTrainer, id: String) -> PersonalTrainer {
        PersonalTrainer(
            id: id,
            displayName: fb.displayName,
            email: fb.email,
            photoURL: fb.photoURL.flatMap { URL(string: $0) },
            specializations: fb.specializations,
            bio: fb.bio,
            isActive: fb.isActive,
            inviteCode: fb.inviteCode,
            maxStudents: fb.maxStudents,
            currentStudentCount: fb.currentStudentCount
        )
    }

    // MARK: - Relationship Mapping

    /// Converts a Firebase trainer-student relationship DTO to a domain model.
    ///
    /// - Parameters:
    ///   - fb: The Firebase DTO to convert.
    ///   - id: The document ID from Firestore.
    /// - Returns: A domain `TrainerStudentRelationship` model.
    static func toRelationship(_ fb: FBTrainerStudent, id: String) -> TrainerStudentRelationship {
        TrainerStudentRelationship(
            id: id,
            trainerId: fb.trainerId,
            studentId: fb.studentId,
            status: TrainerConnectionStatus(rawValue: fb.status) ?? .pending,
            requestedBy: RequestedBy(rawValue: fb.requestedBy) ?? .student,
            requestedAt: fb.requestedAt?.dateValue() ?? Date(),
            acceptedAt: fb.acceptedAt?.dateValue(),
            subscriptionStatus: TrainerSubscriptionStatus(rawValue: fb.subscriptionStatus) ?? .trial,
            subscriptionExpiresAt: fb.subscriptionExpiresAt?.dateValue()
        )
    }
}
