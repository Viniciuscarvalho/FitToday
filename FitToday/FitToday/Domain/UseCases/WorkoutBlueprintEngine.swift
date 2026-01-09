//
//  WorkoutBlueprintEngine.swift
//  FitToday
//
//  Created by AI on 09/01/26.
//

import Foundation

// MARK: - Protocol

/// Protocol para geração de blueprints de treino
protocol BlueprintGenerating: Sendable {
  /// Gera um blueprint de treino baseado nos inputs
  /// - Parameters:
  ///   - input: Inputs consolidados (perfil + check-in + data)
  /// - Returns: Blueprint determinístico para os inputs fornecidos
  func generateBlueprint(from input: BlueprintInput) -> WorkoutBlueprint
  
  /// Gera blueprint a partir de perfil e check-in
  func generateBlueprint(profile: UserProfile, checkIn: DailyCheckIn) -> WorkoutBlueprint
}

// MARK: - Engine Implementation

/// Motor de geração de blueprints de treino
/// Determinístico: mesmos inputs → mesmo blueprint
/// Baseado nos guias de personal-active/ para cada objetivo
struct WorkoutBlueprintEngine: BlueprintGenerating, Sendable {
  
  // MARK: - BlueprintGenerating
  
  func generateBlueprint(profile: UserProfile, checkIn: DailyCheckIn) -> WorkoutBlueprint {
    let input = BlueprintInput.from(profile: profile, checkIn: checkIn)
    return generateBlueprint(from: input)
  }
  
  func generateBlueprint(from input: BlueprintInput) -> WorkoutBlueprint {
    let sessionType = SpecialistSessionRules.sessionType(for: input.goal)
    let domsAdjustment = SpecialistSessionRules.DOMSAdjustment.adjustment(for: input.sorenessLevel)
    let isRecoveryMode = input.sorenessLevel == .strong
    
    // Gerar blocos baseados no objetivo
    let blocks = generateBlocks(
      for: sessionType,
      focus: input.focus,
      level: input.level,
      domsAdjustment: domsAdjustment,
      seed: input.variationSeed
    )
    
    // Determinar intensidade
    let intensity = SpecialistSessionRules.intensity(
      for: input.level,
      soreness: input.sorenessLevel,
      goal: input.goal
    )
    
    // Calcular duração estimada
    let duration = estimateDuration(blocks: blocks, level: input.level, structure: input.structure)
    
    // Gerar título
    let title = SpecialistSessionRules.sessionTitle(
      focus: input.focus,
      goal: input.goal,
      soreness: input.sorenessLevel
    )
    
    // Constraints de equipamento
    let equipmentConstraints = BlueprintEquipmentConstraints.from(structure: input.structure)
    
    return WorkoutBlueprint(
      variationSeed: input.variationSeed,
      title: title,
      focus: input.focus,
      goal: input.goal,
      structure: input.structure,
      level: input.level,
      intensity: intensity,
      estimatedDurationMinutes: duration,
      blocks: blocks,
      equipmentConstraints: equipmentConstraints,
      isRecoveryMode: isRecoveryMode
    )
  }
  
  // MARK: - Block Generation
  
  private func generateBlocks(
    for sessionType: SpecialistSessionRules.SessionType,
    focus: DailyFocus,
    level: TrainingLevel,
    domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
    seed: UInt64
  ) -> [WorkoutBlockBlueprint] {
    var blocks: [WorkoutBlockBlueprint] = []
    
    // 1. Aquecimento (sempre presente)
    blocks.append(generateWarmupBlock(
      focus: focus,
      domsAdjustment: domsAdjustment,
      seed: seed
    ))
    
    // 2. Blocos específicos por objetivo
    switch sessionType {
    case .strength:
      blocks.append(contentsOf: generateStrengthBlocks(
        focus: focus,
        level: level,
        domsAdjustment: domsAdjustment,
        seed: seed
      ))
      
    case .performance:
      blocks.append(contentsOf: generatePerformanceBlocks(
        focus: focus,
        level: level,
        domsAdjustment: domsAdjustment,
        seed: seed
      ))
      
    case .weightLoss:
      blocks.append(contentsOf: generateWeightLossBlocks(
        focus: focus,
        level: level,
        domsAdjustment: domsAdjustment,
        seed: seed
      ))
      
    case .conditioning:
      blocks.append(contentsOf: generateConditioningBlocks(
        focus: focus,
        level: level,
        domsAdjustment: domsAdjustment,
        seed: seed
      ))
      
    case .endurance:
      blocks.append(contentsOf: generateEnduranceBlocks(
        focus: focus,
        level: level,
        domsAdjustment: domsAdjustment,
        seed: seed
      ))
    }
    
    // 3. Aeróbio/Finalização (baseado no objetivo)
    if let aerobicBlock = generateAerobicBlock(
      for: sessionType,
      domsAdjustment: domsAdjustment,
      seed: seed
    ) {
      blocks.append(aerobicBlock)
    }
    
    return blocks
  }
  
