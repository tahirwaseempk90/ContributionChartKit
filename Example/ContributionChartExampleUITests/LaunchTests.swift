import XCTest

final class LaunchTests: ExampleUITestCase {
    func testApplicationLaunches() {
        let app = launch()
        XCTAssertEqual(app.state, .runningForeground)
        require("scenario.reference", in: app)
    }

    func testEveryScenarioIsListed() {
        let app = launch()
        let scenarios = [
            "reference", "mixed", "positiveOnly", "negativeOnly",
            "customStyling", "responsiveLayout", "edgeCases", "accessibility"
        ]
        for scenario in scenarios {
            require("scenario.\(scenario)", in: app)
        }
    }

    func testTappingAScenarioOpensIt() {
        let app = launch()
        press(require("scenario.mixed", in: app))
        require("chart.mixed", in: app)
    }
}
