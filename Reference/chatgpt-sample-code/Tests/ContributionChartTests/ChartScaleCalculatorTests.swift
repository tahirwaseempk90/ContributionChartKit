import XCTest
@testable import ContributionChart

final class ChartScaleCalculatorTests: XCTestCase {
    func testMaximumMagnitudeUsesLargestAbsoluteValue() {
        XCTAssertEqual(ChartScaleCalculator.maximumMagnitude(in: [11.5, -2, 3]), 11.5)
    }

    func testEmptyValuesUseSafeDefault() {
        XCTAssertEqual(ChartScaleCalculator.maximumMagnitude(in: []), 1)
    }

    func testNonFiniteValuesAreIgnored() {
        XCTAssertEqual(ChartScaleCalculator.maximumMagnitude(in: [.nan, .infinity, -4]), 4)
    }

    func testBaselineIsCenteredInUsableHeight() {
        XCTAssertEqual(
            ChartScaleCalculator.baselineY(height: 200, topInset: 20, bottomInset: 20),
            100
        )
    }

    func testPositiveValueAppearsAboveBaseline() {
        let y = ChartScaleCalculator.yPosition(
            value: 5, maximumMagnitude: 10, baselineY: 100, drawableHalfHeight: 80
        )
        XCTAssertLessThan(y, 100)
    }

    func testNegativeValueAppearsBelowBaseline() {
        let y = ChartScaleCalculator.yPosition(
            value: -5, maximumMagnitude: 10, baselineY: 100, drawableHalfHeight: 80
        )
        XCTAssertGreaterThan(y, 100)
    }

    func testScaleClampsOutOfRangeValue() {
        let y = ChartScaleCalculator.yPosition(
            value: 100, maximumMagnitude: 10, baselineY: 100, drawableHalfHeight: 80
        )
        XCTAssertEqual(y, 20)
    }
}
