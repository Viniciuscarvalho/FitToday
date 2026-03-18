//
//  CMSTrainerService.swift
//  FitToday
//
//  Actor-based service for CMS Trainer & Program API endpoints.
//

import Foundation

actor CMSTrainerService {

    // MARK: - Properties

    private let session: URLSession
    private let configuration: CMSConfiguration
    private let tokenProvider: CMSTokenProvider?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    init(configuration: CMSConfiguration = .default, tokenProvider: CMSTokenProvider? = nil) {
        self.configuration = configuration
        self.tokenProvider = tokenProvider

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2
        self.session = URLSession(configuration: sessionConfig)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Trainers API

    /// GET /api/trainers — List active trainers (marketplace).
    func fetchTrainers(
        limit: Int = 20,
        offset: Int = 0,
        specialty: String? = nil,
        city: String? = nil
    ) async throws -> CMSTrainerListResponse {
        var components = URLComponents(url: configuration.baseURL.appendingPathComponent("/api/trainers"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        if let specialty, !specialty.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "specialty", value: specialty))
        }
        if let city, !city.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "city", value: city))
        }
        guard let url = components.url else { throw CMSServiceError.invalidURL }
        let request = try await buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// GET /api/trainers/count — Total active trainers.
    func fetchTrainerCount() async throws -> CMSTrainerCountResponse {
        let url = configuration.baseURL.appendingPathComponent("/api/trainers/count")
        let request = try await buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// GET /api/trainers/[id] — Public trainer profile.
    func fetchTrainer(id: String) async throws -> CMSTrainer {
        let url = configuration.baseURL.appendingPathComponent("/api/trainers/\(id)")
        let request = try await buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// GET /api/trainers/[id]/reviews — Trainer reviews.
    func fetchTrainerReviews(
        trainerId: String,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> CMSTrainerReviewListResponse {
        var components = URLComponents(url: configuration.baseURL.appendingPathComponent("/api/trainers/\(trainerId)/reviews"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else { throw CMSServiceError.invalidURL }
        let request = try await buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    // MARK: - Connection API

    /// POST /api/trainers/[id]/connect — Request connection with a trainer.
    func requestConnection(
        trainerId: String,
        connection: CMSConnectionRequest
    ) async throws -> CMSConnectionResponse {
        let url = configuration.baseURL.appendingPathComponent("/api/trainers/\(trainerId)/connect")
        var request = try await buildRequest(url: url, method: "POST", requiresAuth: true)
        request.httpBody = try encoder.encode(connection)
        return try await execute(request: request)
    }

    /// GET /api/trainers/[id]/connect — Check connection status with a trainer.
    /// The API identifies the student from the Bearer token.
    func checkConnectionStatus(
        trainerId: String
    ) async throws -> CMSConnectionStatusResponse {
        let url = configuration.baseURL.appendingPathComponent("/api/trainers/\(trainerId)/connect")
        let request = try await buildRequest(url: url, method: "GET", requiresAuth: true)
        return try await execute(request: request)
    }

    /// PATCH /api/connections/[id] — Accept, reject, or cancel a connection.
    func updateConnection(
        connectionId: String,
        action: String,
        reason: String? = nil
    ) async throws -> CMSConnectionActionResponse {
        let url = configuration.baseURL.appendingPathComponent("/api/connections/\(connectionId)")
        var request = try await buildRequest(url: url, method: "PATCH", requiresAuth: true)
        let body = CMSConnectionActionRequest(action: action, reason: reason)
        request.httpBody = try encoder.encode(body)
        return try await execute(request: request)
    }

    // MARK: - Reviews API

    /// POST /api/trainers/[id]/reviews — Submit a review for a trainer.
    func submitReview(
        trainerId: String,
        review: CMSCreateReviewRequest
    ) async throws -> CMSTrainerReview {
        let url = configuration.baseURL.appendingPathComponent("/api/trainers/\(trainerId)/reviews")
        var request = try await buildRequest(url: url, method: "POST", requiresAuth: true)
        request.httpBody = try encoder.encode(review)
        return try await execute(request: request)
    }

    // MARK: - Programs API

    /// GET /api/programs — List published programs.
    func fetchPrograms(
        trainerId: String? = nil,
        category: String? = nil,
        limit: Int = 50
    ) async throws -> CMSProgramListResponse {
        var components = URLComponents(url: configuration.baseURL.appendingPathComponent("/api/programs"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let trainerId, !trainerId.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "trainerId", value: trainerId))
        }
        if let category, !category.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "category", value: category))
        }
        guard let url = components.url else { throw CMSServiceError.invalidURL }
        let request = try await buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// GET /api/programs/[id] — Program details.
    func fetchProgram(id: String) async throws -> CMSProgram {
        let url = configuration.baseURL.appendingPathComponent("/api/programs/\(id)")
        let request = try await buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    // MARK: - User Role API

    /// POST /api/users/me — Ensure the current user has role "student" in the CMS.
    /// This must be called before attempting to connect with a trainer.
    func ensureStudentRole(displayName: String) async throws {
        let url = configuration.baseURL.appendingPathComponent("/api/users/me")
        var request = try await buildRequest(url: url, method: "POST", requiresAuth: true)
        let body: [String: String] = ["role": "student", "displayName": displayName]
        request.httpBody = try encoder.encode(body)

        #if DEBUG
        print("[CMSTrainerService] POST /api/users/me — role: student, displayName: \(displayName)")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CMSServiceError.invalidResponse
        }

        #if DEBUG
        print("[CMSTrainerService] ensureStudentRole status: \(httpResponse.statusCode)")
        if let json = String(data: data, encoding: .utf8) {
            print("[CMSTrainerService] ensureStudentRole response: \(json.prefix(500))")
        }
        #endif

        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 401: throw CMSServiceError.unauthorized
            case 403: throw CMSServiceError.forbidden
            default: throw CMSServiceError.unexpectedStatus(httpResponse.statusCode)
            }
        }
    }

    // MARK: - Private Helpers

    private func buildRequest(url: URL, method: String, requiresAuth: Bool = false) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            if let tokenProvider {
                let token = try await tokenProvider()
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if let apiKey = configuration.apiKey {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
        }

        return request
    }

    private func execute<T: Decodable>(request: URLRequest) async throws -> T {
        #if DEBUG
        print("[CMSTrainerService] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CMSServiceError.invalidResponse
        }

        #if DEBUG
        print("[CMSTrainerService] Status: \(httpResponse.statusCode)")
        #endif

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("[CMSTrainerService] Decode error: \(error)")
                if let json = String(data: data, encoding: .utf8) {
                    print("[CMSTrainerService] Response: \(json.prefix(500))")
                }
                #endif
                throw CMSServiceError.decodingFailed(error)
            }
        case 401:
            #if DEBUG
            if let body = String(data: data, encoding: .utf8) {
                print("[CMSTrainerService] 401 body: \(body.prefix(500))")
            }
            #endif
            throw CMSServiceError.unauthorized
        case 403:
            #if DEBUG
            if let body = String(data: data, encoding: .utf8) {
                print("[CMSTrainerService] 403 body: \(body.prefix(500))")
            }
            #endif
            throw CMSServiceError.forbidden
        case 404: throw CMSServiceError.notFound
        case 429: throw CMSServiceError.rateLimited
        case 500...599: throw CMSServiceError.serverError(httpResponse.statusCode)
        default:
            if let apiError = try? decoder.decode(CMSAPIError.self, from: data) {
                throw CMSServiceError.apiError(apiError)
            }
            throw CMSServiceError.unexpectedStatus(httpResponse.statusCode)
        }
    }
}
