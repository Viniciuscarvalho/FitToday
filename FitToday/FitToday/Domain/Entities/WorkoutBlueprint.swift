//
//  WorkoutBlueprint.swift
//  FitToday
//
//  Created by AI on 09/01/26.
//

import Foundation

// MARK: - Blueprint Version

/// Versão do blueprint para compatibilidade de cache e evolução
/// Incrementar quando a lógica de geração mudar significativamente
enum BlueprintVersion: String, Codable, Hashable, Sendable {
  case v1 = "1.0.0"
  
  static let current: BlueprintVersion = .v1
}

// MARK: - Blueprint Constraints

/// Constraints de equipamento e estrutura para um bloco do treino
struct BlueprintEquipmentConstraints: Codable, Hashable, Sendable {
  /// Equipamentos permitidos (baseado em TrainingStructure do perfil)
  let allowedEquipment: [EquipmentType]
  
  /// Equipamentos proibidos (ex.: lesões, indisponibilidade)
  let forbiddenEquipment: [EquipmentType]
  
  /// Se deve priorizar exercícios compostos
  let preferCompoundMovements: Bool
  
  init(
    allowedEquipment: [EquipmentType],
    forbiddenEquipment: [EquipmentType] = [],
    preferCompoundMovements: Bool = true
  ) {
    self.allowedEquipment = allowedEquipment
    self.forbiddenEquipment = forbiddenEquipment
    self.preferCompoundMovements = preferCompoundMovements
  }
  
  /// Factory baseado em TrainingStructure
  static func from(structure: TrainingStructure) -> BlueprintEquipmentConstraints {
    switch structure {
    case .bodyweight:
      return BlueprintEquipmentConstraints(
        allowedEquipment: [.bodyweight],
        preferCompoundMovements: true
      )
    case .homeDumbbells:
      return BlueprintEquipmentConstraints(
        allowedEquipment: [.dumbbell, .bodyweight, .kettlebell, .resistanceBand],
        preferCompoundMovements: true
      )
    case .basicGym:
      return BlueprintEquipmentConstraints(
        allowedEquipment: [.machine, .dumbbell, .cable, .bodyweight, .pullupBar],
        preferCompoundMovements: true
      )
    case .fullGym:
      return BlueprintEquipmentConstraints(
        allowedEquipment: EquipmentType.allCases,
        preferCompoundMovements: true
      )
    }
  }
}

// MARK: - Block Blueprint

/// Blueprint de um bloco/fase do treino
struct WorkoutBlockBlueprint: Codable, Hashable, Sendable, Identifiable {
  let id: UUID
  
  /// Tipo de fase (warmup, strength, accessory, aerobic, etc.)
  let phaseKind: WorkoutPlanPhase.Kind
  
  /// Título sugerido para a fase
  let title: String
  
  /// Número de exercícios a selecionar para esta fase
  let exerciseCount: Int
  
  /// Faixa de séries por exercício
  let setsRange: ClosedRange<Int>
  
  /// Faixa de repetições por exercício
  let repsRange: ClosedRange<Int>
  
  /// Descanso entre séries (segundos)
  let restSeconds: Int
  
  /// RPE alvo (1-10)
  let rpeTarget: Int
  
  /// Grupos musculares prioritários para esta fase
  let targetMuscles: [MuscleGroup]
  
  /// Grupos musculares a evitar (ex.: DOMS)
  let avoidMuscles: [MuscleGroup]
  
  /// Se deve incluir atividade guiada (ex.: mobilidade, aeróbio zona 2)
  let includesGuidedActivity: Bool
  
  /// Tipo de atividade guiada (se aplicável)
  let guidedActivityKind: ActivityPrescription.Kind?
  
  /// Duração da atividade guiada em minutos (se aplicável)
  let guidedActivityMinutes: Int?
  
