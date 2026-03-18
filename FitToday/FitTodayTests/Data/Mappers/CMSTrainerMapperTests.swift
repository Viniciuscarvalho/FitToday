//
//  CMSTrainerMapperTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

final class CMSTrainerMapperTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - CMSTrainerListResponse

    func test_decodeTrainerList_fromActualAPIResponse() throws {
        let json = """
        {
          "trainers": [
            {
              "id": "PQokJfbiS4MkloHeEeyKEP9bdl12",
              "displayName": "Renato Pecchio Gimenis",
              "photoURL": "https://example.com/avatar.jpeg",
              "profile": {
                "bio": "Formado em Educacao Fisica",
                "specialties": ["Musculacao", "Crossfit", "Hipertrofia"],
                "certifications": [],
                "experience": 17,
                "socialMedia": {
                  "youtube": "",
                  "instagram": "renatogimenis"
                },
                "location": {
                  "city": "Sao Paulo",
                  "state": "Sao Paulo"
                }
              },
              "stats": {
                "rating": 4.5,
                "totalReviews": 12,
                "totalStudents": 3
              }
            }
          ],
          "total": 1,
          "hasMore": false
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CMSTrainerListResponse.self, from: json)

        XCTAssertEqual(response.trainers.count, 1)
        XCTAssertEqual(response.total, 1)
        XCTAssertEqual(response.hasMore, false)

        let trainer = response.trainers[0]
        XCTAssertEqual(trainer.id, "PQokJfbiS4MkloHeEeyKEP9bdl12")
        XCTAssertEqual(trainer.displayName, "Renato Pecchio Gimenis")
        XCTAssertEqual(trainer.photoURL, "https://example.com/avatar.jpeg")

        // Nested profile fields via computed properties
        XCTAssertEqual(trainer.bio, "Formado em Educacao Fisica")
        XCTAssertEqual(trainer.specializations, ["Musculacao", "Crossfit", "Hipertrofia"])
        XCTAssertEqual(trainer.city, "Sao Paulo")

        // Nested stats fields via computed properties
        XCTAssertEqual(trainer.rating, 4.5)
        XCTAssertEqual(trainer.reviewCount, 12)
        XCTAssertEqual(trainer.currentStudentCount, 3)
    }

    func test_decodeSingleTrainer_fromActualAPIResponse() throws {
        let json = """
        {
          "id": "abc123",
          "displayName": "Test Trainer",
          "photoURL": null,
          "profile": {
            "bio": null,
            "specialties": ["HIIT"],
            "certifications": [],
            "experience": 5,
            "location": {
              "city": "Rio",
              "state": "RJ"
            }
          },
          "stats": {
            "rating": 0,
            "totalReviews": 0,
            "totalStudents": 0
          }
        }
        """.data(using: .utf8)!

        let trainer = try decoder.decode(CMSTrainer.self, from: json)

        XCTAssertEqual(trainer.id, "abc123")
        XCTAssertEqual(trainer.displayName, "Test Trainer")
        XCTAssertNil(trainer.photoURL)
        XCTAssertNil(trainer.bio)
        XCTAssertEqual(trainer.specializations, ["HIIT"])
        XCTAssertEqual(trainer.city, "Rio")
        XCTAssertEqual(trainer.rating, 0)
        XCTAssertEqual(trainer.reviewCount, 0)
    }

    func test_decodeTrainer_withMissingOptionalFields() throws {
        let json = """
        {
          "id": "minimal",
          "displayName": "Minimal Trainer"
        }
        """.data(using: .utf8)!

        let trainer = try decoder.decode(CMSTrainer.self, from: json)

        XCTAssertEqual(trainer.id, "minimal")
        XCTAssertEqual(trainer.displayName, "Minimal Trainer")
        XCTAssertNil(trainer.photoURL)
        XCTAssertNil(trainer.bio)
        XCTAssertTrue(trainer.specializations.isEmpty)
        XCTAssertNil(trainer.city)
        XCTAssertNil(trainer.rating)
        XCTAssertNil(trainer.reviewCount)
    }

    // MARK: - CMSTrainerMapper.toDomain

    func test_mapperToDomain_mapsAllFields() throws {
        let json = """
        {
          "id": "t1",
          "displayName": "Trainer One",
          "photoURL": "https://example.com/photo.jpg",
          "profile": {
            "bio": "Test bio",
            "specialties": ["Yoga", "Pilates"],
            "location": { "city": "Campinas" }
          },
          "stats": {
            "rating": 4.8,
            "totalReviews": 5,
            "totalStudents": 2
          }
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(CMSTrainer.self, from: json)
        let domain = CMSTrainerMapper.toDomain(dto)

        XCTAssertEqual(domain.id, "t1")
        XCTAssertEqual(domain.displayName, "Trainer One")
        XCTAssertEqual(domain.photoURL?.absoluteString, "https://example.com/photo.jpg")
        XCTAssertEqual(domain.specializations, ["Yoga", "Pilates"])
        XCTAssertEqual(domain.bio, "Test bio")
        XCTAssertEqual(domain.rating, 4.8)
        XCTAssertEqual(domain.reviewCount, 5)
    }
}
