//
//  ExerciseDBServiceTests.swift
//  FitTodayTests
//
//  Created by AI on 05/01/26.
//

import XCTest
@testable import FitToday

final class ExerciseDBServiceTests: XCTestCase {
    var sut: ExerciseDBService!
    var mockSession: MockURLSession!
    var configuration: ExerciseDBConfiguration!
    
    override func setUp() {
        super.setUp()
        configuration = ExerciseDBConfiguration(
            apiKey: "test-key",
            host: "exercisedb.p.rapidapi.com"
        )
        mockSession = MockURLSession()
        sut = ExerciseDBService(configuration: configuration, session: mockSession)
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
        configuration = nil
        super.tearDown()
    }
    
    // MARK: - Target List Tests
    
    func testFetchTargetList_Success() async throws {
        // Given
        let expectedTargets = ["biceps", "triceps", "chest", "back"]
        let jsonData = try JSONEncoder().encode(expectedTargets)
        mockSession.stubbedData = jsonData
        mockSession.stubbedResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let targets = try await sut.fetchTargetList()
        
        // Then
        XCTAssertEqual(targets.count, 4)
        XCTAssertTrue(targets.contains("biceps"))
        XCTAssertTrue(targets.contains("chest"))
    }
    
    func testFetchTargetList_CachesResult() async throws {
        // Given
        let expectedTargets = ["biceps", "triceps"]
        let jsonData = try JSONEncoder().encode(expectedTargets)
        mockSession.stubbedData = jsonData
        mockSession.stubbedResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let firstCall = try await sut.fetchTargetList()
        mockSession.dataTaskCallCount = 0 // Reset
        let secondCall = try await sut.fetchTargetList()
        
        // Then
        XCTAssertEqual(firstCall, secondCall)
        XCTAssertEqual(mockSession.dataTaskCallCount, 0, "Segunda chamada deve usar cache")
    }
    
    func testFetchTargetList_InvalidResponse_ThrowsError() async {
        // Given
        mockSession.stubbedData = Data()
        mockSession.stubbedResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await sut.fetchTargetList()
            XCTFail("Deveria lançar erro")
        } catch let error as ExerciseDBError {
            XCTAssertEqual(error, ExerciseDBError.invalidResponse)
        } catch {
            XCTFail("Erro inesperado: \(error)")
        }
    }
    
    // MARK: - Fetch Exercises by Target Tests
    
    func testFetchExercisesByTarget_Success() async throws {
        // Given
        let exerciseData = [
            ExerciseDBExercise(
                bodyPart: "upper arms",
                equipment: "dumbbell",
                id: "0001",
                name: "dumbbell bicep curl",
                target: "biceps",
                secondaryMuscles: ["forearms"],
                instructions: ["Curl the weight"],
                description: "A bicep exercise",
                difficulty: "beginner",
                category: "strength"
            ),
            ExerciseDBExercise(
                bodyPart: "upper arms",
                equipment: "barbell",
                id: "0002",
                name: "barbell bicep curl",
                target: "biceps",
                secondaryMuscles: ["forearms"],
                instructions: ["Curl the barbell"],
                description: "A bicep exercise",
                difficulty: "intermediate",
                category: "strength"
            )
        ]
        let jsonData = try JSONEncoder().encode(exerciseData)
        mockSession.stubbedData = jsonData
        mockSession.stubbedResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let exercises = try await sut.fetchExercises(target: "biceps", limit: 10)
        
        // Then
        XCTAssertEqual(exercises.count, 2)
        XCTAssertEqual(exercises[0].name, "dumbbell bicep curl")
        XCTAssertEqual(exercises[0].target, "biceps")
        XCTAssertEqual(exercises[1].name, "barbell bicep curl")
    }
    
    func testFetchExercisesByTarget_RespectsLimit() async throws {
        // Given
        let manyExercises = (0..<50).map { index in
            ExerciseDBExercise(
                bodyPart: "upper arms",
                equipment: "dumbbell",
                id: "\(index)",
                name: "exercise \(index)",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        }
        let jsonData = try JSONEncoder().encode(manyExercises)
        mockSession.stubbedData = jsonData
        mockSession.stubbedResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let exercises = try await sut.fetchExercises(target: "biceps", limit: 10)
        
        // Then
        XCTAssertEqual(exercises.count, 10, "Deve respeitar o limite de 10")
    }
    
    func testFetchExercisesByTarget_InvalidTarget_ReturnsEmptyArray() async throws {
        // Given
        mockSession.stubbedData = "[]".data(using: .utf8)!
        mockSession.stubbedResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let exercises = try await sut.fetchExercises(target: "invalid_target", limit: 10)
        
        // Then
        XCTAssertTrue(exercises.isEmpty)
    }
    
    func testFetchExercisesByTarget_NetworkError_ThrowsError() async {
        // Given
        mockSession.stubbedError = URLError(.notConnectedToInternet)
        
        // When/Then
        do {
            _ = try await sut.fetchExercises(target: "biceps", limit: 10)
            XCTFail("Deveria lançar erro")
        } catch let error as ExerciseDBError {
            if case .networkError = error {
                // OK
            } else {
                XCTFail("Deveria ser networkError")
            }
        } catch {
            XCTFail("Erro inesperado: \(error)")
        }
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSession {
    var stubbedData: Data?
    var stubbedResponse: URLResponse?
    var stubbedError: Error?
    var dataTaskCallCount = 0
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        dataTaskCallCount += 1
        
        if let error = stubbedError {
            throw error
        }
        
        let data = stubbedData ?? Data()
        let response = stubbedResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
}


