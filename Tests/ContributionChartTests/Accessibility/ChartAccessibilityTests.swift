import Accessibility
import XCTest
@testable import ContributionChart

final class ChartAccessibilityDescriberTests: XCTestCase {
    private let formatter = ChartValueFormatter.percent(locale: Locale(identifier: "en_US"))

    private func summary(_ values: [Double], title: String? = nil) -> ChartAccessibilitySummary {
        ChartAccessibilityDescriber.summary(for: ChartDataset(points: Fixtures.points(values)), title: title)
    }

    private func text(_ values: [Double], options: ChartAccessibilityOptions = .init()) -> String {
        ChartAccessibilityDescriber.summaryText(for: summary(values), options: options, formatter: formatter)
    }

    // MARK: - Chart label

    func testLabelPrefersCustomThenTitleThenGenericName() {
        XCTAssertEqual(
            ChartAccessibilityDescriber.chartLabel(title: "Title", options: .init(label: "Custom")),
            "Custom"
        )
        XCTAssertEqual(ChartAccessibilityDescriber.chartLabel(title: "Title", options: .init()), "Title")
        XCTAssertEqual(ChartAccessibilityDescriber.chartLabel(title: nil, options: .init()), "Contribution chart")
    }

    // MARK: - Facts

    func testSummaryCountsEachKindOfValue() {
        let facts = summary([1, 2, -1, 0, .nan])
        XCTAssertEqual(facts.pointCount, 4)
        XCTAssertEqual(facts.positiveCount, 2)
        XCTAssertEqual(facts.negativeCount, 1)
        XCTAssertEqual(facts.zeroCount, 1)
        XCTAssertEqual(facts.invalidCount, 1)
    }

    func testSummaryFindsTheLargestValues() {
        let facts = summary([1, 5, -2, -9, 3])
        XCTAssertEqual(facts.largestPositive?.value, 5)
        XCTAssertEqual(facts.largestNegative?.value, -9)
    }

    func testSummaryHasNoLargestValueForAMissingSide() {
        let facts = summary([1, 2])
        XCTAssertNil(facts.largestNegative)
        XCTAssertNil(summary([-1]).largestPositive)
        XCTAssertNil(summary([0]).largestPositive)
    }

    func testSummaryCarriesTheTitle() {
        XCTAssertEqual(summary([1], title: "T").title, "T")
    }

    // MARK: - Wording

    func testSummaryTextForTheReferenceData() {
        let text = ChartAccessibilityDescriber.summaryText(
            for: ChartAccessibilityDescriber.summary(for: ChartDataset(points: Fixtures.contributors), title: nil),
            options: .init(),
            formatter: formatter
        )
        XCTAssertEqual(
            text,
            "3 data points: 2 contributors and 1 detractor. "
                + "Largest contributor: VFIAX, 11.05%. Largest detractor: VTSAX, -2.70%."
        )
    }

    func testSingularWording() {
        XCTAssertEqual(text([1]), "1 data point: 1 contributor. Largest contributor: P0, 1.00%.")
    }

    func testPluralDetractors() {
        XCTAssertTrue(text([-1, -2]).hasPrefix("2 data points: 2 detractors."))
    }

    func testAllThreeKindsAreListed() {
        XCTAssertTrue(text([1, -1, 0]).hasPrefix("3 data points: 1 contributor, 1 detractor and 1 unchanged."))
    }

    func testAllZeroWording() {
        XCTAssertEqual(text([0, 0]), "2 data points: 2 unchanged.")
    }

    func testNoValidValuesWording() {
        XCTAssertEqual(text([.nan]), "0 data points. 1 invalid value not shown.")
    }

    func testInvalidValuesArePluralized() {
        XCTAssertTrue(text([.nan, .infinity, 1]).hasSuffix("2 invalid values not shown."))
    }

    func testCustomSummaryReplacesTheDefault() {
        let options = ChartAccessibilityOptions(summary: { "\($0.pointCount) valores" })
        XCTAssertEqual(text([1, 2], options: options), "2 valores")
    }

    // MARK: - Points

    /// Direction must be stated in words, never left to colour or an arrow.
    func testPointValueStatesDirection() {
        XCTAssertEqual(
            ChartAccessibilityDescriber.pointValue(
                for: ChartDataPoint(title: "", value: 1),
                formattedValue: "1%",
                options: .init()
            ),
            "Positive, 1%"
        )
        XCTAssertEqual(
            ChartAccessibilityDescriber.pointValue(
                for: ChartDataPoint(title: "", value: -1),
                formattedValue: "-1%",
                options: .init()
            ),
            "Negative, -1%"
        )
        XCTAssertEqual(
            ChartAccessibilityDescriber.pointValue(
                for: ChartDataPoint(title: "", value: 0),
                formattedValue: "0%",
                options: .init()
            ),
            "Zero, 0%"
        )
    }

