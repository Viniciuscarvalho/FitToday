//
//  WorkoutCompositionFlowTests.swift
//  FitTodayTests
//
//  Created by AI on 09/01/26.
//
//  Smoke tests do fluxo completo de composição de treino:
//  Blueprint → Prompt → (Mock OpenAI) → Validate → Cache
//
//  Estes testes validam a integração entre componentes sem rede.
//

import XCTest
import SwiftData
@testable import FitToday

@MainActor
final class WorkoutCompositionFlowTests: XCTestCase {
  
  private var blueprintEngine: WorkoutBlueprintEngine!
  private var promptAssembler: WorkoutPromptAssembler!
  private var qualityGate: WorkoutPlanQualityGate!
  private var cacheRepository: SwiftDataWorkoutCompositionCacheRepository!
  private var modelContainer: ModelContainer!
  
  override func setUp() {
    super.setUp()
    blueprintEngine = WorkoutBlueprintEngine()
    promptAssembler = WorkoutPromptAssembler()
    qualityGate = WorkoutPlanQualityGate()
    
    // Cache em memória
    let schema = Schema([SDCachedWorkout.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    modelContainer = try! ModelContainer(for: schema, configurations: [config])
    cacheRepository = SwiftDataWorkoutCompositionCacheRepository(modelContainer: modelContainer)
    SwiftDataWorkoutCompositionCacheRepository.isCacheDisabled = false
  }
  
  override func tearDown() {
    blueprintEngine = nil
    promptAssembler = nil
    qualityGate = nil
    cacheRepository = nil
    modelContainer = nil
    SwiftDataWorkoutCompositionCacheRepository.isCacheDisabled = false
    super.tearDown()
  }
  
  // MARK: - Complete Flow Smoke Tests
  
  /// Smoke test: Blueprint → Prompt → Cache (sem OpenAI mock complexo)
  func testCompleteFlowForHypertrophyFullGym() async throws {
    // 1. Blueprint
    let profile = WorkoutTestFixtures.Profiles.hypertrophyFullGym
    let checkIn = WorkoutTestFixtures.CheckIns.upperNoDoms
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    XCTAssertEqual(blueprint.goal, .hypertrophy)
    XCTAssertEqual(blueprint.structure, .fullGym)
    XCTAssertFalse(blueprint.isRecoveryMode)
    
    // 2. Prompt Assembly
    let prompt = promptAssembler.assemblePrompt(
      blueprint: blueprint,
      blocks: WorkoutTestFixtures.Blocks.all,
      profile: profile,
      checkIn: checkIn
    )
    
    XCTAssertFalse(prompt.systemMessage.isEmpty)
    XCTAssertFalse(prompt.userMessage.isEmpty)
    XCTAssertEqual(prompt.metadata.goal, .hypertrophy)
    
    // 3. Criar plano simples diretamente do blueprint (simula OpenAI)
    let plan = makeSimplePlan(from: blueprint)
    
    // 4. Cache
    let input = BlueprintInput.from(profile: profile, checkIn: checkIn)
    let entry = CachedWorkoutEntry(
      inputsHash: input.cacheKey,
      workoutPlan: plan,
      createdAt: Date(),
      expiresAt: Date().addingTimeInterval(24 * 60 * 60),
      goal: profile.mainGoal,
      structure: profile.availableStructure,
      focus: checkIn.focus,
      blueprintVersion: blueprint.version.rawValue,
      variationSeed: blueprint.variationSeed
    )
    
    try await cacheRepository.saveCachedWorkout(entry)
    
    // 5. Verify cache hit
    let cached = try await cacheRepository.getCachedWorkout(for: input.cacheKey)
    XCTAssertNotNil(cached)
    XCTAssertEqual(cached?.goal, .hypertrophy)
  }
  
  /// Smoke test: Blueprint → Prompt → Cache para emagrecimento
  func testCompleteFlowForWeightLossBodyweight() async throws {
    // 1. Blueprint
    let profile = WorkoutTestFixtures.Profiles.weightLossBodyweight
    let checkIn = WorkoutTestFixtures.CheckIns.neutral
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    XCTAssertEqual(blueprint.goal, .weightLoss)
    XCTAssertEqual(blueprint.structure, .bodyweight)
    XCTAssertEqual(blueprint.equipmentConstraints.allowedEquipment, [.bodyweight])
    
    // 2. Prompt Assembly
    let prompt = promptAssembler.assemblePrompt(
      blueprint: blueprint,
      blocks: WorkoutTestFixtures.Blocks.all,
      profile: profile,
      checkIn: checkIn
    )
    
    XCTAssertTrue(prompt.systemMessage.contains("emagrecimento") || prompt.systemMessage.contains("Emagrecimento"))
    
    // 3. Criar plano simples diretamente do blueprint (simula OpenAI)
    let plan = makeSimplePlan(from: blueprint)
    
    // 4. Cache
    let input = BlueprintInput.from(profile: profile, checkIn: checkIn)
    let entry = CachedWorkoutEntry(
      inputsHash: input.cacheKey,
      workoutPlan: plan,
      createdAt: Date(),
      expiresAt: Date().addingTimeInterval(24 * 60 * 60),
      goal: profile.mainGoal,
      structure: profile.availableStructure,
      focus: checkIn.focus,
      blueprintVersion: blueprint.version.rawValue,
      variationSeed: blueprint.variationSeed
    )
    
    try await cacheRepository.saveCachedWorkout(entry)
    
    // 5. Verify cache hit
    let cached = try await cacheRepository.getCachedWorkout(for: input.cacheKey)
    XCTAssertNotNil(cached)
    XCTAssertEqual(cached?.goal, .weightLoss)
  }
  
  func testCompleteFlowForRecoveryMode() async throws {
    // 1. Blueprint com DOMS alto
    let profile = WorkoutTestFixtures.Profiles.hypertrophyFullGym
    let checkIn = WorkoutTestFixtures.CheckIns.highDoms
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    XCTAssertTrue(blueprint.isRecoveryMode)
    XCTAssertEqual(blueprint.intensity, .low)
    
    // 2. Prompt Assembly
    let prompt = promptAssembler.assemblePrompt(
      blueprint: blueprint,
      blocks: WorkoutTestFixtures.Blocks.all,
      profile: profile,
      checkIn: checkIn
    )
    
    XCTAssertTrue(prompt.systemMessage.contains("recovery") || prompt.systemMessage.contains("recuperação"))
    
    // 3. Verify recovery blueprint characteristics
    XCTAssertGreaterThan(
      blueprint.blocks.first { $0.phaseKind == .strength }?.restSeconds ?? 0,
      60,
      "Recovery mode should have longer rest periods"
    )
  }
  
  // MARK: - Determinism Tests
  
  func testBlueprintDeterminismAcrossAllGoals() {
    // Para cada objetivo, verificar que mesmos inputs = mesmo blueprint
    for goal in FitnessGoal.allCases {
      let profile = WorkoutTestFixtures.Profiles.forGoal(goal)
      let checkIn = WorkoutTestFixtures.CheckIns.neutral
      
      let blueprint1 = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
      let blueprint2 = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
      
      XCTAssertEqual(blueprint1.variationSeed, blueprint2.variationSeed, "Seed should be deterministic for \(goal)")
      XCTAssertEqual(blueprint1.title, blueprint2.title, "Title should be deterministic for \(goal)")
      XCTAssertEqual(blueprint1.blocks.count, blueprint2.blocks.count, "Block count should be deterministic for \(goal)")
    }
  }
  
  func testPromptDeterminismAcrossAllGoals() {
    for goal in FitnessGoal.allCases {
      let profile = WorkoutTestFixtures.Profiles.forGoal(goal)
      let checkIn = WorkoutTestFixtures.CheckIns.neutral
      let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
      
      let prompt1 = promptAssembler.assemblePrompt(
        blueprint: blueprint,
        blocks: WorkoutTestFixtures.Blocks.all,
        profile: profile,
        checkIn: checkIn
      )
      
      let prompt2 = promptAssembler.assemblePrompt(
        blueprint: blueprint,
        blocks: WorkoutTestFixtures.Blocks.all,
        profile: profile,
        checkIn: checkIn
      )
      
      XCTAssertEqual(prompt1.cacheKey, prompt2.cacheKey, "Cache key should be deterministic for \(goal)")
    }
  }
  
  // MARK: - Diversity Tests
  
  func testDifferentGoalsProduceDifferentBlueprints() {
    let goals = FitnessGoal.allCases
    let checkIn = WorkoutTestFixtures.CheckIns.neutral
    
    var blueprints: [FitnessGoal: WorkoutBlueprint] = [:]
    for goal in goals {
      let profile = WorkoutTestFixtures.Profiles.forGoal(goal)
      blueprints[goal] = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    }
    
    // Verificar que objetivos diferentes geram blueprints diferentes
    for goal1 in goals {
      for goal2 in goals where goal1 != goal2 {
        let bp1 = blueprints[goal1]!
        let bp2 = blueprints[goal2]!
        
        let diversityScore = BlueprintDiversityChecker.diversityScore(bp1, bp2)
        XCTAssertGreaterThan(
          diversityScore,
          0.1,
          "Blueprints for \(goal1) and \(goal2) should be diverse"
        )
      }
    }
  }
  
  func testDifferentFocusesProduceDifferentBlueprints() {
    let profile = WorkoutTestFixtures.Profiles.hypertrophyFullGym
    let focuses = DailyFocus.allCases.filter { $0 != .surprise }
    
    var blueprints: [DailyFocus: WorkoutBlueprint] = [:]
    for focus in focuses {
      let checkIn = WorkoutTestFixtures.CheckIns.forFocus(focus)
      blueprints[focus] = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    }
    
    // Verificar que focos diferentes geram variação
    for focus1 in focuses {
      for focus2 in focuses where focus1 != focus2 {
        let bp1 = blueprints[focus1]!
        let bp2 = blueprints[focus2]!
        
        // Pelo menos o foco deve ser diferente
        XCTAssertNotEqual(bp1.focus, bp2.focus, "Focus should be different")
      }
    }
  }
  
  // MARK: - Cache Integration Tests
  
  func testCacheHitAvoidsDuplicateGeneration() async throws {
    let profile = WorkoutTestFixtures.Profiles.hypertrophyFullGym
    let checkIn = WorkoutTestFixtures.CheckIns.upperNoDoms
    let input = BlueprintInput.from(profile: profile, checkIn: checkIn)
    
    // Primeira geração
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let plan = makeSimplePlan(from: blueprint)
    
    let entry = CachedWorkoutEntry(
      inputsHash: input.cacheKey,
      workoutPlan: plan,
      createdAt: Date(),
      expiresAt: Date().addingTimeInterval(24 * 60 * 60),
      goal: profile.mainGoal,
      structure: profile.availableStructure,
      focus: checkIn.focus,
      blueprintVersion: blueprint.version.rawValue,
      variationSeed: blueprint.variationSeed
    )
    
    try await cacheRepository.saveCachedWorkout(entry)
    
    // Verificar cache hit
    let cached = try await cacheRepository.getCachedWorkout(for: input.cacheKey)
    XCTAssertNotNil(cached)
    XCTAssertEqual(cached?.workoutPlan.title, plan.title)
  }
  
  func testCacheVersionMismatchRequiresRegeneration() async throws {
    let profile = WorkoutTestFixtures.Profiles.hypertrophyFullGym
    let checkIn = WorkoutTestFixtures.CheckIns.upperNoDoms
    
    // Simular cache com versão antiga
    let input = BlueprintInput.from(profile: profile, checkIn: checkIn)
    let oldVersionKey = "v0:" + input.cacheKey.dropFirst(3) // Modificar versão
    
    let plan = makeSimplePlan(from: blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn))
    
    let oldEntry = CachedWorkoutEntry(
      inputsHash: oldVersionKey, // Hash com versão diferente
      workoutPlan: plan,
      createdAt: Date(),
      expiresAt: Date().addingTimeInterval(24 * 60 * 60),
      goal: profile.mainGoal,
      structure: profile.availableStructure,
      focus: checkIn.focus,
      blueprintVersion: "v0", // Versão antiga
      variationSeed: 12345
    )
    
    try await cacheRepository.saveCachedWorkout(oldEntry)
    
    // Buscar com chave atual (versão atual)
    let cached = try await cacheRepository.getCachedWorkout(for: input.cacheKey)
    
    // Não deve encontrar porque a versão é diferente
    XCTAssertNil(cached, "Should not find cache with different version")
  }
  
  // MARK: - Goal-Specific Validation Tests
  
  func testHypertrophyBlueprintMeetsExpectations() {
    let profile = WorkoutTestFixtures.Profiles.hypertrophyFullGym
    let checkIn = WorkoutTestFixtures.CheckIns.upperNoDoms
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let expected = WorkoutTestFixtures.ExpectedOutputs.hypertrophy
    
    XCTAssertEqual(blueprint.goal, expected.goal)
    
    let strengthBlock = blueprint.blocks.first { $0.phaseKind == .strength }
    XCTAssertNotNil(strengthBlock)
    
    XCTAssertGreaterThanOrEqual(strengthBlock?.rpeTarget ?? 0, expected.minRpe)
    XCTAssertLessThanOrEqual(strengthBlock?.rpeTarget ?? 99, expected.maxRpe)
    XCTAssertTrue(expected.restSecondsRange.contains(strengthBlock?.restSeconds ?? 0))
  }
  
  func testWeightLossBlueprintMeetsExpectations() {
    let profile = WorkoutTestFixtures.Profiles.weightLossBodyweight
    let checkIn = WorkoutTestFixtures.CheckIns.neutral
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let expected = WorkoutTestFixtures.ExpectedOutputs.weightLoss
    
    XCTAssertEqual(blueprint.goal, expected.goal)
    XCTAssertNotNil(blueprint.aerobicBlock, "Weight loss should have aerobic block")
    
    let strengthBlock = blueprint.blocks.first { $0.phaseKind == .strength }
    XCTAssertNotNil(strengthBlock)
    XCTAssertTrue(expected.restSecondsRange.contains(strengthBlock?.restSeconds ?? 999))
  }
  
  // MARK: - Helpers
  
  private func makeSimplePlan(from blueprint: WorkoutBlueprint) -> WorkoutPlan {
    let phases = blueprint.blocks.map { block in
      WorkoutPlanPhase(
        kind: block.phaseKind,
        title: block.title,
        rpeTarget: block.rpeTarget,
        items: []
      )
    }
    
    return WorkoutPlan(
      title: blueprint.title,
      focus: blueprint.focus,
      estimatedDurationMinutes: blueprint.estimatedDurationMinutes,
      intensity: blueprint.intensity,
      phases: phases
    )
  }
}