  // MARK: - Warmup Block
  
  private func generateWarmupBlock(
    focus: DailyFocus,
    domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
    seed: UInt64
  ) -> WorkoutBlockBlueprint {
    let targetMuscles = musclesFor(focus: focus)
    let activityMinutes = domsAdjustment.intensityReduction ? 8 : 6
    
    return WorkoutBlockBlueprint(
      phaseKind: .warmup,
      title: "Aquecimento",
      exerciseCount: domsAdjustment.intensityReduction ? 1 : 2,
      setsRange: 1...1,
      repsRange: 8...12,
      restSeconds: domsAdjustment.intensityReduction ? 40 : 25,
      rpeTarget: domsAdjustment.intensityReduction ? 5 : 6,
      targetMuscles: targetMuscles,
      avoidMuscles: [],
      includesGuidedActivity: true,
      guidedActivityKind: .mobility,
      guidedActivityMinutes: activityMinutes
    )
  }
  
  // MARK: - Strength Blocks (Hipertrofia/Força)
  
  /// Blocos para objetivo de força/hipertrofia
  /// Baseado em personal-active/hipertrofia.md e força.md:
  /// - Exercícios multiarticulares prioritários
  /// - Alta intensidade, baixo-médio volume
  /// - Descanso longo para recuperação neural
  private func generateStrengthBlocks(
    focus: DailyFocus,
    level: TrainingLevel,
    domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
    seed: UInt64
  ) -> [WorkoutBlockBlueprint] {
    let targetMuscles = musclesFor(focus: focus)
    let volumeMultiplier = domsAdjustment.volumeMultiplier
    
    // Ajustar por nível
    let (mainSets, mainReps, restSeconds): (ClosedRange<Int>, ClosedRange<Int>, Int)
    switch level {
    case .beginner:
      mainSets = 3...3
      mainReps = 8...12
      restSeconds = 90
    case .intermediate:
      mainSets = 3...4
      mainReps = 6...10
      restSeconds = 120
    case .advanced:
      mainSets = 4...5
      mainReps = 4...8
      restSeconds = 180
    }
    
    // Aplicar ajuste de DOMS
    let adjustedSets = applyVolumeAdjustment(mainSets, multiplier: volumeMultiplier)
    let adjustedRest = restSeconds + domsAdjustment.extraRestSeconds
    
    // Ajustar número de exercícios por nível
    let mainExerciseCount: Int
    let accessoryExerciseCount: Int
    switch level {
    case .beginner:
      mainExerciseCount = 4
      accessoryExerciseCount = 2
    case .intermediate:
      mainExerciseCount = 5
      accessoryExerciseCount = 3
    case .advanced:
      mainExerciseCount = 6
      accessoryExerciseCount = 3
    }
    
    let mainBlock = WorkoutBlockBlueprint(
      phaseKind: .strength,
      title: "Força Principal",
      exerciseCount: mainExerciseCount,
      setsRange: adjustedSets,
      repsRange: mainReps,
      restSeconds: adjustedRest,
      rpeTarget: domsAdjustment.avoidMuscleFailure ? 7 : 8,
      targetMuscles: targetMuscles,
      avoidMuscles: []
    )
    
    let accessoryBlock = WorkoutBlockBlueprint(
      phaseKind: .accessory,
      title: "Acessórios",
      exerciseCount: accessoryExerciseCount,
      setsRange: 2...3,
      repsRange: 10...15,
      restSeconds: 60 + domsAdjustment.extraRestSeconds,
      rpeTarget: 6,
      targetMuscles: secondaryMusclesFor(focus: focus),
      avoidMuscles: []
    )
    
    return [mainBlock, accessoryBlock]
  }
  
