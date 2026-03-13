//
//  XPLevelTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

final class XPLevelTests: XCTestCase {

    func test_initWithLevel_mapsToCorrectTitle() {
        XCTAssertEqual(XPLevel(level: 1), .iniciante)
        XCTAssertEqual(XPLevel(level: 4), .iniciante)
        XCTAssertEqual(XPLevel(level: 5), .guerreiro)
        XCTAssertEqual(XPLevel(level: 9), .guerreiro)
        XCTAssertEqual(XPLevel(level: 10), .tita)
        XCTAssertEqual(XPLevel(level: 14), .tita)
        XCTAssertEqual(XPLevel(level: 15), .lenda)
        XCTAssertEqual(XPLevel(level: 19), .lenda)
        XCTAssertEqual(XPLevel(level: 20), .imortal)
        XCTAssertEqual(XPLevel(level: 50), .imortal)
    }

    func test_icon_returnsCorrectSFSymbol() {
        XCTAssertEqual(XPLevel.iniciante.icon, "star")
        XCTAssertEqual(XPLevel.guerreiro.icon, "shield.fill")
        XCTAssertEqual(XPLevel.tita.icon, "bolt.fill")
        XCTAssertEqual(XPLevel.lenda.icon, "crown.fill")
        XCTAssertEqual(XPLevel.imortal.icon, "flame.fill")
    }

    func test_rawValue_returnsDisplayName() {
        XCTAssertEqual(XPLevel.iniciante.rawValue, "Iniciante")
        XCTAssertEqual(XPLevel.guerreiro.rawValue, "Guerreiro")
        XCTAssertEqual(XPLevel.tita.rawValue, "Titã")
        XCTAssertEqual(XPLevel.lenda.rawValue, "Lenda")
        XCTAssertEqual(XPLevel.imortal.rawValue, "Imortal")
    }
}
