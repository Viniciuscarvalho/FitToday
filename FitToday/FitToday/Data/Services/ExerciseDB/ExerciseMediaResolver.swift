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

  static let placeholder = ResolvedExerciseMedia(
    gifURL: nil,
    imageURL: nil,
    source: .placeholder
  )
}

/// Protocolo para resolução de mídia de exercícios.
protocol ExerciseMediaResolving: Sendable {
  /// Resolve a mídia para um exercício, usando dados existentes ou buscando da API.
  func resolveMedia(
    for exerciseId: String,
    existingMedia: ExerciseMedia?
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
  private var resolvedCache: [String: ResolvedExerciseMedia] = [:]

  init(service: ExerciseDBServicing? = nil) {
    self.service = service
  }

  func resolveMedia(
    for exerciseId: String,
    existingMedia: ExerciseMedia?
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

    // 2. Verifica cache
    if let cached = resolvedCache[exerciseId] {
      return cached
    }

    // 3. Tenta buscar da API
    guard let service = service else {
      #if DEBUG
      print("[MediaResolver] Sem serviço ExerciseDB configurado para \(exerciseId)")
      #endif
      return .placeholder
    }

    do {
      if let exercise = try await service.fetchExercise(byId: exerciseId),
         let gifUrlString = exercise.gifUrl,
         let gifURL = URL(string: gifUrlString) {
        let resolved = ResolvedExerciseMedia(
          gifURL: gifURL,
          imageURL: gifURL, // Usa mesma URL como fallback
          source: .exerciseDB
        )
        resolvedCache[exerciseId] = resolved
        return resolved
      }
    } catch {
      #if DEBUG
      print("[MediaResolver] Erro ao buscar mídia para \(exerciseId): \(error)")
      #endif
    }

    // 4. Fallback para placeholder
    let placeholder = ResolvedExerciseMedia.placeholder
    resolvedCache[exerciseId] = placeholder
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
}

// MARK: - Extensão para facilitar uso com WorkoutExercise

extension ExerciseMediaResolving {
  func resolveMedia(for exercise: WorkoutExercise) async -> ResolvedExerciseMedia {
    await resolveMedia(for: exercise.id, existingMedia: exercise.media)
  }

  func resolveMediaSync(for exercise: WorkoutExercise) -> ResolvedExerciseMedia {
    resolveMediaSync(for: exercise.id, existingMedia: exercise.media)
  }
}


