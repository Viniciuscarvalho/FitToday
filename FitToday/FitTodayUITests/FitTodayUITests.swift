//
//  FitTodayUITests.swift
//  FitTodayUITests
//
//  Created by Vinicius Carvalho on 03/01/26.
//

import XCTest

final class FitTodayUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testTabNavigationExists() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Programas"].exists)
        XCTAssertTrue(app.tabBars.buttons["Histórico"].exists)
        XCTAssertTrue(app.tabBars.buttons["Perfil"].exists)
    }

    @MainActor
    func testLaunchWithStoreKitConfiguration() throws {
        let app = XCUIApplication()
        if let path = Bundle.main.path(forResource: "Configuration", ofType: "storekit") {
            app.launchEnvironment["SKStoreKitConfigurationFile"] = path
        }
        app.launch()
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }
}
