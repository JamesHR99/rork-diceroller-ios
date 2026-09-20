//
//  PharaohSWagerUITests.swift
//  PharaohSWagerUITests
//
//  Created by Rork on July 22, 2026.
//

import XCTest

final class PharaohSWagerUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testOpeningMenuAndHeroSelection() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["title.play"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["title.records"].exists)
        app.buttons["title.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
        app.buttons["title.play"].tap()
        for hero in ["archer", "warrior", "rogue", "magician"] {
            XCTAssertTrue(app.buttons["heroSelect.\(hero)"].waitForExistence(timeout: 3))
            app.buttons["heroSelect.\(hero)"].tap()
        }
        app.buttons["heroSelect.back"].tap()
        XCTAssertTrue(app.buttons["title.play"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
