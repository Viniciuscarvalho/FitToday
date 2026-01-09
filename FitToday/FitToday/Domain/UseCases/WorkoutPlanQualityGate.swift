//
//  WorkoutPlanQualityGate.swift
//  FitToday
//
//  Created by AI on 09/01/26.
//

import Foundation

// MARK: - Validation Result

/// Resultado da validação de um plano de treino
struct WorkoutPlanValidationResult: Sendable {
  let isValid: Bool
  let issues: [ValidationIssue]
  let normalizedPlan: WorkoutPlan?
  
  enum ValidationIssue: Sendable, Equatable, CustomStringConvertible {
    case missingPhase(WorkoutPlanPhase.Kind)
    case tooFewExercises(phase: String, expected: Int, got: Int)
    case tooManyExercises(phase: String, expected: Int, got: Int)
    case invalidSetsRange(exercise: String, sets: Int, expected: ClosedRange<Int>)
    case invalidRepsRange(exercise: String, reps: IntRange, expected: ClosedRange<Int>)
    case invalidRestTime(exercise: String, rest: TimeInterval, expected: ClosedRange<Int>)
    case incompatibleEquipment(exercise: String, equipment: EquipmentType, allowed: [EquipmentType])
    case missingAerobicForGoal(goal: FitnessGoal)
    case durationOutOfRange(minutes: Int, expected: ClosedRange<Int>)
    case intensityMismatch(got: WorkoutIntensity, expected: WorkoutIntensity)
    
    var description: String {
      switch self {
      case .missingPhase(let kind):
        return "Fase obrigatória ausente: \(kind.rawValue)"
      case .tooFewExercises(let phase, let expected, let got):
        return "Exercícios insuficientes em \(phase): esperado \(expected), recebido \(got)"
      case .tooManyExercises(let phase, let expected, let got):
        return "Exercícios em excesso em \(phase): esperado \(expected), recebido \(got)"
      case .invalidSetsRange(let exercise, let sets, let expected):
        return "Séries inválidas em \(exercise): \(sets), esperado \(expected)"
      case .invalidRepsRange(let exercise, let reps, let expected):
        return "Reps inválidas em \(exercise): \(reps.display), esperado \(expected)"
      case .invalidRestTime(let exercise, let rest, let expected):
        return "Descanso inválido em \(exercise): \(Int(rest))s, esperado \(expected)s"
      case .incompatibleEquipment(let exercise, let equipment, let allowed):
        return "Equipamento incompatível em \(exercise): \(equipment.rawValue), permitidos: \(allowed.map(\.rawValue).joined(separator: ", "))"
      case .missingAerobicForGoal(let goal):
        return "Aeróbico obrigatório para objetivo \(goal.rawValue) está ausente"
      case .durationOutOfRange(let minutes, let expected):
        return "Duração fora do range: \(minutes) min, esperado \(expected) min"
      case .intensityMismatch(let got, let expected):
        return "Intensidade incorreta: \(got.rawValue), esperado \(expected.rawValue)"
      }
    }
    
    var isCritical: Bool {
      switch self {
      case .missingPhase, .incompatibleEquipment, .missingAerobicForGoal:
        return true
      default:
        return false
      }
    }
  }
  
  var hasCriticalIssues: Bool {
    issues.contains { $0.isCritical }
  }
  
  var canBeNormalized: Bool {
    !hasCriticalIssues
  }
}

// MARK: - Blueprint Plan Validator

/// Validador de planos de treino contra blueprint
struct BlueprintPlanValidator: Sendable {
  
