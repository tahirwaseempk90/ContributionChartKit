import XCTest

/// The chart's visible behaviour, as seen through the accessibility tree.
final class ChartDisplayTests: ExampleUITestCase {
    // MARK: - Reference chart

    func testChartIsDisplayed() {
        let app = launch(scenario: "reference")
        let chart = require("chart.reference", in: app)
        XCTAssertGreaterThan(chart.frame.width, 100)
        XCTAssertGreaterThan(chart.frame.height, 50)
    }

    func testBothReferenceAppearancesAreOnScreenOne() {
        let app = launch(scenario: "reference")
        require("chart.reference.point.period-1", in: app)
        require("chart.labelled.point.VFIAX", in: app)
    }

    func testEditorialChartHasEveryPoint() {
        let app = launch(scenario: "reference")
        for period in 1...30 {
            XCTAssertTrue(
                element("chart.reference.point.period-\(period)", in: app).waitForExistence(timeout: timeout),
                "Period \(period)"
            )
        }
    }

    // MARK: - Header

    func testHeaderIsDisplayedWhenEnabled() {
        let app = launch(scenario: "reference")
        let summary = require("chart.labelled.summary", in: app)
        XCTAssertEqual(summary.label, "Your Biggest Contributors & Detractors")
    }

    func testChartWithoutAHeaderUsesAGenericName() {
        let app = launch(scenario: "reference")
        XCTAssertEqual(require("chart.reference.summary", in: app).label, "Contribution chart")
    }

    // MARK: - Labels

    func testPositiveLabelsAreDiscoverableWithTheirValues() {
        let app = launch(scenario: "reference")
        let first = require("chart.labelled.point.VFIAX", in: app)
        XCTAssertEqual(first.label, "VFIAX")
        XCTAssertEqual(first.value as? String, "Positive, 11.05%")
        let second = require("chart.labelled.point.VTNIX", in: app)
        XCTAssertEqual(second.label, "VTNIX")
        XCTAssertEqual(second.value as? String, "Positive, 6.31%")
    }

    func testNegativeLabelsAreDiscoverableWithTheirValues() {
        let app = launch(scenario: "reference")
        let point = require("chart.labelled.point.VTSAX", in: app)
        XCTAssertEqual(point.label, "VTSAX")
        XCTAssertEqual(point.value as? String, "Negative, -2.70%")
    }

    func testPositivePointsAreAboveNegativePoints() {
        let app = launch(scenario: "reference")
        let positive = require("chart.labelled.point.VFIAX", in: app)
        let negative = require("chart.labelled.point.VTSAX", in: app)
        XCTAssertLessThan(positive.frame.midY, negative.frame.midY)
    }

    func testPointsRunInOrderAcrossTheChart() {
        let app = launch(scenario: "reference")
        let first = require("chart.labelled.point.VFIAX", in: app).frame.midX
        let second = require("chart.labelled.point.VTNIX", in: app).frame.midX
        let third = require("chart.labelled.point.VTSAX", in: app).frame.midX
        XCTAssertLessThan(first, second)
        XCTAssertLessThan(second, third)
    }

    func testPointsStayInsideTheChart() {
        let app = launch(scenario: "reference")
        let chart = require("chart.labelled", in: app).frame
        for id in ["VFIAX", "VTNIX", "VTSAX"] {
            let point = require("chart.labelled.point.\(id)", in: app).frame
            XCTAssertTrue(chart.contains(point), "\(id) \(point) is outside \(chart)")
        }
    }

    // MARK: - Data shapes

    func testPositiveOnlyScreen() {
        let app = launch(scenario: "positiveOnly")
        for region in ["North", "East", "South", "West"] {
            let point = require("chart.positive.point.\(region)", in: app)
            XCTAssertTrue((point.value as? String)?.hasPrefix("Positive") == true, region)
        }
    }

    func testNegativeOnlyScreen() {
        let app = launch(scenario: "negativeOnly")
        for region in ["North", "East", "South", "West"] {
            let point = require("chart.negative.point.\(region)", in: app)
            XCTAssertTrue((point.value as? String)?.hasPrefix("Negative") == true, region)
        }
    }

