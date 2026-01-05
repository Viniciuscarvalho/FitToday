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
  // MARK: - Performance Constants
  
  /// Limite máximo de candidatos a buscar por target (evita respostas muito grandes)
  private static let maxCandidatesPerTarget = 30
  
  /// Limite máximo de candidatos a processar no ranking (evita processamento desnecessário)
  private static let maxCandidatesForRanking = 30
  
  /// Limite máximo de resultados por busca por nome
  private static let maxResultsPerNameSearch = 10
  
  /// Limite máximo de queries de busca por nome (evita loops infinitos)
  private static let maxSearchQueries = 5
  
  // MARK: - Properties
  
  private let service: ExerciseDBServicing?
  private let targetCatalog: ExerciseDBTargetCataloging?
  private let baseURL: URL?
  private var resolvedCache: [String: ResolvedExerciseMedia] = [:]

  init(
    service: ExerciseDBServicing? = nil,
    targetCatalog: ExerciseDBTargetCataloging? = nil,
    baseURL: URL? = nil
  ) {
    self.service = service
    self.targetCatalog = targetCatalog
    // Se o serviço for ExerciseDBService, podemos obter o baseURL dele
    // Por enquanto, usamos o baseURL padrão
    self.baseURL = baseURL ?? URL(string: "https://exercisedb.p.rapidapi.com")
  }

  func resolveMedia(
    for exercise: WorkoutExercise,
    context: MediaDisplayContext = .thumbnail
  ) async -> ResolvedExerciseMedia {
    // 1) Se já temos mídia válida, verifica se precisa converter URLs antigas
    if let existing = exercise.media, existing.gifURL != nil || existing.imageURL != nil {
      let isLegacyImageURL = isLegacyURL(existing.imageURL)
      let isLegacyGifURL = isLegacyURL(existing.gifURL)
      
      // Se for URL antiga, tenta converter; senão usa a original
      let convertedImageURL: URL?
      if isLegacyImageURL {
        convertedImageURL = await convertLegacyURLToRapidAPI(
          existing.imageURL,
          exerciseId: exercise.id,
          context: context
        )
      } else {
        convertedImageURL = existing.imageURL
      }
      
      let convertedGifURL: URL?
      if isLegacyGifURL {
        convertedGifURL = await convertLegacyURLToRapidAPI(
          existing.gifURL,
          exerciseId: exercise.id,
          context: context
        )
      } else {
        convertedGifURL = existing.gifURL
      }
      
      // Se conseguiu converter URL antiga OU não era URL antiga, usa a URL
      // Se não conseguiu converter URL antiga, não usa a antiga - continua para buscar da API
      if let finalImageURL = convertedImageURL ?? (isLegacyImageURL ? nil : existing.imageURL),
         let finalGifURL = convertedGifURL ?? (isLegacyGifURL ? nil : existing.gifURL) {
        // Tem pelo menos uma URL válida (convertida ou original não-antiga)
        let resolved = ResolvedExerciseMedia(
          gifURL: finalGifURL,
          imageURL: finalImageURL,
          source: (isLegacyImageURL || isLegacyGifURL) ? .exerciseDB : .local
        )
        resolvedCache["\(exercise.id)_\(context.resolution.rawValue)"] = resolved
        return resolved
      } else if convertedImageURL != nil || convertedGifURL != nil {
        // Pelo menos uma conversão funcionou (mas a outra falhou)
        let resolved = ResolvedExerciseMedia(
          gifURL: convertedGifURL,
          imageURL: convertedImageURL,
          source: .exerciseDB
        )
        resolvedCache["\(exercise.id)_\(context.resolution.rawValue)"] = resolved
        return resolved
      }
      // Se não conseguiu converter URL antiga, continua para buscar da API abaixo
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
        #if DEBUG
        print("[MediaResolver] ✅ URL resolvida para '\(exercise.name)': \(imageURL.absoluteString)")
        #endif
        let resolved = ResolvedExerciseMedia(
          gifURL: nil,
          imageURL: imageURL,
          source: .exerciseDB
        )
        resolvedCache[cacheKey] = resolved
        return resolved
      }
    } catch let error as URLError {
      // Tratamento específico para erros de rede/timeout
      #if DEBUG
      switch error.code {
      case .timedOut:
        print("[MediaResolver] ⏱️ Timeout ao resolver mídia para \(exercise.name)")
      case .notConnectedToInternet, .networkConnectionLost:
        print("[MediaResolver] 📡 Sem conexão ao resolver mídia para \(exercise.name)")
      default:
        print("[MediaResolver] 🌐 Erro de rede ao resolver mídia para \(exercise.name): \(error.localizedDescription)")
      }
      #endif
      // Retorna placeholder sem travar
    } catch {
      #if DEBUG
      print("[MediaResolver] ❌ Erro ao resolver mídia para \(exercise.name): \(error.localizedDescription)")
      #endif
      // Retorna placeholder sem travar
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
    // 1. Se já temos mídia válida, verifica se precisa converter URLs antigas
    if let existing = existingMedia, existing.gifURL != nil || existing.imageURL != nil {
      let isLegacyImageURL = isLegacyURL(existing.imageURL)
      let isLegacyGifURL = isLegacyURL(existing.gifURL)
      
      // Se for URL antiga, tenta converter; senão usa a original
      let convertedImageURL: URL?
      if isLegacyImageURL {
        convertedImageURL = await convertLegacyURLToRapidAPI(
          existing.imageURL,
          exerciseId: exerciseId,
          context: context
        )
      } else {
        convertedImageURL = existing.imageURL
      }
      
      let convertedGifURL: URL?
      if isLegacyGifURL {
        convertedGifURL = await convertLegacyURLToRapidAPI(
          existing.gifURL,
          exerciseId: exerciseId,
          context: context
        )
      } else {
        convertedGifURL = existing.gifURL
      }
      
      // Se conseguiu converter URL antiga OU não era URL antiga, usa a URL
      // Se não conseguiu converter URL antiga, não usa a antiga - continua para buscar da API
      if let finalImageURL = convertedImageURL ?? (isLegacyImageURL ? nil : existing.imageURL),
         let finalGifURL = convertedGifURL ?? (isLegacyGifURL ? nil : existing.gifURL) {
        // Tem pelo menos uma URL válida (convertida ou original não-antiga)
        let resolved = ResolvedExerciseMedia(
          gifURL: finalGifURL,
          imageURL: finalImageURL,
          source: (isLegacyImageURL || isLegacyGifURL) ? .exerciseDB : .local
        )
        resolvedCache[exerciseId] = resolved
        return resolved
      } else if convertedImageURL != nil || convertedGifURL != nil {
        // Pelo menos uma conversão funcionou (mas a outra falhou)
        let resolved = ResolvedExerciseMedia(
          gifURL: convertedGifURL,
          imageURL: convertedImageURL,
          source: .exerciseDB
        )
        resolvedCache[exerciseId] = resolved
        return resolved
      }
      // Se não conseguiu converter URL antiga, continua para buscar da API abaixo
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
        #if DEBUG
        print("[MediaResolver] ✅ URL resolvida para exerciseId '\(exerciseId)': \(imageURL.absoluteString)")
        #endif
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
    // IMPORTANTE: Se detectar URLs antigas (v2.exercisedb.io), retorna placeholder
    // para forçar resolução assíncrona que fará a conversão para RapidAPI
    if let existing = existingMedia, existing.gifURL != nil || existing.imageURL != nil {
      // Verifica se alguma URL é do formato antigo usando a mesma lógica
      let hasLegacyURL = isLegacyURL(existing.imageURL) || isLegacyURL(existing.gifURL)
      
      if hasLegacyURL {
        // URL antiga detectada: retorna placeholder para forçar resolução assíncrona
        return .placeholder
      }
      
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

  // MARK: - URL Conversion Helpers

  /// Verifica se uma URL é do formato antigo (v2.exercisedb.io).
  nonisolated private func isLegacyURL(_ url: URL?) -> Bool {
    guard let url = url,
          let host = url.host,
          host.contains("exercisedb.io"),
          url.pathComponents.count >= 2,
          url.pathComponents[1] == "image" else {
      return false
    }
    return true
  }
  
  /// Converte URLs antigas (v2.exercisedb.io) para o formato RapidAPI.
  /// Extrai o exerciseId da URL antiga e constrói a URL RapidAPI correta.
  /// Retorna `nil` se não for URL antiga ou se não conseguir converter.
  private func convertLegacyURLToRapidAPI(
    _ url: URL?,
    exerciseId: String?,
    context: MediaDisplayContext
  ) async -> URL? {
    guard let url = url else { return nil }
    
    // Detecta URLs do formato antigo: v2.exercisedb.io/image/{exerciseId}
    guard isLegacyURL(url) else {
      // Não é URL antiga, retorna nil para indicar que não precisa converter
      return nil
    }
    
    // Extrai exerciseId da URL antiga (último componente do path)
    let extractedId = url.pathComponents.last ?? exerciseId ?? ""
    
    guard !extractedId.isEmpty else {
      #if DEBUG
      print("[MediaResolver] ⚠️ Não foi possível extrair exerciseId da URL antiga: \(url.absoluteString)")
      #endif
      return nil
    }
    
    #if DEBUG
    print("[MediaResolver] 🔄 Convertendo URL antiga '\(url.absoluteString)' para RapidAPI (exerciseId=\(extractedId))")
    #endif
    
    // Se temos service, usa fetchImageURL para construir a URL correta
    guard let service = service else {
      #if DEBUG
      print("[MediaResolver] ⚠️ Service não disponível para converter URL antiga")
      #endif
      return nil
    }
    
    do {
      if let rapidAPIURL = try await service.fetchImageURL(
        exerciseId: extractedId,
        resolution: context.resolution
      ) {
        #if DEBUG
        print("[MediaResolver] ✅ URL convertida: \(rapidAPIURL.absoluteString)")
        #endif
        return rapidAPIURL
      } else {
        #if DEBUG
        print("[MediaResolver] ⚠️ fetchImageURL retornou nil para exerciseId=\(extractedId)")
        #endif
        return nil
      }
    } catch {
      #if DEBUG
      print("[MediaResolver] ❌ Erro ao converter URL antiga: \(error.localizedDescription)")
      #endif
      return nil
    }
  }

  // MARK: - Hybrid ID resolution (target-based + name fallback)

  private func resolveExerciseDBId(
    for exercise: WorkoutExercise,
    using service: ExerciseDBServicing
  ) async throws -> String {
    #if DEBUG
    print("[MediaResolver] 🔍 Resolvendo exerciseDBId para '\(exercise.name)' (id: \(exercise.id), músculo: \(exercise.mainMuscle.rawValue), equip: \(exercise.equipment.rawValue))")
    #endif
    
    // 1. Verifica mapping persistido
    if let cached = cachedExerciseDBId(forLocalExerciseId: exercise.id) {
      #if DEBUG
      print("[MediaResolver] ✅ Mapping persistido encontrado: \(cached) (caminho: mapping cacheado)")
      #endif
      return cached
    }

    // 2. Se o id já parece um id do ExerciseDB (numérico), usa direto.
    if exercise.id.count >= 3, exercise.id.allSatisfy({ $0.isNumber }) {
      #if DEBUG
      print("[MediaResolver] ✅ ID numérico detectado, usando direto: \(exercise.id) (caminho: id numérico)")
      #endif
      setCachedExerciseDBId(exercise.id, forLocalExerciseId: exercise.id)
      return exercise.id
    }

    // 3. Target-based resolution (prioridade)
    if let targetCatalog = targetCatalog {
      if let target = await deriveTarget(from: exercise.mainMuscle) {
        #if DEBUG
        print("[MediaResolver] Target derivado para '\(exercise.name)': '\(target)'")
        #endif
        
        do {
          // Limita candidatos buscados para evitar respostas muito grandes
          let maxCandidates = ExerciseMediaResolver.maxCandidatesPerTarget
          let candidates = try await service.fetchExercises(target: target, limit: maxCandidates)
          
          #if DEBUG
          print("[MediaResolver] \(candidates.count) candidatos encontrados para target '\(target)' (limit: \(maxCandidates))")
          #endif
          
          // Limita candidatos processados no ranking para performance
          let maxForRanking = ExerciseMediaResolver.maxCandidatesForRanking
          let candidatesToRank = Array(candidates.prefix(maxForRanking))
          
          if let best = rankCandidates(candidatesToRank, for: exercise) {
            #if DEBUG
            print("[MediaResolver] ✅ Match por target: '\(best.name)' (id: \(best.id)) para '\(exercise.name)'")
            #endif
            setCachedExerciseDBId(best.id, forLocalExerciseId: exercise.id)
            return best.id
          } else {
            #if DEBUG
            print("[MediaResolver] ⚠️ Nenhum candidato adequado para target '\(target)'")
            #endif
          }
        } catch let error as URLError {
          // Tratamento específico para timeout/offline
          #if DEBUG
          switch error.code {
          case .timedOut:
            print("[MediaResolver] ⏱️ Timeout ao buscar por target '\(target)'")
          case .notConnectedToInternet, .networkConnectionLost:
            print("[MediaResolver] 📡 Sem conexão ao buscar por target '\(target)'")
          default:
            print("[MediaResolver] 🌐 Erro de rede ao buscar por target '\(target)': \(error.localizedDescription)")
          }
          #endif
          // Continua para fallback por nome
        } catch {
          #if DEBUG
          print("[MediaResolver] ❌ Erro ao buscar por target '\(target)': \(error.localizedDescription)")
          #endif
          // Continua para fallback por nome
        }
      }
    }

    // 4. Fallback: busca por nome (estratégia progressiva)
    #if DEBUG
    print("[MediaResolver] 🔄 Fallback por nome iniciado para '\(exercise.name)' (equipamento: \(exercise.equipment.rawValue))")
    #endif
    
    let searchQueries = generateSearchQueries(from: exercise.name)
    // Limita número de queries para evitar bursts de requests
    let maxQueries = ExerciseMediaResolver.maxSearchQueries
    let limitedQueries = Array(searchQueries.prefix(maxQueries))
    
    #if DEBUG
    print("[MediaResolver] 📋 Queries geradas (\(searchQueries.count), limitadas a \(limitedQueries.count)): \(limitedQueries.prefix(3).joined(separator: ", "))")
    #endif
    
    let maxResults = ExerciseMediaResolver.maxResultsPerNameSearch
    
    for (index, query) in limitedQueries.enumerated() {
      do {
        // Limita resultados por busca para performance
        let results = try await service.searchExercises(query: query, limit: maxResults)
        
        #if DEBUG
        print("[MediaResolver]   Query \(index + 1)/\(searchQueries.count) '\(query)': \(results.count) resultados")
        #endif
        
        if !results.isEmpty {
          // Log top 3 candidatos para diagnóstico
          #if DEBUG
          let top3 = Array(results.prefix(3))
          for (i, candidate) in top3.enumerated() {
            let equipmentMatch = candidate.equipment?.lowercased() == mapEquipmentToString(exercise.equipment).lowercased() ? "✅" : "❌"
            print("[MediaResolver]     [\(i+1)] \(candidate.name) (id: \(candidate.id)) equip:\(equipmentMatch)")
          }
          #endif
        }
        
        if let best = bestMatch(for: exercise.name, candidates: results, equipment: exercise.equipment) {
          #if DEBUG
          let equipmentMatch = best.equipment?.lowercased() == mapEquipmentToString(exercise.equipment).lowercased() ? "✅" : "⚠️"
          print("[MediaResolver] ✅ Match por nome: '\(best.name)' (id: \(best.id)) via query '\(query)' equip:\(equipmentMatch)")
          #endif
          setCachedExerciseDBId(best.id, forLocalExerciseId: exercise.id)
          return best.id
        }
        
        // Fallback: primeiro resultado se a query for específica o suficiente
        if let first = results.first, query.count >= 5 {
          #if DEBUG
          print("[MediaResolver] ⚠️ Usando primeiro resultado (fallback) para '\(exercise.name)' via query '\(query)': \(first.name) (id: \(first.id))")
          #endif
          setCachedExerciseDBId(first.id, forLocalExerciseId: exercise.id)
          return first.id
        }
      } catch let error as URLError {
        // Tratamento específico para timeout/offline
        #if DEBUG
        switch error.code {
        case .timedOut:
          print("[MediaResolver] ⏱️ Timeout na busca '\(query)'")
        case .notConnectedToInternet, .networkConnectionLost:
          print("[MediaResolver] 📡 Sem conexão na busca '\(query)'")
        default:
          print("[MediaResolver] 🌐 Erro de rede na busca '\(query)': \(error.localizedDescription)")
        }
        #endif
        // Continua para próxima query
        continue
      } catch {
        #if DEBUG
        print("[MediaResolver] ❌ Erro na busca '\(query)': \(error.localizedDescription)")
        #endif
        continue
      }
    }

    #if DEBUG
    print("[MediaResolver] ❌ Nenhum resultado encontrado para '\(exercise.name)' após \(searchQueries.count) tentativas de fallback por nome")
    #endif
    throw ExerciseDBError.notFound
  }
  
  // MARK: - Target Derivation
  
  /// Deriva o target (músculo-alvo) do ExerciseDB a partir de um MuscleGroup local.
  /// Retorna o primeiro target válido encontrado na lista de candidatos.
  private func deriveTarget(from muscleGroup: MuscleGroup) async -> String? {
    let candidates = targetCandidates(for: muscleGroup)
    
    guard !candidates.isEmpty else { return nil }
    
    // Se não temos targetCatalog, retorna o primeiro candidato (fallback)
    guard let catalog = targetCatalog else {
      return candidates.first
    }
    
    // Valida cada candidato e retorna o primeiro válido
    for candidate in candidates {
      if await catalog.isValidTarget(candidate) {
        return candidate
      }
    }
    
    return nil
  }
  
  /// Retorna candidatos de target para um MuscleGroup (em ordem de preferência).
  private func targetCandidates(for muscleGroup: MuscleGroup) -> [String] {
    switch muscleGroup {
    case .chest:
      return ["pectorals", "chest"]
    case .back:
      return ["lats", "back", "middle back", "upper back"]
    case .shoulders:
      return ["delts", "shoulders", "deltoids"]
    case .biceps:
      return ["biceps"]
    case .triceps:
      return ["triceps"]
    case .arms:
      return ["biceps", "triceps"] // Tenta ambos
    case .core:
      return ["abs", "core"]
    case .glutes:
      return ["glutes"]
    case .quads, .quadriceps:
      return ["quads", "quadriceps"]
    case .hamstrings:
      return ["hamstrings"]
    case .calves:
      return ["calves"]
    case .cardioSystem, .fullBody:
      return [] // Não mapeia para target específico
    }
  }
  
  // MARK: - Ranking Determinístico
  
  /// Rankeia candidatos e retorna o melhor match determinístico.
  private func rankCandidates(
    _ candidates: [ExerciseDBExercise],
    for exercise: WorkoutExercise
  ) -> ExerciseDBExercise? {
    guard !candidates.isEmpty else { return nil }
    
    var scoredCandidates: [(exercise: ExerciseDBExercise, score: Int)] = []
    
    for candidate in candidates {
      var score = 0
      
      // Score de equipamento (+3 se match exato, +1 se similar, 0 se desconhecido)
      let equipmentScore = scoreEquipment(candidate.equipment, against: exercise.equipment)
      score += equipmentScore
      
      // Score de nome (tokens em comum)
      let nameScore = scoreNameSimilarity(candidate.name, against: exercise.name)
      score += nameScore
      
      scoredCandidates.append((candidate, score))
    }
    
    // Ordena por score (maior primeiro), depois por nome mais curto (mais "canonical")
    scoredCandidates.sort { lhs, rhs in
      if lhs.score != rhs.score {
        return lhs.score > rhs.score
      }
      return lhs.exercise.name.count < rhs.exercise.name.count
    }
    
    // Log top 3 candidatos com scores detalhados
    #if DEBUG
    if !scoredCandidates.isEmpty {
      let top3 = Array(scoredCandidates.prefix(3))
      print("[MediaResolver]   📊 Top \(min(3, scoredCandidates.count)) candidatos por score:")
      for (i, item) in top3.enumerated() {
        let equipmentInfo = item.exercise.equipment ?? "N/A"
        print("[MediaResolver]     [\(i+1)] '\(item.exercise.name)' (score: \(item.score), equip: \(equipmentInfo), id: \(item.exercise.id))")
      }
    }
    #endif
    
    // Retorna o melhor (score > 0)
    if let best = scoredCandidates.first, best.score > 0 {
      #if DEBUG
      print("[MediaResolver]   🏆 Melhor match escolhido: '\(best.exercise.name)' (score: \(best.score))")
      #endif
      return best.exercise
    }
    
    return nil
  }
  
  /// Score de equipamento: +3 se match exato, +1 se similar, 0 caso contrário.
  private func scoreEquipment(_ candidateEquipment: String?, against localEquipment: EquipmentType) -> Int {
    guard let candidate = candidateEquipment?.lowercased() else { return 0 }
    
    let localString = mapEquipmentToString(localEquipment).lowercased()
    
    // Match exato
    if candidate == localString {
      return 3
    }
    
    // Similaridade (ex: "dumbbell" vs "dumbbells", "machine" vs "cable machine")
    if candidate.contains(localString) || localString.contains(candidate) {
      return 1
    }
    
    return 0
  }
  
  /// Mapeia EquipmentType local para string do ExerciseDB.
  private func mapEquipmentToString(_ equipment: EquipmentType) -> String {
    switch equipment {
    case .barbell: return "barbell"
    case .dumbbell: return "dumbbell"
    case .machine: return "machine"
    case .kettlebell: return "kettlebell"
    case .bodyweight: return "body weight"
    case .resistanceBand: return "band"
    case .cardioMachine: return "machine"
    case .cable: return "cable"
    case .pullupBar: return "pull up bar"
    }
  }
  
  /// Score de similaridade de nome baseado em tokens comuns.
  private func scoreNameSimilarity(_ candidateName: String, against localName: String) -> Int {
    let localTokens = tokenize(localName)
    let candidateTokens = tokenize(candidateName)
    
    let commonTokens = Set(localTokens).intersection(Set(candidateTokens))
    return commonTokens.count
  }
  
  /// Tokeniza um nome removendo stopwords e normalizando.
  private func tokenize(_ name: String) -> [String] {
    let stopwords = Set(["the", "a", "an", "of", "on", "with", "for", "and", "or"])
    
    return name.lowercased()
      .components(separatedBy: CharacterSet.alphanumerics.inverted)
      .filter { $0.count >= 3 && !stopwords.contains($0) }
  }
  
  /// Gera múltiplas queries de busca progressivas para aumentar as chances de encontrar o exercício.
  /// Ordem: mais específica → mais genérica.
  private func generateSearchQueries(from name: String) -> [String] {
    var queries: [String] = []
    
    // 1. Nome completo em minúsculas (mais específico)
    let lowercased = name.lowercased().trimmingCharacters(in: .whitespaces)
    if !lowercased.isEmpty {
      queries.append(lowercased)
    }
    
    // 2. Remove prefixos de equipamento e posição comuns
    let prefixesToRemove = [
      "lever", "cable", "machine", "dumbbell", "dumbbells", "barbell", "barbells",
      "ez bar", "smith", "seated", "standing", "incline", "decline", "flat",
      "lying", "prone", "supine", "one arm", "one-arm", "two arm", "two-arm"
    ]
    
    var simplified = lowercased
    for prefix in prefixesToRemove {
      let prefixWithSpace = prefix + " "
      if simplified.hasPrefix(prefixWithSpace) {
        simplified = String(simplified.dropFirst(prefixWithSpace.count))
        break
      } else if simplified.hasPrefix(prefix) && simplified.count > prefix.count {
        let nextChar = simplified[simplified.index(simplified.startIndex, offsetBy: prefix.count)]
        if nextChar == " " || nextChar == "-" {
          simplified = String(simplified.dropFirst(prefix.count + 1))
          break
        }
      }
    }
    if simplified != lowercased && !simplified.isEmpty {
      queries.append(simplified.trimmingCharacters(in: .whitespaces))
    }
    
    // 3. Extrai palavras-chave principais
    let words = tokenize(name)
    
    // Termos principais do movimento
    let movementKeywords = [
      "fly", "flies", "press", "curl", "row", "squat", "deadlift", "lunge",
      "extension", "raise", "pull", "push", "crunch", "plank", "dip",
      "kickback", "pulldown", "pullover", "press", "extension", "flexion"
    ]
    
    if let mainMovement = words.first(where: { movementKeywords.contains($0) }) {
      // Combina com a parte do corpo se identificável
      let bodyParts = [
        "chest", "pec", "pectorals", "back", "lat", "lats", "shoulder", "shoulders",
        "delt", "delts", "arm", "arms", "bicep", "biceps", "tricep", "triceps",
        "leg", "legs", "quad", "quads", "hamstring", "hamstrings", "glute", "glutes",
        "calf", "calves", "ab", "abs", "core"
      ]
      
      if let bodyPart = words.first(where: { bodyParts.contains($0) }) {
        queries.append("\(bodyPart) \(mainMovement)")
      }
      queries.append(mainMovement)
    }
    
    // 4. Duas primeiras palavras significativas (se houver)
    let significantWords = words.filter { $0.count >= 4 } // Palavras com 4+ caracteres
    if significantWords.count >= 2 {
      queries.append("\(significantWords[0]) \(significantWords[1])")
    } else if let first = significantWords.first {
      queries.append(first)
    }
    
    // 5. Últimas duas palavras (pode capturar "bicep curl" de "dumbbell bicep curl")
    if words.count >= 2 {
      let lastTwo = Array(words.suffix(2))
      queries.append("\(lastTwo[0]) \(lastTwo[1])")
    }
    
    // Remove duplicatas mantendo a ordem (primeira ocorrência)
    var seen = Set<String>()
    return queries.compactMap { query in
      let trimmed = query.trimmingCharacters(in: .whitespaces)
      guard !trimmed.isEmpty, trimmed.count >= 3, !seen.contains(trimmed) else {
        return nil
      }
      seen.insert(trimmed)
      return trimmed
    }
  }

  /// Encontra o melhor match entre candidatos considerando nome e equipamento.
  private func bestMatch(
    for name: String,
    candidates: [ExerciseDBExercise],
    equipment: EquipmentType? = nil
  ) -> ExerciseDBExercise? {
    guard !candidates.isEmpty else { return nil }
    
    let normalizedTarget = normalizeName(name)
    let targetWords = Set(tokenize(name))
    let equipmentString = equipment.map { mapEquipmentToString($0).lowercased() }
    
    var scoredCandidates: [(exercise: ExerciseDBExercise, score: Int)] = []
    
    for candidate in candidates {
      var score = 0
      
      // Score de nome (tokens em comum)
      let candidateWords = Set(tokenize(candidate.name))
      let commonWords = targetWords.intersection(candidateWords)
      score += commonWords.count * 2 // Peso maior para nome
      
      // Score de equipamento (se fornecido)
      if let equipmentStr = equipmentString,
         let candidateEquipment = candidate.equipment?.lowercased() {
        if candidateEquipment == equipmentStr {
          score += 3 // Match exato de equipamento
        } else if candidateEquipment.contains(equipmentStr) || equipmentStr.contains(candidateEquipment) {
          score += 1 // Similaridade de equipamento
        }
      }
      
      // Bonus para igualdade exata normalizada
      if normalizeName(candidate.name) == normalizedTarget {
        score += 5
      }
      
      if score > 0 {
        scoredCandidates.append((candidate, score))
      }
    }
    
    // Ordena por score (maior primeiro), depois por nome mais curto
    scoredCandidates.sort { lhs, rhs in
      if lhs.score != rhs.score {
        return lhs.score > rhs.score
      }
      return lhs.exercise.name.count < rhs.exercise.name.count
    }
    
    // Retorna o melhor se tiver score suficiente
    if let best = scoredCandidates.first, best.score >= 2 {
      #if DEBUG
      if scoredCandidates.count > 1 {
        let top3 = Array(scoredCandidates.prefix(3))
        print("[MediaResolver]     Top candidatos por score:")
        for (i, item) in top3.enumerated() {
          print("[MediaResolver]       [\(i+1)] '\(item.exercise.name)' (score: \(item.score))")
        }
      }
      #endif
      return best.exercise
    }
    
    // Fallback: contém (evita ficar sem match por pequenas variações)
    if let contains = candidates.first(where: { 
      let normalized = normalizeName($0.name)
      return normalized.contains(normalizedTarget) || normalizedTarget.contains(normalized)
    }) {
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