  /// Valida um plano contra o blueprint esperado
  func validate(
    plan: WorkoutPlan,
    blueprint: WorkoutBlueprint,
    profile: UserProfile
  ) -> WorkoutPlanValidationResult {
    var issues: [WorkoutPlanValidationResult.ValidationIssue] = []
    
    // 1. Validar fases obrigatórias
    issues.append(contentsOf: validateRequiredPhases(plan: plan, blueprint: blueprint))
    
    // 2. Validar contagem de exercícios por fase
    issues.append(contentsOf: validateExerciseCounts(plan: plan, blueprint: blueprint))
    
    // 3. Validar sets/reps/descanso
    issues.append(contentsOf: validatePrescriptions(plan: plan, blueprint: blueprint))
    
    // 4. Validar equipamentos
    issues.append(contentsOf: validateEquipment(plan: plan, blueprint: blueprint))
    
    // 5. Validar aeróbico para objetivos que exigem
    issues.append(contentsOf: validateAerobicRequirements(plan: plan, goal: profile.mainGoal))
    
    // 6. Validar duração
    issues.append(contentsOf: validateDuration(plan: plan, blueprint: blueprint))
    
    let isValid = issues.isEmpty
    
    #if DEBUG
    if !isValid {
      print("[Validator] Plano inválido com \(issues.count) issues:")
      for issue in issues {
        print("[Validator]   - \(issue)")
      }
    }
    #endif
    
    return WorkoutPlanValidationResult(
      isValid: isValid,
      issues: issues,
      normalizedPlan: nil
    )
  }
  
  // MARK: - Validation Rules
  
  private func validateRequiredPhases(
    plan: WorkoutPlan,
    blueprint: WorkoutBlueprint
  ) -> [WorkoutPlanValidationResult.ValidationIssue] {
    var issues: [WorkoutPlanValidationResult.ValidationIssue] = []
    
    let requiredKinds = Set(blueprint.blocks.map(\.phaseKind))
    let presentKinds = Set(plan.phases.map(\.kind))
    
    for required in requiredKinds {
      if !presentKinds.contains(required) {
        issues.append(.missingPhase(required))
      }
    }
    
    return issues
  }
  
  private func validateExerciseCounts(
    plan: WorkoutPlan,
    blueprint: WorkoutBlueprint
  ) -> [WorkoutPlanValidationResult.ValidationIssue] {
    var issues: [WorkoutPlanValidationResult.ValidationIssue] = []
    
    for block in blueprint.blocks {
      guard block.exerciseCount > 0 else { continue }
      
      let matchingPhase = plan.phases.first { $0.kind == block.phaseKind }
      let actualCount = matchingPhase?.exercises.count ?? 0
      
      // Tolerância de ±1 exercício
      let minExpected = max(1, block.exerciseCount - 1)
      let maxExpected = block.exerciseCount + 1
      
      if actualCount < minExpected {
        issues.append(.tooFewExercises(
          phase: block.title,
          expected: block.exerciseCount,
          got: actualCount
        ))
      } else if actualCount > maxExpected {
        issues.append(.tooManyExercises(
          phase: block.title,
          expected: block.exerciseCount,
          got: actualCount
        ))
      }
    }
    
    return issues
  }
  
  private func validatePrescriptions(
    plan: WorkoutPlan,
    blueprint: WorkoutBlueprint
  ) -> [WorkoutPlanValidationResult.ValidationIssue] {
    var issues: [WorkoutPlanValidationResult.ValidationIssue] = []
    
    for phase in plan.phases {
      guard let block = blueprint.blocks.first(where: { $0.phaseKind == phase.kind }) else {
        continue
      }
      
      for exercise in phase.exercises {
        // Validar sets (tolerância de ±1)
        let setsRange = (block.setsRange.lowerBound - 1)...(block.setsRange.upperBound + 1)
        if !setsRange.contains(exercise.sets) {
          issues.append(.invalidSetsRange(
            exercise: exercise.exercise.name,
            sets: exercise.sets,
            expected: block.setsRange
          ))
        }
        
        // Validar reps (tolerância de ±3)
        let repsMin = max(1, block.repsRange.lowerBound - 3)
        let repsMax = block.repsRange.upperBound + 3
        if exercise.reps.upperBound < repsMin || exercise.reps.lowerBound > repsMax {
          issues.append(.invalidRepsRange(
            exercise: exercise.exercise.name,
            reps: exercise.reps,
            expected: block.repsRange
          ))
        }
        
        // Validar descanso (tolerância de ±30s)
        let restMin = max(0, block.restSeconds - 30)
        let restMax = block.restSeconds + 60
        if Int(exercise.restInterval) < restMin || Int(exercise.restInterval) > restMax {
          issues.append(.invalidRestTime(
            exercise: exercise.exercise.name,
            rest: exercise.restInterval,
            expected: restMin...restMax
          ))
        }
      }
    }
    
    return issues
  }
  
