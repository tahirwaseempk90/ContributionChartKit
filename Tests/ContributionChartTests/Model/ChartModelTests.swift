import SwiftUI
import XCTest
@testable import ContributionChart

final class ChartModelTests: XCTestCase {
    private func model(
        _ points: [ChartDataPoint] = Fixtures.contributors,
        title: String? = nil,
        _ configure: (inout ChartConfiguration) -> Void = { _ in }
    ) -> ChartModel {
        var configuration = ChartConfiguration()
        configuration.valueFormatter = .percent(locale: Locale(identifier: "en_US"))
        configure(&configuration)
        return ChartModel(points: points, title: title, configuration: configuration)
    }

    func testEmptyTitleIsTreatedAsNoTitle() {
        XCTAssertNil(model(title: "").title)
        XCTAssertNil(model(title: nil).title)
        XCTAssertEqual(model(title: "T").title, "T")
    }

    func testAnnotationValueMatchesTheBrief() {
        let values = model().prominentPoints.map(\.annotationValue)
        XCTAssertEqual(values, ["↑ 11.05%", "↑ 6.31%", "↓ -2.70%"])
    }

    func testZeroValueHasNoIndicatorByDefault() {
        XCTAssertEqual(model(Fixtures.points([0])).prominentPoints.first?.annotationValue, "0.00%")
    }

    func testCustomIndicators() {
        let model = model(Fixtures.points([1, -1, 0])) {
            $0.style.annotation.directionIndicators = .init(positive: "▲", negative: "▼", zero: "•")
        }
        XCTAssertEqual(model.prominentPoints.map(\.annotationValue), ["▲ 1.00%", "▼ -1.00%", "• 0.00%"])
    }

    func testIndicatorsCanBeRemoved() {
        let model = model(Fixtures.points([1, -1])) {
            $0.style.annotation.directionIndicators = .init(positive: nil, negative: "")
        }
        XCTAssertEqual(model.prominentPoints.map(\.annotationValue), ["1.00%", "-1.00%"])
    }

    func testProminentPointsAreCapped() {
        let model = model(Fixtures.dense(1000))
        XCTAssertEqual(model.prominentPoints.count, ChartModel.prominentPointLimit)
        XCTAssertEqual(model.values.count, 1000)
    }

    func testNoTicksWithoutAnAxis() {
        XCTAssertTrue(model().ticks.isEmpty)
    }

    func testAxisProducesFormattedTicks() {
        let model = model(Fixtures.points(Fixtures.editorialValues)) {
            $0.valueAxis = ChartValueAxis(labelFormatter: .number(fractionDigits: 0...0, locale: Locale(identifier: "en_US")))
        }
        XCTAssertEqual(model.ticks.map(\.label), ["-20", "-10", "0", "10", "20", "30"])
        XCTAssertEqual(model.ticks.map(\.ordinal), [-2, -1, 0, 1, 2, 3])
        XCTAssertEqual(model.scale, ChartScale(lower: -20, upper: 30))
    }

    func testTickLabelsAreEmptyWhenHidden() {
        let model = model { $0.valueAxis = ChartValueAxis(showsLabels: false) }
        XCTAssertFalse(model.ticks.isEmpty)
        XCTAssertTrue(model.ticks.allSatisfy { $0.label.isEmpty })
    }

    // MARK: - Axis labels must never print a wrong number

    private let wholeNumbers = ChartValueFormatter.number(fractionDigits: 0...0, locale: Locale(identifier: "en_US"))

    /// Ticks at 2.5 and 7.5 used to round to "2" and "8" with a whole-number formatter.
    func testWholeNumberFormatterGetsWholeNumberTicks() {
        let model = model(Fixtures.points([10, -2])) {
            $0.valueAxis = ChartValueAxis(labelFormatter: self.wholeNumbers)
        }
        XCTAssertEqual(model.ticks.map(\.value), [-5, 0, 5, 10])
        XCTAssertEqual(model.ticks.map(\.label), ["-5", "0", "5", "10"])
    }

    func testTicksWidenUntilTheFormatterCanShowThem() {
        let model = model(Fixtures.points([1, -0.5])) {
            $0.valueAxis = ChartValueAxis(labelFormatter: self.wholeNumbers)
        }
        XCTAssertEqual(model.ticks.map(\.label), ["-1", "0", "1"])
    }

    /// These labels all differ, yet "2" sits at 1.5. The next tick, 2.0, would read the same,
    /// so the check must look past the ticks that are actually on the axis.
    func testRoundedLabelIsCaughtEvenWhenItsTwinIsNotOnTheAxis() {
        let model = model(Fixtures.points([1.5, -0.5])) {
            $0.valueAxis = ChartValueAxis(labelFormatter: self.wholeNumbers)
        }
        XCTAssertEqual(model.ticks.map(\.value), [-1, 0, 1, 2])
        XCTAssertEqual(model.ticks.map(\.label), ["-1", "0", "1", "2"])
    }

    /// The built-in formatter won't round a small value to nothing, so these remain truthful.
    func testSmallTicksStayTruthfulWithAWholeNumberFormatter() {
        let model = model(Fixtures.points([0.4, -0.2])) {
            $0.valueAxis = ChartValueAxis(labelFormatter: self.wholeNumbers)
        }
        XCTAssertEqual(model.ticks.map(\.label), ["-0.2", "0", "0.2", "0.4"])
    }