  init(
    id: UUID = .init(),
    phaseKind: WorkoutPlanPhase.Kind,
    title: String,
    exerciseCount: Int,
    setsRange: ClosedRange<Int>,
    repsRange: ClosedRange<Int>,
    restSeconds: Int,
    rpeTarget: Int,
    targetMuscles: [MuscleGroup],
    avoidMuscles: [MuscleGroup] = [],
    includesGuidedActivity: Bool = false,
    guidedActivityKind: ActivityPrescription.Kind? = nil,
    guidedActivityMinutes: Int? = nil
  ) {
    self.id = id
    self.phaseKind = phaseKind
    self.title = title
    self.exerciseCount = exerciseCount
    self.setsRange = setsRange
    self.repsRange = repsRange
    self.restSeconds = restSeconds
    self.rpeTarget = rpeTarget
    self.targetMuscles = targetMuscles
    self.avoidMuscles = avoidMuscles
    self.includesGuidedActivity = includesGuidedActivity
    self.guidedActivityKind = guidedActivityKind
    self.guidedActivityMinutes = guidedActivityMinutes
  }
}

// MARK: - Workout Blueprint

/// Blueprint completo de um treino - contrato para geração de exercícios
/// Determinístico: mesma entrada (inputs + seed + version) → mesmo blueprint
struct WorkoutBlueprint: Codable, Hashable, Sendable, Identifiable {
  let id: UUID
  
  /// Versão do blueprint (para compatibilidade de cache)
  let version: BlueprintVersion
  
  /// Seed de variação - permite variação controlada
  let variationSeed: UInt64
  
  /// Título sugerido para o treino
  let title: String
  
  /// Foco do treino (upper, lower, fullBody, etc.)
  let focus: DailyFocus
  
  /// Objetivo do usuário que gerou este blueprint
  let goal: FitnessGoal
  
  /// Estrutura/local de treino
  let structure: TrainingStructure
  
  /// Nível do usuário
  let level: TrainingLevel
  
  /// Intensidade geral do treino
  let intensity: WorkoutIntensity
  
  /// Duração estimada em minutos
  let estimatedDurationMinutes: Int
  
  /// Blocos/fases do treino
  let blocks: [WorkoutBlockBlueprint]
  
  /// Constraints de equipamento
  let equipmentConstraints: BlueprintEquipmentConstraints
  
  /// Se está em modo recovery (DOMS alto)
  let isRecoveryMode: Bool
  
  /// Data de criação
  let createdAt: Date
  
  /// Hash estável dos inputs para cache
  var inputsHash: String {
    let components = [
      version.rawValue,
      String(variationSeed),
      focus.rawValue,
      goal.rawValue,
      structure.rawValue,
      level.rawValue,
      String(isRecoveryMode)
    ]
    return components.joined(separator: "|")
  }
  
  init(
    id: UUID = .init(),
    version: BlueprintVersion = .current,
    variationSeed: UInt64,
    title: String,
    focus: DailyFocus,
    goal: FitnessGoal,
    structure: TrainingStructure,
    level: TrainingLevel,
    intensity: WorkoutIntensity,
    estimatedDurationMinutes: Int,
    blocks: [WorkoutBlockBlueprint],
    equipmentConstraints: BlueprintEquipmentConstraints,
    isRecoveryMode: Bool = false,
    createdAt: Date = .init()
  ) {
    self.id = id
    self.version = version
    self.variationSeed = variationSeed
    self.title = title
    self.focus = focus
    self.goal = goal
    self.structure = structure
    self.level = level
    self.intensity = intensity
    self.estimatedDurationMinutes = estimatedDurationMinutes
    self.blocks = blocks
    self.equipmentConstraints = equipmentConstraints
    self.isRecoveryMode = isRecoveryMode
    self.createdAt = createdAt
  }
  
  /// Número total de exercícios no blueprint
  var totalExerciseCount: Int {
    blocks.reduce(0) { $0 + $1.exerciseCount }
  }
  