  private func validateEquipment(
    plan: WorkoutPlan,
    blueprint: WorkoutBlueprint
  ) -> [WorkoutPlanValidationResult.ValidationIssue] {
    var issues: [WorkoutPlanValidationResult.ValidationIssue] = []
    let allowedEquipment = Set(blueprint.equipmentConstraints.allowedEquipment)
    
    for phase in plan.phases {
      for exercise in phase.exercises {
        if !allowedEquipment.contains(exercise.exercise.equipment) {
          issues.append(.incompatibleEquipment(
            exercise: exercise.exercise.name,
            equipment: exercise.exercise.equipment,
            allowed: blueprint.equipmentConstraints.allowedEquipment
          ))
        }
      }
    }
    
    return issues
  }
  
  private func validateAerobicRequirements(
    plan: WorkoutPlan,
    goal: FitnessGoal
  ) -> [WorkoutPlanValidationResult.ValidationIssue] {
    let goalsRequiringAerobic: Set<FitnessGoal> = [.weightLoss, .conditioning, .endurance]
    
    guard goalsRequiringAerobic.contains(goal) else {
      return []
    }
    
    let hasAerobic = plan.phases.contains { $0.kind == .aerobic }
    
    if !hasAerobic {
      return [.missingAerobicForGoal(goal: goal)]
    }
    
    return []
  }
  
  private func validateDuration(
    plan: WorkoutPlan,
    blueprint: WorkoutBlueprint
  ) -> [WorkoutPlanValidationResult.ValidationIssue] {
    let expectedMin = max(15, blueprint.estimatedDurationMinutes - 15)
    let expectedMax = blueprint.estimatedDurationMinutes + 20
    
    if plan.estimatedDurationMinutes < expectedMin || plan.estimatedDurationMinutes > expectedMax {
      return [.durationOutOfRange(
        minutes: plan.estimatedDurationMinutes,
        expected: expectedMin...expectedMax
      )]
    }
    
    return []
  }
}

// MARK: - Workout Plan Normalizer

/// Normalizador de planos de treino (ajustes não-destrutivos)
struct WorkoutPlanNormalizer: Sendable {
  
  /// Normaliza um plano aplicando ajustes baseados no blueprint
  func normalize(
    plan: WorkoutPlan,
    blueprint: WorkoutBlueprint
  ) -> WorkoutPlan {
    var normalizedPhases = plan.phases
    
    // 1. Normalizar prescrições (clamp sets/reps/descanso)
    normalizedPhases = normalizedPhases.map { phase in
      normalizePhase(phase, blueprint: blueprint)
    }
    
    // 2. Garantir ordem correta das fases
    normalizedPhases = reorderPhases(normalizedPhases)
    
    // 3. Calcular duração corrigida
    let correctedDuration = calculateDuration(phases: normalizedPhases)
    
    #if DEBUG
    print("[Normalizer] Plano normalizado: \(plan.estimatedDurationMinutes)min → \(correctedDuration)min")
    #endif
    
    return WorkoutPlan(
      id: plan.id,
      title: plan.title,
      focus: plan.focus,
      estimatedDurationMinutes: correctedDuration,
      intensity: plan.intensity,
      phases: normalizedPhases,
      createdAt: plan.createdAt
    )
  }
  