    func testCustomPointValueReplacesTheDefault() {
        let options = ChartAccessibilityOptions(pointValue: { point, formatted in "\(point.title): \(formatted)" })
        XCTAssertEqual(
            ChartAccessibilityDescriber.pointValue(
                for: ChartDataPoint(title: "A", value: 1),
                formattedValue: "1%",
                options: options
            ),
            "A: 1%"
        )
    }

    func testModelUsesTheSpokenValueWithoutTheArrow() {
        let model = ChartModel(
            points: Fixtures.contributors,
            title: nil,
            configuration: ChartConfiguration(valueFormatter: formatter)
        )
        XCTAssertEqual(model.prominentPoints.map(\.accessibilityValue), [
            "Positive, 11.05%", "Positive, 6.31%", "Negative, -2.70%"
        ])
    }
}

final class ChartAudioGraphDescriptorTests: XCTestCase {
    private func descriptor(
        _ points: [ChartDataPoint],
        options: ChartAccessibilityOptions = ChartAccessibilityOptions()
    ) -> AXChartDescriptor {
        let dataset = ChartDataset(points: points)
        return ChartAudioGraphDescriptor(
            title: "Title",
            summary: "Summary",
            dataset: dataset,
            scale: ChartScale(lower: -20, upper: 30),
            tickValues: [-20, 0, 30],
            formatter: .percent(locale: Locale(identifier: "en_US")),
            options: options
        )
        .makeChartDescriptor()
    }

    func testDescribesTheChart() {
        let chart = descriptor(Fixtures.contributors)
        XCTAssertEqual(chart.title, "Title")
        XCTAssertEqual(chart.summary, "Summary")
    }

    /// Dense charts rely on this: every point must be included, not just the labelled ones.
    func testIncludesEveryPoint() {
        let chart = descriptor(Fixtures.dense(1000))
        XCTAssertEqual(chart.series.first?.dataPoints.count, 1000)
    }

    func testDataPointsCarryValuesAndLabels() throws {
        let series = try XCTUnwrap(descriptor(Fixtures.contributors).series.first)
        XCTAssertEqual(series.dataPoints.compactMap(\.yValue).map(\.__number), [11.05, 6.31, -2.70])
        XCTAssertEqual(series.dataPoints.map(\.label), ["VFIAX", "VTNIX", "VTSAX"])
        XCTAssertFalse(series.isContinuous)
    }

    func testYAxisUsesTheScaleAndFormatter() throws {
        let axis = try XCTUnwrap(descriptor(Fixtures.contributors).yAxis)
        XCTAssertEqual(axis.range, -20...30)
        XCTAssertEqual(axis.gridlinePositions, [-20, 0, 30])
        XCTAssertEqual(axis.valueDescriptionProvider(11.05), "11.05%")
    }

    /// VoiceOver reads these aloud, so they must be the names users see, not internal identifiers.
    func testCategoriesAreTitlesRatherThanIdentifiers() throws {
        let points = [ChartDataPoint(id: "item-1", title: "First", value: 1), ChartDataPoint(id: "item-2", title: "Second", value: 2)]
        let axis = try XCTUnwrap(descriptor(points).xAxis as? AXCategoricalDataAxisDescriptor)
        XCTAssertEqual(axis.categoryOrder, ["First", "Second"])
    }

    func testRepeatedTitlesKeepSeparateCategories() throws {
        let points = [
            ChartDataPoint(id: "a", title: "Same", value: 1),
            ChartDataPoint(id: "b", title: "Same", value: 2),
            ChartDataPoint(id: "c", title: "Other", value: 3)
        ]
        let axis = try XCTUnwrap(descriptor(points).xAxis as? AXCategoricalDataAxisDescriptor)
        XCTAssertEqual(axis.categoryOrder, ["Same", "Same (2)", "Other"])
    }

    func testAxisTitlesDefaultToEnglish() throws {
        let chart = descriptor(Fixtures.contributors)
        XCTAssertEqual(chart.xAxis.title, "Items")
        XCTAssertEqual(chart.yAxis?.title, "Value")
    }

    func testAxisTitlesCanBeTranslated() throws {
        let options = ChartAccessibilityOptions(categoryAxisTitle: "Elementos", valueAxisTitle: "Valor")
        let chart = descriptor(Fixtures.contributors, options: options)
        XCTAssertEqual(chart.xAxis.title, "Elementos")
        XCTAssertEqual(chart.yAxis?.title, "Valor")
    }
}
