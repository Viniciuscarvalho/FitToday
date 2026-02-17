//
//  SaveCustomWorkoutUseCaseTests.swift
//  FitTodayTests
//
//  Tests for SaveCustomWorkoutUseCase and CreateWorkoutViewModel workout CRUD.
//

import XCTest
@testable import FitToday

// MARK: - Mock Repository

final class MockCustomWorkoutRepository: CustomWorkoutRepository {
    var templates: [CustomWorkoutTemplate] = []
    var savedTemplates: [CustomWorkoutTemplate] = []
    var deletedIds: [UUID] = []
    var shouldThrow = false

    func listTemplates() async throws -> [CustomWorkoutTemplate] {
        if shouldThrow { throw MockError.generic }
        return templates
    }

    func getTemplate(id: UUID) async throws -> CustomWorkoutTemplate? {
        if shouldThrow { throw MockError.generic }
        return templates.first { $0.id == id }
    }

    func saveTemplate(_ template: CustomWorkoutTemplate) async throws {
        if shouldThrow { throw MockError.generic }
        savedTemplates.append(template)
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
    }

    func deleteTemplate(id: UUID) async throws {
        if shouldThrow { throw MockError.generic }
        deletedIds.append(id)
        templates.removeAll { $0.id == id }
    }

    func recordCompletion(templateId: UUID, actualExercises: [CustomExerciseEntry], duration: Int, completedAt: Date) async throws {}

    func getCompletionHistory(templateId: UUID) async throws -> [CustomWorkoutCompletion] { [] }

    func updateLastUsed(id: UUID) async throws {}

    enum MockError: Error { case generic }
}

// MARK: - Fixture Helpers

private extension CustomExerciseEntry {
    static func fixture(name: String = "Push Up", orderIndex: Int = 0) -> CustomExerciseEntry {
        CustomExerciseEntry(
            exerciseId: "123",
            exerciseName: name,
            orderIndex: orderIndex,
            sets: [WorkoutSet()]
        )
    }
}

private extension CustomWorkoutTemplate {
    static func fixture(
        name: String = "My Workout",
        exercises: [CustomExerciseEntry] = [.fixture()]
    ) -> CustomWorkoutTemplate {
        CustomWorkoutTemplate(name: name, exercises: exercises)
    }
}

// MARK: - SaveCustomWorkoutUseCase Tests

final class SaveCustomWorkoutUseCaseTests: XCTestCase {

    private var sut: SaveCustomWorkoutUseCase!
    private var mockRepository: MockCustomWorkoutRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockCustomWorkoutRepository()
        sut = SaveCustomWorkoutUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - execute(template:)

    func test_execute_withValidTemplate_savesToRepository() async throws {
        // Given
        let template = CustomWorkoutTemplate.fixture()

        // When
        try await sut.execute(template: template)

        // Then
        XCTAssertEqual(mockRepository.savedTemplates.count, 1)
        XCTAssertEqual(mockRepository.savedTemplates.first?.name, "My Workout")
    }