  private func normalizePhase(
    _ phase: WorkoutPlanPhase,
    blueprint: WorkoutBlueprint
  ) -> WorkoutPlanPhase {
    guard let block = blueprint.blocks.first(where: { $0.phaseKind == phase.kind }) else {
      return phase
    }
    
    let normalizedItems = phase.items.map { item -> WorkoutPlanItem in
      switch item {
      case .exercise(let prescription):
        let normalizedPrescription = normalizePrescription(prescription, block: block)
        return .exercise(normalizedPrescription)
      case .activity:
        return item
      }
    }
    
    return WorkoutPlanPhase(
      id: phase.id,
      kind: phase.kind,
      title: phase.title,
      rpeTarget: block.rpeTarget,
      items: normalizedItems
    )
  }
  
  private func normalizePrescription(
    _ prescription: ExercisePrescription,
    block: WorkoutBlockBlueprint
  ) -> ExercisePrescription {
    // Clamp sets
    let normalizedSets = min(max(prescription.sets, block.setsRange.lowerBound), block.setsRange.upperBound)
    
    // Clamp reps
    let normalizedRepsLower = min(max(prescription.reps.lowerBound, block.repsRange.lowerBound), block.repsRange.upperBound)
    let normalizedRepsUpper = min(max(prescription.reps.upperBound, block.repsRange.lowerBound), block.repsRange.upperBound)
    let normalizedReps = IntRange(normalizedRepsLower, normalizedRepsUpper)
    
    // Clamp rest (±30s do blueprint)
    let minRest = TimeInterval(max(10, block.restSeconds - 30))
    let maxRest = TimeInterval(block.restSeconds + 60)
    let normalizedRest = min(max(prescription.restInterval, minRest), maxRest)
    
    return ExercisePrescription(
      exercise: prescription.exercise,
      sets: normalizedSets,
      reps: normalizedReps,
      restInterval: normalizedRest,
      tip: prescription.tip
    )
  }
  
  private func reorderPhases(_ phases: [WorkoutPlanPhase]) -> [WorkoutPlanPhase] {
    let order: [WorkoutPlanPhase.Kind] = [.warmup, .strength, .accessory, .conditioning, .aerobic, .finisher, .cooldown]
    
    return phases.sorted { a, b in
      let indexA = order.firstIndex(of: a.kind) ?? 999
      let indexB = order.firstIndex(of: b.kind) ?? 999
      return indexA < indexB
    }
  }
  
  private func calculateDuration(phases: [WorkoutPlanPhase]) -> Int {
    var totalSeconds = 0
    
    for phase in phases {
      for item in phase.items {
        switch item {
        case .exercise(let prescription):
          let workTime = Double(prescription.reps.average) * 3.0 * Double(prescription.sets)
          let restTime = Double(prescription.restInterval) * Double(max(0, prescription.sets - 1))
          totalSeconds += Int(workTime + restTime)
          
        case .activity(let activity):
          totalSeconds += activity.durationMinutes * 60
        }
      }
    }
    
    // Adicionar transições
    totalSeconds += phases.count * 60
    
    return max(15, Int(ceil(Double(totalSeconds) / 60.0)))
  }
}

// MARK: - Workout Diversity Gate

/// Gate de diversidade para evitar treinos repetitivos
struct WorkoutDiversityGate: Sendable {
  
  /// Threshold mínimo de diversidade (0.0 - 1.0)
  static let minimumDiversityScore: Double = 0.25
  
  /// Resultado da análise de diversidade
  struct DiversityResult: Sendable {
    let score: Double
    let passesGate: Bool
    let overlapDetails: OverlapDetails
    
    struct OverlapDetails: Sendable {
      let exerciseOverlap: Double
      let orderSimilarity: Double
      let phaseStructureSimilarity: Double
    }
  }
  
