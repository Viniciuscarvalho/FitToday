//
//  WorkoutCompositionFixtures.swift
//  FitTodayTests
//
//  Created by AI on 09/01/26.
//
//  Fixtures padronizadas para testes de composição de treino.
//  Cada combinação objetivo/estrutura representa um cenário crítico.
//

import Foundation
@testable import FitToday

// MARK: - Test Fixture Namespace

enum WorkoutTestFixtures {
  
  // MARK: - Profile Fixtures by Goal/Structure
  
  enum Profiles {
    /// Hipertrofia em academia completa (caso mais comum)
    static let hypertrophyFullGym = UserProfile(
      id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
      mainGoal: .hypertrophy,
      availableStructure: .fullGym,
      preferredMethod: .mixed,
      level: .intermediate,
      healthConditions: [],
      weeklyFrequency: 4,
      createdAt: Date(timeIntervalSince1970: 0),
      isProfileComplete: true
    )
    
    /// Emagrecimento com peso corporal (cenário home)
    static let weightLossBodyweight = UserProfile(
      id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
      mainGoal: .weightLoss,
      availableStructure: .bodyweight,
      preferredMethod: .hiit,
      level: .beginner,
      healthConditions: [],
      weeklyFrequency: 3,
      createdAt: Date(timeIntervalSince1970: 0),
      isProfileComplete: true
    )
    
    /// Condicionamento em casa com halteres
    static let conditioningHomeDumbbells = UserProfile(
      id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
      mainGoal: .conditioning,
      availableStructure: .homeDumbbells,
      preferredMethod: .mixed,
      level: .intermediate,
      healthConditions: [],
      weeklyFrequency: 5,
      createdAt: Date(timeIntervalSince1970: 0),
      isProfileComplete: true
    )
    
    /// Resistência/endurance em academia básica
    static let enduranceBasicGym = UserProfile(
      id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
      mainGoal: .endurance,
      availableStructure: .basicGym,
      preferredMethod: .traditional,
      level: .advanced,
      healthConditions: [],
      weeklyFrequency: 5,
      createdAt: Date(timeIntervalSince1970: 0),
      isProfileComplete: true
    )
    
    /// Performance/força avançado
    static let performanceFullGym = UserProfile(
      id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
      mainGoal: .performance,
      availableStructure: .fullGym,
      preferredMethod: .traditional,
      level: .advanced,
      healthConditions: [],
      weeklyFrequency: 6,
      createdAt: Date(timeIntervalSince1970: 0),
      isProfileComplete: true
    )
    
    /// Iniciante absoluto - bodyweight
    static let beginnerBodyweight = UserProfile(
      id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
      mainGoal: .conditioning,
      availableStructure: .bodyweight,
      preferredMethod: .mixed,
      level: .beginner,
      healthConditions: [],
      weeklyFrequency: 2,
      createdAt: Date(timeIntervalSince1970: 0),
      isProfileComplete: true
    )
    
    /// Todos os profiles de teste
    static let all: [UserProfile] = [
      hypertrophyFullGym,
      weightLossBodyweight,
      conditioningHomeDumbbells,
      enduranceBasicGym,
      performanceFullGym,
      beginnerBodyweight
    ]
    
    /// Profiles por objetivo
    static func forGoal(_ goal: FitnessGoal) -> UserProfile {
      switch goal {
      case .hypertrophy: return hypertrophyFullGym
      case .weightLoss: return weightLossBodyweight
      case .conditioning: return conditioningHomeDumbbells
      case .endurance: return enduranceBasicGym
      case .performance: return performanceFullGym
      }
    }
    
    /// Profiles por estrutura
    static func forStructure(_ structure: TrainingStructure) -> UserProfile {
      switch structure {
      case .fullGym: return hypertrophyFullGym
      case .bodyweight: return weightLossBodyweight
      case .homeDumbbells: return conditioningHomeDumbbells
      case .basicGym: return enduranceBasicGym
      }
    }
  }
  
