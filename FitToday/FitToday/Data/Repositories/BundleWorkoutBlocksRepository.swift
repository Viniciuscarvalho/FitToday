//
//  BundleWorkoutBlocksRepository.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

actor BundleWorkoutBlocksRepository: WorkoutBlocksRepository {
    private let loader: WorkoutBlocksLoader
    private let mediaResolver: ExerciseMediaResolving?
    private let exerciseService: ExerciseDBServicing?
    private var cachedBlocks: [WorkoutBlock]?

    init(
        loader: WorkoutBlocksLoader = WorkoutBlocksLoader(),
        mediaResolver: ExerciseMediaResolving? = nil,
        exerciseService: ExerciseDBServicing? = nil
    ) {
        self.loader = loader
        self.mediaResolver = mediaResolver
        self.exerciseService = exerciseService
    }

    func loadBlocks() async throws -> [WorkoutBlock] {
        if let cached = cachedBlocks {
            return cached
        }
        let blocks = try loader.loadBlocks()

        // Se não houver resolver/serviço, retorna o seed puro.
        guard let mediaResolver else {
            cachedBlocks = blocks
            return blocks
        }

        let enriched = await enrich(blocks: blocks, mediaResolver: mediaResolver, exerciseService: exerciseService)
        cachedBlocks = enriched
        return enriched
    }

    private func enrich(
        blocks: [WorkoutBlock],
        mediaResolver: ExerciseMediaResolving,
        exerciseService: ExerciseDBServicing?
    ) async -> [WorkoutBlock] {
        await withTaskGroup(of: (Int, WorkoutBlock).self) { group in
            for (index, block) in blocks.enumerated() {
                group.addTask {
                    var newBlock = block
                    var newExercises: [WorkoutExercise] = []
                    newExercises.reserveCapacity(block.exercises.count)

                    for exercise in block.exercises {
                        var updated = exercise

                        // 1) Mídia via /image (migração híbrida por nome)
                        let resolvedMedia = await mediaResolver.resolveMedia(for: exercise, context: .thumbnail)
                        if resolvedMedia.hasMedia {
                            updated.media = ExerciseMedia(
                                imageURL: resolvedMedia.imageURL ?? resolvedMedia.gifURL,
                                gifURL: resolvedMedia.gifURL ?? resolvedMedia.imageURL,
                                source: resolvedMedia.source.rawValue
                            )
                        }

                        // 2) Enriquecer instruções (best-effort) se estiver vazio ou muito curto
                        if (updated.instructions.count <= 1), let exerciseService {
                            if let match = try? await exerciseService.searchExercises(query: updated.name, limit: 1).first {
                                if let instructions = match.instructions, !instructions.isEmpty {
                                    updated.instructions = instructions
                                }
                            }
                        }

                        newExercises.append(updated)
                    }

                    newBlock.exercises = newExercises
                    return (index, newBlock)
                }
            }

            var results: [(Int, WorkoutBlock)] = []
            results.reserveCapacity(blocks.count)
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}

