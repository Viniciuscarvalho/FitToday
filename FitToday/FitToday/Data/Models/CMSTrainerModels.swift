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
    let hasMore: Bool?
}

// MARK: - Trainer Count Response

struct CMSTrainerCountResponse: Codable, Sendable {
    let total: Int
}

// MARK: - CMS Trainer Profile Location

struct CMSTrainerLocation: Codable, Sendable {
    let city: String?
    let state: String?
}

// MARK: - CMS Trainer Profile (nested object in API response)

struct CMSTrainerProfile: Codable, Sendable {
    let bio: String?
    let specialties: [String]?
    let certifications: [String]?
    let experience: Int?
    let location: CMSTrainerLocation?
}

// MARK: - CMS Trainer Stats

struct CMSTrainerStats: Codable, Sendable {
    let rating: Double?
    let totalReviews: Int?
    let totalStudents: Int?
}

// MARK: - CMS Trainer DTO

struct CMSTrainer: Codable, Sendable, Identifiable {
    let id: String
    let displayName: String
    let email: String?
    let photoURL: String?
    let profile: CMSTrainerProfile?
    let stats: CMSTrainerStats?
    let isActive: Bool?
    let inviteCode: String?
    let createdAt: Date?

    // Convenience accessors for nested fields
    var bio: String? { profile?.bio }
    var specializations: [String] { profile?.specialties ?? [] }
    var city: String? { profile?.location?.city }
    var rating: Double? { stats?.rating }
    var reviewCount: Int? { stats?.totalReviews }
    var currentStudentCount: Int? { stats?.totalStudents }
    var maxStudents: Int? { nil }
}

// MARK: - Trainer Review List Response

struct CMSTrainerReviewListResponse: Codable, Sendable {
    let reviews: [CMSTrainerReview]
    let total: Int?
    let averageRating: Double?
}

// MARK: - CMS Trainer Review DTO

struct CMSTrainerReview: Codable, Sendable, Identifiable {
    let id: String
    let trainerId: String?
    let studentId: String?
    let studentName: String?
    let studentPhotoURL: String?
    let rating: Int
    let comment: String?
    let createdAt: Date?
}

// MARK: - Connection Request

struct CMSConnectionRequest: Codable, Sendable {
    let message: String?
}

// MARK: - Connection Response

struct CMSConnectionResponse: Sendable {
    let id: String
    let trainerId: String?
    let studentId: String?
    let status: String?
    let createdAt: Date?
}

extension CMSConnectionResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, trainerId, studentId, status, createdAt
        case _id, connectionId
        case connection, data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Helper to extract fields from a keyed container
        func extract(from c: KeyedDecodingContainer<CodingKeys>) -> CMSConnectionResponse {
            let resolvedId = (try? c.decodeIfPresent(String.self, forKey: .id))
                ?? (try? c.decodeIfPresent(String.self, forKey: ._id))
                ?? (try? c.decodeIfPresent(String.self, forKey: .connectionId))
                ?? "unknown"
            return CMSConnectionResponse(
                id: resolvedId,
                trainerId: try? c.decodeIfPresent(String.self, forKey: .trainerId),
                studentId: try? c.decodeIfPresent(String.self, forKey: .studentId),
                status: try? c.decodeIfPresent(String.self, forKey: .status),
                createdAt: try? c.decodeIfPresent(Date.self, forKey: .createdAt)
            )
        }

        // Try nested "connection" or "data" wrapper
        if let nested = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .connection) {
            self = extract(from: nested)
            return
        }
        if let nested = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data) {
            self = extract(from: nested)
            return
        }

        // Flat structure
        self = extract(from: container)
    }
}

extension CMSConnectionResponse: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(trainerId, forKey: .trainerId)
        try container.encodeIfPresent(studentId, forKey: .studentId)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

// MARK: - Connection Status Response

struct CMSConnectionStatusResponse: Codable, Sendable {
    let isConnected: Bool
    let status: String?
    let connectionId: String?
    let trainerId: String?
    let studentId: String?
}

// MARK: - Create Review Request

struct CMSCreateReviewRequest: Codable, Sendable {
    let rating: Int
    let comment: String?
}

// MARK: - Connection Action Request

struct CMSConnectionActionRequest: Codable, Sendable {
    let action: String
    let reason: String?
}

// MARK: - Connection Action Response

struct CMSConnectionActionResponse: Codable, Sendable {
    let id: String
    let status: String
    let subscriptionId: String?
    let chatRoomId: String?
    let cancelledBy: String?
    let reason: String?
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

// MARK: - User Profile Response

struct CMSUserProfileResponse: Codable, Sendable {
    let uid: String?
    let id: String?
    let role: String?
    let displayName: String?
}