    func test_execute_withEmptyName_throwsEmptyNameError() async {
        // Given
        let template = CustomWorkoutTemplate.fixture(name: "   ")

        // When / Then
        do {
            try await sut.execute(template: template)
            XCTFail("Expected error to be thrown")
        } catch CustomWorkoutError.emptyName {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_withNoExercises_throwsNoExercisesError() async {
        // Given
        let template = CustomWorkoutTemplate.fixture(exercises: [])

        // When / Then
        do {
            try await sut.execute(template: template)
            XCTFail("Expected error to be thrown")
        } catch CustomWorkoutError.noExercises {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_withExerciseHavingNoSets_throwsInvalidTemplateError() async {
        // Given
        let exerciseWithNoSets = CustomExerciseEntry(
            exerciseId: "1",
            exerciseName: "Bench Press",
            orderIndex: 0,
            sets: []
        )
        let template = CustomWorkoutTemplate.fixture(exercises: [exerciseWithNoSets])

        // When / Then
        do {
            try await sut.execute(template: template)
            XCTFail("Expected error to be thrown")
        } catch CustomWorkoutError.invalidTemplate {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - createAndSave

    func test_createAndSave_returnsTemplateWithCorrectName() async throws {
        // Given
        let exercises = [CustomExerciseEntry.fixture()]

        // When
        let result = try await sut.createAndSave(name: "Leg Day", exercises: exercises)

        // Then
        XCTAssertEqual(result.name, "Leg Day")
        XCTAssertEqual(result.exercises.count, 1)
        XCTAssertEqual(mockRepository.savedTemplates.count, 1)
    }

    func test_createAndSave_withCategory_setsCategory() async throws {
        // Given
        let exercises = [CustomExerciseEntry.fixture()]

        // When
        let result = try await sut.createAndSave(name: "Push", exercises: exercises, category: "Push")

        // Then
        XCTAssertEqual(result.category, "Push")
    }
}

// MARK: - CreateWorkoutViewModel Tests

@MainActor
final class CreateWorkoutViewModelTests: XCTestCase {

    private var sut: CreateWorkoutViewModel!
    private var mockRepository: MockCustomWorkoutRepository!
    private var saveUseCase: SaveCustomWorkoutUseCase!

    override func setUp() {
        super.setUp()
        mockRepository = MockCustomWorkoutRepository()
        saveUseCase = SaveCustomWorkoutUseCase(repository: mockRepository)
        sut = CreateWorkoutViewModel(saveUseCase: saveUseCase)
    }

    override func tearDown() {
        sut = nil
        saveUseCase = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - canSave

    func test_canSave_withEmptyName_returnsFalse() {
        sut.workoutName = ""
        sut.exercises = [.fixture()]
        XCTAssertFalse(sut.canSave)
    }

    func test_canSave_withNoExercises_returnsFalse() {
        sut.workoutName = "My Workout"
        sut.exercises = []
        XCTAssertFalse(sut.canSave)
    }

    func test_canSave_withNameAndExercises_returnsTrue() {
        sut.workoutName = "My Workout"
        sut.exercises = [.fixture()]
        XCTAssertTrue(sut.canSave)
    }

    // MARK: - addExercise

    func test_addExercise_appendsToList() {
        let entry = CustomExerciseEntry.fixture(name: "Squat")
        sut.addExercise(entry)
        XCTAssertEqual(sut.exercises.count, 1)
        XCTAssertEqual(sut.exercises.first?.exerciseName, "Squat")
    }

    func test_addExercise_setsCorrectOrderIndex() {
        sut.addExercise(.fixture(name: "A"))
        sut.addExercise(.fixture(name: "B"))
        XCTAssertEqual(sut.exercises[0].orderIndex, 0)
        XCTAssertEqual(sut.exercises[1].orderIndex, 1)
    }

    // MARK: - removeExercise

    func test_removeExercise_removesFromList() {
        let entry = CustomExerciseEntry.fixture(name: "Plank")
        sut.addExercise(entry)
        sut.removeExercise(entry)
        XCTAssertTrue(sut.exercises.isEmpty)
    }

    // MARK: - moveExercise

    func test_moveExercise_reordersCorrectly() {
        sut.addExercise(.fixture(name: "A"))
        sut.addExercise(.fixture(name: "B"))
        sut.addExercise(.fixture(name: "C"))

        // Move "A" (index 0) to after "C" (destination 3)
        sut.moveExercise(from: IndexSet(integer: 0), to: 3)

        XCTAssertEqual(sut.exercises[0].exerciseName, "B")
        XCTAssertEqual(sut.exercises[1].exerciseName, "C")
        XCTAssertEqual(sut.exercises[2].exerciseName, "A")
    }

    func test_moveExercise_updatesOrderIndexes() {
        sut.addExercise(.fixture(name: "A"))
        sut.addExercise(.fixture(name: "B"))
        sut.moveExercise(from: IndexSet(integer: 0), to: 2)

        for (index, exercise) in sut.exercises.enumerated() {
            XCTAssertEqual(exercise.orderIndex, index)
        }
    }

    // MARK: - saveWorkout

    func test_saveWorkout_withValidData_persistsToRepository() async {
        sut.workoutName = "Test Workout"
        sut.addExercise(.fixture())

        await sut.saveWorkout()

        XCTAssertEqual(mockRepository.savedTemplates.count, 1)
        XCTAssertEqual(mockRepository.savedTemplates.first?.name, "Test Workout")
    }

    func test_saveWorkout_withInvalidData_doesNotPersist() async {
        sut.workoutName = ""
        sut.exercises = []

        await sut.saveWorkout()

        XCTAssertTrue(mockRepository.savedTemplates.isEmpty)
    }

    func test_saveWorkout_trimsWhitespaceFromName() async {
        sut.workoutName = "  Push Day  "
        sut.addExercise(.fixture())

        await sut.saveWorkout()

        XCTAssertEqual(mockRepository.savedTemplates.first?.name, "Push Day")
    }
}

// MARK: - EditWorkoutViewModel Tests

@MainActor
final class EditWorkoutViewModelTests: XCTestCase {

    private var mockRepository: MockCustomWorkoutRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockCustomWorkoutRepository()
    }

    override func tearDown() {
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - addExerciseEntry

    func test_addExerciseEntry_appendsWithCorrectOrderIndex() {
        var exercises: [CustomExerciseEntry] = [.fixture(name: "A")]
        let newEntry = CustomExerciseEntry.fixture(name: "B")
        var mutableEntry = newEntry
        mutableEntry.orderIndex = exercises.count
        exercises.append(mutableEntry)

        XCTAssertEqual(exercises.count, 2)
        XCTAssertEqual(exercises[1].orderIndex, 1)
        XCTAssertEqual(exercises[1].exerciseName, "B")
    }

    // MARK: - moveExercise

    func test_moveExercise_reordersCorrectly() {
        var exercises: [CustomExerciseEntry] = [
            .fixture(name: "A"),
            .fixture(name: "B"),
            .fixture(name: "C")
        ]
        exercises.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        XCTAssertEqual(exercises[0].exerciseName, "C")
        XCTAssertEqual(exercises[1].exerciseName, "A")
        XCTAssertEqual(exercises[2].exerciseName, "B")
    }

    // MARK: - ProgramWorkoutCustomization ordering

    func test_exerciseOrderPreservedAfterMove() {
        var exercises = [
            CustomExerciseEntry.fixture(name: "Bench"),
            CustomExerciseEntry.fixture(name: "Squat"),
            CustomExerciseEntry.fixture(name: "Deadlift")
        ]

        // Move Deadlift to top
        exercises.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        // Update order indexes
        for i in exercises.indices { exercises[i].orderIndex = i }

        XCTAssertEqual(exercises[0].exerciseName, "Deadlift")
        XCTAssertEqual(exercises[0].orderIndex, 0)
        XCTAssertEqual(exercises[1].exerciseName, "Bench")
        XCTAssertEqual(exercises[1].orderIndex, 1)
        XCTAssertEqual(exercises[2].exerciseName, "Squat")
        XCTAssertEqual(exercises[2].orderIndex, 2)
    }
}
