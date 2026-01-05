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

  /// Busca os bytes da mídia (imagem/GIF) via ExerciseDB.
  /// Importante: necessário para carregar via RapidAPI pois exige headers.
  func fetchImageData(
    exerciseId: String,
    resolution: ExerciseImageResolution
  ) async throws -> (data: Data, mimeType: String)?
  
  /// Busca lista de targets válidos (músculo-alvo) disponíveis na API
  func fetchTargetList() async throws -> [String]
  
  /// Busca exercícios por target (músculo-alvo) específico
  func fetchExercises(target: String, limit: Int) async throws -> [ExerciseDBExercise]
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
  private var targetListCache: [String]?
  private var targetListCachedAt: Date?

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
    guard let url = URL(string: "\(configuration.baseURL.absoluteString)/exercises/exercise/\(id)") else {
      throw ExerciseDBError.invalidConfiguration
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    // Timeout adequado para busca individual (10s)
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
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "\(configuration.baseURL.absoluteString)/exercises/name/\(encodedQuery)") else {
      return []
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    // Timeout maior para busca por nome (pode retornar muitos resultados)
    request.timeoutInterval = 12.0
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
    imageDataCache.removeAll()
    targetListCache = nil
    targetListCachedAt = nil
  }
  
  // MARK: - Target List Endpoint
  
  /// Busca a lista de targets (músculo-alvo) disponíveis na API.
  /// Endpoint: GET https://exercisedb.p.rapidapi.com/exercises/targetList
  /// Cache: em memória (até limpar ou reiniciar app)
  func fetchTargetList() async throws -> [String] {
    // Verifica cache (válido por sessão - sem TTL para simplificar primeira iteração)
    if let cached = targetListCache {
      #if DEBUG
      print("[ExerciseDB] targetList cache hit: \(cached.count) targets")
      #endif
      return cached
    }
    
    // Fonte de verdade: https://exercisedb.p.rapidapi.com/exercises/targetList
    guard let url = URL(string: "\(configuration.baseURL.absoluteString)/exercises/targetList") else {
      throw ExerciseDBError.invalidConfiguration
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    // Timeout adequado para targetList (uma vez por TTL, pode ser maior)
    request.timeoutInterval = 12.0
    request.addValue(configuration.apiKey, forHTTPHeaderField: "x-rapidapi-key")
    request.addValue(configuration.host, forHTTPHeaderField: "x-rapidapi-host")
    
    do {
      let (data, response) = try await session.data(for: request)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw ExerciseDBError.invalidResponse
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        #if DEBUG
        print("[ExerciseDB] HTTP \(httpResponse.statusCode) para targetList")
        #endif
        throw ExerciseDBError.invalidResponse
      }
      
      let decoder = JSONDecoder()
      let targets = try decoder.decode([String].self, from: data)
      
      // Cacheia resultado
      targetListCache = targets
      targetListCachedAt = Date()
      
      #if DEBUG
      print("[ExerciseDB] targetList fetched: \(targets.count) targets")
      #endif
      
      return targets
    } catch let error as ExerciseDBError {
      throw error
    } catch {
      #if DEBUG
      print("[ExerciseDB] Erro ao buscar targetList: \(error)")
      #endif
      throw ExerciseDBError.networkError(error)
    }
  }
  
  // MARK: - Target Exercises Endpoint
  
  /// Busca exercícios por target (músculo-alvo) específico.
  /// Endpoint: GET https://exercisedb.p.rapidapi.com/exercises/target/{target}
  func fetchExercises(target: String, limit: Int = 20) async throws -> [ExerciseDBExercise] {
    guard let encodedTarget = target.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "\(configuration.baseURL.absoluteString)/exercises/target/\(encodedTarget)") else {
      return []
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    // Timeout adequado para busca por target (pode retornar muitos resultados)
    request.timeoutInterval = 12.0
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
      
      // Cacheia exercícios retornados
      for exercise in exercises.prefix(limit) {
        cache[exercise.id] = exercise
      }
      
      #if DEBUG
      print("[ExerciseDB] target/\(target) fetched: \(exercises.count) exercícios (limit: \(limit))")
      #endif
      
      return Array(exercises.prefix(limit))
    } catch let error as ExerciseDBError {
      throw error
    } catch {
      #if DEBUG
      print("[ExerciseDB] Erro ao buscar exercícios para target '\(target)': \(error)")
      #endif
      throw ExerciseDBError.networkError(error)
    }
  }
  
  // MARK: - Image Endpoint
  
  private var imageURLCache: [String: URL] = [:]
  private var imageDataCache: [String: (data: Data, mimeType: String)] = [:]
  
  /// Busca a URL da imagem do exercício via endpoint /image da RapidAPI.
  /// Parâmetros obrigatórios: resolution e exerciseId.
  /// Fonte de verdade: https://exercisedb.p.rapidapi.com/image?resolution={resolution}&exerciseId={exerciseId}
  func fetchImageURL(exerciseId: String, resolution: ExerciseImageResolution) async throws -> URL? {
    let cacheKey = "\(exerciseId)_\(resolution.rawValue)"
    
    // Verifica cache primeiro
    if let cached = imageURLCache[cacheKey] {
      return cached
    }
    
    // Constrói URL com query parameters obrigatórios usando URLComponents
    // Fonte de verdade: https://exercisedb.p.rapidapi.com/image?resolution={resolution}&exerciseId={exerciseId}
    var components = URLComponents(string: "\(configuration.baseURL.absoluteString)/image")
    components?.queryItems = [
      URLQueryItem(name: "resolution", value: resolution.rawValue),
      URLQueryItem(name: "exerciseId", value: exerciseId)
    ]
    
    guard let url = components?.url else {
      #if DEBUG
      print("[ExerciseDB] URL inválida para imagem do exercício \(exerciseId)")
      #endif
      throw ExerciseDBError.invalidConfiguration
    }
    
    #if DEBUG
    print("[ExerciseDB] 🔗 Construindo URL RapidAPI: \(url.absoluteString)")
    #endif
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    // Timeout adequado para busca de imagem (pode ser maior para imagens grandes)
    request.timeoutInterval = 15.0
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
      
      // IMPORTANTE: A API RapidAPI pode retornar JSON com uma URL do formato antigo (v2.exercisedb.io),
      // mas essa URL não funciona sem headers RapidAPI. Sempre retornamos a URL do RapidAPI
      // que o loader vai usar com fetchImageData (que inclui os headers).
      
      // Verifica se a resposta é uma imagem diretamente (mimeType image/*)
      let mimeType = httpResponse.mimeType ?? "application/octet-stream"
      if mimeType.hasPrefix("image/") {
        // Resposta é imagem direta: retorna a URL do RapidAPI (o loader vai usar fetchImageData)
        #if DEBUG
        print("[ExerciseDB] ✅ Resposta é imagem direta (\(mimeType)), retornando URL RapidAPI")
        #endif
        imageURLCache[cacheKey] = url
        return url
      }
      
      // Se for JSON, ignora a URL que vem no JSON e retorna a URL do RapidAPI
      // O loader vai usar fetchImageData que baixa os bytes corretamente com headers
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        #if DEBUG
        if let jsonURL = json["url"] as? String ?? json["imageUrl"] as? String {
          print("[ExerciseDB] ⚠️ API retornou JSON com URL antiga (\(jsonURL)), usando URL RapidAPI ao invés")
        }
        #endif
      }
      
      // Sempre retorna a URL do RapidAPI (com resolution e exerciseId)
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

  /// Busca bytes da mídia (imagem/GIF) com headers RapidAPI.
  /// - Retorna: bytes + mimeType quando disponível.
  func fetchImageData(
    exerciseId: String,
    resolution: ExerciseImageResolution
  ) async throws -> (data: Data, mimeType: String)? {
    let cacheKey = "\(exerciseId)_\(resolution.rawValue)"
    if let cached = imageDataCache[cacheKey] {
      return cached
    }

    // Fonte de verdade: https://exercisedb.p.rapidapi.com/image?resolution={resolution}&exerciseId={exerciseId}
    var components = URLComponents(string: "\(configuration.baseURL.absoluteString)/image")
    components?.queryItems = [
      URLQueryItem(name: "resolution", value: resolution.rawValue),
      URLQueryItem(name: "exerciseId", value: exerciseId)
    ]

    guard let url = components?.url else {
      #if DEBUG
      print("[ExerciseDB] URL inválida para mídia do exercício \(exerciseId)")
      #endif
      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    // Timeout adequado para busca de mídia (GIF pode ser maior)
    request.timeoutInterval = 15.0
    request.addValue(configuration.apiKey, forHTTPHeaderField: "x-rapidapi-key")
    request.addValue(configuration.host, forHTTPHeaderField: "x-rapidapi-host")
    
    #if DEBUG
    print("[ExerciseDB] 📡 Iniciando requisição fetchImageData para exercício \(exerciseId)")
    print("[ExerciseDB]   URL: \(url.absoluteString)")
    print("[ExerciseDB]   Resolution: \(resolution.rawValue)")
    print("[ExerciseDB]   Timeout: \(request.timeoutInterval)s")
    #endif

    do {
      let (data, response) = try await session.data(for: request)
      
      #if DEBUG
      print("[ExerciseDB] ✅ Resposta recebida para exercício \(exerciseId): \(data.count) bytes")
      #endif
      guard let httpResponse = response as? HTTPURLResponse else {
        throw ExerciseDBError.invalidResponse
      }

      guard (200...299).contains(httpResponse.statusCode) else {
        #if DEBUG
        print("[ExerciseDB] ❌ HTTP \(httpResponse.statusCode) para mídia \(exerciseId)")
        #endif
        return nil
      }

      var detectedMimeType = httpResponse.mimeType ?? "application/octet-stream"
      
      // Se mimeType não for confiável, tenta detectar pelo conteúdo (magic bytes)
      if !detectedMimeType.hasPrefix("image/") && data.count >= 4 {
        let magicBytes = data.prefix(4)
        if magicBytes.starts(with: [0x47, 0x49, 0x46, 0x38]) { // GIF89a ou GIF87a
          detectedMimeType = "image/gif"
        } else if magicBytes.starts(with: [0xFF, 0xD8, 0xFF]) { // JPEG
          detectedMimeType = "image/jpeg"
        } else if magicBytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { // PNG
          detectedMimeType = "image/png"
        } else if magicBytes.starts(with: [0x52, 0x49, 0x46, 0x46]) { // WebP (RIFF)
          detectedMimeType = "image/webp"
        }
      }
      
      #if DEBUG
      print("[ExerciseDB] 📦 Resposta recebida: mimeType=\(detectedMimeType) (original: \(httpResponse.mimeType ?? "nil")), dataSize=\(data.count) bytes para exercício \(exerciseId)")
      #endif

      // Caso 1: a API já retorna a mídia diretamente (ideal)
      if detectedMimeType.hasPrefix("image/") {
        #if DEBUG
        print("[ExerciseDB] ✅ Mídia recebida diretamente: \(detectedMimeType) (\(data.count) bytes)")
        #endif
        let payload = (data: data, mimeType: detectedMimeType)
        imageDataCache[cacheKey] = payload
        return payload
      }

      // Caso 2: a API retorna JSON com uma URL final (ex.: v2.exercisedb.io)
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        #if DEBUG
        print("[ExerciseDB] 📄 Resposta é JSON, tentando extrair URL final...")
        #endif
        if let urlString = (json["url"] as? String) ?? (json["imageUrl"] as? String) ?? (json["gifUrl"] as? String),
           let finalURL = URL(string: urlString) {
          #if DEBUG
          print("[ExerciseDB] 🔗 URL final encontrada: \(urlString)")
          #endif
          let (finalData, finalResponse) = try await session.data(from: finalURL)
          let finalMimeType = (finalResponse as? HTTPURLResponse)?.mimeType ?? "application/octet-stream"
          #if DEBUG
          print("[ExerciseDB] ✅ Mídia baixada da URL final: \(finalMimeType) (\(finalData.count) bytes)")
          #endif
          let payload = (data: finalData, mimeType: finalMimeType)
          imageDataCache[cacheKey] = payload
          return payload
        } else {
          #if DEBUG
          print("[ExerciseDB] ⚠️ JSON não contém URL válida. Chaves disponíveis: \(json.keys.joined(separator: ", "))")
          #endif
        }
      }

      #if DEBUG
      print("[ExerciseDB] ❌ Não foi possível processar a resposta para exercício \(exerciseId) (mimeType: \(detectedMimeType), dataSize: \(data.count))")
      #endif
      return nil
    } catch let error as ExerciseDBError {
      throw error
    } catch let urlError as URLError {
      // Tratamento específico para URLError
      #if DEBUG
      switch urlError.code {
      case .cancelled:
        print("[ExerciseDB] ⏸️ Requisição cancelada para exercício \(exerciseId) (pode ser esperado se view saiu da tela)")
      case .timedOut:
        print("[ExerciseDB] ⏱️ Timeout ao buscar mídia \(exerciseId) (timeout: \(request.timeoutInterval)s)")
      case .notConnectedToInternet, .networkConnectionLost:
        print("[ExerciseDB] 📡 Sem conexão ao buscar mídia \(exerciseId)")
      default:
        print("[ExerciseDB] 🌐 Erro de rede ao buscar mídia \(exerciseId): \(urlError.localizedDescription) (code: \(urlError.code.rawValue))")
      }
      #endif
      throw ExerciseDBError.networkError(urlError)
    } catch {
      #if DEBUG
      print("[ExerciseDB] ❌ Erro inesperado ao buscar mídia \(exerciseId): \(error.localizedDescription)")
      print("[ExerciseDB]   Tipo: \(type(of: error))")
      #endif
      throw ExerciseDBError.networkError(error)
    }
  }
}

