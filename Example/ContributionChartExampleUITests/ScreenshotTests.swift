import XCTest

/// Captures every screen for visual review. The attachments are kept in the test result bundle,
/// where `Scripts/export-screenshots.py` can collect them.
final class ScreenshotTests: ExampleUITestCase {
    private let scenarios = [
        "reference", "mixed", "positiveOnly", "negativeOnly",
        "customStyling", "responsiveLayout", "edgeCases", "accessibility"
    ]

    func testCaptureEveryScenarioInLightAppearance() {
        for scenario in scenarios {
            let app = launch(scenario: scenario, appearance: "light")
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            attachScreenshot(named: "\(scenario)-light", of: app)
            app.terminate()
        }
    }

    func testCaptureEveryScenarioInDarkAppearance() {
        for scenario in scenarios {
            let app = launch(scenario: scenario, appearance: "dark")
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            attachScreenshot(named: "\(scenario)-dark", of: app)
            app.terminate()
        }
    }
}