  // MARK: - Performance Blocks
  
  /// Blocos para objetivo de performance atlética
  /// - Movimentos explosivos e funcionais
  /// - Qualidade > quantidade
  /// - Recuperação adequada
  private func generatePerformanceBlocks(
    focus: DailyFocus,
    level: TrainingLevel,
    domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
    seed: UInt64
  ) -> [WorkoutBlockBlueprint] {
    let targetMuscles = musclesFor(focus: focus)
    
    // Ajustar número de exercícios por nível
    let mainExerciseCount: Int
    let conditioningExerciseCount: Int
    switch level {
    case .beginner:
      mainExerciseCount = 3
      conditioningExerciseCount = 2
    case .intermediate:
      mainExerciseCount = 4
      conditioningExerciseCount = 3
    case .advanced:
      mainExerciseCount = 5
      conditioningExerciseCount = 3
    }
    
    let mainBlock = WorkoutBlockBlueprint(
      phaseKind: .strength,
      title: "Performance Atlética",
      exerciseCount: mainExerciseCount,
      setsRange: 3...4,
      repsRange: 5...8,
      restSeconds: 90 + domsAdjustment.extraRestSeconds,
      rpeTarget: 7,
      targetMuscles: targetMuscles,
      avoidMuscles: []
    )
    
    let conditioningBlock = WorkoutBlockBlueprint(
      phaseKind: .conditioning,
      title: "Condicionamento Funcional",
      exerciseCount: conditioningExerciseCount,
      setsRange: 2...3,
      repsRange: 10...15,
      restSeconds: 45,
      rpeTarget: 7,
      targetMuscles: [.fullBody],
      avoidMuscles: []
    )
    
    return [mainBlock, conditioningBlock]
  }
  
  // MARK: - Weight Loss Blocks (Emagrecimento)
  
  /// Blocos para objetivo de emagrecimento
  /// Baseado em personal-active/emagrecimento.md:
  /// - Circuitos full body
  /// - Alta densidade (intervalos curtos)
  /// - RPE 6-8
  /// - Ênfase em gasto energético
  private func generateWeightLossBlocks(
    focus: DailyFocus,
    level: TrainingLevel,
    domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
    seed: UInt64
  ) -> [WorkoutBlockBlueprint] {
    let targetMuscles = musclesFor(focus: focus)
    let volumeMultiplier = domsAdjustment.volumeMultiplier
    
    // Ajustar número de exercícios por nível (emagrecimento precisa de volume)
    let metabolicExerciseCount: Int
    let accessoryExerciseCount: Int
    switch level {
    case .beginner:
      metabolicExerciseCount = 5
      accessoryExerciseCount = 2
    case .intermediate:
      metabolicExerciseCount = 6
      accessoryExerciseCount = 3
    case .advanced:
      metabolicExerciseCount = 7
      accessoryExerciseCount = 3
    }
    
    // Metabolic circuit block
    let metabolicBlock = WorkoutBlockBlueprint(
      phaseKind: .strength,
      title: "Circuito Metabólico",
      exerciseCount: metabolicExerciseCount,
      setsRange: applyVolumeAdjustment(3...4, multiplier: volumeMultiplier),
      repsRange: 12...18,
      restSeconds: 30 + domsAdjustment.extraRestSeconds,
      rpeTarget: domsAdjustment.intensityReduction ? 6 : 7,
      targetMuscles: targetMuscles,
      avoidMuscles: []
    )
    
    let accessoryBlock = WorkoutBlockBlueprint(
      phaseKind: .accessory,
      title: "Finalizadores",
      exerciseCount: accessoryExerciseCount,
      setsRange: 2...3,
      repsRange: 15...20,
      restSeconds: 20,
      rpeTarget: 6,
      targetMuscles: secondaryMusclesFor(focus: focus),
      avoidMuscles: []
    )
    
    return [metabolicBlock, accessoryBlock]
  }
  
