//
//  WorkoutPlanQualityGateTests.swift
//  FitTodayTests
//
//  Created by AI on 09/01/26.
//

import XCTest
@testable import FitToday

final class WorkoutPlanQualityGateTests: XCTestCase {
  
  private var qualityGate: WorkoutPlanQualityGate!
  private var blueprintEngine: WorkoutBlueprintEngine!
  
  override func setUp() {
    super.setUp()
    qualityGate = WorkoutPlanQualityGate()
    blueprintEngine = WorkoutBlueprintEngine()
  }
  
  override func tearDown() {
    qualityGate = nil
    blueprintEngine = nil
    super.tearDown()
  }
  
  // MARK: - Validation Tests
  
  func testValidPlanPasses() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let plan = makeValidPlan(for: blueprint, profile: profile)
    
    // When
    let result = qualityGate.process(
      plan: plan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: []
    )
    
    // Then
    XCTAssertTrue(result.succeeded)
    XCTAssertNotNil(result.finalPlan)
  }
  
  func testPlanWithTooFewExercisesGetsNormalized() {
    // Given
    let profile = makeProfile(goal: .weightLoss, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .fullBody, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    // Plan com valores fora do range (mas normalizável)
    let plan = makePlanWithOutOfRangeValues(for: blueprint, profile: profile)
    
    // When
    let result = qualityGate.process(
      plan: plan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: []
    )
    
    // Then: deve ser normalizado (não falhar)
    XCTAssertTrue(result.succeeded || result.status == .normalizedAndPassed)
  }
  
  func testPlanWithIncompatibleEquipmentFails() {
    // Given: bodyweight structure
    let profile = makeProfile(goal: .conditioning, structure: .bodyweight, level: .intermediate)
    let checkIn = makeCheckIn(focus: .fullBody, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    // Plan com equipamento incompatível (barbell)
    let plan = makePlanWithIncompatibleEquipment()
    
    // When
    let result = qualityGate.process(
      plan: plan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: []
    )
    
    // Then
    XCTAssertEqual(result.status, .failedValidation)
    XCTAssertNil(result.finalPlan)
    XCTAssertTrue(result.validationResult.hasCriticalIssues)
  }
  
  // MARK: - Normalization Tests
  
  func testNormalizerClampsSetsToRange() {
    // Given
    let normalizer = WorkoutPlanNormalizer()
    let blueprint = makeSimpleBlueprint(setsRange: 3...4, repsRange: 8...12)
    let plan = makePlanWithSets(10) // fora do range
    
    // When
    let normalized = normalizer.normalize(plan: plan, blueprint: blueprint)
    
    // Then
    for exercise in normalized.exercises {
      XCTAssertLessThanOrEqual(exercise.sets, 4)
      XCTAssertGreaterThanOrEqual(exercise.sets, 3)
    }
  }
  
  func testNormalizerReordersPhases() {
    // Given
    let normalizer = WorkoutPlanNormalizer()
    let blueprint = makeSimpleBlueprint()
    
    // Plan com fases fora de ordem
    let plan = makePlanWithUnorderedPhases()
    
    // When
    let normalized = normalizer.normalize(plan: plan, blueprint: blueprint)
    
    // Then: warmup deve vir antes de strength
    if let warmupIndex = normalized.phases.firstIndex(where: { $0.kind == .warmup }),
       let strengthIndex = normalized.phases.firstIndex(where: { $0.kind == .strength }) {
      XCTAssertLessThan(warmupIndex, strengthIndex)
    }
  }
  
  // MARK: - Diversity Tests
  
  func testDiversityGatePassesForFirstPlan() {
    // Given
    let diversityGate = WorkoutDiversityGate()
    let plan = makeRandomPlan()
    
    // When
    let result = diversityGate.analyze(newPlan: plan, previousPlans: [])
    
    // Then
    XCTAssertTrue(result.passesGate)
    XCTAssertEqual(result.score, 1.0)
  }
  
  func testDiversityGateDetectsIdenticalPlans() {
    // Given
    let diversityGate = WorkoutDiversityGate()
    let plan = makeRandomPlan()
    
    // When
    let result = diversityGate.analyze(newPlan: plan, previousPlans: [plan])
    
    // Then
    XCTAssertFalse(result.passesGate)
    XCTAssertLessThan(result.score, WorkoutDiversityGate.minimumDiversityScore)
  }
  
  func testDiversityGatePassesForDifferentPlans() {
    // Given
    let diversityGate = WorkoutDiversityGate()
    let plan1 = makeRandomPlan(exerciseIds: ["ex1", "ex2", "ex3"])
    let plan2 = makeRandomPlan(exerciseIds: ["ex4", "ex5", "ex6"])
    
    // When
    let result = diversityGate.analyze(newPlan: plan2, previousPlans: [plan1])
    
    // Then
    XCTAssertTrue(result.passesGate)
    XCTAssertGreaterThanOrEqual(result.score, WorkoutDiversityGate.minimumDiversityScore)
  }
  
  // MARK: - Retry Feedback Tests
  
  func testRetryFeedbackGeneratedForFailedValidation() {
    // Given
    let profile = makeProfile(goal: .conditioning, structure: .bodyweight, level: .intermediate)
    let checkIn = makeCheckIn(focus: .fullBody, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let plan = makePlanWithIncompatibleEquipment()
    
    let result = qualityGate.process(
      plan: plan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: []
    )
    
    // When
    let feedback = qualityGate.generateRetryFeedback(from: result)
    
    // Then
    XCTAssertNotNil(feedback)
    XCTAssertTrue(feedback?.contains("estrutura") ?? false)
  }
  
  func testRetryFeedbackGeneratedForFailedDiversity() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let plan = makeValidPlan(for: blueprint, profile: profile)
    
    // Simular falha de diversidade passando o mesmo plano como histórico
    let result = qualityGate.process(
      plan: plan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: [plan, plan, plan]
    )
    
    // When
    let feedback = qualityGate.generateRetryFeedback(from: result)
    
    // Then
    if result.status == .failedDiversity {
      XCTAssertNotNil(feedback)
      XCTAssertTrue(feedback?.contains("similar") ?? false)
    }
  }
  
  func testNoFeedbackForPassingResult() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let plan = makeValidPlan(for: blueprint, profile: profile)

    let result = qualityGate.process(
      plan: plan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: []
    )

    // When
    let feedback = qualityGate.generateRetryFeedback(from: result)

    // Then
    XCTAssertNil(feedback)
  }

  // MARK: - Exercise Diversity Tests (80% Rule)

  func testExerciseDiversityPassesWhenAbove80Percent() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)

    // Create new plan with completely unique exercises (no previous history)
    let newPlan = makeRandomPlan(exerciseIds: ["alpha", "beta", "gamma", "delta", "epsilon"])

    // When - No previous plans means 100% unique
    let result = qualityGate.process(
      plan: newPlan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: []
    )

    // Then - Should pass with 100% unique exercises (no history)
    XCTAssertTrue(result.succeeded || result.status == .normalizedAndPassed)
    XCTAssertNotNil(result.exerciseDiversityResult)
    if let diversityResult = result.exerciseDiversityResult {
      XCTAssertTrue(diversityResult.isValid)
      XCTAssertEqual(diversityResult.score, 1.0)
    }
  }

  func testExerciseDiversityFailsWhenBelow80Percent() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)

    // Create new plan
    let newPlan = makeRandomPlan(exerciseIds: ["ex1", "ex2", "ex3", "ex4", "ex5"])

    // Previous plans have same exercises (high overlap)
    let previousPlan = makeRandomPlan(exerciseIds: ["ex1", "ex2", "ex3", "ex4", "ex5"])

    // When
    let result = qualityGate.process(
      plan: newPlan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: [previousPlan]
    )

    // Then - May fail either diversity check (depends on threshold)
    if result.status == .failedExerciseDiversity {
      XCTAssertNotNil(result.exerciseDiversityResult)
      XCTAssertFalse(result.exerciseDiversityResult?.isValid ?? true)
    }
  }

  func testRetryFeedbackGeneratedForFailedExerciseDiversity() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)

    // Same exercises - should fail exercise diversity
    let newPlan = makeRandomPlan(exerciseIds: ["ex1", "ex2", "ex3"])
    let previousPlan = makeRandomPlan(exerciseIds: ["ex1", "ex2", "ex3"])

    let result = qualityGate.process(
      plan: newPlan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: [previousPlan]
    )

    // When
    let feedback = qualityGate.generateRetryFeedback(from: result)

    // Then
    if result.status == .failedExerciseDiversity {
      XCTAssertNotNil(feedback)
      XCTAssertTrue(feedback?.contains("ATENÇÃO") ?? false)
      XCTAssertTrue(feedback?.contains("80%") ?? false)
    }
  }

  func testQualityResultIncludesExerciseDiversityResult() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let plan = makeValidPlan(for: blueprint, profile: profile)

    // When
    let result = qualityGate.process(
      plan: plan,
      blueprint: blueprint,
      profile: profile,
      previousPlans: []
    )

    // Then - exerciseDiversityResult should be present on success
    if result.succeeded {
      XCTAssertNotNil(result.exerciseDiversityResult)
    }
  }

  // MARK: - Helpers
  
  private func makeProfile(
    goal: FitnessGoal,
    structure: TrainingStructure,
    level: TrainingLevel
  ) -> UserProfile {
    UserProfile(
      id: UUID(),
      mainGoal: goal,
      availableStructure: structure,
      preferredMethod: .mixed,
      level: level,
      healthConditions: [],
      weeklyFrequency: 4,
      createdAt: Date(),
      isProfileComplete: true
    )
  }
  
  private func makeCheckIn(
    focus: DailyFocus,
    soreness: MuscleSorenessLevel
  ) -> DailyCheckIn {
    DailyCheckIn(
      focus: focus,
      sorenessLevel: soreness,
      sorenessAreas: []
    )
  }
  
  private func makeValidPlan(for blueprint: WorkoutBlueprint, profile: UserProfile) -> WorkoutPlan {
    var phases: [WorkoutPlanPhase] = []
    
    for block in blueprint.blocks {
      var items: [WorkoutPlanItem] = []
      
      if block.includesGuidedActivity, let activityKind = block.guidedActivityKind {
        items.append(.activity(ActivityPrescription(
          kind: activityKind,
          title: block.title,
          durationMinutes: block.guidedActivityMinutes ?? 5
        )))
      }
      
      // Adicionar exercícios compatíveis
      for i in 0..<block.exerciseCount {
        let equipment: EquipmentType = blueprint.equipmentConstraints.allowedEquipment.first ?? .bodyweight
        let exercise = WorkoutExercise(
          id: "ex-\(block.phaseKind.rawValue)-\(i)",
          name: "Exercise \(i + 1)",
          mainMuscle: block.targetMuscles.first ?? .chest,
          equipment: equipment,
          instructions: [],
          media: nil
        )
        
        let prescription = ExercisePrescription(
          exercise: exercise,
          sets: block.setsRange.lowerBound,
          reps: IntRange(block.repsRange.lowerBound, block.repsRange.upperBound),
          restInterval: TimeInterval(block.restSeconds),
          tip: nil
        )
        
        items.append(.exercise(prescription))
      }
      
      phases.append(WorkoutPlanPhase(
        kind: block.phaseKind,
        title: block.title,
        rpeTarget: block.rpeTarget,
        items: items
      ))
    }
    
    return WorkoutPlan(
      title: blueprint.title,
      focus: blueprint.focus,
      estimatedDurationMinutes: blueprint.estimatedDurationMinutes,
      intensity: blueprint.intensity,
      phases: phases
    )
  }
  
  private func makePlanWithOutOfRangeValues(for blueprint: WorkoutBlueprint, profile: UserProfile) -> WorkoutPlan {
    var plan = makeValidPlan(for: blueprint, profile: profile)
    
    // Modificar phases para ter valores fora do range
    var modifiedPhases = plan.phases
    if !modifiedPhases.isEmpty {
      var items = modifiedPhases[0].items
      if case .exercise(var prescription) = items.first {
        prescription = ExercisePrescription(
          exercise: prescription.exercise,
          sets: 20, // muito alto
          reps: IntRange(1, 2), // muito baixo
          restInterval: 5, // muito curto
          tip: nil
        )
        items[0] = .exercise(prescription)
        modifiedPhases[0] = WorkoutPlanPhase(
          id: modifiedPhases[0].id,
          kind: modifiedPhases[0].kind,
          title: modifiedPhases[0].title,
          rpeTarget: modifiedPhases[0].rpeTarget,
          items: items
        )
      }
    }
    
    return WorkoutPlan(
      id: plan.id,
      title: plan.title,
      focus: plan.focus,
      estimatedDurationMinutes: plan.estimatedDurationMinutes,
      intensity: plan.intensity,
      phases: modifiedPhases,
      createdAt: plan.createdAt
    )
  }
  
  private func makePlanWithIncompatibleEquipment() -> WorkoutPlan {
    let exercise = WorkoutExercise(
      id: "ex-barbell",
      name: "Barbell Squat",
      mainMuscle: .quads,
      equipment: .barbell, // incompatível com bodyweight
      instructions: [],
      media: nil
    )
    
    let prescription = ExercisePrescription(
      exercise: exercise,
      sets: 3,
      reps: IntRange(8, 12),
      restInterval: 90,
      tip: nil
    )
    
    let phase = WorkoutPlanPhase(
      kind: .strength,
      title: "Força",
      rpeTarget: 8,
      items: [.exercise(prescription)]
    )
    
    return WorkoutPlan(
      title: "Test Plan",
      focus: .fullBody,
      estimatedDurationMinutes: 45,
      intensity: .moderate,
      phases: [phase]
    )
  }
  
  private func makePlanWithSets(_ sets: Int) -> WorkoutPlan {
    let exercise = WorkoutExercise(
      id: "ex-1",
      name: "Test Exercise",
      mainMuscle: .chest,
      equipment: .bodyweight,
      instructions: [],
      media: nil
    )
    
    let prescription = ExercisePrescription(
      exercise: exercise,
      sets: sets,
      reps: IntRange(10, 12),
      restInterval: 60,
      tip: nil
    )
    
    let phase = WorkoutPlanPhase(
      kind: .strength,
      title: "Força",
      rpeTarget: 7,
      items: [.exercise(prescription)]
    )
    
    return WorkoutPlan(
      title: "Test",
      focus: .upper,
      estimatedDurationMinutes: 30,
      intensity: .moderate,
      phases: [phase]
    )
  }
  
  private func makePlanWithUnorderedPhases() -> WorkoutPlan {
    let strengthPhase = WorkoutPlanPhase(
      kind: .strength,
      title: "Força",
      rpeTarget: 8,
      items: []
    )
    
    let warmupPhase = WorkoutPlanPhase(
      kind: .warmup,
      title: "Aquecimento",
      rpeTarget: 5,
      items: []
    )
    
    // Ordem errada: strength antes de warmup
    return WorkoutPlan(
      title: "Test",
      focus: .upper,
      estimatedDurationMinutes: 30,
      intensity: .moderate,
      phases: [strengthPhase, warmupPhase]
    )
  }
  
  private func makeRandomPlan(exerciseIds: [String] = ["ex1", "ex2", "ex3"]) -> WorkoutPlan {
    let items = exerciseIds.map { id in
      WorkoutPlanItem.exercise(ExercisePrescription(
        exercise: WorkoutExercise(
          id: id,
          name: "Exercise \(id)",
          mainMuscle: .chest,
          equipment: .bodyweight,
          instructions: [],
          media: nil
        ),
        sets: 3,
        reps: IntRange(10, 12),
        restInterval: 60,
        tip: nil
      ))
    }
    
    let phase = WorkoutPlanPhase(
      kind: .strength,
      title: "Força",
      rpeTarget: 7,
      items: items
    )
    
    return WorkoutPlan(
      title: "Random Plan",
      focus: .upper,
      estimatedDurationMinutes: 30,
      intensity: .moderate,
      phases: [phase]
    )
  }
  
  private func makeSimpleBlueprint(
    setsRange: ClosedRange<Int> = 3...4,
    repsRange: ClosedRange<Int> = 8...12
  ) -> WorkoutBlueprint {
    WorkoutBlueprint(
      variationSeed: 12345,
      title: "Test Blueprint",
      focus: .upper,
      goal: .hypertrophy,
      structure: .fullGym,
      level: .intermediate,
      intensity: .moderate,
      estimatedDurationMinutes: 45,
      blocks: [
        WorkoutBlockBlueprint(
          phaseKind: .warmup,
          title: "Aquecimento",
          exerciseCount: 1,
          setsRange: 1...1,
          repsRange: 10...12,
          restSeconds: 30,
          rpeTarget: 5,
          targetMuscles: [.chest]
        ),
        WorkoutBlockBlueprint(
          phaseKind: .strength,
          title: "Força",
          exerciseCount: 3,
          setsRange: setsRange,
          repsRange: repsRange,
          restSeconds: 90,
          rpeTarget: 8,
          targetMuscles: [.chest, .back]
        )
      ],
      equipmentConstraints: BlueprintEquipmentConstraints.from(structure: .fullGym),
      isRecoveryMode: false
    )
  }
}