  /// Analisa diversidade entre um novo plano e planos anteriores
  func analyze(
    newPlan: WorkoutPlan,
    previousPlans: [WorkoutPlan],
    maxComparisons: Int = 3
  ) -> DiversityResult {
    guard !previousPlans.isEmpty else {
      // Sem histórico, diversidade máxima
      return DiversityResult(
        score: 1.0,
        passesGate: true,
        overlapDetails: .init(exerciseOverlap: 0, orderSimilarity: 0, phaseStructureSimilarity: 0)
      )
    }
    
    // Comparar com os últimos N planos
    let recentPlans = Array(previousPlans.suffix(maxComparisons))
    
    var totalOverlap: Double = 0
    var totalOrderSimilarity: Double = 0
    var totalPhaseSimilarity: Double = 0
    
    for previous in recentPlans {
      let (overlap, order, phase) = comparePlans(newPlan, previous)
      totalOverlap += overlap
      totalOrderSimilarity += order
      totalPhaseSimilarity += phase
    }
    
    let count = Double(recentPlans.count)
    let avgOverlap = totalOverlap / count
    let avgOrder = totalOrderSimilarity / count
    let avgPhase = totalPhaseSimilarity / count
    
    // Diversidade = 1 - similaridade
    // Pesos: exercício overlap (50%), ordem (30%), estrutura (20%)
    let similarity = avgOverlap * 0.5 + avgOrder * 0.3 + avgPhase * 0.2
    let diversityScore = 1.0 - similarity
    
    #if DEBUG
    print("[DiversityGate] Score: \(String(format: "%.2f", diversityScore)) (overlap=\(String(format: "%.2f", avgOverlap)), order=\(String(format: "%.2f", avgOrder)), phase=\(String(format: "%.2f", avgPhase)))")
    #endif
    
    return DiversityResult(
      score: diversityScore,
      passesGate: diversityScore >= Self.minimumDiversityScore,
      overlapDetails: .init(
        exerciseOverlap: avgOverlap,
        orderSimilarity: avgOrder,
        phaseStructureSimilarity: avgPhase
      )
    )
  }
  
  private func comparePlans(_ a: WorkoutPlan, _ b: WorkoutPlan) -> (overlap: Double, order: Double, phase: Double) {
    // 1. Exercise overlap (Jaccard similarity)
    let exercisesA = Set(a.exercises.map { $0.exercise.id })
    let exercisesB = Set(b.exercises.map { $0.exercise.id })
    
    let intersection = exercisesA.intersection(exercisesB).count
    let union = exercisesA.union(exercisesB).count
    let exerciseOverlap = union > 0 ? Double(intersection) / Double(union) : 0
    
    // 2. Order similarity (Kendall tau-like)
    let orderA = a.exercises.map { $0.exercise.id }
    let orderB = b.exercises.map { $0.exercise.id }
    let orderSimilarity = calculateOrderSimilarity(orderA, orderB)
    
    // 3. Phase structure similarity
    let phasesA = a.phases.map { $0.kind }
    let phasesB = b.phases.map { $0.kind }
    let phaseSimilarity = phasesA == phasesB ? 1.0 : (Double(Set(phasesA).intersection(Set(phasesB)).count) / Double(max(phasesA.count, phasesB.count)))
    
    return (exerciseOverlap, orderSimilarity, phaseSimilarity)
  }
  
  private func calculateOrderSimilarity(_ a: [String], _ b: [String]) -> Double {
    guard !a.isEmpty && !b.isEmpty else { return 0 }
    
    let commonElements = Set(a).intersection(Set(b))
    guard !commonElements.isEmpty else { return 0 }
    
    // Verificar quantos elementos comuns estão na mesma posição relativa
    var samePositionCount = 0
    for element in commonElements {
      if let posA = a.firstIndex(of: element),
         let posB = b.firstIndex(of: element) {
        // Posição relativa similar (±1)
        let relPosA = Double(posA) / Double(a.count)
        let relPosB = Double(posB) / Double(b.count)
        if abs(relPosA - relPosB) < 0.2 {
          samePositionCount += 1
        }
      }
    }
    
    return Double(samePositionCount) / Double(commonElements.count)
  }
}

// MARK: - Quality Gate Coordinator

/// Coordenador do quality gate completo
struct WorkoutPlanQualityGate: Sendable {
  
