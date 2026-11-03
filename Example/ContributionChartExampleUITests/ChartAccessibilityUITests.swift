import XCTest

/// What assistive technology can reach.
final class ChartAccessibilityUITests: ExampleUITestCase {
    func testSummaryDescribesTheChart() {
        let app = launch(scenario: "reference")
        let summary = require("chart.brief.summary", in: app)
        XCTAssertEqual(summary.label, "Your Biggest Contributors & Detractors")
        XCTAssertEqual(
            summary.value as? String,
            "3 data points: 2 contributors and 1 detractor. "
                + "Largest contributor: VFIAX, 11.05%. Largest detractor: VTSAX, -2.70%."
        )
    }

    /// Without this trait, macOS doesn't expose the element's value, so a point would lose its number.
    func testPointsAreStaticTextElements() {
        let app = launch(scenario: "reference")
        XCTAssertTrue(app.staticTexts["chart.brief.point.VFIAX"].waitForExistence(timeout: timeout))
    }

    func testPointsAreReadInDisplayOrder() {
        let app = launch(scenario: "reference")
        require("chart.brief.point.VFIAX", in: app)
        let chart = element("chart.brief", in: app)
        let identifiers = chart.descendants(matching: .any)
            .allElementsBoundByIndex
            .map(\.identifier)
            .filter { !$0.isEmpty }
        XCTAssertEqual(identifiers, [
            "chart.brief.summary",
            "chart.brief.point.VFIAX",
            "chart.brief.point.VTNIX",
            "chart.brief.point.VTSAX"
        ])
    }

    func testPointsWithHiddenLabelsAreStillReachable() {
        let app = launch(scenario: "reference")
        // The screenshot reproduction hides every label.
        let point = require("chart.reference.point.period-10", in: app)
        XCTAssertEqual(point.label, "Period 10")
        XCTAssertEqual(point.value as? String, "Positive, 23.2")
    }

    func testDenseChartLimitsIndividualElementsAndSummarizesTheRest() {
        let app = launch(scenario: "edgeCases")
        let summary = require("chart.edge.dense.summary", in: app)
        XCTAssertTrue((summary.value as? String)?.contains("Largest contributor") == true)
    }

    func testCustomWordingIsUsed() {
        let app = launch(scenario: "accessibility")
        let summary = require("chart.accessibility.custom.summary", in: app)
        XCTAssertEqual(summary.label, "Mayores contribuyentes y detractores")
        XCTAssertEqual(summary.value as? String, "3 valores: 2 positivos y 1 negativos.")
        XCTAssertEqual(require("chart.accessibility.custom.point.VTSAX", in: app).value as? String, "Negativo, -2.70%")
    }

    func testAccessibilityScreenControlsWork() {
        let app = launch(scenario: "accessibility")
        require("chart.accessibility.type.summary", in: app)
        require("accessibility.type-size", in: app)
        require("accessibility.rtl", in: app)
    }

