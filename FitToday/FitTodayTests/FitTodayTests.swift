//
//  FitTodayTests.swift
//  FitTodayTests
//
//  Created by Vinicius Carvalho on 03/01/26.
//

import XCTest
@testable import FitToday

final class FitTodayTests: XCTestCase {

    func testGeneratePlanRespectsFocusAndCatalog() async throws {
        let upperBlock = makeBlock(id: "upper_basic", group: .upper, level: .intermediate, muscles: [.chest, .shoulders])
        let lowerBlock = makeBlock(id: "lower_basic", group: .lower, level: .intermediate, muscles: [.quads, .glutes])
        let repo = StubBlocksRepository(blocks: [upperBlock, lowerBlock])

        let useCase = GenerateWorkoutPlanUseCase(blocksRepository: repo)
        let plan = try await useCase.execute(profile: sampleProfile, checkIn: DailyCheckIn(focus: .upper, sorenessLevel: .none))

        XCTAssertEqual(plan.focus, .upper)
        XCTAssertFalse(plan.exercises.isEmpty)

        let catalog = Set(upperBlock.exercises.map(\.id) + lowerBlock.exercises.map(\.id))
        XCTAssertTrue(Set(plan.exercises.map { $0.exercise.id }).isSubset(of: catalog))
    }

    func testStrongSorenessReducesVolume() async throws {
        let repo = StubBlocksRepository(blocks: [makeBlock(id: "upper_basic", group: .upper, level: .intermediate, muscles: [.chest])])
        let useCase = GenerateWorkoutPlanUseCase(blocksRepository: repo)

        let plan = try await useCase.execute(
            profile: sampleProfile,
            checkIn: DailyCheckIn(focus: .upper, sorenessLevel: .strong, sorenessAreas: [.glutes, .hamstrings])
        )

        guard let prescription = plan.exercises.first else {
            return XCTFail("Esperava exercícios no plano")
        }

        XCTAssertLessThan(prescription.sets, 4, "Dor forte deve reduzir o número de séries")
        XCTAssertGreaterThanOrEqual(prescription.restInterval, 60, "Dor forte mantém ou aumenta descanso")
    }

    func testFallbackPlanRunsWhenNoCompatibleBlocks() async throws {
        let incompatible = WorkoutBlock(
            id: "advanced_machine",
            group: .fullBody,
            level: .advanced,
            compatibleStructures: [.bodyweight],
            equipmentOptions: [.machine],
            exercises: [
                WorkoutExercise(id: "ex1", name: "Complex Move", mainMuscle: .chest, equipment: .machine, instructions: [], media: nil)
            ],
            suggestedSets: IntRange(5, 6),
            suggestedReps: IntRange(5, 6),
            restInterval: 90
        )

        let repo = StubBlocksRepository(blocks: [incompatible])
        let useCase = GenerateWorkoutPlanUseCase(blocksRepository: repo)

        let plan = try await useCase.execute(
            profile: sampleProfile,
            checkIn: DailyCheckIn(focus: .upper, sorenessLevel: .none)
        )

        XCTAssertEqual(plan.focus, .fullBody)
        XCTAssertFalse(plan.exercises.isEmpty)
    }

    func testHybridComposerUsesRemoteWhenAllowed() async throws {
        let block = makeBlock(id: "upper_basic", group: .upper, level: .intermediate, muscles: [.chest])
        let repo = StubBlocksRepository(blocks: [block])
        let localComposer = LocalWorkoutPlanComposer()
        let remoteClient = MockOpenAIClient(payload: """
        {"selected_blocks":[{"block_id":"upper_basic","sets_multiplier":1.2,"reps_multiplier":1.1,"rest_adjustment_seconds":5}]}
        """)
        let remoteComposer = OpenAIWorkoutPlanComposer(client: remoteClient, localComposer: localComposer)
        let limiter = MockUsageLimiter(canUse: true)
        let hybrid = HybridWorkoutPlanComposer(
            remoteComposer: remoteComposer,
            localComposer: localComposer,
            usageLimiter: limiter
        )
        let useCase = GenerateWorkoutPlanUseCase(blocksRepository: repo, composer: hybrid)

        let plan = try await useCase.execute(profile: sampleProfile, checkIn: DailyCheckIn(focus: .upper, sorenessLevel: .none))

        XCTAssertTrue(limiter.registerUsageCalled)
        XCTAssertGreaterThan(plan.exercises.first?.sets ?? 0, block.suggestedSets.average)
    }

