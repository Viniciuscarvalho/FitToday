//
//  ExerciseDBBlockEnricher.swift
//  FitToday
//
//  Created by AI on 11/01/26.
//

import Foundation

/// Protocolo para enriquecer blocos de treino com exercícios da API ExerciseDB
protocol ExerciseDBBlockEnriching: Sendable {
  /// Enriquece blocos existentes com exercícios adicionais da API
  func enrichBlocks(_ blocks: [WorkoutBlock]) async throws -> [WorkoutBlock]

  /// Cria blocos dinâmicos baseados em objetivos e targets da API
  func createDynamicBlocks(
    for goal: FitnessGoal,
    level: TrainingLevel,
    structure: TrainingStructure
  ) async throws -> [WorkoutBlock]
}

/// Mapeia targets do ExerciseDB para MuscleGroups do app
struct ExerciseDBTargetMapper: Sendable {

  /// Mapeia target do ExerciseDB para MuscleGroup
  static func mapTarget(_ target: String) -> MuscleGroup? {
    let normalized = target.lowercased().trimmingCharacters(in: .whitespaces)

    switch normalized {
    // Chest
    case "pectorals", "chest":
      return .chest

    // Back
    case "lats":
      return .lats
    case "upper back", "traps":
      return .back
    case "lower back":
      return .lowerBack

    // Shoulders
    case "delts", "shoulders":
      return .shoulders

    // Arms
    case "biceps":
      return .biceps
    case "triceps":
      return .triceps
    case "forearms":
      return .forearms

    // Legs
    case "quads", "quadriceps":
      return .quads
    case "hamstrings":
      return .hamstrings
    case "glutes":
      return .glutes
    case "calves":
      return .calves

    // Core
    case "abs", "abdominals", "core":
      return .core

    // Cardio
    case "cardiovascular system", "cardio":
      return .cardioSystem

    default:
      return nil
    }
  }

  /// Retorna lista de targets VÁLIDOS para um MuscleGroup
  /// 
  /// IMPORTANTE: Usar APENAS targets que existem na API ExerciseDB:
  /// abs, adductors, abductors, biceps, calves, cardiovascular system,
  /// delts, forearms, glutes, hamstrings, lats, levator scapulae,
  /// pectorals, quads, serratus anterior, spine, traps, triceps, upper back
  static func targetsFor(muscleGroup: MuscleGroup) -> [String] {
    switch muscleGroup {
    case .chest:
      return ["pectorals"] // "chest" NÃO existe na API
    case .back:
      return ["lats", "upper back", "traps"]
    case .lats:
      return ["lats"]
    case .lowerBack:
      return ["spine"] // "lower back" NÃO existe na API
    case .shoulders:
      return ["delts"] // "shoulders" NÃO existe na API
    case .biceps:
      return ["biceps"]
    case .triceps:
      return ["triceps"]
    case .forearms:
      return ["forearms"]
    case .arms:
      return ["biceps", "triceps", "forearms"]
    case .quads, .quadriceps:
      return ["quads"] // "quadriceps" NÃO existe na API
    case .hamstrings:
      return ["hamstrings"]
    case .glutes:
      return ["glutes"]
    case .calves:
      return ["calves"]
    case .core:
      return ["abs", "serratus anterior"] // "core" NÃO existe na API
    case .cardioSystem:
      return ["cardiovascular system"]
    case .fullBody:
      return []
    }
  }
}

/// Mapeia equipment do ExerciseDB para EquipmentType do app
struct ExerciseDBEquipmentMapper: Sendable {

  static func mapEquipment(_ equipment: String) -> EquipmentType? {
    let normalized = equipment.lowercased().trimmingCharacters(in: .whitespaces)

    switch normalized {
    case "barbell":
      return .barbell
    case "dumbbell":
      return .dumbbell
    case "bodyweight", "body weight":
      return .bodyweight
    case "cable", "cable machine":
      return .cable
    case "machine", "leverage machine", "sled machine":
      return .machine
    case "kettlebell":
      return .kettlebell
    case "resistance band", "band":
      return .resistanceBand
    case "pull-up bar", "pullup bar":
      return .pullupBar
    case "ez barbell", "ez-bar":
      return .barbell
    default:
      return nil
    }
  }
}