    /// Runs the system's own accessibility checks against each main screen.
    func testScreensPassAccessibilityAudit() throws {
        guard #available(iOS 17.0, macOS 14.0, *) else {
            throw XCTSkip("Accessibility audits need iOS 17 or macOS 14.")
        }
        for scenario in ["reference", "mixed", "edgeCases"] {
            let app = launch(scenario: scenario)
            let charts = ["reference": "chart.brief", "mixed": "chart.mixed", "edgeCases": "chart.edge.empty"]
            require(charts[scenario, default: ""], in: app)
            #if os(iOS)
            let audits: XCUIAccessibilityAuditType = [.contrast, .elementDetection, .textClipped, .trait]
            #else
            let audits: XCUIAccessibilityAuditType = [.contrast, .elementDetection]
            #endif
            try app.performAccessibilityAudit(for: audits) { issue in
                // Only the chart is under test here, not the demo app's own controls.
                guard let element = issue.element else { return true }
                #if os(macOS)
                // The chart's elements are transparent, with no text of their own. macOS measures
                // the marks underneath as if they were letters, so this result means nothing.
                // `ChartPaletteTests` checks the contrast of the text that is actually drawn.
                if issue.auditType == .contrast { return true }
                #endif
                return !element.identifier.hasPrefix("chart.")
            }
        }
    }

    #if os(iOS)
    private let largestTextSize = "UICTContentSizeCategoryAccessibilityXXXL"

    // MARK: - What VoiceOver reads

    /// The lines VoiceOver would read, from the app's walk of the real accessibility tree.
    private func voiceOverLines(
        scenario: String,
        in app: XCUIApplication? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [String] {
        let app = app ?? launch(scenario: scenario, arguments: ["-exposeVoiceOverTree", "YES"])
        let probe = require("voiceover.tree", in: app, file: file, line: line)
        let populated = NSPredicate(format: "label != ''")
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation(for: populated, evaluatedWith: probe)], timeout: timeout),
            .completed,
            "The app should publish its accessibility tree",
            file: file,
            line: line
        )
        return probe.label.components(separatedBy: "\n")
    }

    /// The title leads as a heading and each value is heard once, in display order.
    func testVoiceOverReadsTheTitleThenEachPointOnce() throws {
        let lines = voiceOverLines(scenario: "reference")
        let first = try XCTUnwrap(lines.firstIndex { $0.hasPrefix("[heading] Your Biggest Contributors") })
        XCTAssertTrue(lines[first].contains("2 contributors and 1 detractor"))
        XCTAssertEqual(Array(lines[(first + 1)...(first + 3)]), [
            "VFIAX | Positive, 11.05%",
            "VTNIX | Positive, 6.31%",
            "VTSAX | Negative, -2.70%"
        ])
    }

    func testVoiceOverDoesNotReadTheVisibleLabelsAsWell() {
        let lines = voiceOverLines(scenario: "reference")
        XCTAssertEqual(lines.filter { $0.hasPrefix("VFIAX") }.count, 1, "\(lines)")
        let hasArrow = lines.contains { $0.contains("↑") || $0.contains("↓") }
        XCTAssertFalse(hasArrow, "Direction should be spoken in words: \(lines)")
    }

    func testVoiceOverDoesNotReadTheAxis() {
        let lines = voiceOverLines(scenario: "reference")
        for tick in ["30", "20", "10", "0", "-10", "-20"] {
            XCTAssertFalse(lines.contains(tick), "Tick label \(tick) should not be read: \(lines)")
        }
    }

    /// A chart this small has no room for labels, but VoiceOver users must not lose anything.
    func testVoiceOverReadsPointsWhoseLabelsDoNotFit() {
        let lines = voiceOverLines(scenario: "responsiveLayout")
        // The compact, small, wide, and tall frames all show the same three points.
        XCTAssertGreaterThanOrEqual(lines.filter { $0 == "VFIAX | Positive, 11.05%" }.count, 4, "\(lines)")
    }

    func testVoiceOverLimitsElementsInADenseChart() {
        let app = launch(scenario: "edgeCases", arguments: ["-exposeVoiceOverTree", "YES"])
        let items = voiceOverLines(scenario: "edgeCases", in: app).filter { $0.hasPrefix("Item ") }
        XCTAssertEqual(items.count, 100, "Each of the 100 points has an element at this density")
    }

    func testVoiceOverReadsTheEmptyState() {
        let lines = voiceOverLines(scenario: "edgeCases")
        XCTAssertTrue(lines.contains("[heading] Nothing yet"), "\(lines)")
        XCTAssertTrue(lines.contains("No data available"), "\(lines)")
    }

    // MARK: - Dynamic Type

    func testLargestAccessibilityTextDoesNotBreakTheScreen() {
        let app = launch(
            scenario: "reference",
            arguments: ["-UIPreferredContentSizeCategoryName", largestTextSize]
        )
        let chart = require("chart.brief", in: app)
        let window = app.windows.firstMatch.frame
        XCTAssertLessThanOrEqual(chart.frame.width, window.width)
        require("chart.brief.point.VFIAX", in: app)
        require("chart.brief.point.VTSAX", in: app)
        attachScreenshot(named: "dynamic-type-axxxl-reference")
    }

    func testAccessibilityTextGrowsAChartWithNoFixedHeight() {
        func height(arguments: [String]) -> CGFloat {
            let app = launch(scenario: "accessibility", arguments: arguments)
            let height = require("chart.accessibility.type", in: app).frame.height
            app.terminate()
            return height
        }
        let regular = height(arguments: [])
        let large = height(arguments: ["-UIPreferredContentSizeCategoryName", largestTextSize])
        // A real margin, because frames far down a page can differ by rounding alone.
        XCTAssertGreaterThan(large, regular + 50)
    }

    func testStepperChangesTheChartsTextSize() {
        let app = launch(scenario: "accessibility")
        let chart = require("chart.accessibility.type", in: app)
        let before = chart.frame.height
        let increase = require("accessibility.type-size", in: app).buttons.element(boundBy: 1)
        for _ in 0..<7 {
            increase.tap()
        }
        let taller = NSPredicate { _, _ in chart.frame.height > before + 50 }
        let result = XCTWaiter.wait(for: [expectation(for: taller, evaluatedWith: nil)], timeout: timeout)
        XCTAssertEqual(result, .completed)
    }

    func testEveryScreenSurvivesLargeText() {
        let scenarios = ["mixed", "positiveOnly", "negativeOnly", "customStyling", "responsiveLayout", "edgeCases"]
        for scenario in scenarios {
            let app = launch(
                scenario: scenario,
                arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
            )
            XCTAssertEqual(app.state, .runningForeground, scenario)
            XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: timeout), scenario)
            app.terminate()
        }
    }

    // MARK: - Right to left

    func testRightToLeftMirrorsTheChart() {
        let app = launch(
            scenario: "reference",
            arguments: ["-AppleTextDirection", "YES", "-NSForceRightToLeftWritingDirection", "YES"]
        )
        let first = require("chart.brief.point.VFIAX", in: app).frame.midX
        let last = require("chart.brief.point.VTSAX", in: app).frame.midX
        XCTAssertGreaterThan(first, last, "The first point should be on the right")
        attachScreenshot(named: "right-to-left")
    }
    #endif
}
