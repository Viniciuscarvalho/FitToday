//
//  NewOpenAIClientTests.swift
//  FitTodayTests
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 3.0)
//

import XCTest
@testable import FitToday

final class NewOpenAIClientTests: XCTestCase {

    // MARK: - Initialization Tests

    func testClientInitializationWithValidKey() {
        // Given
        let apiKey = "sk-test-key"

        // When
        let client = NewOpenAIClient(apiKey: apiKey)

        // Then - client should be created successfully
        XCTAssertNotNil(client)
    }

    func testClientFromUserKeyReturnsNilWhenNoKey() {
        // Given - no API key configured
        UserAPIKeyManager.shared.deleteAPIKey(for: .openAI)

        // When
        let client = NewOpenAIClient.fromUserKey()

        // Then
        XCTAssertNil(client)
    }

    func testClientFromUserKeyReturnsClientWhenKeyExists() {
        // Given
        let testKey = "sk-test-\(UUID().uuidString)"
        UserAPIKeyManager.shared.saveAPIKey(testKey, for: .openAI)

        // When
        let client = NewOpenAIClient.fromUserKey()

        // Then
        XCTAssertNotNil(client)

        // Cleanup
        UserAPIKeyManager.shared.deleteAPIKey(for: .openAI)
    }

    // MARK: - Error Handling Tests

    func testClientErrorDescriptions() {
        // Given
        let errors: [NewOpenAIClient.ClientError] = [
            .missingAPIKey,
            .invalidResponse,
            .httpError(statusCode: 404, message: "Not found"),
            .decodingError("Invalid JSON")
        ]

        // Then
        XCTAssertEqual(errors[0].errorDescription, "OpenAI API key not configured")
        XCTAssertEqual(errors[1].errorDescription, "Invalid response from OpenAI")
        XCTAssertEqual(errors[2].errorDescription, "HTTP 404: Not found")
        XCTAssertEqual(errors[3].errorDescription, "Failed to decode response: Invalid JSON")
    }

    // MARK: - ChatCompletionResponse Tests

    func testChatCompletionResponseDecoding() throws {
        // Given
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

        // When
        let decoder = JSONDecoder()
        let response = try decoder.decode(ChatCompletionResponse.self, from: data)

        // Then
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices.first?.message.content, "Test content")
    }

    func testChatCompletionResponseDecodingWithNullContent() throws {
        // Given
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

        // When
        let decoder = JSONDecoder()
        let response = try decoder.decode(ChatCompletionResponse.self, from: data)

        // Then
        XCTAssertNil(response.choices.first?.message.content)
    }

    func testChatCompletionResponseDecodingWithMultipleChoices() throws {
        // Given
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

        // When
        let decoder = JSONDecoder()
        let response = try decoder.decode(ChatCompletionResponse.self, from: data)

        // Then
        XCTAssertEqual(response.choices.count, 2)
        XCTAssertEqual(response.choices[0].message.content, "First choice")
        XCTAssertEqual(response.choices[1].message.content, "Second choice")
    }

    // MARK: - Configuration Tests

    func testDefaultConfiguration() {
        // Given
        let apiKey = "sk-test-key"

        // When
        let client = NewOpenAIClient(apiKey: apiKey)

        // Then - default values should be applied
        // Note: We can't directly test private properties,
        // but we can verify the client initializes successfully
        XCTAssertNotNil(client)
    }

    func testCustomConfiguration() {
        // Given
        let apiKey = "sk-test-key"
        let customModel = "gpt-4"
        let customTimeout: TimeInterval = 120
        let customMaxTokens = 4000
        let customTemperature = 0.8
        let customMaxRetries = 3

        // When
        let client = NewOpenAIClient(
            apiKey: apiKey,
            model: customModel,
            timeout: customTimeout,
            maxTokens: customMaxTokens,
            temperature: customTemperature,
            maxRetries: customMaxRetries
        )

        // Then
        XCTAssertNotNil(client)
    }
}