  // MARK: - Conditioning Blocks
  
  /// Blocos para objetivo de condicionamento
  /// - Força + resistência
  /// - Intensidade moderada
  private func generateConditioningBlocks(
    focus: DailyFocus,
    level: TrainingLevel,
    domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
    seed: UInt64
  ) -> [WorkoutBlockBlueprint] {
    let targetMuscles = musclesFor(focus: focus)
    
    // Ajustar número de exercícios por nível
    let mainExerciseCount: Int
    let accessoryExerciseCount: Int
    switch level {
    case .beginner:
      mainExerciseCount = 4
      accessoryExerciseCount = 2
    case .intermediate:
      mainExerciseCount = 5
      accessoryExerciseCount = 3
    case .advanced:
      mainExerciseCount = 6
      accessoryExerciseCount = 3
    }
    
    let mainBlock = WorkoutBlockBlueprint(
      phaseKind: .strength,
      title: "Força & Condicionamento",
      exerciseCount: mainExerciseCount,
      setsRange: 3...4,
      repsRange: 10...15,
      restSeconds: 60 + domsAdjustment.extraRestSeconds,
      rpeTarget: 6,
      targetMuscles: targetMuscles,
      avoidMuscles: []
    )
    
    let accessoryBlock = WorkoutBlockBlueprint(
      phaseKind: .accessory,
      title: "Acessórios Funcionais",
      exerciseCount: accessoryExerciseCount,
      setsRange: 2...3,
      repsRange: 12...18,
      restSeconds: 45,
      rpeTarget: 5,
      targetMuscles: secondaryMusclesFor(focus: focus),
      avoidMuscles: []
    )
    
    return [mainBlock, accessoryBlock]
  }
  
  // MARK: - Endurance Blocks (Resistência)
  
  /// Blocos para objetivo de resistência cardiorrespiratória
  /// Baseado em personal-active/resistencia.md:
  /// - Ênfase em aeróbio e técnica
  /// - Volume alto, intensidade controlada
  private func generateEnduranceBlocks(
    focus: DailyFocus,
    level: TrainingLevel,
    domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
    seed: UInt64
  ) -> [WorkoutBlockBlueprint] {
    let targetMuscles = musclesFor(focus: focus)
    
    // Ajustar número de exercícios por nível (resistência precisa de volume)
    let mainExerciseCount: Int
    let accessoryExerciseCount: Int
    switch level {
    case .beginner:
      mainExerciseCount = 4
      accessoryExerciseCount = 2
    case .intermediate:
      mainExerciseCount = 5
      accessoryExerciseCount = 3
    case .advanced:
      mainExerciseCount = 6
      accessoryExerciseCount = 3
    }
    
    // Resistência muscular
    let mainBlock = WorkoutBlockBlueprint(
      phaseKind: .strength,
      title: "Resistência Muscular",
      exerciseCount: mainExerciseCount,
      setsRange: 2...3,
      repsRange: 15...25,
      restSeconds: 30 + domsAdjustment.extraRestSeconds,
      rpeTarget: 6,
      targetMuscles: targetMuscles,
      avoidMuscles: []
    )
    
    let accessoryBlock = WorkoutBlockBlueprint(
      phaseKind: .accessory,
      title: "Complementares",
      exerciseCount: accessoryExerciseCount,
      setsRange: 2...3,
      repsRange: 15...20,
      restSeconds: 20,
      rpeTarget: 5,
      targetMuscles: secondaryMusclesFor(focus: focus),
      avoidMuscles: []
    )
    
    return [mainBlock, accessoryBlock]
  }
  
  // MARK: - Aerobic Block
  
