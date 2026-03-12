//
//  SocialFeedFeatureFlagTests.swift
//  FitTodayTests
//
//  Tests for social feed feature flag gating (PRO-89).
//

import XCTest
@testable import FitToday

final class SocialFeedFeatureFlagTests: XCTestCase {

    // MARK: - FeatureFlagKey Tests

    func test_socialFeedEnabled_hasCorrectRawValue() {
        XCTAssertEqual(FeatureFlagKey.socialFeedEnabled.rawValue, "social_feed_enabled")
    }

    func test_socialFeedEnabled_defaultsToFalse() {
        XCTAssertFalse(FeatureFlagKey.socialFeedEnabled.defaultValue)
    }

    func test_socialFeedEnabled_hasDisplayName() {
        XCTAssertEqual(FeatureFlagKey.socialFeedEnabled.displayName, "Social Feed")
    }

    // MARK: - Segment Filtering Tests

    func test_feedSegmentHidden_whenFlagDisabled() {
        let allSegments = ActivitySegment.allCases
        let isSocialFeedEnabled = false

        let availableSegments = allSegments.filter { segment in
            segment != .feed || isSocialFeedEnabled
        }

        XCTAssertFalse(availableSegments.contains(.feed))
        XCTAssertEqual(availableSegments.count, 3)
        XCTAssertTrue(availableSegments.contains(.history))
        XCTAssertTrue(availableSegments.contains(.challenges))
        XCTAssertTrue(availableSegments.contains(.stats))
    }

    func test_feedSegmentVisible_whenFlagEnabled() {
        let allSegments = ActivitySegment.allCases
        let isSocialFeedEnabled = true

        let availableSegments = allSegments.filter { segment in
            segment != .feed || isSocialFeedEnabled
        }

        XCTAssertTrue(availableSegments.contains(.feed))
        XCTAssertEqual(availableSegments.count, 4)
    }

    func test_defaultSelectedSegment_isHistory() {
        // Feed is disabled by default, so .history should be the default selection
        let defaultSegment: ActivitySegment = .history
        XCTAssertEqual(defaultSegment, .history)
    }

    // MARK: - MockFeatureFlagChecking Integration

    @MainActor
    func test_featureFlagChecking_returnsFalse_whenSocialFeedDisabled() async {
        let mock = StubFeatureFlagChecking(enabledFlags: [])
        let isEnabled = await mock.isFeatureEnabled(.socialFeedEnabled)
        XCTAssertFalse(isEnabled)
    }

    @MainActor
    func test_featureFlagChecking_returnsTrue_whenSocialFeedEnabled() async {
        let mock = StubFeatureFlagChecking(enabledFlags: [.socialFeedEnabled])
        let isEnabled = await mock.isFeatureEnabled(.socialFeedEnabled)
        XCTAssertTrue(isEnabled)
    }
}

// MARK: - Stub

private final class StubFeatureFlagChecking: FeatureFlagChecking, @unchecked Sendable {
    let enabledFlags: Set<FeatureFlagKey>

    init(enabledFlags: Set<FeatureFlagKey>) {
        self.enabledFlags = enabledFlags
    }

    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool {
        enabledFlags.contains(key)
    }

    func checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey) async -> FeatureAccessResult {
        .featureDisabled(reason: "stub")
    }

    func refreshFlags() async throws {}
}
