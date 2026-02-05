//
//  CMSWorkoutService.swift
//  FitToday
//
//  Actor-based service for CMS Personal Trainer API integration.
//  Handles all REST API interactions for trainer workouts.
//

import Foundation

// MARK: - CMS Configuration

/// Configuration for CMS API connection.
struct CMSConfiguration: Sendable {
    let baseURL: URL
    let apiKey: String?
    let timeout: TimeInterval

    static let `default` = CMSConfiguration(
        baseURL: URL(string: "https://api.fittoday.app")!,
        apiKey: nil,
        timeout: 30
    )

    init(baseURL: URL, apiKey: String? = nil, timeout: TimeInterval = 30) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.timeout = timeout
    }
}

// MARK: - CMS Workout Service

/// Actor-based service for CMS workout API operations.
///
/// Provides type-safe access to all CMS workout endpoints:
/// - GET/POST /api/workouts
/// - GET/PATCH/DELETE /api/workouts/[id]
/// - GET /api/workouts/[id]/progress
/// - GET/POST /api/workouts/[id]/feedback
actor CMSWorkoutService {

    // MARK: - Properties

    private let session: URLSession
    private let configuration: CMSConfiguration
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    init(configuration: CMSConfiguration = .default) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2
        self.session = URLSession(configuration: sessionConfig)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Workouts API

    /// Fetches workouts for a student from the CMS.
    ///
    /// - Parameters:
    ///   - studentId: The student's user ID.
    ///   - trainerId: Optional trainer ID to filter by.
    ///   - page: Page number for pagination (default: 1).
    ///   - limit: Number of items per page (default: 20).
    /// - Returns: A paginated list of workouts.
    /// - Throws: CMSServiceError if the request fails.
    func fetchWorkouts(
        studentId: String,
        trainerId: String? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> CMSWorkoutListResponse {
        var components = URLComponents(url: configuration.baseURL.appendingPathComponent("/api/workouts"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "student_id", value: studentId),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let trainerId {
            components.queryItems?.append(URLQueryItem(name: "trainer_id", value: trainerId))
        }

        guard let url = components.url else {
            throw CMSServiceError.invalidURL
        }

        let request = try buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// Fetches a single workout by ID.
    ///
    /// - Parameter id: The workout ID.
    /// - Returns: The workout details.
    /// - Throws: CMSServiceError if the request fails.
    func fetchWorkout(id: String) async throws -> CMSWorkout {
        let url = configuration.baseURL.appendingPathComponent("/api/workouts/\(id)")
        let request = try buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// Updates a workout's status or metadata.
    ///
    /// - Parameters:
    ///   - id: The workout ID.
    ///   - update: The update request body.
    /// - Returns: The updated workout.
    /// - Throws: CMSServiceError if the request fails.
    func updateWorkout(id: String, update: CMSWorkoutUpdateRequest) async throws -> CMSWorkout {
        let url = configuration.baseURL.appendingPathComponent("/api/workouts/\(id)")
        var request = try buildRequest(url: url, method: "PATCH")
        request.httpBody = try encoder.encode(update)
        return try await execute(request: request)
    }

    /// Marks a workout as deleted (soft delete).
    ///
    /// - Parameter id: The workout ID.
    /// - Throws: CMSServiceError if the request fails.
    func deleteWorkout(id: String) async throws {
        let url = configuration.baseURL.appendingPathComponent("/api/workouts/\(id)")
        let request = try buildRequest(url: url, method: "DELETE")
        let _: EmptyResponse = try await execute(request: request)
    }

    // MARK: - Progress API

    /// Fetches the student's progress for a workout.
    ///
    /// - Parameter workoutId: The workout ID.
    /// - Returns: The progress data.
    /// - Throws: CMSServiceError if the request fails.
    func fetchProgress(workoutId: String) async throws -> CMSWorkoutProgress {
        let url = configuration.baseURL.appendingPathComponent("/api/workouts/\(workoutId)/progress")
        let request = try buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    // MARK: - Feedback API

    /// Fetches all feedback for a workout.
    ///
    /// - Parameter workoutId: The workout ID.
    /// - Returns: An array of feedback items.
    /// - Throws: CMSServiceError if the request fails.
    func fetchFeedback(workoutId: String) async throws -> [CMSWorkoutFeedback] {
        let url = configuration.baseURL.appendingPathComponent("/api/workouts/\(workoutId)/feedback")
        let request = try buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// Posts new feedback for a workout.
    ///
    /// - Parameters:
    ///   - workoutId: The workout ID.
    ///   - feedback: The feedback request body.
    /// - Returns: The created feedback.
    /// - Throws: CMSServiceError if the request fails.
    func postFeedback(workoutId: String, feedback: CMSFeedbackRequest) async throws -> CMSWorkoutFeedback {
        let url = configuration.baseURL.appendingPathComponent("/api/workouts/\(workoutId)/feedback")
        var request = try buildRequest(url: url, method: "POST")
        request.httpBody = try encoder.encode(feedback)
        return try await execute(request: request)
    }

    // MARK: - Private Helpers

    private func buildRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let apiKey = configuration.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute<T: Decodable>(request: URLRequest) async throws -> T {
        #if DEBUG
        print("[CMSWorkoutService] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CMSServiceError.invalidResponse
        }

        #if DEBUG
        print("[CMSWorkoutService] Status: \(httpResponse.statusCode)")
        #endif

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("[CMSWorkoutService] Decode error: \(error)")
                if let json = String(data: data, encoding: .utf8) {
                    print("[CMSWorkoutService] Response: \(json.prefix(500))")
                }
                #endif
                throw CMSServiceError.decodingFailed(error)
            }

        case 401:
            throw CMSServiceError.unauthorized

        case 403:
            throw CMSServiceError.forbidden

        case 404:
            throw CMSServiceError.notFound

        case 429:
            throw CMSServiceError.rateLimited

        case 500...599:
            throw CMSServiceError.serverError(httpResponse.statusCode)

        default:
            if let apiError = try? decoder.decode(CMSAPIError.self, from: data) {
                throw CMSServiceError.apiError(apiError)
            }
            throw CMSServiceError.unexpectedStatus(httpResponse.statusCode)
        }
    }
}

// MARK: - Empty Response

/// Used for endpoints that return no body on success.
private struct EmptyResponse: Decodable {}

// MARK: - CMS Service Error

/// Errors that can occur during CMS API operations.
enum CMSServiceError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(Int)
    case unexpectedStatus(Int)
    case decodingFailed(Error)
    case apiError(CMSAPIError)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalida"
        case .invalidResponse:
            return "Resposta invalida do servidor"
        case .unauthorized:
            return "Sessao expirada. Faca login novamente."
        case .forbidden:
            return "Voce nao tem permissao para acessar este recurso"
        case .notFound:
            return "Treino nao encontrado"
        case .rateLimited:
            return "Muitas requisicoes. Aguarde um momento."
        case .serverError(let code):
            return "Erro no servidor (\(code)). Tente novamente."
        case .unexpectedStatus(let code):
            return "Erro inesperado (\(code))"
        case .decodingFailed:
            return "Erro ao processar resposta"
        case .apiError(let error):
            return error.message
        case .networkError:
            return "Erro de conexao. Verifique sua internet."
        }
    }
}
