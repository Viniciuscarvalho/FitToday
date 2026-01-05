//
//  ExerciseMediaResolver.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Representa a mídia resolvida de um exercício.
struct ResolvedExerciseMedia: Sendable, Equatable {
  let gifURL: URL?
  let imageURL: URL?
  let source: MediaSource

  enum MediaSource: String, Sendable {
    case exerciseDB = "ExerciseDB"
    case local = "Local"
    case placeholder = "Placeholder"
  }

  /// URL preferencial para exibição (prioriza GIF).
  var preferredURL: URL? {
    gifURL ?? imageURL
  }

  /// Indica se há mídia disponível.
  var hasMedia: Bool {
    gifURL != nil || imageURL != nil
  }

  nonisolated static let placeholder = ResolvedExerciseMedia(
    gifURL: nil,
    imageURL: nil,
    source: .placeholder
  )
}

/// Contexto de exibição para escolher a resolução correta
enum MediaDisplayContext: Sendable {
  case thumbnail  // Cards, listas - usa resolução baixa
  case card       // Cards maiores - usa resolução média  
  case detail     // Tela de detalhes - usa resolução alta
  
  nonisolated var resolution: ExerciseImageResolution {
    switch self {
    case .thumbnail: return .r180
    case .card: return .r360
    case .detail: return .r720
    }
  }
}

/// Protocolo para resolução de mídia de exercícios.
protocol ExerciseMediaResolving: Sendable {
  /// Resolve a mídia usando o exercício (permite migração híbrida via nome -> exerciseId).
  func resolveMedia(
    for exercise: WorkoutExercise,
    context: MediaDisplayContext
  ) async -> ResolvedExerciseMedia

  /// Resolve a mídia para um exercício, usando dados existentes ou buscando da API.
  func resolveMedia(
    for exerciseId: String,
    existingMedia: ExerciseMedia?,
    context: MediaDisplayContext
  ) async -> ResolvedExerciseMedia

  /// Resolve a mídia de forma síncrona usando apenas dados já disponíveis/cache.
  func resolveMediaSync(
    for exerciseId: String,
    existingMedia: ExerciseMedia?
  ) -> ResolvedExerciseMedia
}