  // MARK: - CheckIn Fixtures by Focus/Soreness
  
  enum CheckIns {
    /// Check-in neutro (sem dor, foco fullBody)
    static let neutral = DailyCheckIn(
      focus: .fullBody,
      sorenessLevel: .none,
      sorenessAreas: []
    )
    
    /// Foco upper sem dor
    static let upperNoDoms = DailyCheckIn(
      focus: .upper,
      sorenessLevel: .none,
      sorenessAreas: []
    )
    
    /// Foco lower sem dor
    static let lowerNoDoms = DailyCheckIn(
      focus: .lower,
      sorenessLevel: .none,
      sorenessAreas: []
    )
    
    /// Foco cardio sem dor
    static let cardioNoDoms = DailyCheckIn(
      focus: .cardio,
      sorenessLevel: .none,
      sorenessAreas: []
    )
    
    /// Foco core sem dor
    static let coreNoDoms = DailyCheckIn(
      focus: .core,
      sorenessLevel: .none,
      sorenessAreas: []
    )
    
    /// Surpresa (random)
    static let surprise = DailyCheckIn(
      focus: .surprise,
      sorenessLevel: .none,
      sorenessAreas: []
    )
    
    /// Alta dor muscular (recovery mode)
    static let highDoms = DailyCheckIn(
      focus: .fullBody,
      sorenessLevel: .strong,
      sorenessAreas: [.chest, .back, .quads]
    )
    
    /// Dor moderada
    static let moderateDoms = DailyCheckIn(
      focus: .upper,
      sorenessLevel: .moderate,
      sorenessAreas: [.chest, .shoulders]
    )
    
    /// Dor leve
    static let lightDoms = DailyCheckIn(
      focus: .lower,
      sorenessLevel: .light,
      sorenessAreas: [.quads]
    )
    
    /// Todos os check-ins de teste
    static let all: [DailyCheckIn] = [
      neutral,
      upperNoDoms,
      lowerNoDoms,
      cardioNoDoms,
      coreNoDoms,
      surprise,
      highDoms,
      moderateDoms,
      lightDoms
    ]
    
    /// Check-in por foco
    static func forFocus(_ focus: DailyFocus) -> DailyCheckIn {
      switch focus {
      case .fullBody: return neutral
      case .upper: return upperNoDoms
      case .lower: return lowerNoDoms
      case .cardio: return cardioNoDoms
      case .core: return coreNoDoms
      case .surprise: return surprise
      }
    }
    
    /// Check-in por nível de DOMS
    static func forDoms(_ level: MuscleSorenessLevel) -> DailyCheckIn {
      switch level {
      case .none: return neutral
      case .light: return lightDoms
      case .moderate: return moderateDoms
      case .strong: return highDoms
      }
    }
  }
  
  // MARK: - Exercise Block Fixtures
  
  enum Blocks {
    /// Bloco de exercícios upper para fullGym
    static let upperFullGym = WorkoutBlock(
      id: "fixture-upper-fullgym",
      group: .upper,
      level: .intermediate,
      compatibleStructures: [.fullGym, .basicGym],
      equipmentOptions: [.barbell, .dumbbell, .machine],
      exercises: [
        WorkoutExercise(
          id: "ex-supino",
          name: "Supino Reto",
          mainMuscle: .chest,
          equipment: .barbell,
          instructions: ["Controle na descida"],
          media: nil
        ),
        WorkoutExercise(
          id: "ex-remada",
          name: "Remada Curvada",
          mainMuscle: .back,
          equipment: .barbell,
          instructions: ["Mantenha as costas retas"],
          media: nil
        ),
        WorkoutExercise(
          id: "ex-desenvolvimento",
          name: "Desenvolvimento",
          mainMuscle: .shoulders,
          equipment: .dumbbell,
          instructions: ["Controle o movimento"],
          media: nil
        )
      ],
      suggestedSets: IntRange(3, 4),
      suggestedReps: IntRange(8, 12),
      restInterval: 90
    )
    
