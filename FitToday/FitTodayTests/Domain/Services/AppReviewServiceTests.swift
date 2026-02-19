//
//  AppReviewServiceTests.swift
//  FitTodayTests
//
//  Tests for AppReviewService eligibility logic.
//

import XCTest
@testable import FitToday

final class AppReviewServiceTests: XCTestCase {

    private var defaults: UserDefaults!
    private var service: AppReviewService!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "AppReviewServiceTests")!
        defaults.removePersistentDomain(forName: "AppReviewServiceTests")
        service = AppReviewService(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "AppReviewServiceTests")
        defaults = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Workout Count Tests

    func testNotEligibleWithZeroWorkouts() {
        setFirstLaunchDate(daysAgo: 30)
        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 0))
    }

    func testNotEligibleWithTwoWorkouts() {
        setFirstLaunchDate(daysAgo: 30)
        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 2))
    }

    func testEligibleWithThreeWorkouts() {
        setFirstLaunchDate(daysAgo: 30)
        XCTAssertTrue(service.isEligible(completedWorkoutsCount: 3))
    }

    func testEligibleWithManyWorkouts() {
        setFirstLaunchDate(daysAgo: 30)
        XCTAssertTrue(service.isEligible(completedWorkoutsCount: 50))
    }

    // MARK: - First Launch Date Tests

    func testNotEligibleWhenFirstLaunchDateMissing() {
        // No first launch date set
        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 10))
    }

    func testNotEligibleWhenNewUser() {
        setFirstLaunchDate(daysAgo: 3) // Only 3 days ago
        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 10))
    }

    func testNotEligibleOnDay6() {
        setFirstLaunchDate(daysAgo: 6)
        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 10))
    }

    func testEligibleOnDay7() {
        setFirstLaunchDate(daysAgo: 7)
        XCTAssertTrue(service.isEligible(completedWorkoutsCount: 10))
    }

    // MARK: - Last Request Throttle Tests

    func testNotEligibleWhenRecentlyRequested() {
        setFirstLaunchDate(daysAgo: 60)
        setLastReviewRequestDate(daysAgo: 10) // Only 10 days ago
        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 10))
    }

    func testNotEligibleWhenRequestedYesterday() {
        setFirstLaunchDate(daysAgo: 60)
        setLastReviewRequestDate(daysAgo: 1)
        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 10))
    }

    func testEligibleWhen30DaysSinceLastRequest() {
        setFirstLaunchDate(daysAgo: 60)
        setLastReviewRequestDate(daysAgo: 30)
        XCTAssertTrue(service.isEligible(completedWorkoutsCount: 10))
    }

    func testEligibleWhenNeverRequested() {
        setFirstLaunchDate(daysAgo: 30)
        // No last request date set
        XCTAssertTrue(service.isEligible(completedWorkoutsCount: 5))
    }

    // MARK: - Version Tracking Tests

    func testNotEligibleWhenAlreadyPromptedForCurrentVersion() {
        setFirstLaunchDate(daysAgo: 60)

        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        defaults.set(currentVersion, forKey: AppStorageKeys.lastVersionPromptedForReview)

        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 10))
    }

    func testEligibleWhenPromptedForDifferentVersion() {
        setFirstLaunchDate(daysAgo: 60)
        defaults.set("0.0.1", forKey: AppStorageKeys.lastVersionPromptedForReview)

        XCTAssertTrue(service.isEligible(completedWorkoutsCount: 10))
    }

    // MARK: - Record Request Tests

    func testRecordReviewRequestSetsDate() {
        service.recordReviewRequest()

        let date = defaults.object(forKey: AppStorageKeys.lastReviewRequestDate) as? Date
        XCTAssertNotNil(date)
    }

    func testRecordReviewRequestSetsVersion() {
        service.recordReviewRequest()

        let version = defaults.string(forKey: AppStorageKeys.lastVersionPromptedForReview)
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        XCTAssertEqual(version, currentVersion)
    }

    // MARK: - Combined Criteria Tests

    func testNotEligibleWhenAllCriteriaFailSimultaneously() {
        // No first launch, 0 workouts
        XCTAssertFalse(service.isEligible(completedWorkoutsCount: 0))
    }

    func testEligibleWhenAllCriteriaMet() {
        setFirstLaunchDate(daysAgo: 30)
        setLastReviewRequestDate(daysAgo: 45)
        defaults.set("0.0.1", forKey: AppStorageKeys.lastVersionPromptedForReview)

        XCTAssertTrue(service.isEligible(completedWorkoutsCount: 5))
    }

    // MARK: - Helpers

    private func setFirstLaunchDate(daysAgo: Int) {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        defaults.set(date, forKey: AppStorageKeys.firstLaunchDate)
    }

    private func setLastReviewRequestDate(daysAgo: Int) {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        defaults.set(date, forKey: AppStorageKeys.lastReviewRequestDate)
    }
}
