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
  
  // MARK: - Exercise Name Translation (PT → EN)
  
  /// Dicionário de tradução de nomes de exercícios do português para inglês.
  /// Usado para melhorar a busca na API ExerciseDB que está em inglês.
  nonisolated private static let exerciseNameTranslation: [String: String] = [
    // ✅ EXERCÍCIOS ESPECÍFICOS PROBLEMÁTICOS (adicionados para 90%+ de assertividade)
    // Abdominais específicos
    "abdominal bicicleta": "bicycle crunch",
    "bicycle crunch": "bicycle crunch",
    "abdominal canivete": "v-up",
    "v-up": "v-up",
    "elevação de joelhos": "knee raise",
    "knee raise": "knee raise",
    "elevação de joelhos suspenso": "hanging knee raise",
    "hanging knee raise": "hanging knee raise",
    "elevação de pernas": "leg raise",
    "leg raise": "leg raise",

    // Agachamentos específicos
    "agachamento com salto": "jump squat",
    "jump squat": "jump squat",
    "agachamento búlgaro": "bulgarian split squat",
    "bulgarian split squat": "bulgarian split squat",
    "agachamento sumô": "sumo squat",
    "sumo squat": "sumo squat",
    "agachamento frontal": "front squat",
    "front squat": "front squat",

    // Prancha específicas
    "prancha com elevação de braço": "plank arm raise",
    "prancha com rotação": "plank rotation",
    "prancha lateral com rotação": "side plank rotation",
    "prancha alta": "high plank",
    "prancha baixa": "forearm plank",

    // Burpees específicos
    "burpee com salto": "burpee",
    "burpee com flexão": "burpee with push-up",
    "burpee com salto lateral": "lateral burpee",

    // Flexões específicas
    "flexão diamante": "diamond push-up",
    "diamond push-up": "diamond push-up",
    "flexão com aplauso": "clap push-up",
    "flexão archer": "archer push-up",
    "flexão pike": "pike push-up",

    // Remadas específicas
    "remada unilateral com halter": "one arm dumbbell row",
    "one arm dumbbell row": "one arm dumbbell row",
    "remada curvada": "bent over row",
    "bent over row": "bent over row",
    "remada cavalinho": "t-bar row",
    "t-bar row": "t-bar row",

    // Core & Estabilidade
    "prancha": "plank",
    "plank": "plank",
    "dead bug": "dead bug",
    "bird dog": "bird dog",
    "prancha lateral": "side plank",
    "side plank": "side plank",
    "abdominal reverso": "reverse crunch",
    "reverse crunch": "reverse crunch",
    "elevação pélvica": "glute bridge",
    "glute bridge": "glute bridge",
    "hip thrust": "glute bridge",
    "ponte": "glute bridge",
    "elevação pélvica com halter": "dumbbell hip thrust",

    // Cardio & Full Body
    "burpee": "burpee",
    "mountain climber": "mountain climber",
    "escalador": "mountain climber",

    // Upper Body
    "flexão": "push-up",
    "push-up": "push-up",
    "pushup": "push-up",
    "flexão de braço": "push-up",
    "barra": "pull-up",
    "pull-up": "pull-up",
    "pullup": "pull-up",
    "barra fixa": "pull-up",
    "supino reto com barra": "barbell bench press",
    "supino inclinado com halteres": "incline dumbbell press",
    "supino": "bench press",
    "bench press": "bench press",

    // Lower Body
    "agachamento": "squat",
    "squat": "squat",
    "afundo": "lunge",
    "lunge": "lunge",
    "passada": "lunge",
    "leg press": "leg press",
    "extensão de perna": "leg extension",
    "flexão de perna": "leg curl",

    // Abdominais gerais
    "abdominal": "crunch",
    "crunch": "crunch",
    "abdominal tradicional": "crunch",
    "abdominal oblíquo": "side crunch",
    "side crunch": "side crunch",

    // Ombros
    "desenvolvimento": "shoulder press",
    "shoulder press": "shoulder press",
    "elevação lateral": "lateral raise",
    "lateral raise": "lateral raise",

    // Costas
    "remada": "row",
    "row": "row",
    "puxada": "pulldown",
    "pulldown": "pulldown",

    // Tríceps
    "tríceps": "triceps",
    "triceps extension": "triceps extension",
    "tríceps testa": "lying triceps extension",

    // Bíceps
    "bíceps": "biceps",
    "biceps curl": "biceps curl",
    "rosca": "curl",
    "curl": "curl",
  ]
  
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
    // Fonte de verdade: https://exercisedb.p.rapidapi.com
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
      
      // Valida se o exercício existe na API antes de usar
      if let _ = try? await service.fetchExercise(byId: exerciseDBId) {
        if let imageURL = try await service.fetchImageURL(
          exerciseId: exerciseDBId,
          resolution: context.resolution
        ) {
          #if DEBUG
          print("[MediaResolver] ✅ URL resolvida e validada para '\(exercise.name)' (id: \(exerciseDBId)): \(imageURL.absoluteString)")
          #endif
          let resolved = ResolvedExerciseMedia(
            gifURL: nil,
            imageURL: imageURL,
            source: .exerciseDB
          )
          resolvedCache[cacheKey] = resolved
          return resolved
        } else {
          #if DEBUG
          print("[MediaResolver] ⚠️ Exercício \(exerciseDBId) existe mas não retornou URL de imagem")
          #endif
        }
      } else {
        #if DEBUG
        print("[MediaResolver] ⚠️ ExerciseId \(exerciseDBId) não encontrado na API, limpando mapping e tentando novamente")
        #endif
        // Limpa o mapping incorreto
        clearMapping(forLocalExerciseId: exercise.id)
        // Tenta resolver novamente (sem cache)
        // Mas para evitar loop infinito, retorna placeholder
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
      // Valida se o exercício existe na API antes de usar
      if let _ = try? await service.fetchExercise(byId: exerciseId) {
        // Usa o novo endpoint /image com resolução baseada no contexto
        // Aqui assume-se que exerciseId já é o id do ExerciseDB.
        if let imageURL = try await service.fetchImageURL(exerciseId: exerciseId, resolution: context.resolution) {
          #if DEBUG
          print("[MediaResolver] ✅ URL resolvida e validada para exerciseId '\(exerciseId)': \(imageURL.absoluteString)")
          #endif
          let resolved = ResolvedExerciseMedia(
            gifURL: nil,
            imageURL: imageURL,
            source: .exerciseDB
          )
          resolvedCache[cacheKey] = resolved
          return resolved
        } else {
          #if DEBUG
          print("[MediaResolver] ⚠️ Exercício \(exerciseId) existe mas não retornou URL de imagem")
          #endif
        }
      } else {
        #if DEBUG
        print("[MediaResolver] ⚠️ ExerciseId \(exerciseId) não encontrado na API")
        #endif
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
  
  /// Limpa o mapping de um exercício específico (útil quando mapping está incorreto).
  func clearMapping(forLocalExerciseId localId: String) {
    var dict = (UserDefaults.standard.dictionary(forKey: MappingKeys.mapping) as? [String: String]) ?? [:]
    dict.removeValue(forKey: localId)
    UserDefaults.standard.set(dict, forKey: MappingKeys.mapping)

    // Também limpa do cache resolvido
    let keysToRemove = resolvedCache.keys.filter { $0.hasPrefix("\(localId)_") }
    for key in keysToRemove {
      resolvedCache.removeValue(forKey: key)
    }

    #if DEBUG
    print("[MediaResolver] 🗑️ Mapping limpo para exercício '\(localId)'")
    #endif
  }

  /// Limpa TODOS os mappings de exercícios do UserDefaults.
  /// Útil para invalidar cache após melhorias no algoritmo de matching.
  func clearAllMappings() {
    UserDefaults.standard.removeObject(forKey: MappingKeys.mapping)
    resolvedCache.removeAll()

    #if DEBUG
    print("[MediaResolver] 🗑️ TODOS os mappings foram limpos (cache invalidado)")
    #endif
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

  // MARK: - Exercise Name Translation Helpers
  
  /// Traduz o nome do exercício de português para inglês.
  /// Retorna o nome traduzido se encontrado, senão retorna o nome original.
  private func translateExerciseName(_ name: String) -> String {
    let lowercased = name.lowercased().trimmingCharacters(in: .whitespaces)
    
    // Busca exata primeiro
    if let translated = Self.exerciseNameTranslation[lowercased] {
      #if DEBUG
      print("[MediaResolver] 🌐 Tradução aplicada: '\(name)' → '\(translated)'")
      #endif
      return translated
    }
    
    // Busca parcial (para casos como "Prancha Lateral" → "side plank")
    for (ptName, enName) in Self.exerciseNameTranslation {
      if lowercased.contains(ptName) || ptName.contains(lowercased) {
        #if DEBUG
        print("[MediaResolver] 🌐 Tradução parcial aplicada: '\(name)' → '\(enName)' (match: '\(ptName)')")
        #endif
        return enName
      }
    }
    
    // Fallback: tenta variações comuns
    let fallbackTranslations: [String: String] = [
      "prancha": "plank",
      "plank": "plank",
      "abdominal": "crunch",
      "crunch": "crunch",
      "flexão": "push-up",
      "push-up": "push-up",
      "agachamento": "squat",
      "squat": "squat",
    ]
    
    for (key, value) in fallbackTranslations {
      if lowercased.contains(key) {
        #if DEBUG
        print("[MediaResolver] 🔄 Fallback de tradução: '\(name)' → '\(value)' (chave: '\(key)')")
        #endif
        return value
      }
    }
    
    // Se não encontrou tradução, retorna o nome original
    return name
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
  /// IMPORTANTE: Valida se o exerciseId existe na API antes de retornar a URL.
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
    
    // Se temos service, valida e usa fetchImageURL para construir a URL correta
    guard let service = service else {
      #if DEBUG
      print("[MediaResolver] ⚠️ Service não disponível para converter URL antiga")
      #endif
      return nil
    }
    
    // PRIMEIRO: Valida se o exercício existe na API
    do {
      if let _ = try await service.fetchExercise(byId: extractedId) {
        // Exercício existe, agora busca a URL
        if let rapidAPIURL = try await service.fetchImageURL(
          exerciseId: extractedId,
          resolution: context.resolution
        ) {
          #if DEBUG
          print("[MediaResolver] ✅ URL convertida e validada: \(rapidAPIURL.absoluteString)")
          #endif
          return rapidAPIURL
        } else {
          #if DEBUG
          print("[MediaResolver] ⚠️ Exercício \(extractedId) existe mas fetchImageURL retornou nil")
          #endif
          return nil
        }
      } else {
        #if DEBUG
        print("[MediaResolver] ⚠️ ExerciseId \(extractedId) extraído da URL antiga não existe na API - URL inválida")
        #endif
        return nil
      }
    } catch {
      #if DEBUG
      print("[MediaResolver] ❌ Erro ao validar/converter URL antiga: \(error.localizedDescription)")
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
    print("[MediaResolver]    Cache version: \(MappingKeys.mapping)")
    #endif

    // 1. Verifica mapping persistido (cache v2 após melhorias de 2026-01-08)
    if let cached = cachedExerciseDBId(forLocalExerciseId: exercise.id) {
      #if DEBUG
      print("[MediaResolver] ✅ Mapping persistido encontrado: \(cached) (caminho: cache v2)")
      print("[MediaResolver]    ⚠️  Usando cache - algoritmo melhorado NÃO será executado")
      #endif
      return cached
    }

    #if DEBUG
    print("[MediaResolver] 🆕 Nenhum cache encontrado - executando algoritmo melhorado")
    #endif

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
  
  /// Retorna candidatos de target VÁLIDOS para um MuscleGroup (em ordem de preferência).
  ///
  /// IMPORTANTE: Usar APENAS targets que existem na API ExerciseDB.
  /// Lista completa dos 19 targets oficiais (verificado em 2026-01-08):
  /// abs, adductors, abductors, biceps, calves, cardiovascular system,
  /// delts, forearms, glutes, hamstrings, lats, levator scapulae,
  /// pectorals, quads, serratus anterior, spine, traps, triceps, upper back
  ///
  /// - Parameter muscleGroup: Grupo muscular local
  /// - Returns: Lista de targets do ExerciseDB em ordem de preferência (mais específico primeiro)
  private func targetCandidates(for muscleGroup: MuscleGroup) -> [String] {
    switch muscleGroup {
    case .chest:
      // ✅ Corrigido: "chest" NÃO existe no ExerciseDB, apenas "pectorals"
      return ["pectorals"]

    case .back:
      // ✅ Corrigido: "back" e "middle back" NÃO existem
      // Opções válidas: lats (latíssimo), upper back (trapézio superior), traps
      return ["lats", "upper back", "traps"]

    case .lats:
      return ["lats"]

    case .lowerBack:
      return ["lower back"]

    case .shoulders:
      // ✅ Corrigido: "shoulders" e "deltoids" NÃO existem, apenas "delts"
      return ["delts"]

    case .biceps:
      return ["biceps"]

    case .triceps:
      return ["triceps"]

    case .forearms:
      return ["forearms"]

    case .arms:
      // Cobre todos os músculos do braço
      return ["biceps", "triceps", "forearms"]

    case .core:
      // ✅ Corrigido: "core" NÃO existe
      // Opções válidas: abs (abdominais), serratus anterior (serrátil)
      return ["abs", "serratus anterior"]

    case .glutes:
      return ["glutes"]

    case .quads, .quadriceps:
      // ✅ Corrigido: "quadriceps" NÃO existe, apenas "quads"
      return ["quads"]

    case .hamstrings:
      return ["hamstrings"]

    case .calves:
      return ["calves"]

    case .cardioSystem:
      return ["cardiovascular system"]

    case .fullBody:
      // Corpo inteiro não tem target específico
      return []
    }
  }
  
  // MARK: - Ranking Determinístico

  /// Threshold mínimo de confiança para aceitar um match.
  /// Score = equipamento (0-3) + tokens de nome em comum (1+ cada).
  ///
  /// IMPORTANTE: Preferimos retornar nil (sem imagem) do que retornar exercício errado!
  ///
  /// Threshold de 5 significa (ULTRA-RIGOROSO para 90%+ de assertividade):
  /// - Match exato de equipamento (3) + pelo menos 2 tokens de nome OU
  /// - Equipamento similar (1) + pelo menos 4 tokens de nome OU
  /// - Sem match de equipamento (0) + pelo menos 5 tokens de nome
  ///
  /// Isso FORÇA correspondência forte no nome, não aceita matches apenas por equipamento.
  private static let minimumConfidenceThreshold = 5

  /// Rankeia candidatos e retorna o melhor match determinístico.
  /// Retorna nil se não houver match confiável (score abaixo do threshold).
  private func rankCandidates(
    _ candidates: [ExerciseDBExercise],
    for exercise: WorkoutExercise
  ) -> ExerciseDBExercise? {
    guard !candidates.isEmpty else { return nil }

    var scoredCandidates: [(exercise: ExerciseDBExercise, score: Int, nameScore: Int)] = []

    for candidate in candidates {
      var score = 0

      // Score de equipamento (+3 se match exato, +1 se similar, 0 se desconhecido)
      let equipmentScore = scoreEquipment(candidate.equipment, against: exercise.equipment)
      score += equipmentScore

      // Score de nome (tokens em comum)
      let nameScore = scoreNameSimilarity(candidate.name, against: exercise.name)
      score += nameScore

      scoredCandidates.append((candidate, score, nameScore))
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
        print("[MediaResolver]     [\(i+1)] '\(item.exercise.name)' (score: \(item.score), name tokens: \(item.nameScore), equip: \(equipmentInfo), id: \(item.exercise.id))")
      }
    }
    #endif

    // ✅ MUDANÇA CRÍTICA 1: Aplicar threshold de confiança básico
    // Primeiro, garantir que temos um candidato
    guard let best = scoredCandidates.first else {
      #if DEBUG
      print("[MediaResolver]   ℹ️ Nenhum candidato disponível para '\(exercise.name)'")
      print("[MediaResolver]   💡 Exercício '\(exercise.name)' não terá imagem/gif (não encontrado na API)")
      #endif
      return nil
    }

    // EXCEÇÃO: Para nomes de 1 token único, aceitar score 4 se for match 100%
    let localTokens = tokenize(exercise.name)
    let effectiveThreshold: Int
    if localTokens.count == 1 && best.nameScore == 1 {
      effectiveThreshold = 4  // Aceita equipamento (3) + 1 token exato (1)
    } else {
      effectiveThreshold = Self.minimumConfidenceThreshold  // 5 para todos os outros
    }

    // Validar score mínimo
    guard best.score >= effectiveThreshold else {
      #if DEBUG
      print("[MediaResolver]   ⚠️ Score muito baixo (\(best.score) < \(effectiveThreshold)) - rejeitando match '\(best.exercise.name)'")
      print("[MediaResolver]   💡 Exercício '\(exercise.name)' não terá imagem/gif (não encontrado na API)")
      #endif
      return nil
    }

    // ✅ MUDANÇA CRÍTICA 2: Validar cobertura mínima de tokens do nome
    // Exigir que pelo menos 80% dos tokens principais do nome local estejam no candidato
    // Isso evita matches ruins tipo "elevação de joelhos" → "leg raise" (falta "knee")
    // Nota: localTokens já foi declarado acima para calcular effectiveThreshold
    let candidateTokens = tokenize(best.exercise.name)
    let commonTokens = Set(localTokens).intersection(Set(candidateTokens))

    let tokenCoverage = localTokens.isEmpty ? 1.0 : Double(commonTokens.count) / Double(localTokens.count)

    // ✅ ULTRA-RIGOROSO: Cobertura mínima de 80% para TODOS os exercícios
    // Não aceitamos matches parciais - ou é muito similar ou não tem imagem!
    let minimumTokenCoverage: Double = 0.8  // 80% para todos!

    // ✅ Tokens mínimos absolutos (calculados com 80% de rigor):
    // - 1 token: mínimo 1 (100% - deve ser exato)
    // - 2 tokens: mínimo 2 (100% - ambos devem estar presentes)
    // - 3 tokens: mínimo 3 (100% - todos devem estar presentes)
    // - 4+ tokens: mínimo 80% arredondado para cima
    //
    // Exemplos:
    // - "Knee Raise" (2) → precisa 2/2 = 100%
    // - "Jump Squat" (2) → precisa 2/2 = 100%
    // - "Bicycle Crunch" (2) → precisa 2/2 = 100%
    // - "Side Plank Rotation" (3) → precisa 3/3 = 100%
    let minimumTokensRequired = max(1, Int(ceil(Double(localTokens.count) * 0.8)))
    let hasMinimumTokens = commonTokens.count >= minimumTokensRequired

    if tokenCoverage >= minimumTokenCoverage && hasMinimumTokens {
      #if DEBUG
      print("[MediaResolver]   🏆 Melhor match escolhido: '\(best.exercise.name)' (score: \(best.score), threshold: \(Self.minimumConfidenceThreshold))")
      print("[MediaResolver]   📊 Cobertura de tokens: \(Int(tokenCoverage * 100))% (\(commonTokens.count)/\(localTokens.count) tokens, mín: \(minimumTokensRequired))")
      print("[MediaResolver]   ✅ Local: '\(exercise.name)' → Candidato: '\(best.exercise.name)'")
      #endif
      return best.exercise
    }

    // ⚠️ Rejeitado por cobertura insuficiente de tokens
    #if DEBUG
    let requiredCoverage = Int(minimumTokenCoverage * 100)
    print("[MediaResolver]   ⚠️ Cobertura de tokens insuficiente (\(Int(tokenCoverage * 100))% < \(requiredCoverage)% ou tokens \(commonTokens.count) < \(minimumTokensRequired)) - rejeitando match '\(best.exercise.name)'")
    print("[MediaResolver]   📝 Local: '\(exercise.name)' → tokens: \(localTokens)")
    print("[MediaResolver]   📝 Candidato: '\(best.exercise.name)' → tokens: \(candidateTokens)")
    print("[MediaResolver]   📝 Comum: \(Array(commonTokens)) (\(commonTokens.count) tokens, cobertura: \(Int(tokenCoverage * 100))%)")
    print("[MediaResolver]   💡 Exercício '\(exercise.name)' não terá imagem/gif (match não confiável)")
    #endif

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

    // ✅ Casos especiais de bodyweight (comum em HIIT/Circuito/Full Body)
    if localEquipment == .bodyweight {
      // Reconhece variações: "body weight", "bodyweight", "body only"
      if candidate.contains("body") || candidate == "bodyweight" {
        return 3  // Match exato para bodyweight
      }
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
  /// PRIMEIRO traduz de português para inglês.
  private func generateSearchQueries(from name: String) -> [String] {
    var queries: [String] = []
    
    // 0. PRIMEIRO: Traduz o nome de português para inglês
    let translatedName = translateExerciseName(name)
    let lowercased = translatedName.lowercased().trimmingCharacters(in: .whitespaces)
    
    // Se houve tradução, adiciona ambas as versões (traduzida priorizada)
    if translatedName.lowercased() != name.lowercased() {
      queries.append(lowercased) // Prioriza a tradução
      // Também tenta o original (caso esteja em inglês ou tenha variação)
      let originalLowercased = name.lowercased().trimmingCharacters(in: .whitespaces)
      if originalLowercased != lowercased {
        queries.append(originalLowercased)
      }
    } else {
      // Se não houve tradução, usa o nome original
      if !lowercased.isEmpty {
        queries.append(lowercased)
      }
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
  /// Usa tradução PT → EN para melhor matching.
  private func bestMatch(
    for name: String,
    candidates: [ExerciseDBExercise],
    equipment: EquipmentType? = nil
  ) -> ExerciseDBExercise? {
    guard !candidates.isEmpty else { return nil }
    
    // Traduz o nome para inglês antes de comparar
    let translatedName = translateExerciseName(name)
    let normalizedTarget = normalizeName(translatedName)
    let targetWords = Set(tokenize(translatedName))
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
    // ✅ v2: Incrementado para invalidar mappings antigos após melhorias no algoritmo (2026-01-08)
    // Changelog:
    // - v1: Versão inicial (tinha mappings incorretos devido a targets inválidos)
    // - v2: Após correção de targets + threshold=5 + 80% token coverage
    static let mapping = "exercisedb_id_mapping_v2"
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

