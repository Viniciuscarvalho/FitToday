//
//  AppReviewService.swift
//  FitToday
//
//  Service for requesting App Store reviews at appropriate moments.
//

import Foundation

// MARK: - Protocol

protocol AppReviewRequesting {
    func isEligible(completedWorkoutsCount: Int) -> Bool
}

// MARK: - AppReviewService

struct AppReviewService: AppReviewRequesting {

    /// Minimum completed workouts before requesting a review.
    static let minimumWorkouts = 3

    /// Minimum days since first app launch.
    static let minimumDaysSinceFirstLaunch = 7

    /// Minimum days between review requests (app-level throttle).
    static let minimumDaysBetweenRequests = 30

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isEligible(completedWorkoutsCount: Int) -> Bool {
        // 1. Minimum workout threshold
        guard completedWorkoutsCount >= Self.minimumWorkouts else {
            return false
        }

        // 2. Not a brand new user
        guard let firstLaunch = defaults.object(forKey: AppStorageKeys.firstLaunchDate) as? Date else {
            return false
        }

        let daysSinceFirstLaunch = Calendar.current.dateComponents(
            [.day], from: firstLaunch, to: Date()
        ).day ?? 0

        guard daysSinceFirstLaunch >= Self.minimumDaysSinceFirstLaunch else {
            return false
        }

        // 3. Not prompted for this app version
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let lastVersionPrompted = defaults.string(forKey: AppStorageKeys.lastVersionPromptedForReview) ?? ""

        guard currentVersion != lastVersionPrompted else {
            return false
        }

        // 4. App-level throttle: at least N days since last request
        if let lastRequest = defaults.object(forKey: AppStorageKeys.lastReviewRequestDate) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents(
                [.day], from: lastRequest, to: Date()
            ).day ?? 0

            guard daysSinceLastRequest >= Self.minimumDaysBetweenRequests else {
                return false
            }
        }

        return true
    }

    /// Records that a review request was shown.
    func recordReviewRequest() {
        defaults.set(Date(), forKey: AppStorageKeys.lastReviewRequestDate)

        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        defaults.set(currentVersion, forKey: AppStorageKeys.lastVersionPromptedForReview)
    }
}
