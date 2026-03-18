//
//  CMSConnectionModelTests.swift
//  FitTodayTests
//
//  Tests for CMS connection and review DTOs — verifies alignment with actual API responses.
//

import XCTest
@testable import FitToday

final class CMSConnectionModelTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    // MARK: - CMSConnectionStatusResponse

    func test_decodeConnectionStatus_withIsConnectedAndConnectionId() throws {
        let json = """
        {
          "isConnected": true,
          "status": "active",
          "connectionId": "conn-abc123",
          "trainerId": "t1",
          "studentId": "s1"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CMSConnectionStatusResponse.self, from: json)

        XCTAssertTrue(response.isConnected)
        XCTAssertEqual(response.status, "active")
        XCTAssertEqual(response.connectionId, "conn-abc123")
        XCTAssertEqual(response.trainerId, "t1")
        XCTAssertEqual(response.studentId, "s1")
    }

    func test_decodeConnectionStatus_notConnected() throws {
        let json = """
        {
          "isConnected": false
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CMSConnectionStatusResponse.self, from: json)

        XCTAssertFalse(response.isConnected)
        XCTAssertNil(response.connectionId)
        XCTAssertNil(response.status)
    }

    // MARK: - CMSConnectionResponse (POST 201)

    func test_decodeConnectionResponse_201() throws {
        let json = """
        {
          "id": "conn-new-1",
          "trainerId": "t2",
          "studentId": "s2",
          "status": "pending",
          "createdAt": "2026-03-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CMSConnectionResponse.self, from: json)

        XCTAssertEqual(response.id, "conn-new-1")
        XCTAssertEqual(response.trainerId, "t2")
        XCTAssertEqual(response.status, "pending")
    }

    // MARK: - CMSConnectionActionResponse (PATCH)

    func test_decodeConnectionActionResponse() throws {
        let json = """
        {
          "id": "conn-abc123",
          "status": "cancelled",
          "cancelledBy": "student",
          "reason": "Changed my mind"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CMSConnectionActionResponse.self, from: json)

        XCTAssertEqual(response.id, "conn-abc123")
        XCTAssertEqual(response.status, "cancelled")
        XCTAssertEqual(response.cancelledBy, "student")
        XCTAssertEqual(response.reason, "Changed my mind")
        XCTAssertNil(response.subscriptionId)
        XCTAssertNil(response.chatRoomId)
    }

    func test_decodeConnectionActionResponse_accept() throws {
        let json = """
        {
          "id": "conn-abc123",
          "status": "active",
          "subscriptionId": "sub-1",
          "chatRoomId": "chat-1"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CMSConnectionActionResponse.self, from: json)

        XCTAssertEqual(response.status, "active")
        XCTAssertEqual(response.subscriptionId, "sub-1")
        XCTAssertEqual(response.chatRoomId, "chat-1")
        XCTAssertNil(response.cancelledBy)
    }

    // MARK: - CMSConnectionRequest (Encode)

    func test_encodeConnectionRequest_onlyMessage() throws {
        let request = CMSConnectionRequest(message: "Hello trainer!")
        let data = try encoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict["message"] as? String, "Hello trainer!")
    }

    func test_encodeConnectionRequest_nilMessage() throws {
        let request = CMSConnectionRequest(message: nil)
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!

        // Should not contain studentId or studentName
        XCTAssertFalse(json.contains("studentId"))
        XCTAssertFalse(json.contains("studentName"))
    }

    // MARK: - CMSCreateReviewRequest (Encode)

    func test_encodeCreateReviewRequest_onlyRatingAndComment() throws {
        let request = CMSCreateReviewRequest(rating: 5, comment: "Great trainer!")
        let data = try encoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["rating"] as? Int, 5)
        XCTAssertEqual(dict["comment"] as? String, "Great trainer!")
        XCTAssertNil(dict["studentId"])
        XCTAssertNil(dict["studentName"])
    }

    // MARK: - CMSTrainerCountResponse

    func test_decodeTrainerCount_withTotal() throws {
        let json = """
        { "total": 42 }
        """.data(using: .utf8)!

        let response = try decoder.decode(CMSTrainerCountResponse.self, from: json)

        XCTAssertEqual(response.total, 42)
    }

    // MARK: - CMSTrainerReviewListResponse

    func test_decodeReviewList_withAverageRating() throws {
        let json = """
        {
          "reviews": [
            {
              "id": "rev-1",
              "rating": 5,
              "comment": "Amazing!",
              "studentName": "John",
              "studentPhotoURL": "https://example.com/photo.jpg",
              "createdAt": "2026-03-10T08:00:00Z"
            }
          ],
          "total": 1,
          "averageRating": 4.8
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(CMSTrainerReviewListResponse.self, from: json)

        XCTAssertEqual(response.reviews.count, 1)
        XCTAssertEqual(response.total, 1)
        XCTAssertEqual(response.averageRating, 4.8)

        let review = response.reviews[0]
        XCTAssertEqual(review.id, "rev-1")
        XCTAssertEqual(review.rating, 5)
        XCTAssertEqual(review.studentName, "John")
        XCTAssertEqual(review.studentPhotoURL, "https://example.com/photo.jpg")
        XCTAssertNil(review.trainerId)
        XCTAssertNil(review.studentId)
    }

    // MARK: - CMSTrainerReview (optional fields)

    func test_decodeTrainerReview_withOptionalFields() throws {
        let json = """
        {
          "id": "rev-2",
          "trainerId": "t1",
          "studentId": "s1",
          "studentName": "Jane",
          "studentPhotoURL": null,
          "rating": 4,
          "comment": "Good sessions",
          "createdAt": "2026-03-12T14:30:00Z"
        }
        """.data(using: .utf8)!

        let review = try decoder.decode(CMSTrainerReview.self, from: json)

        XCTAssertEqual(review.id, "rev-2")
        XCTAssertEqual(review.trainerId, "t1")
        XCTAssertEqual(review.studentId, "s1")
        XCTAssertEqual(review.studentName, "Jane")
        XCTAssertNil(review.studentPhotoURL)
        XCTAssertEqual(review.rating, 4)
    }

    // MARK: - CMSStudentRegistrationRequest (Encode)

    func test_encodeStudentRegistration_noFirebaseUid() throws {
        let request = CMSStudentRegistrationRequest(
            displayName: "Test Student",
            email: "test@email.com",
            photoURL: "https://example.com/photo.jpg",
            fcmToken: "fcm-token-123",
            trainerId: "t1"
        )
        let data = try encoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["displayName"] as? String, "Test Student")
        XCTAssertEqual(dict["email"] as? String, "test@email.com")
        XCTAssertEqual(dict["photoURL"] as? String, "https://example.com/photo.jpg")
        XCTAssertEqual(dict["fcmToken"] as? String, "fcm-token-123")
        XCTAssertEqual(dict["trainerId"] as? String, "t1")
        XCTAssertNil(dict["firebaseUid"])
    }
}
