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
    private let blockEnricher: ExerciseDBBlockEnriching?
    private var cachedBlocks: [WorkoutBlock]?
    private let enableDynamicEnrichment: Bool

    init(
        loader: WorkoutBlocksLoader = WorkoutBlocksLoader(),
        mediaResolver: ExerciseMediaResolving? = nil,
        exerciseService: ExerciseDBServicing? = nil,
        blockEnricher: ExerciseDBBlockEnriching? = nil,
        enableDynamicEnrichment: Bool = true
    ) {
        self.loader = loader
        self.mediaResolver = mediaResolver
        self.exerciseService = exerciseService
        self.blockEnricher = blockEnricher
        self.enableDynamicEnrichment = enableDynamicEnrichment
    }

    func loadBlocks() async throws -> [WorkoutBlock] {
        if let cached = cachedBlocks {
            return cached
        }
        var blocks = try loader.loadBlocks()

        // 1. Enriquecimento dinâmico com ExerciseDB API (se habilitado)
        if enableDynamicEnrichment, let blockEnricher = blockEnricher {
            #if DEBUG
            print("[Repository] Enriquecendo blocos com ExerciseDB API...")
            #endif
            do {
                blocks = try await blockEnricher.enrichBlocks(blocks)
                #if DEBUG
                let totalExercises = blocks.reduce(0) { $0 + $1.exercises.count }
                print("[Repository] ✅ Enriquecimento dinâmico completo: \(totalExercises) exercícios")
                #endif
            } catch {
                #if DEBUG
                print("[Repository] ⚠️ Erro no enriquecimento dinâmico: \(error). Usando blocos originais.")
                #endif
            }
        }

        // 2. Enriquecimento de mídia e instruções (legacy)
        if let mediaResolver {
            blocks = await enrich(blocks: blocks, mediaResolver: mediaResolver, exerciseService: exerciseService)
        }

        cachedBlocks = blocks
        return blocks
    }

    /// Carrega blocos específicos para um objetivo e cria blocos dinâmicos adicionais
    func loadBlocks(for goal: FitnessGoal, level: TrainingLevel, structure: TrainingStructure) async throws -> [WorkoutBlock] {
        // Carregar blocos base
        var allBlocks = try await loadBlocks()

        // Se enriquecimento dinâmico está habilitado, criar blocos adicionais específicos por objetivo
        if enableDynamicEnrichment, let blockEnricher = blockEnricher {
            #if DEBUG
            print("[Repository] Criando blocos dinâmicos para objetivo: \(goal.rawValue)")
            #endif
            do {
                let dynamicBlocks = try await blockEnricher.createDynamicBlocks(
                    for: goal,
                    level: level,
                    structure: structure
                )
                #if DEBUG
                print("[Repository] ✅ \(dynamicBlocks.count) blocos dinâmicos criados")
                #endif
                allBlocks.append(contentsOf: dynamicBlocks)
            } catch {
                #if DEBUG
                print("[Repository] ⚠️ Erro ao criar blocos dinâmicos: \(error)")
                #endif
            }
        }

        return allBlocks
    }

    /// Limpa cache (útil para forçar reload)
    func clearCache() {
        cachedBlocks = nil
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

