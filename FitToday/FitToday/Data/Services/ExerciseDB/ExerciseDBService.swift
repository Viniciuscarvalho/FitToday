//
//  ExerciseDBService.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Modelo de exercício retornado pela API ExerciseDB.
struct ExerciseDBExercise: Codable, Sendable {
  let bodyPart: String?
  let equipment: String?
  let id: String
  let name: String
  let target: String?
  let secondaryMuscles: [String]?
  let instructions: [String]?
  let description: String?
  let difficulty: String?
  let category: String?
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

/// Resolução de imagem para o endpoint /image
enum ExerciseImageResolution: String, Sendable {
  /// Thumbnail para listas/cards
  case r180 = "180"
  /// Card/preview maior
  case r360 = "360"
  /// Detail
  case r720 = "720"
}

/// Protocolo para o serviço de exercícios.
protocol ExerciseDBServicing: Sendable {
  func fetchExercise(byId id: String) async throws -> ExerciseDBExercise?
  func searchExercises(query: String, limit: Int) async throws -> [ExerciseDBExercise]
  
  /// Busca URL da imagem do exercício via endpoint /image
  func fetchImageURL(exerciseId: String, resolution: ExerciseImageResolution) async throws -> URL?
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

    // Endpoint: GET https://exercisedb.p.rapidapi.com/exercises/exercise/{id}
    let url = configuration.baseURL.appendingPathComponent("/exercises/exercise/\(id)")
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 10.0
    request.addValue(configuration.apiKey, forHTTPHeaderField: "x-rapidapi-key")
    request.addValue(configuration.host, forHTTPHeaderField: "x-rapidapi-host")

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
      cache[exercise.id] = exercise
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
    // Endpoint: GET https://exercisedb.p.rapidapi.com/exercises/name/{name}
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      return []
    }

    let finalURL = configuration.baseURL.appendingPathComponent("/exercises/name/\(encodedQuery)")

    var request = URLRequest(url: finalURL)
    request.httpMethod = "GET"
    request.timeoutInterval = 15.0
    request.addValue(configuration.apiKey, forHTTPHeaderField: "x-rapidapi-key")
    request.addValue(configuration.host, forHTTPHeaderField: "x-rapidapi-host")

    do {
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        throw ExerciseDBError.invalidResponse
      }

      let decoder = JSONDecoder()
      let exercises = (try? decoder.decode([ExerciseDBExercise].self, from: data)) ?? []
      for exercise in exercises.prefix(max(1, limit)) {
        cache[exercise.id] = exercise
      }
      return Array(exercises.prefix(max(1, limit)))
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
    imageURLCache.removeAll()
  }
  
  // MARK: - Image Endpoint
  
  private var imageURLCache: [String: URL] = [:]
  
  /// Busca a URL da imagem do exercício via endpoint /image da RapidAPI.
  /// Parâmetros obrigatórios: resolution e exerciseId.
  func fetchImageURL(exerciseId: String, resolution: ExerciseImageResolution) async throws -> URL? {
    let cacheKey = "\(exerciseId)_\(resolution.rawValue)"
    
    // Verifica cache primeiro
    if let cached = imageURLCache[cacheKey] {
      return cached
    }
    
    // Constrói URL com query parameters obrigatórios
    // Endpoint: GET https://exercisedb.p.rapidapi.com/image?resolution={resolution}&exerciseId={exerciseId}
    var components = URLComponents(url: configuration.baseURL.appendingPathComponent("/image"), resolvingAgainstBaseURL: true)!
    components.queryItems = [
      URLQueryItem(name: "resolution", value: resolution.rawValue),
      URLQueryItem(name: "exerciseId", value: exerciseId)
    ]
    
    guard let url = components.url else {
      #if DEBUG
      print("[ExerciseDB] URL inválida para imagem do exercício \(exerciseId)")
      #endif
      return nil
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 10.0
    // Headers obrigatórios para RapidAPI
    request.addValue(configuration.apiKey, forHTTPHeaderField: "x-rapidapi-key")
    request.addValue(configuration.host, forHTTPHeaderField: "x-rapidapi-host")
    
    do {
      let (data, response) = try await session.data(for: request)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw ExerciseDBError.invalidResponse
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        #if DEBUG
        print("[ExerciseDB] HTTP \(httpResponse.statusCode) para imagem \(exerciseId)")
        #endif
        return nil
      }
      
      // A resposta pode ser JSON com URL ou a imagem diretamente
      // Primeiro tenta parsear como JSON
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let imageURLString = json["url"] as? String ?? json["imageUrl"] as? String,
         let imageURL = URL(string: imageURLString) {
        imageURLCache[cacheKey] = imageURL
        return imageURL
      }
      
      // Se não for JSON, pode ser que a própria URL seja a imagem
      // Nesse caso, retornamos a URL original da requisição
      imageURLCache[cacheKey] = url
      return url
      
    } catch let error as ExerciseDBError {
      throw error
    } catch {
      #if DEBUG
      print("[ExerciseDB] Erro ao buscar imagem \(exerciseId): \(error.localizedDescription)")
      #endif
      throw ExerciseDBError.networkError(error)
    }
  }
}