    /// Bloco de exercícios lower para bodyweight
    static let lowerBodyweight = WorkoutBlock(
      id: "fixture-lower-bodyweight",
      group: .lower,
      level: .beginner,
      compatibleStructures: [.bodyweight, .homeDumbbells],
      equipmentOptions: [.bodyweight],
      exercises: [
        WorkoutExercise(
          id: "ex-agachamento",
          name: "Agachamento Livre",
          mainMuscle: .quads,
          equipment: .bodyweight,
          instructions: ["Joelhos na direção dos pés"],
          media: nil
        ),
        WorkoutExercise(
          id: "ex-afundo",
          name: "Avanço",
          mainMuscle: .quads,
          equipment: .bodyweight,
          instructions: ["Passo controlado"],
          media: nil
        ),
        WorkoutExercise(
          id: "ex-elevacao-quadril",
          name: "Elevação de Quadril",
          mainMuscle: .glutes,
          equipment: .bodyweight,
          instructions: ["Contraia o glúteo no topo"],
          media: nil
        )
      ],
      suggestedSets: IntRange(3, 4),
      suggestedReps: IntRange(12, 15),
      restInterval: 45
    )
    
    /// Bloco core
    static let coreAll = WorkoutBlock(
      id: "fixture-core",
      group: .core,
      level: .beginner,
      compatibleStructures: TrainingStructure.allCases,
      equipmentOptions: [.bodyweight],
      exercises: [
        WorkoutExercise(
          id: "ex-prancha",
          name: "Prancha",
          mainMuscle: .core,
          equipment: .bodyweight,
          instructions: ["Mantenha o corpo reto"],
          media: nil
        ),
        WorkoutExercise(
          id: "ex-abdominal",
          name: "Abdominal",
          mainMuscle: .core,
          equipment: .bodyweight,
          instructions: ["Contraia o abdômen"],
          media: nil
        )
      ],
      suggestedSets: IntRange(2, 3),
      suggestedReps: IntRange(15, 20),
      restInterval: 30
    )
    
    /// Todos os blocos
    static let all: [WorkoutBlock] = [
      upperFullGym,
      lowerBodyweight,
      coreAll
    ]
  }
  
  // MARK: - Blueprint Fixtures
  
  enum Blueprints {
    /// Blueprint de hipertrofia upper
    static func hypertrophyUpper() -> WorkoutBlueprint {
      let engine = WorkoutBlueprintEngine()
      return engine.generateBlueprint(
        profile: Profiles.hypertrophyFullGym,
        checkIn: CheckIns.upperNoDoms
      )
    }
    
    /// Blueprint de emagrecimento fullBody
    static func weightLossFullBody() -> WorkoutBlueprint {
      let engine = WorkoutBlueprintEngine()
      return engine.generateBlueprint(
        profile: Profiles.weightLossBodyweight,
        checkIn: CheckIns.neutral
      )
    }
    
    /// Blueprint de recovery (DOMS alto)
    static func recoveryMode() -> WorkoutBlueprint {
      let engine = WorkoutBlueprintEngine()
      return engine.generateBlueprint(
        profile: Profiles.hypertrophyFullGym,
        checkIn: CheckIns.highDoms
      )
    }
  }
  
  // MARK: - Expected Outputs
  
  enum ExpectedOutputs {
    /// Características esperadas de blueprint por objetivo
    struct BlueprintExpectation {
      let goal: FitnessGoal
      let hasAerobicBlock: Bool
      let minRpe: Int
      let maxRpe: Int
      let restSecondsRange: ClosedRange<Int>
      let repsRange: ClosedRange<Int>
    }
    
    static let hypertrophy = BlueprintExpectation(
      goal: .hypertrophy,
      hasAerobicBlock: false,
      minRpe: 7,
      maxRpe: 9,
      restSecondsRange: 90...180,
      repsRange: 6...12
    )
    
