//
//  ExerciseDBService.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Modelo de exercício retornado pela API ExerciseDB.
struct ExerciseDBExercise: Codable, Sendable {
  let id: String
  let name: String
  let imageUrl: String?  // Nome do arquivo (ex: "Barbell-Bench-Press_Chest.png")
  let videoUrl: String?
  let bodyPart: String?
  let equipment: String?
  let target: String?
  let secondaryMuscles: [String]?
  let instructions: [String]?
  let exerciseId: String?  // Campo alternativo do ID

  enum CodingKeys: String, CodingKey {
    case id
    case exerciseId
    case name
    case imageUrl
    case videoUrl
    case bodyPart
    case equipment
    case target
    case secondaryMuscles
    case instructions
  }
  
  /// Retorna o ID do exercício (prioriza exerciseId, fallback para id)
  var effectiveId: String {
    exerciseId ?? id
  }
  
  /// Constrói a URL completa da imagem usando o base URL da API
  func fullImageURL(baseURL: URL) -> URL? {
    guard let imageUrl = imageUrl, !imageUrl.isEmpty else { return nil }
    // Se já é uma URL completa, retorna como está
    if imageUrl.hasPrefix("http://") || imageUrl.hasPrefix("https://") {
      return URL(string: imageUrl)
    }
    // Caso contrário, constrói a URL completa
    return baseURL.appendingPathComponent("/images/\(imageUrl)")
  }
}

/// Resposta paginada da API ExerciseDB.
struct ExerciseDBResponse: Codable, Sendable {
  let success: Bool?
  let data: ExerciseDBData?
}

struct ExerciseDBData: Codable, Sendable {
  let exercises: [ExerciseDBExercise]?
  let totalPages: Int?
  let currentPage: Int?
}

/// Protocolo para o serviço de exercícios.
protocol ExerciseDBServicing: Sendable {
  func fetchExercise(byId id: String) async throws -> ExerciseDBExercise?
  func searchExercises(query: String, limit: Int) async throws -> [ExerciseDBExercise]
}

/// Erros do serviço ExerciseDB.
enum ExerciseDBError: Error, LocalizedError {
  case invalidConfiguration
  case networkError(Error)
  case invalidResponse
  case notFound

  var errorDescription: String? {
    switch self {
    case .invalidConfiguration:
      return "Configuração da API ExerciseDB inválida."
    case .networkError(let error):
      return "Erro de rede: \(error.localizedDescription)"
    case .invalidResponse:
      return "Resposta inválida da API."
    case .notFound:
      return "Exercício não encontrado."
    }
  }
}

/// Serviço para buscar dados de exercícios via API ExerciseDB (RapidAPI).
actor ExerciseDBService: ExerciseDBServicing {
  private let configuration: ExerciseDBConfiguration
  private let session: URLSession
  private var cache: [String: ExerciseDBExercise] = [:]

  init(configuration: ExerciseDBConfiguration, session: URLSession = .shared) {
    self.configuration = configuration
    self.session = session
  }

  func fetchExercise(byId id: String) async throws -> ExerciseDBExercise? {
    // Verifica cache primeiro
    if let cached = cache[id] {
      return cached
    }

    let url = configuration.baseURL.appendingPathComponent("/api/v1/exercises/\(id)")
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 10.0
    request.allHTTPHeaderFields = configuration.authHeaders

    do {
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw ExerciseDBError.invalidResponse
      }

      if httpResponse.statusCode == 404 {
        return nil
      }

      guard (200...299).contains(httpResponse.statusCode) else {
        #if DEBUG
        print("[ExerciseDB] HTTP \(httpResponse.statusCode) para exercício \(id)")
        #endif
        throw ExerciseDBError.invalidResponse
      }

      let decoder = JSONDecoder()
      let exercise = try decoder.decode(ExerciseDBExercise.self, from: data)
      cache[exercise.effectiveId] = exercise
      return exercise
    } catch let error as ExerciseDBError {
      throw error
    } catch {
      #if DEBUG
      print("[ExerciseDB] Erro ao buscar exercício \(id): \(error)")
      #endif
      throw ExerciseDBError.networkError(error)
    }
  }

  func searchExercises(query: String, limit: Int = 20) async throws -> [ExerciseDBExercise] {
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
      return []
    }

    let url = configuration.baseURL.appendingPathComponent("/api/v1/exercises/search")
    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
    components.queryItems = [
      URLQueryItem(name: "search", value: encodedQuery),
      URLQueryItem(name: "limit", value: String(limit))
    ]

    guard let finalURL = components.url else {
      return []
    }

    var request = URLRequest(url: finalURL)
    request.httpMethod = "GET"
    request.timeoutInterval = 15.0
    request.allHTTPHeaderFields = configuration.authHeaders

    do {
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        throw ExerciseDBError.invalidResponse
      }

      let decoder = JSONDecoder()

      // Tenta decodificar como resposta paginada primeiro
      if let paginatedResponse = try? decoder.decode(ExerciseDBResponse.self, from: data),
         let exercises = paginatedResponse.data?.exercises {
        // Cache os exercícios
        for exercise in exercises {
          cache[exercise.effectiveId] = exercise
        }
        return exercises
      }

      // Fallback: tenta decodificar como array direto
      if let exercises = try? decoder.decode([ExerciseDBExercise].self, from: data) {
        for exercise in exercises {
          cache[exercise.effectiveId] = exercise
        }
        return exercises
      }

      return []
    } catch let error as ExerciseDBError {
      throw error
    } catch {
      #if DEBUG
      print("[ExerciseDB] Erro ao buscar exercícios: \(error)")
      #endif
      throw ExerciseDBError.networkError(error)
    }
  }

  /// Limpa o cache de exercícios.
  func clearCache() {
    cache.removeAll()
  }
}

