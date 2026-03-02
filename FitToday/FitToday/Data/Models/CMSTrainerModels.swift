//
//  CMSTrainerModels.swift
//  FitToday
//
//  DTOs for CMS Trainer & Program API integration.
//  Supports: /api/trainers, /api/trainers/[id], /api/trainers/[id]/reviews,
//            /api/trainers/count, /api/programs, /api/programs/[id]
//

import Foundation

// MARK: - Trainer List Response

struct CMSTrainerListResponse: Codable, Sendable {
    let trainers: [CMSTrainer]
    let total: Int?
    let limit: Int?
    let offset: Int?
}

// MARK: - Trainer Count Response

struct CMSTrainerCountResponse: Codable, Sendable {
    let count: Int
}

// MARK: - CMS Trainer Profile (nested object in API response)

struct CMSTrainerProfile: Codable, Sendable {
    let bio: String?
    let specializations: [String]?
    let city: String?
    let maxStudents: Int?
}

// MARK: - CMS Trainer DTO

struct CMSTrainer: Codable, Sendable, Identifiable {
    let id: String
    let displayName: String
    let email: String?
    let photoURL: String?
    let profile: CMSTrainerProfile?
    let isActive: Bool?
    let inviteCode: String?
    let currentStudentCount: Int?
    let rating: Double?
    let reviewCount: Int?
    let createdAt: Date?

    // Convenience accessors for nested profile fields
    var bio: String? { profile?.bio }
    var specializations: [String] { profile?.specializations ?? [] }
    var city: String? { profile?.city }
    var maxStudents: Int? { profile?.maxStudents }
}

// MARK: - Trainer Review List Response

struct CMSTrainerReviewListResponse: Codable, Sendable {
    let reviews: [CMSTrainerReview]
    let total: Int?
    let limit: Int?
    let offset: Int?
}

// MARK: - CMS Trainer Review DTO

struct CMSTrainerReview: Codable, Sendable, Identifiable {
    let id: String
    let trainerId: String
    let studentId: String
    let studentName: String?
    let rating: Int
    let comment: String?
    let createdAt: Date?
}

// MARK: - Program List Response

struct CMSProgramListResponse: Codable, Sendable {
    let programs: [CMSProgram]
    let total: Int?
    let limit: Int?
}

// MARK: - CMS Program DTO

struct CMSProgram: Codable, Sendable, Identifiable {
    let id: String
    let trainerId: String
    let title: String
    let description: String?
    let category: String?
    let durationWeeks: Int?
    let difficulty: String?
    let imageUrl: String?
    let isPublished: Bool?
    let workoutCount: Int?
    let createdAt: Date?
    let updatedAt: Date?
}
