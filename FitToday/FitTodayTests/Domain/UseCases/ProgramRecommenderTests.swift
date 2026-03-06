//
//  ProgramRecommenderTests.swift
//  FitTodayTests
//
//  Tests for ProgramRecommender scoring with expanded fields.
//

import XCTest
@testable import FitToday

final class ProgramRecommenderTests: XCTestCase {

    private var sut: ProgramRecommender!

    override func setUp() {
        super.setUp()
        sut = ProgramRecommender()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeProgram(
        id: String = "test_gym",
        goalTag: ProgramGoalTag = .strength,
        level: ProgramLevel = .intermediate
    ) -> Program {
        Program(
            id: id,
            name: "Test Program",
            subtitle: "Test",
            goalTag: goalTag,
            level: level,
            equipment: .gym,
            durationWeeks: 8,
            heroImageName: "test",
            workoutTemplateIds: ["lib_test"],
            estimatedMinutesPerSession: 45,
            sessionsPerWeek: 4
        )
    }

    private func makeProfile(
        goal: FitnessGoal = .hypertrophy,
        structure: TrainingStructure = .fullGym,
        method: TrainingMethod = .traditional,
        level: TrainingLevel = .intermediate
    ) -> UserProfile {
        UserProfile(
            mainGoal: goal,
            availableStructure: structure,
            preferredMethod: method,
            level: level,
            healthConditions: [.none],
            weeklyFrequency: 4
        )
    }

    private func makeHistoryEntry(
        date: Date = Date(),
        focus: DailyFocus = .fullBody,
        status: WorkoutStatus = .completed
    ) -> WorkoutHistoryEntry {
        WorkoutHistoryEntry(
            id: UUID(),
            date: date,
            planId: UUID(),
            title: "Test Workout",
            focus: focus,
            status: status
        )
    }

    // MARK: - No Profile

    func testRecommendWithoutProfileReturnsFirstN() {
        let programs = (0..<5).map { makeProgram(id: "prog_\($0)_gym") }
        let result = sut.recommend(programs: programs, profile: nil, history: [], limit: 3)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].id, "prog_0_gym")
    }

    func testRecommendEmptyProgramsReturnsEmpty() {
        let result = sut.recommend(programs: [], profile: makeProfile(), history: [], limit: 5)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Goal Matching (+10)

    func testGoalMatchingBoostsScore() {
        let strengthProgram = makeProgram(id: "strength_gym", goalTag: .strength)
        let conditioningProgram = makeProgram(id: "cond_gym", goalTag: .conditioning)
        let profile = makeProfile(goal: .performance) // maps to .strength

        let result = sut.recommend(
            programs: [conditioningProgram, strengthProgram],
            profile: profile,
            history: [],
            limit: 2
        )

        XCTAssertEqual(result.first?.id, "strength_gym")
    }

    func testHypertrophyGoalMapsToHypertrophyTag() {
        let hypertrophyProgram = makeProgram(id: "hyp_gym", goalTag: .hypertrophy)
        let strengthProgram = makeProgram(id: "str_gym", goalTag: .strength)
        let profile = makeProfile(goal: .hypertrophy)

        let result = sut.recommend(
            programs: [strengthProgram, hypertrophyProgram],
            profile: profile,
            history: [],
            limit: 2
        )

        XCTAssertEqual(result.first?.id, "hyp_gym")
    }

    // MARK: - Level Matching (+5)

    func testLevelMatchingBoostsScore() {
        let beginnerProgram = makeProgram(id: "beg_gym", goalTag: .strength, level: .beginner)
        let intermediateProgram = makeProgram(id: "int_gym", goalTag: .strength, level: .intermediate)
        let profile = makeProfile(goal: .performance, level: .intermediate)

        let result = sut.recommend(
            programs: [beginnerProgram, intermediateProgram],
            profile: profile,
            history: [],
            limit: 2
        )

        // Both match goal (+10), but intermediate also matches level (+5)
        XCTAssertEqual(result.first?.id, "int_gym")
    }

    // MARK: - Structure Matching (+4)

    func testFullGymStructureMatchesGymPrograms() {
        let gymProgram = makeProgram(id: "test_gym", goalTag: .conditioning)
        let homeProgram = makeProgram(id: "test_home", goalTag: .conditioning)
        let profile = makeProfile(goal: .conditioning, structure: .fullGym)

        let result = sut.recommend(
            programs: [homeProgram, gymProgram],
            profile: profile,
            history: [],
            limit: 2
        )

        XCTAssertEqual(result.first?.id, "test_gym")
    }

    func testBodyweightStructureMatchesHomePrograms() {
        let gymProgram = makeProgram(id: "test_gym", goalTag: .conditioning)
        let homeProgram = makeProgram(id: "test_home", goalTag: .conditioning)
        let profile = makeProfile(goal: .conditioning, structure: .bodyweight)

        let result = sut.recommend(
            programs: [gymProgram, homeProgram],
            profile: profile,
            history: [],
            limit: 2
        )

        XCTAssertEqual(result.first?.id, "test_home")
    }

    // MARK: - Method Matching (+3)

    func testTraditionalMethodMatchesStrengthAndHypertrophy() {
        let strengthProgram = makeProgram(id: "str_gym", goalTag: .strength)
        let conditioningProgram = makeProgram(id: "cond_gym", goalTag: .conditioning)
        let profile = makeProfile(goal: .conditioning, method: .traditional)

        let result = sut.recommend(
            programs: [conditioningProgram, strengthProgram],
            profile: profile,
            history: [],
            limit: 2
        )

        // conditioning matches goal (+10), strength matches method (+3)
        // conditioning wins because goal match is stronger
        XCTAssertEqual(result.first?.id, "cond_gym")
    }

    func testMixedMethodMatchesAll() {
        let programs = [
            makeProgram(id: "str_gym", goalTag: .strength),
            makeProgram(id: "cond_gym", goalTag: .conditioning),
            makeProgram(id: "well_home", goalTag: .wellness),
        ]
        let profile = makeProfile(goal: .hypertrophy, method: .mixed)

        let result = sut.recommend(programs: programs, profile: profile, history: [], limit: 3)

        // All get method match (+3), none match goal exactly
        XCTAssertEqual(result.count, 3)
    }

    // MARK: - Yesterday Penalty (-5)

    func testYesterdayTrainingSameGoalPenalizesScore() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let historyEntry = makeHistoryEntry(date: yesterday, focus: .upper) // maps to .strength

        let strengthProgram = makeProgram(id: "str_gym", goalTag: .strength)
        let conditioningProgram = makeProgram(id: "cond_gym", goalTag: .conditioning)

        let profile = makeProfile(goal: .performance) // maps to .strength

        let result = sut.recommend(
            programs: [strengthProgram, conditioningProgram],
            profile: profile,
            history: [historyEntry],
            limit: 2
        )

        // strength: goal(+10) + yesterday(-5) = 5
        // conditioning: no goal match = 0
        // strength still wins but with reduced score
        XCTAssertEqual(result.first?.id, "str_gym")
    }

    // MARK: - Combined Scoring

    func testCombinedScoringSelectsBestMatch() {
        let programs = [
            makeProgram(id: "str_beginner_gym", goalTag: .strength, level: .beginner),
            makeProgram(id: "hyp_intermediate_gym", goalTag: .hypertrophy, level: .intermediate),
            makeProgram(id: "cond_advanced_home", goalTag: .conditioning, level: .advanced),
        ]

        // Profile: hypertrophy goal, intermediate, fullGym, traditional
        let profile = makeProfile(
            goal: .hypertrophy,
            structure: .fullGym,
            method: .traditional,
            level: .intermediate
        )

        let result = sut.recommend(programs: programs, profile: profile, history: [], limit: 3)

        // hyp_intermediate_gym: goal(+10) + level(+5) + structure(+4) + method(+3) = 22
        // str_beginner_gym: structure(+4) + method(+3) = 7
        // cond_advanced_home: 0
        XCTAssertEqual(result.first?.id, "hyp_intermediate_gym")
    }

    // MARK: - Limit

    func testLimitRespectsMaxCount() {
        let programs = (0..<10).map { makeProgram(id: "prog_\($0)_gym") }
        let result = sut.recommend(programs: programs, profile: makeProfile(), history: [], limit: 3)
        XCTAssertEqual(result.count, 3)
    }
}