    func testHybridComposerFallsBackWhenLimitReached() async throws {
        let block = makeBlock(id: "upper_basic", group: .upper, level: .intermediate, muscles: [.chest])
        let repo = StubBlocksRepository(blocks: [block])
        let localComposer = LocalWorkoutPlanComposer()
        let remoteClient = MockOpenAIClient(payload: """
        {"selected_blocks":[{"block_id":"upper_basic"}]}
        """)
        let remoteComposer = OpenAIWorkoutPlanComposer(client: remoteClient, localComposer: localComposer)
        let limiter = MockUsageLimiter(canUse: false)
        let hybrid = HybridWorkoutPlanComposer(
            remoteComposer: remoteComposer,
            localComposer: localComposer,
            usageLimiter: limiter
        )
        let useCase = GenerateWorkoutPlanUseCase(blocksRepository: repo, composer: hybrid)

        _ = try await useCase.execute(profile: sampleProfile, checkIn: DailyCheckIn(focus: .upper, sorenessLevel: .none))

        XCTAssertFalse(remoteClient.invocationCount > 0, "Remote não deve ser chamado quando limite atingido")
    }

    @MainActor
    func testLibraryFilterByGoal() async throws {
        let workouts = [
            LibraryWorkout(
                id: "w1",
                title: "Upper Power",
                subtitle: "Hipertrofia",
                goal: .hypertrophy,
                structure: .fullGym,
                estimatedDurationMinutes: 40,
                intensity: .moderate,
                exercises: []
            ),
            LibraryWorkout(
                id: "w2",
                title: "HIIT Casa",
                subtitle: "Queima",
                goal: .weightLoss,
                structure: .bodyweight,
                estimatedDurationMinutes: 25,
                intensity: .high,
                exercises: []
            )
        ]

        let repo = StubLibraryRepo(workouts: workouts)
        let viewModel = LibraryViewModel(repository: repo)
        viewModel.loadWorkouts()
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(viewModel.filteredWorkouts.count, 2)
        viewModel.filter.goal = .hypertrophy
        XCTAssertEqual(viewModel.filteredWorkouts.count, 1)
        XCTAssertEqual(viewModel.filteredWorkouts.first?.id, "w1")
    }

    func testIntRangeDisplay() {
        XCTAssertEqual(IntRange(10, 10).display, "10")
        XCTAssertEqual(IntRange(8, 12).display, "8-12")
        XCTAssertEqual(IntRange(12, 8).display, "8-12")
    }
}

// MARK: - Helpers

private let sampleProfile = UserProfile(
    mainGoal: .hypertrophy,
    availableStructure: .fullGym,
    preferredMethod: .traditional,
    level: .intermediate,
    healthConditions: [],
    weeklyFrequency: 4
)

private func makeBlock(
    id: String,
    group: DailyFocus,
    level: TrainingLevel,
    muscles: [MuscleGroup],
    equipment: EquipmentType = .dumbbell
) -> WorkoutBlock {
    let exercises = muscles.enumerated().map { index, muscle in
        WorkoutExercise(
            id: "\(id)_\(index)",
            name: "\(muscle)_move",
            mainMuscle: muscle,
            equipment: equipment,
            instructions: ["Execute com controle."],
            media: nil
        )
    }

    return WorkoutBlock(
        id: id,
        group: group,
        level: level,
        compatibleStructures: TrainingStructure.allCases,
        equipmentOptions: [equipment],
        exercises: exercises,
        suggestedSets: IntRange(3, 4),
        suggestedReps: IntRange(8, 12),
        restInterval: 60
    )
}

private final class StubBlocksRepository: WorkoutBlocksRepository {
    private let blocks: [WorkoutBlock]

    init(blocks: [WorkoutBlock]) {
        self.blocks = blocks
    }

    func loadBlocks() async throws -> [WorkoutBlock] {
        blocks
    }
}

private final class MockOpenAIClient: OpenAIClienting {
    private let payload: String
    private(set) var invocationCount = 0

    init(payload: String) {
        self.payload = payload
    }

    func sendJSONPrompt(prompt: String, cachedKey: String?) async throws -> Data {
        invocationCount += 1
        return Data(payload.utf8)
    }
}

@MainActor
private final class StubLibraryRepo: LibraryWorkoutsRepository {
    private let workouts: [LibraryWorkout]

    init(workouts: [LibraryWorkout]) {
        self.workouts = workouts
    }

    func loadWorkouts() async throws -> [LibraryWorkout] {
        workouts
    }
}

private final class MockUsageLimiter: OpenAIUsageLimiting {
    private let canUse: Bool
    private(set) var registerUsageCalled = false

    init(canUse: Bool) {
        self.canUse = canUse
    }

    func canUseAI(userId: UUID, on date: Date) async -> Bool {
        canUse
    }

    func registerUsage(userId: UUID, on date: Date) async {
        registerUsageCalled = true
    }
}