    static let weightLoss = BlueprintExpectation(
      goal: .weightLoss,
      hasAerobicBlock: true,
      minRpe: 6,
      maxRpe: 8,
      restSecondsRange: 20...45,
      repsRange: 12...20
    )
    
    static let endurance = BlueprintExpectation(
      goal: .endurance,
      hasAerobicBlock: true,
      minRpe: 5,
      maxRpe: 7,
      restSecondsRange: 15...30,
      repsRange: 15...25
    )
    
    static let conditioning = BlueprintExpectation(
      goal: .conditioning,
      hasAerobicBlock: true,
      minRpe: 6,
      maxRpe: 8,
      restSecondsRange: 30...60,
      repsRange: 10...15
    )
    
    static let performance = BlueprintExpectation(
      goal: .performance,
      hasAerobicBlock: false,
      minRpe: 8,
      maxRpe: 10,
      restSecondsRange: 120...300,
      repsRange: 1...6
    )
    
    static func forGoal(_ goal: FitnessGoal) -> BlueprintExpectation {
      switch goal {
      case .hypertrophy: return hypertrophy
      case .weightLoss: return weightLoss
      case .endurance: return endurance
      case .conditioning: return conditioning
      case .performance: return performance
      }
    }
  }
  
  // MARK: - Mock OpenAI Response
  
  enum MockOpenAIResponses {
    /// Resposta válida de treino de força
    static let validStrengthWorkout = """
    {
      "phases": [
        {
          "kind": "warmup",
          "activity": {
            "kind": "mobility",
            "title": "Mobilidade Articular",
            "durationMinutes": 5,
            "notes": null
          }
        },
        {
          "kind": "strength",
          "exercises": [
            {
              "name": "Supino Reto",
              "muscleGroup": "chest",
              "equipment": "barbell",
              "sets": 4,
              "reps": "6-8",
              "restSeconds": 120,
              "notes": "Controle na descida"
            },
            {
              "name": "Remada Curvada",
              "muscleGroup": "back",
              "equipment": "barbell",
              "sets": 4,
              "reps": "6-8",
              "restSeconds": 120,
              "notes": "Mantenha as costas retas"
            }
          ]
        }
      ],
      "title": "Upper Força",
      "notes": null
    }
    """
    
    /// Resposta válida de treino metabólico
    static let validMetabolicWorkout = """
    {
      "phases": [
        {
          "kind": "warmup",
          "activity": {
            "kind": "mobility",
            "title": "Aquecimento Dinâmico",
            "durationMinutes": 5,
            "notes": null
          }
        },
        {
          "kind": "strength",
          "exercises": [
            {
              "name": "Agachamento",
              "muscleGroup": "legs",
              "equipment": "bodyweight",
              "sets": 3,
              "reps": "15-20",
              "restSeconds": 30,
              "notes": null
            }
          ]
        },
        {
          "kind": "aerobic",
          "activity": {
            "kind": "aerobicZone2",
            "title": "Cardio Moderado",
            "durationMinutes": 15,
            "notes": null
          }
        }
      ],
      "title": "Fat Burn Circuit",
      "notes": null
    }
    """
    
    /// Resposta inválida (JSON malformado)
    static let invalidJSON = "{ invalid json }"
    
    /// Resposta com fases vazias
    static let emptyPhases = """
    {
      "phases": [],
      "title": "Empty"
    }
    """
    
    /// Resposta com equipamento incompatível para bodyweight
    static let incompatibleEquipment = """
    {
      "phases": [
        {
          "kind": "strength",
          "exercises": [
            {
              "name": "Supino",
              "muscleGroup": "chest",
              "equipment": "barbell",
              "sets": 4,
              "reps": "6-8",
              "restSeconds": 120,
              "notes": null
            }
          ]
        }
      ],
      "title": "Invalid"
    }
    """
  }
}
