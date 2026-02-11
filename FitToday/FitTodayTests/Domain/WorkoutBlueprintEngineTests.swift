//
//  WorkoutBlueprintEngineTests.swift
//  FitTodayTests
//
//  Created by AI on 09/01/26.
//

import XCTest
@testable import FitToday

final class WorkoutBlueprintEngineTests: XCTestCase {
  
  private var engine: WorkoutBlueprintEngine!
  
  override func setUp() {
    super.setUp()
    engine = WorkoutBlueprintEngine()
  }
  
  override func tearDown() {
    engine = nil
    super.tearDown()
  }
  
  // MARK: - Variation Tests

  func testEachCallProducesDifferentBlueprint() {
    // Given: mesmos inputs
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)

    // When: gerar blueprint duas vezes
    let blueprint1 = engine.generateBlueprint(profile: profile, checkIn: checkIn)
    let blueprint2 = engine.generateBlueprint(profile: profile, checkIn: checkIn)

    // Then: seeds devem ser DIFERENTES (variação garantida)
    XCTAssertNotEqual(blueprint1.variationSeed, blueprint2.variationSeed, "Seeds should be different for variation")

    // Estrutura consistente (mesmo goal, focus, blocks.count)
    XCTAssertEqual(blueprint1.focus, blueprint2.focus)
    XCTAssertEqual(blueprint1.goal, blueprint2.goal)
    XCTAssertEqual(blueprint1.blocks.count, blueprint2.blocks.count)
  }
  
  func testLowEnergyDowngradesIntensity() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let normalEnergy = DailyCheckIn(focus: .upper, sorenessLevel: .none, sorenessAreas: [], energyLevel: 7)
    let lowEnergy = DailyCheckIn(focus: .upper, sorenessLevel: .none, sorenessAreas: [], energyLevel: 2)
    
    // When
    let blueprintNormal = engine.generateBlueprint(profile: profile, checkIn: normalEnergy)
    let blueprintLow = engine.generateBlueprint(profile: profile, checkIn: lowEnergy)
    
    // Then
    // Energia baixa nunca deve aumentar intensidade; esperamos que seja <=
    let order: [WorkoutIntensity] = [.low, .moderate, .high]
    let normalIndex = order.firstIndex(of: blueprintNormal.intensity) ?? 0
    let lowIndex = order.firstIndex(of: blueprintLow.intensity) ?? 0
    XCTAssertLessThanOrEqual(lowIndex, normalIndex)
  }
  
  func testDifferentInputsProduceDifferentBlueprints() {
    // Given: inputs diferentes (goal diferente)
    let profile1 = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let profile2 = makeProfile(goal: .weightLoss, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    
    // When: gerar blueprints
    let blueprint1 = engine.generateBlueprint(profile: profile1, checkIn: checkIn)
    let blueprint2 = engine.generateBlueprint(profile: profile2, checkIn: checkIn)
    
    // Then: blueprints são diferentes
    XCTAssertNotEqual(blueprint1.goal, blueprint2.goal)
    // Força tem descanso maior que emagrecimento
    let strengthRest = blueprint1.blocks.first { $0.phaseKind == .strength }?.restSeconds ?? 0
    let weightLossRest = blueprint2.blocks.first { $0.phaseKind == .strength }?.restSeconds ?? 0
    XCTAssertGreaterThan(strengthRest, weightLossRest, "Força deve ter descanso maior que emagrecimento")
  }
  
  // MARK: - Goal-Specific Tests
  
  func testHypertrophyBlueprintHasCorrectStructure() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    
    // When
    let blueprint = engine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    // Then
    XCTAssertEqual(blueprint.goal, .hypertrophy)
    XCTAssertNotNil(blueprint.warmupBlock, "Deve ter aquecimento")
    XCTAssertFalse(blueprint.strengthBlocks.isEmpty, "Deve ter blocos de força")
    
    // Hipertrofia deve ter RPE alto (7-8)
    let strengthBlock = blueprint.blocks.first { $0.phaseKind == .strength }
    XCTAssertNotNil(strengthBlock)
    XCTAssertGreaterThanOrEqual(strengthBlock?.rpeTarget ?? 0, 7)
  }
  
  func testWeightLossBlueprintHasMetabolicFocus() {
    // Given
    let profile = makeProfile(goal: .weightLoss, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .fullBody, soreness: .none)
    
    // When
    let blueprint = engine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    // Then
    XCTAssertEqual(blueprint.goal, .weightLoss)
    
    // Emagrecimento deve ter intervalos curtos
    let strengthBlock = blueprint.blocks.first { $0.phaseKind == .strength }
    XCTAssertNotNil(strengthBlock)
    XCTAssertLessThanOrEqual(strengthBlock?.restSeconds ?? 999, 45, "Emagrecimento deve ter descanso curto")
    
    // Deve ter mais reps
    XCTAssertGreaterThanOrEqual(strengthBlock?.repsRange.lowerBound ?? 0, 12, "Emagrecimento deve ter reps altas")
    
    // Deve ter bloco aeróbico
    XCTAssertNotNil(blueprint.aerobicBlock, "Emagrecimento deve ter aeróbico")
  }
  
  func testEnduranceBlueprintHasHighVolume() {
    // Given
    let profile = makeProfile(goal: .endurance, structure: .basicGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .cardio, soreness: .none)
    
    // When
    let blueprint = engine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    // Then
    XCTAssertEqual(blueprint.goal, .endurance)
    
    // Resistência deve ter reps altas (15+)
    let strengthBlock = blueprint.blocks.first { $0.phaseKind == .strength }
    XCTAssertGreaterThanOrEqual(strengthBlock?.repsRange.lowerBound ?? 0, 15)
    
    // Deve ter aeróbico zona 2
    let aerobicBlock = blueprint.aerobicBlock
    XCTAssertEqual(aerobicBlock?.guidedActivityKind, .aerobicZone2)
  }
  
  // MARK: - Structure/Equipment Tests
  
  func testBodyweightStructureHasOnlyBodyweightEquipment() {
    // Given
    let profile = makeProfile(goal: .conditioning, structure: .bodyweight, level: .beginner)
    let checkIn = makeCheckIn(focus: .fullBody, soreness: .none)
    
    // When
    let blueprint = engine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    // Then
    XCTAssertEqual(blueprint.structure, .bodyweight)
    XCTAssertEqual(blueprint.equipmentConstraints.allowedEquipment, [.bodyweight])
    XCTAssertTrue(blueprint.equipmentConstraints.forbiddenEquipment.isEmpty)
  }
  
  func testFullGymHasAllEquipment() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .advanced)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    
    // When
    let blueprint = engine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    // Then
    XCTAssertEqual(blueprint.structure, .fullGym)
    XCTAssertTrue(blueprint.equipmentConstraints.allowedEquipment.contains(.barbell))
    XCTAssertTrue(blueprint.equipmentConstraints.allowedEquipment.contains(.machine))
    XCTAssertTrue(blueprint.equipmentConstraints.allowedEquipment.contains(.dumbbell))
  }
  
  // MARK: - DOMS/Recovery Tests
  
  func testHighDOMSReducesVolumeAndIntensity() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkInNoDoms = makeCheckIn(focus: .upper, soreness: .none)
    let checkInHighDoms = makeCheckIn(focus: .upper, soreness: .strong)
    
    // When
    let normalBlueprint = engine.generateBlueprint(profile: profile, checkIn: checkInNoDoms)
    let recoveryBlueprint = engine.generateBlueprint(profile: profile, checkIn: checkInHighDoms)
    
    // Then
    XCTAssertFalse(normalBlueprint.isRecoveryMode)
    XCTAssertTrue(recoveryBlueprint.isRecoveryMode)
    
    // Recovery deve ter intensidade menor
    XCTAssertEqual(recoveryBlueprint.intensity, .low)
    
    // Recovery deve ter menos exercícios no aquecimento ou mais descanso
    let normalWarmup = normalBlueprint.warmupBlock
    let recoveryWarmup = recoveryBlueprint.warmupBlock
    XCTAssertGreaterThanOrEqual(
      recoveryWarmup?.restSeconds ?? 0,
      normalWarmup?.restSeconds ?? 0,
      "Recovery deve ter mais descanso"
    )
  }
  
  // MARK: - Level Tests
  
  func testBeginnerHasLowerVolume() {
    // Given
    let beginnerProfile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .beginner)
    let advancedProfile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .advanced)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    
    // When
    let beginnerBlueprint = engine.generateBlueprint(profile: beginnerProfile, checkIn: checkIn)
    let advancedBlueprint = engine.generateBlueprint(profile: advancedProfile, checkIn: checkIn)
    
    // Then: beginner deve ter menos séries
    let beginnerSets = beginnerBlueprint.blocks.first { $0.phaseKind == .strength }?.setsRange.upperBound ?? 0
    let advancedSets = advancedBlueprint.blocks.first { $0.phaseKind == .strength }?.setsRange.upperBound ?? 0
    
    XCTAssertLessThanOrEqual(beginnerSets, advancedSets)
  }
  
  // MARK: - Diversity Tests
  
  func testDiversityCheckerIdentifiesSimilarBlueprints() {
    // Given: mesmos inputs mas seeds diferentes
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)

    let blueprint1 = engine.generateBlueprint(profile: profile, checkIn: checkIn)
    let blueprint2 = engine.generateBlueprint(profile: profile, checkIn: checkIn)

    // When
    let diversityScore = BlueprintDiversityChecker.diversityScore(blueprint1, blueprint2)

    // Then: blueprints com mesmos parâmetros mas seeds diferentes
    // ainda devem ter score relativamente baixo pois goal/focus/structure são iguais
    XCTAssertLessThan(diversityScore, 0.5, "Blueprints similares devem ter diversidade < 0.5")
  }
  
  func testDiversityCheckerIdentifiesDifferentBlueprints() {
    // Given
    let profile1 = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .advanced)
    let profile2 = makeProfile(goal: .weightLoss, structure: .bodyweight, level: .beginner)
    let checkIn1 = makeCheckIn(focus: .upper, soreness: .none)
    let checkIn2 = makeCheckIn(focus: .cardio, soreness: .strong)
    
    let blueprint1 = engine.generateBlueprint(profile: profile1, checkIn: checkIn1)
    let blueprint2 = engine.generateBlueprint(profile: profile2, checkIn: checkIn2)
    
    // When
    let diversityScore = BlueprintDiversityChecker.diversityScore(blueprint1, blueprint2)
    let areDiverse = BlueprintDiversityChecker.areDiverse(blueprint1, blueprint2)
    
    // Then: blueprints muito diferentes devem ter score alto
    XCTAssertGreaterThan(diversityScore, BlueprintDiversityChecker.minimumDiversityScore)
    XCTAssertTrue(areDiverse)
  }
  
  // MARK: - Seeded Random Generator Tests
  
  func testSeededRandomGeneratorIsDeterministic() {
    // Given
    let seed: UInt64 = 12345
    var gen1 = SeededRandomGenerator(seed: seed)
    var gen2 = SeededRandomGenerator(seed: seed)
    
    // When: gerar sequência de números
    let sequence1 = (0..<10).map { _ in gen1.next() }
    let sequence2 = (0..<10).map { _ in gen2.next() }
    
    // Then: mesma seed = mesma sequência
    XCTAssertEqual(sequence1, sequence2)
  }
  
  func testDifferentSeedsProduceDifferentSequences() {
    // Given
    var gen1 = SeededRandomGenerator(seed: 111)
    var gen2 = SeededRandomGenerator(seed: 222)
    
    // When
    let sequence1 = (0..<5).map { _ in gen1.next() }
    let sequence2 = (0..<5).map { _ in gen2.next() }
    
    // Then
    XCTAssertNotEqual(sequence1, sequence2)
  }
  
  func testSelectElementsIsDeterministic() {
    // Given
    let elements = ["A", "B", "C", "D", "E", "F", "G"]
    var gen1 = SeededRandomGenerator(seed: 999)
    var gen2 = SeededRandomGenerator(seed: 999)
    
    // When
    let selection1 = gen1.selectElements(from: elements, count: 3)
    let selection2 = gen2.selectElements(from: elements, count: 3)
    
    // Then
    XCTAssertEqual(selection1, selection2)
    XCTAssertEqual(selection1.count, 3)
  }
  
  // MARK: - Version Tests
  
  func testBlueprintHasCurrentVersion() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    
    // When
    let blueprint = engine.generateBlueprint(profile: profile, checkIn: checkIn)
    
    // Then
    XCTAssertEqual(blueprint.version, .current)
    XCTAssertEqual(blueprint.version, .v1)
  }
  
  func testInputsWithSameSeedHaveSameCacheKey() {
    // Given: mesma seed = mesma cacheKey
    let seed: UInt64 = 12345

    let input1 = BlueprintInput(
      goal: .hypertrophy,
      structure: .fullGym,
      level: .intermediate,
      focus: .upper,
      sorenessLevel: .none,
      sorenessAreas: [],
      energyLevel: 7,
      variationSeed: seed
    )

    let input2 = BlueprintInput(
      goal: .hypertrophy,
      structure: .fullGym,
      level: .intermediate,
      focus: .upper,
      sorenessLevel: .none,
      sorenessAreas: [],
      energyLevel: 7,
      variationSeed: seed
    )

    // Then
    XCTAssertEqual(input1.cacheKey, input2.cacheKey)
    XCTAssertEqual(input1.variationSeed, input2.variationSeed)
  }

  func testFactoryMethodGeneratesRandomSeeds() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)

    // When: criar dois inputs via factory
    let input1 = BlueprintInput.from(profile: profile, checkIn: checkIn)
    let input2 = BlueprintInput.from(profile: profile, checkIn: checkIn)

    // Then: seeds devem ser diferentes (random)
    XCTAssertNotEqual(input1.variationSeed, input2.variationSeed, "Factory should generate random seeds")
    XCTAssertNotEqual(input1.cacheKey, input2.cacheKey, "Different seeds = different cache keys")
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
}
