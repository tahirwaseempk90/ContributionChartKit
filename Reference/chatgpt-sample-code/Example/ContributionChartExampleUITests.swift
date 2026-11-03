import XCTest

final class ContributionChartExampleUITests: XCTestCase {
    func testExampleScreenLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Chart Example"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your biggest contributors & detractors"].exists)
    }
}