    /// With nothing but fractions to show and no decimals to show them with, a wrong number is
    /// worse than none. Widening the scale to reach a whole number would flatten the data instead.
    func testOnlyZeroIsLabelledWhenTheFormatterCannotShowAnyOtherTick() {
        let model = model(Fixtures.points([0.4, -0.2])) {
            $0.valueAxis = ChartValueAxis(labelFormatter: ChartValueFormatter { String(format: "%.0f", $0) })
        }
        XCTAssertEqual(model.ticks.map(\.label), ["0"])
        XCTAssertEqual(model.scale.upper, 0.4, accuracy: 0.0001, "The data should still fill the chart")
    }

    func testAFormatterThatRepeatsItselfCannotWidenTheScale() {
        let model = model(Fixtures.points([10, -2])) {
            $0.valueAxis = ChartValueAxis(labelFormatter: ChartValueFormatter { _ in "same" })
        }
        XCTAssertEqual(model.ticks.map(\.label), ["same"])
        XCTAssertLessThanOrEqual(model.scale.upper, 15)
    }

    func testHiddenLabelsDoNotAffectTickSpacing() {
        let model = model(Fixtures.points([1, -0.5])) {
            $0.valueAxis = ChartValueAxis(showsLabels: false, labelFormatter: self.wholeNumbers)
        }
        XCTAssertGreaterThan(model.ticks.count, 3)
    }

    func testFixedScaleKeepsItsRangeWhileWideningTicks() {
        let model = model(Fixtures.points([1])) {
            $0.scale = .fixed(lower: -1.5, upper: 1.5)
            $0.valueAxis = ChartValueAxis(labelFormatter: self.wholeNumbers)
        }
        XCTAssertEqual(model.scale, ChartScale(lower: -1.5, upper: 1.5))
        XCTAssertEqual(Set(model.ticks.map(\.label)).count, model.ticks.count)
    }

    /// Small values used to print the top two gridlines as the same "0.01".
    func testDefaultAxisLabelsAlwaysShowEnoughDigits() {
        for values in [[0.012, 0.004], [0.5, -0.25], [1.2, 0.3], [0.0012, -0.0003], [12, -3], [1200, -300]] {
            let model = model(Fixtures.points(values)) { $0.valueAxis = ChartValueAxis() }
            let labels = model.ticks.map(\.label)
            XCTAssertGreaterThan(labels.count, 2, "\(values)")
            XCTAssertEqual(Set(labels).count, labels.count, "\(values) gave \(labels)")
        }
    }

    func testDefaultAxisLabelsShowExactValues() {
        let model = model(Fixtures.points([0.012, 0.004])) { $0.valueAxis = ChartValueAxis() }
        let exact = ChartValueFormatter.number(fractionDigits: 0...3)
        XCTAssertEqual(model.ticks.map(\.label), model.ticks.map { exact.string(for: $0.value) })
    }

    // MARK: - Reference lines

    private let line = ChartLineStyle(color: .red)

    /// A line that isn't drawn used to stretch the scale, squashing the data for no visible reason.
    func testReferenceLineOverNoPointsDoesNotAffectTheScale() {
        let model = model(Fixtures.points([1, 2])) {
            $0.referenceLines = [ChartReferenceLine(value: 40, points: 7...9, style: self.line)]
        }
        XCTAssertEqual(model.scale.upper, 2)
    }

    func testReferenceLineExtendsTheAutomaticScale() {
        let target = ChartReferenceLine(value: 40, style: line)
        let model = model(Fixtures.points([10, -5])) { $0.referenceLines = [target] }
        XCTAssertEqual(model.scale.upper, 40)
        XCTAssertEqual(model.referenceLines.count, 1)
    }

    func testReferenceLineOutsideAFixedScaleIsLeftOut() {
        let target = ChartReferenceLine(value: 40, style: line)
        let model = model {
            $0.scale = .fixed(lower: -10, upper: 10)
            $0.referenceLines = [target]
        }
        XCTAssertEqual(model.scale.upper, 10)
        XCTAssertTrue(model.referenceLines.isEmpty)
    }

    func testInvalidOrHiddenReferenceLinesAreLeftOut() {
        let model = model(Fixtures.points([1])) {
            $0.referenceLines = [
                ChartReferenceLine(value: .nan, style: line),
                ChartReferenceLine(value: 2, style: ChartLineStyle(isVisible: false, color: .red))
            ]
        }
        XCTAssertTrue(model.referenceLines.isEmpty)
        XCTAssertEqual(model.scale.upper, 1)
    }

    func testReferenceLinePositionsMapPastInvalidPoints() {
        let model = model(Fixtures.points([1, .nan, 2, 3])) {
            $0.referenceLines = [ChartReferenceLine(value: 1, points: 2...3, style: line)]
        }
        XCTAssertEqual(model.referenceLines.first?.positions, 1...2)
    }

    func testReferenceLineOverNoPointsIsLeftOut() {
        let model = model(Fixtures.points([1, 2])) {
            $0.referenceLines = [ChartReferenceLine(value: 1, points: 7...9, style: line)]
        }
        XCTAssertTrue(model.referenceLines.isEmpty)
    }

    // MARK: - Regions and category ticks

    func testRegionsAndTicksOverNoPointsAreLeftOut() {
        let model = model(Fixtures.points([1, 2])) {
            $0.regions = [ChartRegion(points: 5...9, color: .red), ChartRegion(points: 0...1, color: .blue)]
            $0.categoryTicks = ChartCategoryTicks(points: [1, 7])
        }
        XCTAssertEqual(model.regions.map(\.positions), [0...1])
        XCTAssertEqual(model.categoryTickPositions, [1])
    }
}