  private func generateAerobicBlock(
    for sessionType: SpecialistSessionRules.SessionType,
    domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
    seed: UInt64
  ) -> WorkoutBlockBlueprint? {
    let (activityKind, title, minutes): (ActivityPrescription.Kind, String, Int)
    
    switch sessionType {
    case .weightLoss:
      activityKind = .aerobicIntervals
      title = "Aeróbio Intervalado (leve)"
      minutes = domsAdjustment.intensityReduction ? 10 : 15
      
    case .conditioning, .endurance:
      activityKind = .aerobicZone2
      title = "Aeróbio Zona 2"
      minutes = domsAdjustment.intensityReduction ? 12 : 18
      
    case .performance:
      activityKind = .aerobicIntervals
      title = "Condicionamento Intervalado"
      minutes = 10
      
    case .strength:
      activityKind = .breathing
      title = "Desaceleração"
      minutes = 5
    }
    
    return WorkoutBlockBlueprint(
      phaseKind: .aerobic,
      title: title,
      exerciseCount: 0,
      setsRange: 0...0,
      repsRange: 0...0,
      restSeconds: 0,
      rpeTarget: 6,
      targetMuscles: [.cardioSystem],
      avoidMuscles: [],
      includesGuidedActivity: true,
      guidedActivityKind: activityKind,
      guidedActivityMinutes: minutes
    )
  }
  
  // MARK: - Helpers
  
  private func musclesFor(focus: DailyFocus) -> [MuscleGroup] {
    switch focus {
    case .upper:
      return [.chest, .back, .shoulders]
    case .lower:
      return [.quads, .quadriceps, .glutes, .hamstrings]
    case .fullBody:
      return [.chest, .back, .quads, .quadriceps]
    case .cardio:
      return [.cardioSystem, .fullBody]
    case .core:
      return [.core]
    case .surprise:
      return [.fullBody]
    }
  }
  
  private func secondaryMusclesFor(focus: DailyFocus) -> [MuscleGroup] {
    switch focus {
    case .upper:
      return [.biceps, .triceps, .arms]
    case .lower:
      return [.calves, .core]
    case .fullBody:
      return [.shoulders, .core, .glutes]
    case .cardio:
      return [.core, .glutes]
    case .core:
      return [.glutes, .back]
    case .surprise:
      return [.core]
    }
  }
  
  private func applyVolumeAdjustment(
    _ range: ClosedRange<Int>,
    multiplier: Double
  ) -> ClosedRange<Int> {
    let adjustedLower = max(1, Int(Double(range.lowerBound) * multiplier))
    let adjustedUpper = max(adjustedLower, Int(Double(range.upperBound) * multiplier))
    return adjustedLower...adjustedUpper
  }
  
  private func estimateDuration(
    blocks: [WorkoutBlockBlueprint],
    level: TrainingLevel,
    structure: TrainingStructure
  ) -> Int {
    // Base por estrutura
    let baseDuration: Int
    switch structure {
    case .bodyweight: baseDuration = 30
    case .homeDumbbells: baseDuration = 35
    case .basicGym: baseDuration = 45
    case .fullGym: baseDuration = 55
    }
    
    // Ajuste por nível
    let levelAdjustment: Int
    switch level {
    case .beginner: levelAdjustment = -5
    case .intermediate: levelAdjustment = 0
    case .advanced: levelAdjustment = 5
    }
    
    // Adicionar tempo de atividades guiadas
    let guidedMinutes = blocks
      .compactMap(\.guidedActivityMinutes)
      .reduce(0, +)
    
    return max(20, baseDuration + levelAdjustment + guidedMinutes)
  }
}

// MARK: - Blueprint Diversity Checker

/// Verifica diversidade entre blueprints para evitar treinos repetitivos
struct BlueprintDiversityChecker: Sendable {
  
  /// Threshold mínimo de diferença para considerar blueprints "diversos"
  /// 0.0 = idênticos, 1.0 = completamente diferentes
  static let minimumDiversityScore: Double = 0.3
  
  /// Verifica se dois blueprints são suficientemente diferentes
  static func areDiverse(_ a: WorkoutBlueprint, _ b: WorkoutBlueprint) -> Bool {
    diversityScore(a, b) >= minimumDiversityScore
  }
  
