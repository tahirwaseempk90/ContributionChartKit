import XCTest

/// The chart adapting to different frames, containers, and orientations.
final class ResponsiveUITests: ExampleUITestCase {
    func testDifferentChartSizesRender() {
        let app = launch(scenario: "responsiveLayout")
        let compact = require("chart.responsive.compact", in: app).frame
        let small = require("chart.responsive.small", in: app).frame
        let wide = require("chart.responsive.wide", in: app).frame
        let tall = require("chart.responsive.tall", in: app).frame

        XCTAssertLessThan(compact.width, small.width)
        XCTAssertLessThan(compact.height, small.height)
        XCTAssertGreaterThan(wide.width, small.width)
        XCTAssertGreaterThan(tall.height, wide.height)
    }

    func testPointsStayInsideEachFrame() {
        let app = launch(scenario: "responsiveLayout")
        for size in ["compact", "small", "wide", "tall"] {
            let frame = require("chart.responsive.\(size)", in: app).frame
            for point in ["VFIAX", "VTNIX", "VTSAX"] {
                let pointFrame = require("chart.responsive.\(size).point.\(point)", in: app).frame
                XCTAssertTrue(
                    frame.insetBy(dx: -1, dy: -1).contains(pointFrame),
                    "\(point) \(pointFrame) escapes the \(size) chart \(frame)"
                )
            }
        }
    }

    func testChartFillsAnHStack() {
        let app = launch(scenario: "responsiveLayout")
        let left = require("chart.responsive.hstack.left", in: app).frame
        let right = require("chart.responsive.hstack.right", in: app).frame
        XCTAssertEqual(left.width, right.width, accuracy: 2)
        XCTAssertLessThan(left.maxX, right.minX + 1)
    }

    func testChartFillsAGrid() {
        let app = launch(scenario: "responsiveLayout")
        let first = require("chart.responsive.grid.a", in: app).frame
        let second = require("chart.responsive.grid.b", in: app).frame
        XCTAssertEqual(first.width, second.width, accuracy: 2)
        XCTAssertEqual(first.height, second.height, accuracy: 2)
    }

    /// A list row gives no height, which is where a chart built on `GeometryReader` collapses.
    func testChartInAListChoosesASensibleHeight() {
        let app = launch(scenario: "responsiveLayout")
        scrollIntoView(element("chart.responsive.list", in: app), in: app)
        let frame = require("chart.responsive.list", in: app).frame
        XCTAssertGreaterThan(frame.height, 100)
        XCTAssertLessThan(frame.height, 600)
    }

    func testDenseChartInAHorizontalScrollViewIsWiderThanTheScreen() {
        let app = launch(scenario: "responsiveLayout")
        let chart = require("chart.responsive.horizontal-scroll", in: app).frame
        XCTAssertGreaterThan(chart.width, app.windows.firstMatch.frame.width)
    }

    func testResizingTheFrameResizesTheChart() {
        let app = launch(scenario: "responsiveLayout")
        let chart = require("chart.responsive.resizable", in: app)
        let before = chart.frame.width
        require("responsive.width", in: app).adjust(toNormalizedSliderPosition: 0.05)
        let narrower = NSPredicate { _, _ in chart.frame.width < before - 10 }
        let result = XCTWaiter.wait(for: [expectation(for: narrower, evaluatedWith: nil)], timeout: timeout)
        XCTAssertEqual(result, .completed)
        require("chart.responsive.resizable.point.Tech", in: app)
    }

    func testShrinkingTheHeightKeepsPointsReachable() {
        let app = launch(scenario: "responsiveLayout")
        let chart = require("chart.responsive.resizable", in: app)
        let before = chart.frame.height
        require("responsive.height", in: app).adjust(toNormalizedSliderPosition: 0)
        let shorter = NSPredicate { _, _ in chart.frame.height < before - 10 }
        let result = XCTWaiter.wait(for: [expectation(for: shorter, evaluatedWith: nil)], timeout: timeout)
        XCTAssertEqual(result, .completed)
        // The labels are gone at this size, but VoiceOver can still reach every value.
        XCTAssertEqual(require("chart.responsive.resizable.point.Tech", in: app).value as? String, "Positive, 9.70%")
    }

    func testChartWorksInASheet() {
        let app = launch(scenario: "responsiveLayout")
        scrollIntoView(element("responsive.sheet", in: app), in: app)
        press(element("responsive.sheet", in: app))
        require("chart.responsive.sheet.point.Tech", in: app)
        press(element("responsive.sheet.done", in: app))
    }

    #if os(iOS)
    func testChartAdaptsToRotation() {
        XCUIDevice.shared.orientation = .portrait
        let app = launch(scenario: "reference")
        let chart = require("chart.reference", in: app)
        let portrait = chart.frame.width
        attachScreenshot(named: "reference-portrait")

        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock { @MainActor in XCUIDevice.shared.orientation = .portrait }
        let wider = NSPredicate { _, _ in chart.frame.width > portrait + 10 }
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: wider, evaluatedWith: nil)], timeout: timeout), .completed)
        require("chart.reference.point.period-30", in: app)
        attachScreenshot(named: "reference-landscape")
    }
    #endif
}