  private let validator = BlueprintPlanValidator()
  private let normalizer = WorkoutPlanNormalizer()
  private let diversityGate = WorkoutDiversityGate()
  
  /// Resultado do quality gate
  struct QualityResult: Sendable {
    let originalPlan: WorkoutPlan
    let finalPlan: WorkoutPlan?
    let status: Status
    let validationResult: WorkoutPlanValidationResult
    let diversityResult: WorkoutDiversityGate.DiversityResult?
    
    enum Status: Sendable {
      case passed
      case normalizedAndPassed
      case failedValidation
      case failedDiversity
    }
    
    var succeeded: Bool {
      status == .passed || status == .normalizedAndPassed
    }
  }
  
  /// Processa um plano pelo quality gate
  func process(
    plan: WorkoutPlan,
    blueprint: WorkoutBlueprint,
    profile: UserProfile,
    previousPlans: [WorkoutPlan] = []
  ) -> QualityResult {
    // 1. Validar
    let validationResult = validator.validate(plan: plan, blueprint: blueprint, profile: profile)
    
    // 2. Se inválido com issues críticas, falhar
    if !validationResult.isValid && validationResult.hasCriticalIssues {
      #if DEBUG
      print("[QualityGate] FAILED: Issues críticas de validação")
      #endif
      
      return QualityResult(
        originalPlan: plan,
        finalPlan: nil,
        status: .failedValidation,
        validationResult: validationResult,
        diversityResult: nil
      )
    }
    
    // 3. Normalizar se necessário
    let normalizedPlan: WorkoutPlan
    let wasNormalized: Bool
    
    if !validationResult.isValid && validationResult.canBeNormalized {
      normalizedPlan = normalizer.normalize(plan: plan, blueprint: blueprint)
      wasNormalized = true
      
      #if DEBUG
      print("[QualityGate] Plano normalizado com \(validationResult.issues.count) correções")
      #endif
    } else {
      normalizedPlan = plan
      wasNormalized = false
    }
    
    // 4. Verificar diversidade
    let diversityResult = diversityGate.analyze(
      newPlan: normalizedPlan,
      previousPlans: previousPlans
    )
    
    if !diversityResult.passesGate {
      #if DEBUG
      print("[QualityGate] FAILED: Diversidade insuficiente (\(String(format: "%.2f", diversityResult.score)) < \(WorkoutDiversityGate.minimumDiversityScore))")
      #endif
      
      return QualityResult(
        originalPlan: plan,
        finalPlan: nil,
        status: .failedDiversity,
        validationResult: validationResult,
        diversityResult: diversityResult
      )
    }
    
    // 5. Sucesso
    #if DEBUG
    print("[QualityGate] PASSED: diversidade=\(String(format: "%.2f", diversityResult.score)), normalized=\(wasNormalized)")
    #endif
    
    return QualityResult(
      originalPlan: plan,
      finalPlan: normalizedPlan,
      status: wasNormalized ? .normalizedAndPassed : .passed,
      validationResult: validationResult,
      diversityResult: diversityResult
    )
  }
  
  /// Gera feedback para retry baseado no resultado
  func generateRetryFeedback(from result: QualityResult) -> String? {
    guard !result.succeeded else { return nil }
    
    var feedback: [String] = []
    
    switch result.status {
    case .failedValidation:
      feedback.append("O treino anterior teve problemas de estrutura:")
      for issue in result.validationResult.issues.prefix(3) {
        feedback.append("- \(issue)")
      }
      feedback.append("Por favor, corrija e gere novamente respeitando o blueprint.")
      
    case .failedDiversity:
      if let diversity = result.diversityResult {
        feedback.append("O treino gerado é muito similar aos anteriores (similaridade: \(Int((1 - diversity.score) * 100))%).")
        feedback.append("Por favor, varie mais os exercícios e a ordem de execução.")
        feedback.append("Use a seed de variação para garantir diferenciação.")
      }
      
    case .passed, .normalizedAndPassed:
      return nil
    }
    
    return feedback.joined(separator: "\n")
  }
}