    func testMixedScreenShowsBothDirections() {
        let app = launch(scenario: "mixed")
        XCTAssertTrue((require("chart.mixed.point.Tech", in: app).value as? String)?.hasPrefix("Positive") == true)
        XCTAssertTrue((require("chart.mixed.point.Retail", in: app).value as? String)?.hasPrefix("Negative") == true)
    }

    // MARK: - Empty and edge states

    func testEmptyStateIsDisplayed() {
        let app = launch(scenario: "edgeCases")
        let empty = require("chart.edge.empty.empty", in: app)
        XCTAssertTrue(empty.exists)
        XCTAssertTrue(app.staticTexts["No data available"].waitForExistence(timeout: timeout))
        require("chart.edge.empty.header", in: app)
    }

    func testCustomEmptyStateIsDisplayed() {
        let app = launch(scenario: "edgeCases")
        require("edge.custom-empty", in: app)
    }

    func testInvalidValuesAreLeftOut() {
        let app = launch(scenario: "edgeCases")
        require("chart.edge.invalid.point.Good", in: app)
        require("chart.edge.invalid.point.Also good", in: app)
        XCTAssertFalse(element("chart.edge.invalid.point.NaN", in: app).exists)
        XCTAssertFalse(element("chart.edge.invalid.point.Infinity", in: app).exists)
    }

    func testInvalidValuesAreReportedToVoiceOver() {
        let app = launch(scenario: "edgeCases")
        let summary = require("chart.edge.invalid.summary", in: app)
        XCTAssertTrue((summary.value as? String)?.contains("3 invalid values not shown") == true)
    }

    func testDuplicateIdentifiersAreBothShown() {
        let app = launch(scenario: "edgeCases")
        XCTAssertEqual(require("chart.edge.duplicates.point.same", in: app).label, "First")
        XCTAssertEqual(require("chart.edge.duplicates.point.same#2", in: app).label, "Second")
    }

    func testZeroValuesAreDescribedAsZero() {
        let app = launch(scenario: "edgeCases")
        let summary = require("chart.edge.zero.summary", in: app)
        XCTAssertTrue((summary.value as? String)?.contains("3 unchanged") == true)
    }

    func testDensePickerChangesTheData() {
        let app = launch(scenario: "edgeCases")
        let summary = require("chart.edge.dense.summary", in: app)
        XCTAssertTrue((summary.value as? String)?.hasPrefix("100 data points") == true)
        scrollIntoView(element("edge.density", in: app), in: app)
        selectSegment("1000", of: element("edge.density", in: app))
        let predicate = NSPredicate(format: "value BEGINSWITH '1000 data points'")
        let result = XCTWaiter.wait(for: [expectation(for: predicate, evaluatedWith: summary)], timeout: timeout)
        XCTAssertEqual(result, .completed)
    }

    // MARK: - Configuration

    func testCustomConfigurationsAreDisplayed() {
        let app = launch(scenario: "customStyling")
        for style in ["ocean", "monochrome", "bars", "markers", "currency", "target", "labels-off"] {
            require("chart.custom.\(style)", in: app)
        }
    }

    func testCustomFormatterIsUsed() {
        let app = launch(scenario: "customStyling")
        let point = require("chart.custom.currency.point.Tech", in: app)
        XCTAssertTrue((point.value as? String)?.contains("$9,700") == true, String(describing: point.value))
    }

    func testChartWithLabelsOffStillExposesItsPoints() {
        let app = launch(scenario: "customStyling")
        XCTAssertEqual(require("chart.custom.labels-off.point.Tech", in: app).label, "Tech")
    }

    func testScaleModesCanBeChanged() {
        let app = launch(scenario: "mixed")
        let picker = require("mixed.scale", in: app)
        let point = require("chart.mixed.point.Tech", in: app)
        let proportional = point.frame.midY
        selectSegment("Fixed ±20", of: picker)
        let lower = NSPredicate { _, _ in point.frame.midY > proportional + 1 }
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation(for: lower, evaluatedWith: nil)], timeout: timeout),
            .completed,
            "A wider scale should bring the point closer to the baseline"
        )
    }

    // MARK: - Appearance

    func testDarkAppearanceRuns() {
        let app = launch(scenario: "reference", appearance: "dark")
        require("chart.labelled.point.VFIAX", in: app)
        attachScreenshot(named: "reference-dark")
    }
}
