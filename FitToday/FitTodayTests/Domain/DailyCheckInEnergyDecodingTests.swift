//
//  DailyCheckInEnergyDecodingTests.swift
//  FitTodayTests
//
//  Created by AI on 12/01/26.
//

import XCTest
@testable import FitToday

final class DailyCheckInEnergyDecodingTests: XCTestCase {
    func testDecodingOldCheckInWithoutEnergyDefaultsToFive() throws {
        // Given: JSON antigo sem energyLevel
        let json = """
        {
          "focus": "upper",
          "sorenessLevel": "none",
          "sorenessAreas": [],
          "createdAt": "2026-01-12T10:00:00Z"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        
        // When
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyCheckIn.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.energyLevel, 5)
    }
}

