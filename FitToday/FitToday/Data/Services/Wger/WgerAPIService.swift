//
//  WgerAPIService.swift
//  FitToday
//
//  Service for fetching exercise data from Wger API.
//  API Documentation: https://wger.de/en/software/api
//

@preconcurrency import Foundation

// MARK: - Protocol

/// Protocol for exercise data service.
protocol ExerciseServiceProtocol: Sendable {
    /// Fetches exercises with optional filters.
    func fetchExercises(
        language: WgerLanguageCode,
        category: Int?,
        equipment: [Int]?,
        limit: Int
    ) async throws -> [WgerExercise]

    /// Fetches a single exercise by ID.
    func fetchExercise(id: Int) async throws -> WgerExercise?

    /// Searches exercises by name.
    func searchExercises(query: String, language: WgerLanguageCode, limit: Int) async throws -> [WgerExercise]

    /// Fetches exercise images.
    func fetchExerciseImages(exerciseBaseId: Int) async throws -> [WgerExerciseImage]

    /// Fetches all categories.
    func fetchCategories() async throws -> [WgerCategory]

    /// Fetches all equipment types.
    func fetchEquipment() async throws -> [WgerEquipment]

    /// Fetches all muscles.
    func fetchMuscles() async throws -> [WgerMuscle]
}

// MARK: - Errors

/// Errors that can occur when using the Wger API.
enum WgerAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case notFound
    case rateLimited
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "URL inválida para a API de exercícios.")
        case .networkError(let error):
            return String(localized: "Erro de rede: \(error.localizedDescription)")
        case .invalidResponse:
            return String(localized: "Resposta inválida da API de exercícios.")
        case .notFound:
            return String(localized: "Exercício não encontrado.")
        case .rateLimited:
            return String(localized: "Muitas requisições. Tente novamente em alguns segundos.")
        case .decodingError(let error):
            return String(localized: "Erro ao processar dados: \(error.localizedDescription)")
        }
    }
}

// MARK: - Service Implementation