  /// Calcula score de diversidade entre dois blueprints (0.0 - 1.0)
  static func diversityScore(_ a: WorkoutBlueprint, _ b: WorkoutBlueprint) -> Double {
    var differences: Double = 0
    var totalFactors: Double = 0
    
    // 1. Foco diferente (peso 2)
    totalFactors += 2
    if a.focus != b.focus {
      differences += 2
    }
    
    // 2. Objetivo diferente (peso 2)
    totalFactors += 2
    if a.goal != b.goal {
      differences += 2
    }
    
    // 3. Número de exercícios diferente (peso 1)
    totalFactors += 1
    let exerciseDiff = abs(a.totalExerciseCount - b.totalExerciseCount)
    if exerciseDiff > 0 {
      differences += min(1.0, Double(exerciseDiff) / 3.0)
    }
    
    // 4. Intensidade diferente (peso 1)
    totalFactors += 1
    if a.intensity != b.intensity {
      differences += 1
    }
    
    // 5. Duração diferente (peso 1)
    totalFactors += 1
    let durationDiff = abs(a.estimatedDurationMinutes - b.estimatedDurationMinutes)
    if durationDiff >= 10 {
      differences += 1
    } else if durationDiff >= 5 {
      differences += 0.5
    }
    
    // 6. Recovery mode diferente (peso 1)
    totalFactors += 1
    if a.isRecoveryMode != b.isRecoveryMode {
      differences += 1
    }
    
    // 7. Blocos com músculos diferentes (peso 2)
    totalFactors += 2
    let aMuscles = Set(a.blocks.flatMap(\.targetMuscles))
    let bMuscles = Set(b.blocks.flatMap(\.targetMuscles))
    let muscleOverlap = Double(aMuscles.intersection(bMuscles).count) / Double(max(1, aMuscles.union(bMuscles).count))
    differences += (1.0 - muscleOverlap) * 2
    
    return differences / totalFactors
  }
  
  /// Sugere ajustes para aumentar diversidade
  static func suggestVariation(
    for blueprint: WorkoutBlueprint,
    avoiding previous: [WorkoutBlueprint]
  ) -> BlueprintVariationSuggestion {
    // Analisar padrões nos blueprints anteriores
    let recentFocuses = previous.prefix(3).map(\.focus)
    _ = previous.prefix(3).map(\.goal) // Disponível para futuras análises
    
    var suggestions: [String] = []
    
    // Se o foco atual está repetido
    if recentFocuses.filter({ $0 == blueprint.focus }).count >= 2 {
      suggestions.append("Considerar foco diferente (atual: \(blueprint.focus.rawValue))")
    }
    
    // Se intensidade está sempre igual
    let recentIntensities = previous.prefix(3).map(\.intensity)
    if Set(recentIntensities).count == 1 {
      suggestions.append("Variar intensidade")
    }
    
    return BlueprintVariationSuggestion(
      shouldVary: !suggestions.isEmpty,
      suggestions: suggestions
    )
  }
}

/// Sugestão de variação para blueprint
struct BlueprintVariationSuggestion: Sendable {
  let shouldVary: Bool
  let suggestions: [String]
}

// MARK: - Seeded Random Generator

/// Gerador de números pseudo-aleatórios determinístico
/// Mesma seed → mesma sequência de números
struct SeededRandomGenerator: RandomNumberGenerator, Sendable {
  private var state: UInt64
  
  init(seed: UInt64) {
    self.state = seed
  }
  
  mutating func next() -> UInt64 {
    // Implementação simples de LCG (Linear Congruential Generator)
    // Constantes do MINSTD
    state = state &* 48271 &+ 1
    return state
  }
  
  /// Retorna um Double entre 0 e 1
  mutating func nextDouble() -> Double {
    Double(next() % 1_000_000) / 1_000_000.0
  }
  
  /// Retorna um Int no range especificado
  mutating func nextInt(in range: ClosedRange<Int>) -> Int {
    let span = UInt64(range.upperBound - range.lowerBound + 1)
    return range.lowerBound + Int(next() % span)
  }
  
  /// Seleciona N elementos de um array de forma determinística
  mutating func selectElements<T>(from array: [T], count: Int) -> [T] {
    guard count > 0, !array.isEmpty else { return [] }
    guard count < array.count else { return array }
    
    var result: [T] = []
    var available = array
    
    for _ in 0..<min(count, array.count) {
      let index = nextInt(in: 0...(available.count - 1))
      result.append(available.remove(at: index))
    }
    
    return result
  }
}