  /// Blocos de força (strength + accessory)
  var strengthBlocks: [WorkoutBlockBlueprint] {
    blocks.filter { $0.phaseKind == .strength || $0.phaseKind == .accessory }
  }
  
  /// Bloco de aquecimento (se existir)
  var warmupBlock: WorkoutBlockBlueprint? {
    blocks.first { $0.phaseKind == .warmup }
  }
  
  /// Bloco aeróbico (se existir)
  var aerobicBlock: WorkoutBlockBlueprint? {
    blocks.first { $0.phaseKind == .aerobic }
  }
}

// MARK: - Blueprint Input

/// Inputs para geração de blueprint (usado para hash de cache)
struct BlueprintInput: Codable, Hashable, Sendable {
  let goal: FitnessGoal
  let structure: TrainingStructure
  let level: TrainingLevel
  let focus: DailyFocus
  let sorenessLevel: MuscleSorenessLevel
  let sorenessAreas: [MuscleGroup]
  let dayOfWeek: Int // 1-7 (segunda-domingo)
  let weekOfYear: Int // 1-52
  let hourOfDay: Int // 0-23 (hora do dia para variação mais frequente)
  
  /// Gera hash estável para cache (usado para evitar chamadas duplicadas na mesma hora)
  var cacheKey: String {
    let components = [
      BlueprintVersion.current.rawValue,
      goal.rawValue,
      structure.rawValue,
      level.rawValue,
      focus.rawValue,
      sorenessLevel.rawValue,
      String(dayOfWeek),
      String(weekOfYear),
      String(hourOfDay)
    ]
    return components.joined(separator: ":")
  }
  
  /// Gera seed de variação baseada nos inputs + data + hora
  /// Determinística: mesmos inputs na mesma hora → mesma seed
  /// Mas: a cada hora, seed diferente para garantir variação
  var variationSeed: UInt64 {
    var hasher = Hasher()
    hasher.combine(cacheKey)
    let hash = hasher.finalize()
    
    #if DEBUG
    print("[BlueprintInput] cacheKey: \(cacheKey)")
    print("[BlueprintInput] variationSeed: \(UInt64(bitPattern: Int64(hash)))")
    #endif
    
    return UInt64(bitPattern: Int64(hash))
  }
  
  /// Factory a partir de profile + checkIn
  static func from(profile: UserProfile, checkIn: DailyCheckIn, date: Date = .init()) -> BlueprintInput {
    let calendar = Calendar.current
    let dayOfWeek = calendar.component(.weekday, from: date)
    let weekOfYear = calendar.component(.weekOfYear, from: date)
    let hourOfDay = calendar.component(.hour, from: date)
    
    #if DEBUG
    print("[BlueprintInput] Criando input: goal=\(profile.mainGoal.rawValue) focus=\(checkIn.focus.rawValue) day=\(dayOfWeek) week=\(weekOfYear) hour=\(hourOfDay)")
    #endif
    
    return BlueprintInput(
      goal: profile.mainGoal,
      structure: profile.availableStructure,
      level: profile.level,
      focus: checkIn.focus,
      sorenessLevel: checkIn.sorenessLevel,
      sorenessAreas: checkIn.sorenessAreas,
      dayOfWeek: dayOfWeek,
      weekOfYear: weekOfYear,
      hourOfDay: hourOfDay
    )
  }
}

// MARK: - Codable Extensions for ClosedRange

extension ClosedRange: @retroactive Hashable where Bound: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(lowerBound)
    hasher.combine(upperBound)
  }
}

extension ClosedRange: @retroactive Encodable where Bound: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(lowerBound)
    try container.encode(upperBound)
  }
}

extension ClosedRange: @retroactive Decodable where Bound: Decodable & Comparable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let lower = try container.decode(Bound.self)
    let upper = try container.decode(Bound.self)
    self = lower...upper
  }
}
