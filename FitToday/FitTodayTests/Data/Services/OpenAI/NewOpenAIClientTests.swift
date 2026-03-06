//
//  NewOpenAIClientTests.swift
//  FitTodayTests
//
//  Tests for NewOpenAIClient (Firebase Functions proxy).
//

import XCTest
@testable import FitToday

final class NewOpenAIClientTests: XCTestCase {

    // MARK: - Initialization Tests

    func testClientInitializationWithDefaults() {
        let client = NewOpenAIClient()
        XCTAssertNotNil(client)
    }

    func testClientInitializationWithCustomRetries() {
        let client = NewOpenAIClient(maxRetries: 5)
        XCTAssertNotNil(client)
    }

    // MARK: - Error Handling Tests

    func testClientErrorDescriptions() {
        let errors: [NewOpenAIClient.ClientError] = [
            .notAuthenticated,
            .invalidResponse,
            .httpError(statusCode: 404, message: "Not found"),
            .decodingError("Invalid JSON"),
            .emptyWorkoutResponse,
            .functionsError("Server error"),
        ]

        XCTAssertEqual(errors[0].errorDescription, "Authentication required to use AI features")
        XCTAssertEqual(errors[1].errorDescription, "Invalid response from AI service")
        XCTAssertEqual(errors[2].errorDescription, "HTTP 404: Not found")
        XCTAssertEqual(errors[3].errorDescription, "Failed to decode response: Invalid JSON")
        XCTAssertEqual(errors[4].errorDescription, "AI returned an empty workout response")
        XCTAssertEqual(errors[5].errorDescription, "AI service error: Server error")
    }

    // MARK: - ChatCompletionResponse Tests

    func testChatCompletionResponseDecoding() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {
                        "content": "Test content"
                    }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices.first?.message.content, "Test content")
    }

    func testChatCompletionResponseDecodingWithNullContent() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {
                        "content": null
                    }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        XCTAssertNil(response.choices.first?.message.content)
    }

    func testChatCompletionResponseDecodingWithMultipleChoices() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {
                        "content": "First choice"
                    }
                },
                {
                    "message": {
                        "content": "Second choice"
                    }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!

        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        XCTAssertEqual(response.choices.count, 2)
        XCTAssertEqual(response.choices[0].message.content, "First choice")
        XCTAssertEqual(response.choices[1].message.content, "Second choice")
    }
}