/// Implementação do resolver de mídia que usa a API ExerciseDB.
actor ExerciseMediaResolver: ExerciseMediaResolving {
  private let service: ExerciseDBServicing?
  private let baseURL: URL?
  private var resolvedCache: [String: ResolvedExerciseMedia] = [:]

  init(service: ExerciseDBServicing? = nil, baseURL: URL? = nil) {
    self.service = service
    // Se o serviço for ExerciseDBService, podemos obter o baseURL dele
    // Por enquanto, usamos o baseURL padrão
    self.baseURL = baseURL ?? URL(string: "https://exercisedb.p.rapidapi.com")
  }

  func resolveMedia(
    for exercise: WorkoutExercise,
    context: MediaDisplayContext = .thumbnail
  ) async -> ResolvedExerciseMedia {
    // 1) Se já temos mídia válida, usa ela
    if let existing = exercise.media, existing.gifURL != nil || existing.imageURL != nil {
      let resolved = ResolvedExerciseMedia(
        gifURL: existing.gifURL,
        imageURL: existing.imageURL,
        source: .local
      )
      resolvedCache["\(exercise.id)_\(context.resolution.rawValue)"] = resolved
      return resolved
    }

    // 2) Verifica cache
    let cacheKey = "\(exercise.id)_\(context.resolution.rawValue)"
    if let cached = resolvedCache[cacheKey] {
      return cached
    }

    // 3) Tenta buscar da API /image, resolvendo exerciseId via migração híbrida
    guard let service else {
      #if DEBUG
      print("[MediaResolver] Sem serviço ExerciseDB configurado para \(exercise.id)")
      #endif
      return .placeholder
    }

    do {
      let exerciseDBId = try await resolveExerciseDBId(for: exercise, using: service)
      if let imageURL = try await service.fetchImageURL(
        exerciseId: exerciseDBId,
        resolution: context.resolution
      ) {
        let resolved = ResolvedExerciseMedia(
          gifURL: nil,
          imageURL: imageURL,
          source: .exerciseDB
        )
        resolvedCache[cacheKey] = resolved
        return resolved
      }
    } catch {
      #if DEBUG
      print("[MediaResolver] Erro ao resolver mídia para \(exercise.name): \(error.localizedDescription)")
      #endif
    }

    let placeholder = ResolvedExerciseMedia.placeholder
    resolvedCache[cacheKey] = placeholder
    return placeholder
  }

  func resolveMedia(
    for exerciseId: String,
    existingMedia: ExerciseMedia?,
    context: MediaDisplayContext = .thumbnail
  ) async -> ResolvedExerciseMedia {
    // 1. Se já temos mídia válida, usa ela
    if let existing = existingMedia, existing.gifURL != nil || existing.imageURL != nil {
      let resolved = ResolvedExerciseMedia(
        gifURL: existing.gifURL,
        imageURL: existing.imageURL,
        source: .local
      )
      resolvedCache[exerciseId] = resolved
      return resolved
    }

    // 2. Verifica cache (com contexto de resolução)
    let cacheKey = "\(exerciseId)_\(context.resolution.rawValue)"
    if let cached = resolvedCache[cacheKey] {
      return cached
    }

    // 3. Tenta buscar da API via endpoint /image
    guard let service = service else {
      #if DEBUG
      print("[MediaResolver] Sem serviço ExerciseDB configurado para \(exerciseId)")
      #endif
      return .placeholder
    }

    do {
      // Usa o novo endpoint /image com resolução baseada no contexto
      // Aqui assume-se que exerciseId já é o id do ExerciseDB.
      if let imageURL = try await service.fetchImageURL(exerciseId: exerciseId, resolution: context.resolution) {
        let resolved = ResolvedExerciseMedia(
          gifURL: nil,
          imageURL: imageURL,
          source: .exerciseDB
        )
        resolvedCache[cacheKey] = resolved
        return resolved
      }
    } catch {
      #if DEBUG
      print("[MediaResolver] Erro ao buscar mídia para \(exerciseId): \(error.localizedDescription)")
      #endif
    }

    // 4. Fallback para placeholder
    let placeholder = ResolvedExerciseMedia.placeholder
    resolvedCache[cacheKey] = placeholder
    return placeholder
  }

  nonisolated func resolveMediaSync(
    for exerciseId: String,
    existingMedia: ExerciseMedia?
  ) -> ResolvedExerciseMedia {
    // Versão síncrona: usa apenas dados já existentes
    if let existing = existingMedia, existing.gifURL != nil || existing.imageURL != nil {
      return ResolvedExerciseMedia(
        gifURL: existing.gifURL,
        imageURL: existing.imageURL,
        source: .local
      )
    }

    // Sem dados, retorna placeholder
    return .placeholder
  }

  /// Limpa o cache de mídia resolvida.
  func clearCache() {
    resolvedCache.removeAll()
  }

  /// Pré-carrega mídia para uma lista de exercícios.
  func prefetchMedia(for exerciseIds: [String]) async {
    await withTaskGroup(of: Void.self) { group in
      for id in exerciseIds {
        group.addTask {
          _ = await self.resolveMedia(for: id, existingMedia: nil)
        }
      }
    }
  }

  // MARK: - Hybrid ID resolution (name -> exerciseId)

  private func resolveExerciseDBId(
    for exercise: WorkoutExercise,
    using service: ExerciseDBServicing
  ) async throws -> String {
    if let cached = cachedExerciseDBId(forLocalExerciseId: exercise.id) {
      return cached
    }

    // Se o id já parece um id do ExerciseDB (numérico), usa direto.
    if exercise.id.count >= 3, exercise.id.allSatisfy({ $0.isNumber }) {
      setCachedExerciseDBId(exercise.id, forLocalExerciseId: exercise.id)
      return exercise.id
    }

    // Estratégia de busca progressiva:
    // 1. Nome completo
    // 2. Palavras principais (removendo prefixos como "lever", "cable", etc.)
    // 3. Apenas o nome do movimento principal
    
    let searchQueries = generateSearchQueries(from: exercise.name)
    
    for query in searchQueries {
      do {
        let results = try await service.searchExercises(query: query, limit: 10)
        
        if let best = bestMatch(for: exercise.name, candidates: results) {
          #if DEBUG
          print("[MediaResolver] Match encontrado para '\(exercise.name)' via query '\(query)': \(best.name) (id: \(best.id))")
          #endif
          setCachedExerciseDBId(best.id, forLocalExerciseId: exercise.id)
          return best.id
        }
        
        // Fallback: primeiro resultado se a query for específica o suficiente
        if let first = results.first, query.count >= 5 {
          #if DEBUG
          print("[MediaResolver] Usando primeiro resultado para '\(exercise.name)' via query '\(query)': \(first.name) (id: \(first.id))")
          #endif
          setCachedExerciseDBId(first.id, forLocalExerciseId: exercise.id)
          return first.id
        }
      } catch {
        #if DEBUG
        print("[MediaResolver] Erro na busca '\(query)': \(error.localizedDescription)")
        #endif
        continue
      }
    }

    #if DEBUG
    print("[MediaResolver] Nenhum resultado encontrado para '\(exercise.name)' após \(searchQueries.count) tentativas")
    #endif
    throw ExerciseDBError.notFound
  }
  
  /// Gera múltiplas queries de busca para aumentar as chances de encontrar o exercício
  private func generateSearchQueries(from name: String) -> [String] {
    var queries: [String] = []
    
    // 1. Nome completo em minúsculas
    let lowercased = name.lowercased()
    queries.append(lowercased)
    
    // 2. Remove prefixos de equipamento comuns
    let equipmentPrefixes = ["lever", "cable", "machine", "dumbbell", "barbell", "ez bar", "smith", "seated", "standing", "incline", "decline", "flat"]
    var simplified = lowercased
    for prefix in equipmentPrefixes {
      if simplified.hasPrefix(prefix + " ") {
        simplified = String(simplified.dropFirst(prefix.count + 1))
        break
      }
    }
    if simplified != lowercased {
      queries.append(simplified)
    }
    
    // 3. Extrai palavras-chave principais (2+ palavras mais longas)
    let words = name.lowercased()
      .components(separatedBy: CharacterSet.alphanumerics.inverted)
      .filter { $0.count >= 3 }
    
    // Termos principais do movimento
    let movementKeywords = ["fly", "press", "curl", "row", "squat", "deadlift", "lunge", "extension", "raise", "pull", "push", "crunch", "plank", "dip", "kickback", "pulldown", "pullover"]
    
    if let mainMovement = words.first(where: { movementKeywords.contains($0) }) {
      // Combina com a parte do corpo se identificável
      let bodyParts = ["chest", "back", "shoulder", "arm", "bicep", "tricep", "leg", "quad", "hamstring", "glute", "calf", "ab", "core", "pec", "lat", "delt"]
      if let bodyPart = words.first(where: { bodyParts.contains($0) || $0.hasPrefix("pec") || $0.hasPrefix("lat") || $0.hasPrefix("delt") }) {
        queries.append("\(bodyPart) \(mainMovement)")
      }
      queries.append(mainMovement)
    }
    
    // 4. Duas primeiras palavras significativas
    let significantWords = words.filter { !["the", "a", "an", "of", "on", "with", "for"].contains($0) }
    if significantWords.count >= 2 {
      queries.append("\(significantWords[0]) \(significantWords[1])")
    }
    
    // Remove duplicatas mantendo a ordem
    return queries.reduce(into: [String]()) { result, query in
      if !result.contains(query) && !query.isEmpty {
        result.append(query)
      }
    }
  }

  private func bestMatch(for name: String, candidates: [ExerciseDBExercise]) -> ExerciseDBExercise? {
    let normalizedTarget = normalizeName(name)
    let targetWords = Set(name.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count >= 3 })
    
    // 1) Igualdade exata normalizada
    if let exact = candidates.first(where: { normalizeName($0.name) == normalizedTarget }) {
      return exact
    }
    
    // 2) Match por palavras-chave (maior número de palavras em comum)
    var bestCandidate: ExerciseDBExercise?
    var bestScore = 0
    
    for candidate in candidates {
      let candidateWords = Set(candidate.name.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count >= 3 })
      let commonWords = targetWords.intersection(candidateWords)
      let score = commonWords.count
      
      if score > bestScore {
        bestScore = score
        bestCandidate = candidate
      }
    }
    
    // Aceita se tiver pelo menos 2 palavras em comum
    if bestScore >= 2 {
      return bestCandidate
    }
    
    // 3) Contém (evita ficar sem match por pequenas variações)
    if let contains = candidates.first(where: { normalizeName($0.name).contains(normalizedTarget) || normalizedTarget.contains(normalizeName($0.name)) }) {
      return contains
    }
    
    return nil
  }

  private func normalizeName(_ s: String) -> String {
    s.lowercased()
      .replacingOccurrences(of: "-", with: " ")
      .replacingOccurrences(of: "_", with: " ")
      .components(separatedBy: CharacterSet.alphanumerics.inverted)
      .joined()
  }

  // MARK: - Persisted cache (UserDefaults)

  private enum MappingKeys {
    static let mapping = "exercisedb_id_mapping_v1"
  }

  private func cachedExerciseDBId(forLocalExerciseId localId: String) -> String? {
    let dict = UserDefaults.standard.dictionary(forKey: MappingKeys.mapping) as? [String: String]
    return dict?[localId]
  }

  private func setCachedExerciseDBId(_ exerciseDBId: String, forLocalExerciseId localId: String) {
    var dict = (UserDefaults.standard.dictionary(forKey: MappingKeys.mapping) as? [String: String]) ?? [:]
    dict[localId] = exerciseDBId
    UserDefaults.standard.set(dict, forKey: MappingKeys.mapping)
  }
}

// MARK: - Extensão para facilitar uso com WorkoutExercise

extension ExerciseMediaResolving {
  func resolveMediaSync(for exercise: WorkoutExercise) -> ResolvedExerciseMedia {
    resolveMediaSync(for: exercise.id, existingMedia: exercise.media)
  }
}

