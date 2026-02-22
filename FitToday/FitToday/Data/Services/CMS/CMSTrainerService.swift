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
    private let decoder: JSONDecoder

    // MARK: - Initialization

    init(configuration: CMSConfiguration = .default) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2
        self.session = URLSession(configuration: sessionConfig)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
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
        let request = try buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// GET /api/trainers/count — Total active trainers.
    func fetchTrainerCount() async throws -> CMSTrainerCountResponse {
        let url = configuration.baseURL.appendingPathComponent("/api/trainers/count")
        let request = try buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// GET /api/trainers/[id] — Public trainer profile.
    func fetchTrainer(id: String) async throws -> CMSTrainer {
        let url = configuration.baseURL.appendingPathComponent("/api/trainers/\(id)")
        let request = try buildRequest(url: url, method: "GET")
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
        let request = try buildRequest(url: url, method: "GET")
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
        let request = try buildRequest(url: url, method: "GET")
        return try await execute(request: request)
    }

    /// GET /api/programs/[id] — Program details.
    func fetchProgram(id: String) async throws -> CMSProgram {
        let url = configuration.baseURL.appendingPathComponent("/api/programs/\(id)")
        let request = try buildRequest(url: url, method: "GET")
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
        case 401: throw CMSServiceError.unauthorized
        case 403: throw CMSServiceError.forbidden
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