/// Service for fetching exercise data from Wger API.
/// Thread-safe using actor isolation.
actor WgerAPIService: ExerciseServiceProtocol {
    private let configuration: WgerConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    // In-memory caches
    private var exerciseCache: [Int: WgerExercise] = [:]
    private var categoriesCache: [WgerCategory]?
    private var equipmentCache: [WgerEquipment]?
    private var musclesCache: [WgerMuscle]?
    private var imageCache: [Int: [WgerExerciseImage]] = [:]

    init(configuration: WgerConfiguration = .default, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Exercises

    func fetchExercises(
        language: WgerLanguageCode = .portuguese,
        category: Int? = nil,
        equipment: [Int]? = nil,
        limit: Int = 50
    ) async throws -> [WgerExercise] {
        var components = URLComponents(string: "\(configuration.baseURL)/exercise/")
        var queryItems = [
            URLQueryItem(name: "language", value: String(language.rawValue)),
            URLQueryItem(name: "limit", value: String(min(limit, configuration.pageLimit)))
        ]

        if let category {
            queryItems.append(URLQueryItem(name: "category", value: String(category)))
        }

        if let equipment {
            for eq in equipment {
                queryItems.append(URLQueryItem(name: "equipment", value: String(eq)))
            }
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw WgerAPIError.invalidURL
        }

        let response: WgerPaginatedResponse<WgerExercise> = try await performRequest(url: url)

        // Cache results
        for exercise in response.results {
            exerciseCache[exercise.id] = exercise
        }

        return response.results
    }

    func fetchExercise(id: Int) async throws -> WgerExercise? {
        // Check cache first
        if let cached = exerciseCache[id] {
            return cached
        }

        guard let url = URL(string: "\(configuration.baseURL)/exercise/\(id)/") else {
            throw WgerAPIError.invalidURL
        }

        do {
            let exercise: WgerExercise = try await performRequest(url: url)
            exerciseCache[id] = exercise
            return exercise
        } catch WgerAPIError.notFound {
            return nil
        }
    }

    func searchExercises(
        query: String,
        language: WgerLanguageCode = .portuguese,
        limit: Int = 20
    ) async throws -> [WgerExercise] {
        guard !query.isEmpty else { return [] }

        var components = URLComponents(string: "\(configuration.baseURL)/exercise/search/")
        components?.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "language", value: String(language.rawValue))
        ]

        guard let url = components?.url else {
            throw WgerAPIError.invalidURL
        }

        // Search endpoint returns a different structure
        struct SearchResponse: Codable, Sendable {
            let suggestions: [SearchSuggestion]
        }

        struct SearchSuggestion: Codable, Sendable {
            let value: String
            let data: SearchData
        }

        struct SearchData: Codable, Sendable {
            let id: Int
            let name: String
            let category: String
            let imagesThumbnail: String?

            enum CodingKeys: String, CodingKey {
                case id, name, category
                case imagesThumbnail = "image_thumbnail"
            }
        }

        let response: SearchResponse = try await performRequest(url: url)

        // Fetch full exercise details for each result
        var exercises: [WgerExercise] = []
        for suggestion in response.suggestions.prefix(limit) {
            if let exercise = try? await fetchExercise(id: suggestion.data.id) {
                exercises.append(exercise)
            }
        }

        return exercises
    }

    // MARK: - Images

    func fetchExerciseImages(exerciseBaseId: Int) async throws -> [WgerExerciseImage] {
        // Check cache first
        if let cached = imageCache[exerciseBaseId] {
            return cached
        }

        var components = URLComponents(string: "\(configuration.baseURL)/exerciseimage/")
        components?.queryItems = [
            URLQueryItem(name: "exercise_base", value: String(exerciseBaseId))
        ]

        guard let url = components?.url else {
            throw WgerAPIError.invalidURL
        }

        let response: WgerPaginatedResponse<WgerExerciseImage> = try await performRequest(url: url)
        imageCache[exerciseBaseId] = response.results
        return response.results
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [WgerCategory] {
        if let cached = categoriesCache {
            return cached
        }

        guard let url = URL(string: "\(configuration.baseURL)/exercisecategory/") else {
            throw WgerAPIError.invalidURL
        }

        let response: WgerPaginatedResponse<WgerCategory> = try await performRequest(url: url)
        categoriesCache = response.results
        return response.results
    }

    // MARK: - Equipment

    func fetchEquipment() async throws -> [WgerEquipment] {
        if let cached = equipmentCache {
            return cached
        }

        guard let url = URL(string: "\(configuration.baseURL)/equipment/") else {
            throw WgerAPIError.invalidURL
        }

        let response: WgerPaginatedResponse<WgerEquipment> = try await performRequest(url: url)
        equipmentCache = response.results
        return response.results
    }

    // MARK: - Muscles

    func fetchMuscles() async throws -> [WgerMuscle] {
        if let cached = musclesCache {
            return cached
        }

        guard let url = URL(string: "\(configuration.baseURL)/muscle/") else {
            throw WgerAPIError.invalidURL
        }

        let response: WgerPaginatedResponse<WgerMuscle> = try await performRequest(url: url)
        musclesCache = response.results
        return response.results
    }

    // MARK: - Cache Management

    /// Clears all in-memory caches.
    func clearCache() {
        exerciseCache.removeAll()
        categoriesCache = nil
        equipmentCache = nil
        musclesCache = nil
        imageCache.removeAll()
    }

    // MARK: - Private Helpers

    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        let timeout = configuration.timeoutInterval
        let data = try await fetchData(from: url, timeout: timeout)
        return try decodeJSON(data)
    }

    /// Fetches data from URL - actor-isolated for session access.
    private func fetchData(from url: URL, timeout: TimeInterval) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        #if DEBUG
        print("[WgerAPI] Request: \(url.absoluteString)")
        #endif

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw WgerAPIError.invalidResponse
            }

            #if DEBUG
            print("[WgerAPI] Response: HTTP \(httpResponse.statusCode)")
            #endif

            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 404:
                throw WgerAPIError.notFound
            case 429:
                throw WgerAPIError.rateLimited
            default:
                throw WgerAPIError.invalidResponse
            }
        } catch let error as WgerAPIError {
            throw error
        } catch {
            throw WgerAPIError.networkError(error)
        }
    }

    /// Decodes JSON data - nonisolated for Swift 6 concurrency compatibility.
    private nonisolated func decodeJSON<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[WgerAPI] Decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[WgerAPI] Raw response: \(jsonString.prefix(500))")
            }
            #endif
            throw WgerAPIError.decodingError(error)
        }
    }
}