/// Serviço para enriquecer blocos de treino com exercícios da API ExerciseDB
actor ExerciseDBBlockEnricher: ExerciseDBBlockEnriching {
  private let service: ExerciseDBServicing
  private let maxExercisesPerBlock: Int
  private let maxExercisesPerTarget: Int

  init(
    service: ExerciseDBServicing,
    maxExercisesPerBlock: Int = 12,
    maxExercisesPerTarget: Int = 20
  ) {
    self.service = service
    self.maxExercisesPerBlock = maxExercisesPerBlock
    self.maxExercisesPerTarget = maxExercisesPerTarget
  }

  func enrichBlocks(_ blocks: [WorkoutBlock]) async throws -> [WorkoutBlock] {
    var enrichedBlocks: [WorkoutBlock] = []

    for block in blocks {
      // Se o bloco já tem exercícios suficientes, mantém como está
      if block.exercises.count >= maxExercisesPerBlock {
        enrichedBlocks.append(block)
        continue
      }

      // Tenta enriquecer com exercícios da API
      do {
        let enriched = try await enrichBlock(block)
        enrichedBlocks.append(enriched)
      } catch {
        #if DEBUG
        print("[ExerciseEnricher] Erro ao enriquecer bloco '\(block.id)': \(error)")
        #endif
        // Em caso de erro, mantém bloco original
        enrichedBlocks.append(block)
      }
    }

    return enrichedBlocks
  }

  func createDynamicBlocks(
    for goal: FitnessGoal,
    level: TrainingLevel,
    structure: TrainingStructure
  ) async throws -> [WorkoutBlock] {
    var blocks: [WorkoutBlock] = []

    // Criar blocos específicos baseados no objetivo
    switch goal {
    case .hypertrophy:
      blocks += try await createHypertrophyBlocks(level: level, structure: structure)
    case .weightLoss:
      blocks += try await createWeightLossBlocks(level: level, structure: structure)
    case .performance:
      blocks += try await createPerformanceBlocks(level: level, structure: structure)
    case .conditioning:
      blocks += try await createConditioningBlocks(level: level, structure: structure)
    case .endurance:
      blocks += try await createEnduranceBlocks(level: level, structure: structure)
    }

    return blocks
  }

  // MARK: - Private Helpers

  private func enrichBlock(_ block: WorkoutBlock) async throws -> WorkoutBlock {
    var exercises = block.exercises

    // Determinar quais muscle groups precisam de mais exercícios
    let existingMuscles = Set(exercises.map { $0.mainMuscle })
    let targetMuscles = Set(block.exercises.map { $0.mainMuscle })

    // Para cada muscle group, buscar exercícios adicionais
    for muscle in targetMuscles {
      let currentCount = exercises.filter { $0.mainMuscle == muscle }.count
      if currentCount >= 4 { continue } // Máximo 4 exercícios por músculo no bloco

      // Buscar targets correspondentes
      let targets = ExerciseDBTargetMapper.targetsFor(muscleGroup: muscle)

      for target in targets {
        do {
          let apiExercises = try await service.fetchExercises(target: target, limit: maxExercisesPerTarget)

          // Converter para WorkoutExercise
          let workoutExercises = apiExercises.compactMap { apiEx -> WorkoutExercise? in
            convertAPIExercise(apiEx, targetMuscle: muscle, blockEquipment: block.equipmentOptions)
          }

          // Adicionar exercícios que não duplicam nomes existentes
          let existingNames = Set(exercises.map { $0.name.lowercased() })
          let newExercises = workoutExercises.filter { !existingNames.contains($0.name.lowercased()) }

          exercises.append(contentsOf: newExercises.prefix(maxExercisesPerBlock - exercises.count))

          if exercises.count >= maxExercisesPerBlock {
            break
          }
        } catch {
          #if DEBUG
          print("[ExerciseEnricher] Erro ao buscar target '\(target)': \(error)")
          #endif
          continue
        }
      }

      if exercises.count >= maxExercisesPerBlock {
        break
      }
    }

    // Retornar bloco enriquecido
    return WorkoutBlock(
      id: block.id,
      group: block.group,
      level: block.level,
      compatibleStructures: block.compatibleStructures,
      equipmentOptions: block.equipmentOptions,
      exercises: exercises,
      suggestedSets: block.suggestedSets,
      suggestedReps: block.suggestedReps,
      restInterval: block.restInterval
    )
  }

  private func convertAPIExercise(
    _ apiExercise: ExerciseDBExercise,
    targetMuscle: MuscleGroup,
    blockEquipment: [EquipmentType]
  ) -> WorkoutExercise? {
    // Mapear equipment
    guard let equipmentStr = apiExercise.equipment,
          let equipment = ExerciseDBEquipmentMapper.mapEquipment(equipmentStr),
          blockEquipment.contains(equipment) else {
      return nil
    }

    // Usar instruções da API ou criar padrão
    let instructions = apiExercise.instructions ?? [
      "Execute o movimento com controle.",
      "Mantenha a forma correta durante toda execução.",
      "Respire adequadamente."
    ]

    return WorkoutExercise(
      id: apiExercise.id,
      name: apiExercise.name,
      mainMuscle: targetMuscle,
      equipment: equipment,
      instructions: instructions,
      media: ExerciseMedia(
        imageURL: URL(string: "https://raw.githubusercontent.com/ExerciseDB/exercisedb-api/main/assets/images/\(apiExercise.name.replacingOccurrences(of: " ", with: "-")).png"),
        gifURL: URL(string: "https://raw.githubusercontent.com/ExerciseDB/exercisedb-api/main/assets/gifs/\(apiExercise.name.replacingOccurrences(of: " ", with: "-")).gif"),
        source: "ExerciseDB"
      )
    )
  }

  // MARK: - Goal-Specific Block Creators

  private func createHypertrophyBlocks(level: TrainingLevel, structure: TrainingStructure) async throws -> [WorkoutBlock] {
    // Hipertrofia: foco em volume, tempo sob tensão, sobrecarga progressiva
    // Sets: 3-5, Reps: 6-12, Rest: 60-120s
    var blocks: [WorkoutBlock] = []

    let equipment = equipmentForStructure(structure)

    // Bloco de peito isolado (hipertrofia)
    if let chestBlock = try? await createMuscleBlock(
      id: "hypertrophy_chest_\(level.rawValue)",
      group: .upper,
      level: level,
      structures: [structure],
      equipment: equipment,
      targetMuscle: .chest,
      sets: 4...5,
      reps: 8...12,
      rest: 90
    ) {
      blocks.append(chestBlock)
    }

    // Bloco de costas isolado (hipertrofia)
    if let backBlock = try? await createMuscleBlock(
      id: "hypertrophy_back_\(level.rawValue)",
      group: .upper,
      level: level,
      structures: [structure],
      equipment: equipment,
      targetMuscle: .back,
      sets: 4...5,
      reps: 8...12,
      rest: 90
    ) {
      blocks.append(backBlock)
    }

    // Bloco de pernas isolado (hipertrofia)
    if let legsBlock = try? await createMuscleBlock(
      id: "hypertrophy_legs_\(level.rawValue)",
      group: .lower,
      level: level,
      structures: [structure],
      equipment: equipment,
      targetMuscle: .quads,
      sets: 4...5,
      reps: 8...12,
      rest: 120
    ) {
      blocks.append(legsBlock)
    }

    return blocks
  }

  private func createWeightLossBlocks(level: TrainingLevel, structure: TrainingStructure) async throws -> [WorkoutBlock] {
    // Emagrecimento: foco em gasto calórico, circuitos, alta densidade
    // Sets: 3-4, Reps: 12-20, Rest: 30-45s
    var blocks: [WorkoutBlock] = []

    let equipment = equipmentForStructure(structure)

    // Bloco de circuito full body
    if let circuitBlock = try? await createMuscleBlock(
      id: "weightloss_circuit_\(level.rawValue)",
      group: .fullBody,
      level: level,
      structures: [structure],
      equipment: equipment,
      targetMuscle: .fullBody,
      sets: 3...4,
      reps: 15...20,
      rest: 30
    ) {
      blocks.append(circuitBlock)
    }

    // Bloco cardio intenso
    if let cardioBlock = try? await createMuscleBlock(
      id: "weightloss_cardio_\(level.rawValue)",
      group: .cardio,
      level: level,
      structures: [structure],
      equipment: [.bodyweight],
      targetMuscle: .cardioSystem,
      sets: 4...5,
      reps: 30...45,
      rest: 20
    ) {
      blocks.append(cardioBlock)
    }

    return blocks
  }

  private func createPerformanceBlocks(level: TrainingLevel, structure: TrainingStructure) async throws -> [WorkoutBlock] {
    // Performance: foco em força, potência, explosão
    // Sets: 3-5, Reps: 3-8, Rest: 90-180s
    var blocks: [WorkoutBlock] = []

    let equipment = equipmentForStructure(structure)

    // Bloco de força máxima
    if let strengthBlock = try? await createMuscleBlock(
      id: "performance_strength_\(level.rawValue)",
      group: .fullBody,
      level: level,
      structures: [structure],
      equipment: equipment,
      targetMuscle: .fullBody,
      sets: 3...5,
      reps: 4...8,
      rest: 180
    ) {
      blocks.append(strengthBlock)
    }

    return blocks
  }

  private func createConditioningBlocks(level: TrainingLevel, structure: TrainingStructure) async throws -> [WorkoutBlock] {
    // Condicionamento: equilíbrio força + resistência
    // Sets: 3-4, Reps: 10-15, Rest: 45-75s
    var blocks: [WorkoutBlock] = []

    let equipment = equipmentForStructure(structure)

    if let conditioningBlock = try? await createMuscleBlock(
      id: "conditioning_fullbody_\(level.rawValue)",
      group: .fullBody,
      level: level,
      structures: [structure],
      equipment: equipment,
      targetMuscle: .fullBody,
      sets: 3...4,
      reps: 10...15,
      rest: 60
    ) {
      blocks.append(conditioningBlock)
    }

    return blocks
  }

  private func createEnduranceBlocks(level: TrainingLevel, structure: TrainingStructure) async throws -> [WorkoutBlock] {
    // Resistência: volume alto, intensidade moderada
    // Sets: 2-4, Reps: 15-25, Rest: 30-45s
    var blocks: [WorkoutBlock] = []

    let equipment = equipmentForStructure(structure)

    if let enduranceBlock = try? await createMuscleBlock(
      id: "endurance_circuit_\(level.rawValue)",
      group: .fullBody,
      level: level,
      structures: [structure],
      equipment: equipment,
      targetMuscle: .fullBody,
      sets: 3...4,
      reps: 18...25,
      rest: 30
    ) {
      blocks.append(enduranceBlock)
    }

    return blocks
  }

  private func createMuscleBlock(
    id: String,
    group: DailyFocus,
    level: TrainingLevel,
    structures: [TrainingStructure],
    equipment: [EquipmentType],
    targetMuscle: MuscleGroup,
    sets: ClosedRange<Int>,
    reps: ClosedRange<Int>,
    rest: Int
  ) async throws -> WorkoutBlock? {
    // Buscar exercícios da API para o muscle group
    let targets = ExerciseDBTargetMapper.targetsFor(muscleGroup: targetMuscle)
    var exercises: [WorkoutExercise] = []

    for target in targets {
      let apiExercises = try await service.fetchExercises(target: target, limit: maxExercisesPerTarget)

      let workoutExercises = apiExercises.compactMap { apiEx -> WorkoutExercise? in
        convertAPIExercise(apiEx, targetMuscle: targetMuscle, blockEquipment: equipment)
      }

      exercises.append(contentsOf: workoutExercises)

      if exercises.count >= maxExercisesPerBlock {
        break
      }
    }

    // Se não conseguiu exercícios suficientes, retorna nil
    guard exercises.count >= 3 else {
      return nil
    }

    return WorkoutBlock(
      id: id,
      group: group,
      level: level,
      compatibleStructures: structures,
      equipmentOptions: equipment,
      exercises: Array(exercises.prefix(maxExercisesPerBlock)),
      suggestedSets: IntRange(sets.lowerBound, sets.upperBound),
      suggestedReps: IntRange(reps.lowerBound, reps.upperBound),
      restInterval: TimeInterval(rest)
    )
  }

  private func equipmentForStructure(_ structure: TrainingStructure) -> [EquipmentType] {
    switch structure {
    case .bodyweight:
      return [.bodyweight]
    case .homeDumbbells:
      return [.bodyweight, .dumbbell, .resistanceBand]
    case .basicGym:
      return [.machine, .dumbbell, .cable, .bodyweight, .pullupBar]
    case .fullGym:
      return EquipmentType.allCases
    }
  }
}
