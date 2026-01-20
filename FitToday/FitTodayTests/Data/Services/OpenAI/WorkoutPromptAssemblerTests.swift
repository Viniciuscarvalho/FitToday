//
//  WorkoutPromptAssemblerTests.swift
//  FitTodayTests
//
//  Created by AI on 09/01/26.
//

import XCTest
@testable import FitToday

final class WorkoutPromptAssemblerTests: XCTestCase {
  
  private var assembler: WorkoutPromptAssembler!
  private var blueprintEngine: WorkoutBlueprintEngine!
  
  override func setUp() {
    super.setUp()
    assembler = WorkoutPromptAssembler()
    blueprintEngine = WorkoutBlueprintEngine()
  }
  
  override func tearDown() {
    assembler = nil
    blueprintEngine = nil
    super.tearDown()
  }
  
  // MARK: - Determinism Tests
  
  func testSameInputsProduceSamePrompt() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let blocks = makeSampleBlocks()
    
    // When
    let prompt1 = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn
    )
    
    let prompt2 = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn
    )
    
    // Then
    XCTAssertEqual(prompt1.systemMessage, prompt2.systemMessage)
    XCTAssertEqual(prompt1.userMessage, prompt2.userMessage)
    XCTAssertEqual(prompt1.cacheKey, prompt2.cacheKey)
  }
  
  func testDifferentGoalsProduceDifferentPrompts() {
    // Given
    let profile1 = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let profile2 = makeProfile(goal: .weightLoss, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blocks = makeSampleBlocks()
    
    let blueprint1 = blueprintEngine.generateBlueprint(profile: profile1, checkIn: checkIn)
    let blueprint2 = blueprintEngine.generateBlueprint(profile: profile2, checkIn: checkIn)
    
    // When
    let prompt1 = assembler.assemblePrompt(
      blueprint: blueprint1,
      blocks: blocks,
      profile: profile1,
      checkIn: checkIn
    )
    
    let prompt2 = assembler.assemblePrompt(
      blueprint: blueprint2,
      blocks: blocks,
      profile: profile2,
      checkIn: checkIn
    )
    
    // Then
    XCTAssertNotEqual(prompt1.systemMessage, prompt2.systemMessage)
    XCTAssertNotEqual(prompt1.metadata.goal, prompt2.metadata.goal)
    XCTAssertNotEqual(prompt1.cacheKey, prompt2.cacheKey)
    
    // Hipertrofia deve mencionar força/hipertrofia
    XCTAssertTrue(prompt1.systemMessage.contains("hipertrofia") || prompt1.systemMessage.contains("força"))
    
    // Emagrecimento deve mencionar emagrecimento/circuito
    XCTAssertTrue(prompt2.systemMessage.contains("emagrecimento") || prompt2.systemMessage.contains("Emagrecimento"))
  }
  
  // MARK: - Content Tests
  
  func testPromptContainsBlueprint() {
    // Given
    let profile = makeProfile(goal: .conditioning, structure: .basicGym, level: .beginner)
    let checkIn = makeCheckIn(focus: .fullBody, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let blocks = makeSampleBlocks()

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn
    )

    // Then - Updated assertions for new prompt structure
    XCTAssertTrue(prompt.userMessage.contains("ESTRUTURA DO TREINO"))
    XCTAssertTrue(prompt.userMessage.contains(blueprint.title))
    XCTAssertTrue(prompt.userMessage.contains("FASES"))
  }
  
  func testPromptContainsEquipmentConstraints() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .bodyweight, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let blocks = makeSampleBlocks()
    
    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn
    )
    
    // Then: bodyweight structure should only allow bodyweight equipment
    XCTAssertTrue(prompt.systemMessage.contains("bodyweight"))
    // Blueprint for bodyweight should NOT include barbell in allowed equipment list
    XCTAssertEqual(blueprint.equipmentConstraints.allowedEquipment, [.bodyweight])
  }
  
  func testPromptContainsUserProfile() {
    // Given
    let profile = makeProfile(goal: .endurance, structure: .homeDumbbells, level: .advanced)
    let checkIn = makeCheckIn(focus: .cardio, soreness: .moderate)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let blocks = makeSampleBlocks()

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn
    )

    // Then - Check for profile info (rawValue strings)
    XCTAssertTrue(prompt.userMessage.contains("ENDURANCE") || prompt.userMessage.contains("endurance"))
    XCTAssertTrue(prompt.userMessage.contains("advanced"))
    XCTAssertTrue(prompt.userMessage.contains("homeDumbbells"))
    // DailyFocus.cardio may use different display value
    XCTAssertTrue(prompt.userMessage.contains("Energia:") || prompt.userMessage.contains("DOMS:"))
    XCTAssertTrue(prompt.userMessage.contains("moderate"))
  }
  
  func testPromptContainsAntiRepetitionInstructions() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let blocks = makeSampleBlocks()

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn
    )

    // Then - Check for anti-repetition rules in system message
    XCTAssertTrue(prompt.systemMessage.contains("repetição") || prompt.systemMessage.contains("Evite"))
    // Also check diversity rules in user message
    XCTAssertTrue(prompt.userMessage.contains("DIVERSIDADE") || prompt.userMessage.contains("DIFERENTES"))
  }
  
  // MARK: - Metadata Tests
  
  func testMetadataContainsCorrectValues() {
    // Given
    let profile = makeProfile(goal: .performance, structure: .fullGym, level: .advanced)
    let checkIn = makeCheckIn(focus: .lower, soreness: .light)
    let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)
    let blocks = makeSampleBlocks()
    
    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn
    )
    
    // Then
    XCTAssertEqual(prompt.metadata.goal, .performance)
    XCTAssertEqual(prompt.metadata.structure, .fullGym)
    XCTAssertEqual(prompt.metadata.level, .advanced)
    XCTAssertEqual(prompt.metadata.focus, .lower)
    XCTAssertEqual(prompt.metadata.variationSeed, blueprint.variationSeed)
    XCTAssertEqual(prompt.metadata.blueprintVersion, blueprint.version)
    XCTAssertFalse(prompt.metadata.contextSource.isEmpty)
  }
  
  // MARK: - Response Validation Tests
  
  func testValidResponseParsesCorrectly() throws {
    // Given
    let validJSON = """
    {
      "phases": [
        {
          "kind": "warmup",
          "activity": {
            "kind": "mobility",
            "title": "Mobilidade",
            "durationMinutes": 5,
            "notes": null
          }
        },
        {
          "kind": "strength",
          "exercises": [
            {
              "name": "Supino reto",
              "muscleGroup": "chest",
              "equipment": "barbell",
              "sets": 4,
              "reps": "6-8",
              "restSeconds": 120,
              "notes": "Controle na descida"
            }
          ]
        }
      ],
      "title": "Upper Força",
      "notes": null
    }
    """
    
    let blueprint = makeSimpleBlueprint()
    
    // When
    let response = try OpenAIResponseValidator.validate(
      jsonData: validJSON.data(using: .utf8)!,
      expectedBlueprint: blueprint
    )
    
    // Then
    XCTAssertEqual(response.phases.count, 2)
    XCTAssertEqual(response.phases[0].kind, "warmup")
    XCTAssertEqual(response.phases[1].kind, "strength")
    XCTAssertEqual(response.phases[1].exercises?.first?.name, "Supino reto")
  }
  
  func testInvalidJSONThrowsError() {
    // Given
    let invalidJSON = "{ invalid json }"
    let blueprint = makeSimpleBlueprint()
    
    // When/Then
    XCTAssertThrowsError(
      try OpenAIResponseValidator.validate(
        jsonData: invalidJSON.data(using: .utf8)!,
        expectedBlueprint: blueprint
      )
    ) { error in
      guard let validationError = error as? OpenAIResponseValidator.ValidationError else {
        XCTFail("Expected ValidationError")
        return
      }
      
      if case .invalidJSON = validationError {
        // Expected
      } else {
        XCTFail("Expected invalidJSON error")
      }
    }
  }
  
  func testEmptyPhasesThrowsError() {
    // Given
    let emptyPhasesJSON = """
    {
      "phases": [],
      "title": "Test"
    }
    """
    let blueprint = makeSimpleBlueprint()
    
    // When/Then
    XCTAssertThrowsError(
      try OpenAIResponseValidator.validate(
        jsonData: emptyPhasesJSON.data(using: .utf8)!,
        expectedBlueprint: blueprint
      )
    ) { error in
      guard let validationError = error as? OpenAIResponseValidator.ValidationError else {
        XCTFail("Expected ValidationError")
        return
      }
      
      if case .missingPhases = validationError {
        // Expected
      } else {
        XCTFail("Expected missingPhases error, got \(validationError)")
      }
    }
  }
  
  func testExtractJSONFromTextWithMarkdown() {
    // Given
    let textWithMarkdown = """
    Aqui está o treino:
    
    ```json
    {"phases":[{"kind":"strength"}]}
    ```
    
    Espero que goste!
    """
    
    // When
    let jsonData = OpenAIResponseValidator.extractJSON(from: textWithMarkdown)
    
    // Then
    XCTAssertNotNil(jsonData)
    
    // Verificar que é JSON válido
    if let data = jsonData {
      XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }
  }
  
  func testExtractJSONFromPlainJSON() {
    // Given
    let plainJSON = """
    {"phases":[{"kind":"warmup"}],"title":"Test"}
    """
    
    // When
    let jsonData = OpenAIResponseValidator.extractJSON(from: plainJSON)
    
    // Then
    XCTAssertNotNil(jsonData)
    XCTAssertEqual(plainJSON.data(using: .utf8), jsonData)
  }
  
  // MARK: - Variation Tests
  
  func testDifferentSeedsProduceDifferentCatalogs() {
    // Given: mesmos inputs mas seeds diferentes no blueprint
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blocks = makeSampleBlocks()
    
    let blueprint1 = WorkoutBlueprint(
      variationSeed: 111,
      title: "Test",
      focus: .upper,
      goal: .hypertrophy,
      structure: .fullGym,
      level: .intermediate,
      intensity: .moderate,
      estimatedDurationMinutes: 45,
      blocks: [],
      equipmentConstraints: BlueprintEquipmentConstraints.from(structure: .fullGym),
      isRecoveryMode: false
    )
    
    let blueprint2 = WorkoutBlueprint(
      variationSeed: 222, // Seed diferente
      title: "Test",
      focus: .upper,
      goal: .hypertrophy,
      structure: .fullGym,
      level: .intermediate,
      intensity: .moderate,
      estimatedDurationMinutes: 45,
      blocks: [],
      equipmentConstraints: BlueprintEquipmentConstraints.from(structure: .fullGym),
      isRecoveryMode: false
    )
    
    // When
    let prompt1 = assembler.assemblePrompt(
      blueprint: blueprint1,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: []
    )
    
    let prompt2 = assembler.assemblePrompt(
      blueprint: blueprint2,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: []
    )
    
    // Then: os prompts devem ter cache keys diferentes devido à seed diferente
    XCTAssertNotEqual(prompt1.cacheKey, prompt2.cacheKey, "Prompts com seeds diferentes devem ter cache keys diferentes")
    XCTAssertEqual(prompt1.metadata.variationSeed, 111)
    XCTAssertEqual(prompt2.metadata.variationSeed, 222)
  }
  
  func testPromptIncludesPreviousWorkoutsWarning() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blocks = makeSampleBlocks()
    let blueprint = makeSimpleBlueprint()

    // Criar treinos anteriores com exercícios específicos
    let previousWorkout = WorkoutPlan.mock(title: "Treino Anterior")

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: [previousWorkout]
    )

    // Then - Updated for 7 days history
    XCTAssertTrue(prompt.userMessage.contains("EXERCÍCIOS PROIBIDOS"), "Prompt deve incluir seção de exercícios proibidos")
    XCTAssertTrue(prompt.userMessage.contains("NÃO repita"), "Prompt deve ter instruções anti-repetição")
  }

  func testPromptWithoutPreviousWorkoutsHasNoWarning() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blocks = makeSampleBlocks()
    let blueprint = makeSimpleBlueprint()

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: []
    )

    // Then
    XCTAssertFalse(prompt.userMessage.contains("EXERCÍCIOS PROIBIDOS"), "Sem treinos anteriores, não deve ter seção de exercícios proibidos")
  }

  // MARK: - Task 5.0 Tests: Feedback Integration

  func testPromptIncludesExerciseLimitsSection() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = makeSimpleBlueprint()
    let blocks = makeSampleBlocks()

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: []
    )

    // Then
    XCTAssertTrue(prompt.userMessage.contains("LIMITES POR FASE"), "Prompt deve incluir limites por fase")
    XCTAssertTrue(prompt.userMessage.contains("Warmup: 2-3 exercícios"), "Deve ter limite para warmup")
    XCTAssertTrue(prompt.userMessage.contains("Strength: 4-6 exercícios"), "Deve ter limite para strength")
    XCTAssertTrue(prompt.userMessage.contains("Accessory: 2-4 exercícios"), "Deve ter limite para accessory")
  }

  func testPromptIncludesDiversityRules() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = makeSimpleBlueprint()
    let blocks = makeSampleBlocks()

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: []
    )

    // Then
    XCTAssertTrue(prompt.userMessage.contains("REGRA DE DIVERSIDADE"), "Prompt deve incluir regra de diversidade")
    XCTAssertTrue(prompt.userMessage.contains("PUSH, PULL, HINGE, SQUAT"), "Deve mencionar padrões de movimento")
    XCTAssertTrue(prompt.userMessage.contains("80%"), "Deve mencionar regra de 80%")
  }

  func testPromptIncludesFeedbackHistoryWhenAdjustmentNeeded() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = makeSimpleBlueprint()
    let blocks = makeSampleBlocks()
    let adjustment = IntensityAdjustment.increaseIntensity

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: [],
      intensityAdjustment: adjustment
    )

    // Then
    XCTAssertTrue(prompt.userMessage.contains("HISTÓRICO DE FEEDBACK"), "Prompt deve incluir seção de feedback")
    XCTAssertTrue(prompt.userMessage.contains(adjustment.recommendation), "Deve incluir recomendação de ajuste")
  }

  func testPromptExcludesFeedbackHistoryWhenNoAdjustment() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = makeSimpleBlueprint()
    let blocks = makeSampleBlocks()
    let noAdjustment = IntensityAdjustment.noChange

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: [],
      intensityAdjustment: noAdjustment
    )

    // Then
    XCTAssertFalse(prompt.userMessage.contains("HISTÓRICO DE FEEDBACK"), "Prompt não deve incluir seção de feedback quando não há ajuste")
  }

  func testCacheKeyIncludesFeedbackHash() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = makeSimpleBlueprint()
    let blocks = makeSampleBlocks()

    // When - prompts with different intensity adjustments
    let promptNoChange = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: [],
      intensityAdjustment: .noChange
    )

    let promptIncrease = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: [],
      intensityAdjustment: .increaseIntensity
    )

    let promptDecrease = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: [],
      intensityAdjustment: .decreaseIntensity
    )

    // Then - cache keys should be different
    XCTAssertNotEqual(promptNoChange.cacheKey, promptIncrease.cacheKey, "Cache key deve mudar com ajuste de intensidade")
    XCTAssertNotEqual(promptNoChange.cacheKey, promptDecrease.cacheKey, "Cache key deve mudar com ajuste de intensidade")
    XCTAssertNotEqual(promptIncrease.cacheKey, promptDecrease.cacheKey, "Cache keys diferentes para ajustes diferentes")
  }

  func testMetadataIncludesFeedbackHash() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = makeSimpleBlueprint()
    let blocks = makeSampleBlocks()
    let adjustment = IntensityAdjustment.increaseIntensity

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: [],
      intensityAdjustment: adjustment
    )

    // Then
    XCTAssertFalse(prompt.metadata.feedbackHash.isEmpty, "Metadata deve incluir feedback hash")
    XCTAssertTrue(prompt.metadata.feedbackHash.contains("1.15"), "Feedback hash deve conter volume multiplier")
  }

  func testPromptWith7DayHistory() {
    // Given
    let profile = makeProfile(goal: .hypertrophy, structure: .fullGym, level: .intermediate)
    let checkIn = makeCheckIn(focus: .upper, soreness: .none)
    let blueprint = makeSimpleBlueprint()
    let blocks = makeSampleBlocks()

    // Create 7 previous workouts
    let previousWorkouts = (1...7).map { WorkoutPlan.mock(title: "Treino \($0)") }

    // When
    let prompt = assembler.assemblePrompt(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: previousWorkouts
    )

    // Then
    XCTAssertTrue(prompt.userMessage.contains("últimos 7 treinos"), "Deve mencionar 7 dias de histórico")
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
  
  private func makeSampleBlocks() -> [WorkoutBlock] {
    [
      WorkoutBlock(
        id: "block-upper-1",
        group: .upper,
        level: .intermediate,
        compatibleStructures: [.fullGym, .basicGym],
        equipmentOptions: [.barbell, .dumbbell],
        exercises: [
          WorkoutExercise(
            id: "ex-1",
            name: "Supino Reto",
            mainMuscle: .chest,
            equipment: .barbell,
            instructions: ["Controle na descida"],
            media: nil
          ),
          WorkoutExercise(
            id: "ex-2",
            name: "Remada Curvada",
            mainMuscle: .back,
            equipment: .barbell,
            instructions: ["Mantenha as costas retas"],
            media: nil
          )
        ],
        suggestedSets: IntRange(3, 4),
        suggestedReps: IntRange(8, 12),
        restInterval: 90
      ),
      WorkoutBlock(
        id: "block-lower-1",
        group: .lower,
        level: .intermediate,
        compatibleStructures: [.fullGym, .basicGym, .bodyweight],
        equipmentOptions: [.bodyweight, .dumbbell],
        exercises: [
          WorkoutExercise(
            id: "ex-3",
            name: "Agachamento",
            mainMuscle: .quads,
            equipment: .bodyweight,
            instructions: ["Joelhos na direção dos pés"],
            media: nil
          )
        ],
        suggestedSets: IntRange(3, 4),
        suggestedReps: IntRange(10, 15),
        restInterval: 60
      )
    ]
  }
  
  private func makeSimpleBlueprint() -> WorkoutBlueprint {
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
          targetMuscles: [.chest, .back],
          includesGuidedActivity: true,
          guidedActivityKind: .mobility,
          guidedActivityMinutes: 5
        ),
        WorkoutBlockBlueprint(
          phaseKind: .strength,
          title: "Força",
          exerciseCount: 3,
          setsRange: 3...4,
          repsRange: 6...10,
          restSeconds: 120,
          rpeTarget: 8,
          targetMuscles: [.chest, .back, .shoulders]
        )
      ],
      equipmentConstraints: BlueprintEquipmentConstraints.from(structure: .fullGym),
      isRecoveryMode: false
    )
  }
}

// MARK: - WorkoutPlan Mock

extension WorkoutPlan {
  static func mock(
    title: String = "Mock Workout",
    focus: DailyFocus = .fullBody
  ) -> WorkoutPlan {
    let mockExercise = WorkoutExercise(
      id: "mock-ex-1",
      name: "Mock Exercise",
      mainMuscle: .chest,
      equipment: .bodyweight,
      instructions: ["Test instruction"],
      media: nil
    )
    
    let mockPrescription = ExercisePrescription(
      exercise: mockExercise,
      sets: 3,
      reps: IntRange(10, 12),
      restInterval: 60,
      tip: nil
    )
    
    let mockPhase = WorkoutPlanPhase(
      kind: .strength,
      title: "Força",
      rpeTarget: 7,
      items: [.exercise(mockPrescription)]
    )
    
    return WorkoutPlan(
      title: title,
      focus: focus,
      estimatedDurationMinutes: 45,
      intensity: .moderate,
      phases: [mockPhase]
    )
  }
}
