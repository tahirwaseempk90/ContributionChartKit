import SwiftUI
import XCTest
@testable import ContributionChart

final class ChartLayoutEngineTests: XCTestCase {
    private let size = CGSize(width: 400, height: 300)
    private let measurer = StubMeasurer()

    private func layout(
        _ points: [ChartDataPoint] = Fixtures.contributors,
        title: String? = nil,
        in size: CGSize? = nil,
        measurer: StubMeasurer? = nil,
        configure: (inout ChartConfiguration) -> Void = { _ in }
    ) -> ChartLayoutResult {
        var configuration = ChartConfiguration()
        configure(&configuration)
        return makeEngine(points, title: title, configuration: configuration)
            .layout(in: size ?? self.size, measuring: measurer ?? self.measurer)
    }

    // MARK: - Degenerate input

    func testEmptyDataProducesAnEmptyLayout() {
        let result = layout([])
        XCTAssertTrue(result.marks.isEmpty)
        XCTAssertEqual(result.marksFrame, .zero)
    }

    func testInvalidSizesProduceAnEmptyLayout() {
        let sizes = [
            CGSize.zero,
            CGSize(width: 0, height: 100),
            CGSize(width: 100, height: 0),
            CGSize(width: -10, height: -10),
            CGSize(width: CGFloat.nan, height: 100),
            CGSize(width: 100, height: CGFloat.nan),
            CGSize(width: CGFloat.infinity, height: 100),
            CGSize(width: 100, height: CGFloat.infinity)
        ]
        for size in sizes {
            let result = layout(in: size)
            XCTAssertTrue(result.marks.isEmpty, "\(size)")
            assertGeometryIsValid(result, context: "\(size)")
        }
    }

    func testInsetsLargerThanTheChartProduceAnEmptyLayout() {
        let result = layout { $0.layout.insets = EdgeInsets(top: 500, leading: 500, bottom: 500, trailing: 500) }
        XCTAssertTrue(result.marks.isEmpty)
    }

    func testOnePointIsCentered() {
        let result = layout([ChartDataPoint(title: "A", value: 1)])
        XCTAssertEqual(result.marks.count, 1)
        XCTAssertEqual(result.marks[0].center.x, 200)
    }

    func testTwoPointsAreSymmetric() {
        let result = layout(Fixtures.points([1, -1]))
        XCTAssertEqual(result.marks[0].center.x, 400 - result.marks[1].center.x, accuracy: 0.5)
    }

    // MARK: - Size negotiation

    func testFiniteProposalsAreHonoured() {
        let engine = makeEngine(Fixtures.contributors)
        let size = engine.size(for: ProposedViewSize(width: 123, height: 45), measuring: measurer)
        XCTAssertEqual(size, CGSize(width: 123, height: 45))
    }

    func testZeroProposalIsHonoured() {
        XCTAssertEqual(makeEngine(Fixtures.contributors).size(for: .zero, measuring: measurer), .zero)
    }

    /// A parent asks for the most a view can take by proposing infinity. Answering with a
    /// finite size would make the chart look inflexible to its parent's layout.
    func testInfiniteProposalsAreReturnedSoTheChartIsFlexible() {
        let size = makeEngine(Fixtures.contributors).size(for: .infinity, measuring: measurer)
        XCTAssertEqual(size, CGSize(width: CGFloat.infinity, height: .infinity))
    }

    func testInvalidProposalsBecomeZero() {
        let engine = makeEngine(Fixtures.contributors)
        let size = engine.size(for: ProposedViewSize(width: -5, height: .nan), measuring: measurer)
        XCTAssertEqual(size, .zero)
    }

    func testOpenWidthUsesTheIdealWidth() {
        let size = makeEngine(Fixtures.contributors).size(for: ProposedViewSize(width: nil, height: 100), measuring: measurer)
        XCTAssertEqual(size.width, ChartLayoutOptions().idealWidth)
        XCTAssertEqual(size.height, 100)
    }

    func testIdealWidthIsConfigurable() {
        var configuration = ChartConfiguration()
        configuration.layout.idealWidth = 555
        let size = makeEngine(Fixtures.contributors, configuration: configuration)
            .size(for: .unspecified, measuring: measurer)
        XCTAssertEqual(size.width, 555)
    }

    /// This is what makes a dense chart readable in a horizontal `ScrollView`.
    func testIdealWidthGrowsWithThePointCount() {
        let size = makeEngine(Fixtures.dense(200)).size(for: .unspecified, measuring: measurer)
        XCTAssertGreaterThanOrEqual(size.width, 200 * ChartLayoutOptions().minimumPointSpacing)
    }

    /// The limit is on pixels, so a sharper display gets a narrower chart.
    func testIdealWidthStaysWithinTheCanvasPixelLimit() {
        for displayScale in [CGFloat(1), 2, 3] {
            let size = makeEngine(Fixtures.dense(100_000), displayScale: displayScale)
                .size(for: .unspecified, measuring: measurer)
            XCTAssertEqual(size.width * displayScale, ChartLayoutEngine.maximumIdealPixelWidth, accuracy: 0.001)
        }
    }

    func testOpenHeightFitsThePlotAndLabels() {
        let size = makeEngine(Fixtures.contributors).size(for: ProposedViewSize(width: 400, height: nil), measuring: measurer)
        // Plot of 140, plus above and below it a marker radius of 6, a gap of 4, and a label of 30.
        XCTAssertEqual(size.height, 140 + 40 + 40)
    }

    func testOpenHeightIncludesTheTitleAndInsets() {
        var configuration = ChartConfiguration()
        configuration.layout.insets = EdgeInsets(top: 10, leading: 0, bottom: 5, trailing: 0)
        let size = makeEngine(Fixtures.contributors, title: "Title", configuration: configuration)
            .size(for: ProposedViewSize(width: 400, height: nil), measuring: measurer)
        XCTAssertEqual(size.height, 220 + 20 + 12 + 15)
    }

    /// Dynamic Type: a chart in a `ScrollView` grows to fit larger text.
    func testOpenHeightGrowsWithLargerText() {
        var large = StubMeasurer()
        large.annotation = CGSize(width: 50, height: 90)
        let engine = makeEngine(Fixtures.contributors)
        let regular = engine.size(for: ProposedViewSize(width: 400, height: nil), measuring: measurer)
        let grown = engine.size(for: ProposedViewSize(width: 400, height: nil), measuring: large)
        XCTAssertEqual(grown.height - regular.height, 120)
    }

    /// The chart's own ideal size must not fall below its own minimum, or it would lose its
    /// labels for no reason in a `ScrollView`.
    func testIdealHeightIsEnoughToKeepLabelsWhenTheIdealPlotIsBelowTheMinimum() {
        var configuration = ChartConfiguration()
        configuration.layout.idealPlotHeight = 20
        configuration.layout.minimumPlotHeight = 32
        let engine = makeEngine(Fixtures.contributors, configuration: configuration)
        let size = engine.size(for: ProposedViewSize(width: 400, height: nil), measuring: measurer)
        XCTAssertEqual(size.height, 32 + 40 + 40)
        XCTAssertEqual(engine.layout(in: size, measuring: measurer).annotations.count, 3)
    }

    func testOpenHeightOnlyReservesTheSidesInUse() {
        let positive = makeEngine(Fixtures.points([1, 2])).size(for: ProposedViewSize(width: 400, height: nil), measuring: measurer)
        // Label space above, and only a marker radius below.
        XCTAssertEqual(positive.height, 140 + 40 + 6)
    }

    func testOpenHeightWithInfiniteWidthIsFinite() {
        let size = makeEngine(Fixtures.contributors).size(for: ProposedViewSize(width: .infinity, height: nil), measuring: measurer)
        XCTAssertTrue(size.height.isFinite)
    }

    func testOpenHeightWithoutDataIsThePlotAndMarkMargins() {
        let size = makeEngine([]).size(for: ProposedViewSize(width: 400, height: nil), measuring: measurer)
        XCTAssertEqual(size.height, 140 + 6 + 6)
    }

    // MARK: - Title

    func testTitleSitsAtTheTop() {
        let result = layout(title: "Title")
        XCTAssertEqual(result.headerFrame, CGRect(x: 0, y: 0, width: 400, height: 20))
    }

    func testNoTitleTakesNoSpace() {
        XCTAssertEqual(layout().headerFrame, .zero)
    }

    func testPlotStartsBelowTheTitle() {
        let result = layout(title: "Title")
        let highest = result.annotations.map(\.frame.minY).min() ?? 0
        XCTAssertGreaterThanOrEqual(highest, 20 + ChartStyle.HeaderStyle().spacing)
    }

    func testTitleCanBeEmpty() {
        XCTAssertEqual(layout(title: "").headerFrame, .zero)
    }

    // MARK: - Scale modes

    func testProportionalBaselineFollowsTheData() {
        let result = layout(Fixtures.points([30, -10]))
        let plot = result.plotFrame
        XCTAssertEqual(result.baselineFrame.midY, plot.minY + plot.height * 0.75, accuracy: 0.5)
    }

    func testSymmetricBaselineIsCentered() {
        let result = layout(Fixtures.points([30, -10])) { $0.scale = .symmetric }
        XCTAssertEqual(result.baselineFrame.midY, result.plotFrame.midY, accuracy: 0.5)
    }

    func testAllPositiveBaselineIsAtTheBottomOfThePlot() {
        let result = layout(Fixtures.points([1, 2]))
        XCTAssertEqual(result.baselineFrame.midY, result.plotFrame.maxY, accuracy: 0.5)
    }

    func testAllNegativeBaselineIsAtTheTopOfThePlot() {
        let result = layout(Fixtures.points([-1, -2]))
        XCTAssertEqual(result.baselineFrame.midY, result.plotFrame.minY, accuracy: 0.5)
    }

    func testAllZeroBaselineIsCentered() {
        let result = layout(Fixtures.points([0, 0]))
        XCTAssertEqual(result.baselineFrame.midY, result.plotFrame.midY, accuracy: 0.5)
        XCTAssertTrue(result.marks.allSatisfy { $0.stem == nil })
    }

    func testBaselineSpansTheChart() {
        let result = layout()
        XCTAssertEqual(result.baselineFrame.minX, 0)
        XCTAssertEqual(result.baselineFrame.maxX, 400)
    }

    func testBaselineSpansTheContentInsideInsets() {
        let result = layout { $0.layout.insets = EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 20) }
        XCTAssertEqual(result.baselineFrame.minX, 10)
        XCTAssertEqual(result.baselineFrame.maxX, 380)
    }

    func testBaselineEndsAtTheLastMarkerWhenEdgeToEdge() {
        let result = layout { $0.layout.pointDistribution = .edgeToEdge }
        XCTAssertEqual(result.baselineFrame.maxX, result.marks.last?.center.x)
    }

    /// With one point, the "last marker" is in the middle, and lines used to stop there.
    func testLinesSpanTheChartForOnePointEdgeToEdge() throws {
        let result = layout(Fixtures.points([5])) {
            $0.layout.pointDistribution = .edgeToEdge
            $0.valueAxis = ChartValueAxis(showsLabels: false)
            $0.referenceLines = [ChartReferenceLine(value: 2, style: self.lineStyle)]
        }
        XCTAssertEqual(result.baselineFrame.maxX, 400)
        XCTAssertEqual(try XCTUnwrap(result.gridlineFrames.first).maxX, 400)
        XCTAssertEqual(try XCTUnwrap(result.referenceLineFrames.first).maxX, 400)
    }

    func testOnePlottedPointAmongInvalidOnesSpansTheChartEdgeToEdge() {
        let result = layout(Fixtures.points([.nan, 5, .nan])) { $0.layout.pointDistribution = .edgeToEdge }
        XCTAssertEqual(result.baselineFrame.maxX, 400)
    }

    func testHiddenBaselineHasNoFrame() {
        XCTAssertEqual(layout { $0.style.baseline.isVisible = false }.baselineFrame, .zero)
    }

    // MARK: - Labels

    func testLabelsAreVisibleWhenThereIsRoom() {
        XCTAssertEqual(layout().annotations.map(\.isVisible), [true, true, true])
    }

    func testLabelsAreOfferedTheirSlotWidth() {
        let recorder = WidthRecorder()
        _ = makeEngine(Fixtures.points([1, 2])).layout(in: CGSize(width: 212, height: 300), measuring: recorder)
        // A 200-point plot gives each of two slots 100 points, less 2 of padding.
        XCTAssertEqual(recorder.widths.value.first, 98)
    }

    func testLabelsAreOfferedTheMinimumWidthWhenDense() {
        let recorder = WidthRecorder()
        _ = makeEngine(Fixtures.dense(50)).layout(in: CGSize(width: 212, height: 300), measuring: recorder)
        XCTAssertEqual(recorder.widths.value.first, ChartStyle.AnnotationStyle().minimumWidth)
    }

    /// The axis takes width too. A label offered more than remains used to be hidden as too wide.
    func testLongLabelOnOnePointBesideAnAxisIsOfferedOnlyTheWidthLeft() {
        let recorder = WidthRecorder()
        var configuration = ChartConfiguration()
        configuration.valueAxis = ChartValueAxis(labelSpacing: 0, labelTrailingSpacing: 0)
        let tick = TickSizedRecorder(base: recorder, tickWidth: 30)
        _ = makeEngine(Fixtures.points([1]), configuration: configuration).layout(in: CGSize(width: 200, height: 300), measuring: tick)
        XCTAssertEqual(recorder.widths.value.first, 170)
    }

    func testLongLabelOnOnePointBesideAnAxisStaysVisible() {
        var measurer = StubMeasurer()
        measurer.annotation = CGSize(width: 1000, height: 30)
        measurer.tickLabel = CGSize(width: 30, height: 12)
        let result = layout(Fixtures.points([1]), in: CGSize(width: 200, height: 300), measurer: measurer) {
            $0.valueAxis = ChartValueAxis()
        }
        XCTAssertEqual(result.annotations.first?.isVisible, true)
    }

    /// The text must keep the line breaks it was measured with. If it were placed using its
    /// measured width, a name wrapped to fit the slot could reflow into fewer lines.
    func testLabelsArePlacedWithTheWidthTheyWereMeasuredWith() throws {
        var measurer = StubMeasurer()
        measurer.annotation = CGSize(width: 90, height: 30)
        let result = layout(Fixtures.points([1, 2, 3, 4, 5, 6, 7, 8]), in: CGSize(width: 212, height: 300), measurer: measurer)
        let visible = try XCTUnwrap(result.annotations.first { $0.isVisible })
        let proposal = result.proposal(for: .annotation(visible.index))
        XCTAssertEqual(proposal.width, ChartStyle.AnnotationStyle().minimumWidth)
        XCTAssertNil(proposal.height)
    }

    func testHiddenLabelsAreProposedNoSpace() throws {
        let result = layout(Fixtures.dense(200), in: CGSize(width: 300, height: 300))
        let hidden = try XCTUnwrap(result.annotations.first { !$0.isVisible })
        XCTAssertEqual(result.proposal(for: .annotation(hidden.index)), .zero)
    }

    func testOtherElementsAreProposedTheirFrames() {
        let result = layout(title: "Title")
        XCTAssertEqual(result.proposal(for: .header), ProposedViewSize(result.headerFrame.size))
        XCTAssertEqual(result.proposal(for: .marks), ProposedViewSize(result.marksFrame.size))
    }

    func testLabelsAreNeverOfferedMoreThanTheContentWidth() {
        let recorder = WidthRecorder()
        _ = makeEngine(Fixtures.points([1])).layout(in: CGSize(width: 40, height: 300), measuring: recorder)
        XCTAssertEqual(recorder.widths.value.first, 40)
    }

    func testPositiveLabelsAreAboveAndNegativeBelowTheirMarkers() {
        let result = layout()
        XCTAssertLessThan(result.annotations[0].frame.maxY, result.marks[0].markerFrame.minY)
        XCTAssertGreaterThan(result.annotations[2].frame.minY, result.marks[2].markerFrame.maxY)
    }

    func testTallestLabelFitsAboveTheHighestMarker() {
        var measurer = StubMeasurer()
        measurer.annotationOverrides[0] = CGSize(width: 50, height: 60)
        let result = layout(measurer: measurer)
        XCTAssertGreaterThanOrEqual(result.annotations[0].frame.minY, 0)
    }

    func testHiddenLabelsTakeNoSpace() {
        let result = layout { $0.style.annotation.isVisible = false }
        XCTAssertTrue(result.annotations.isEmpty)
        XCTAssertEqual(result.plotFrame.minY, 6)
        XCTAssertEqual(result.plotFrame.maxY, 294)
    }

    func testDenseChartShowsOnlyLabelsThatFit() {
        let result = layout(Fixtures.dense(500), in: CGSize(width: 393, height: 300))
        let visible = result.annotations.filter(\.isVisible)
        XCTAssertGreaterThan(visible.count, 0)
        XCTAssertLessThan(visible.count, result.annotations.count)
        for (index, first) in visible.enumerated() {
            for second in visible[(index + 1)...] {
                XCTAssertFalse(first.frame.intersects(second.frame))
            }
        }
    }

    func testMoreWidthRevealsMoreLabels() {
        func visibleCount(width: CGFloat) -> Int {
            layout(Fixtures.dense(100), in: CGSize(width: width, height: 300)).annotations.filter(\.isVisible).count
        }
        XCTAssertGreaterThan(visibleCount(width: 1200), visibleCount(width: 300))
    }

    // MARK: - Graceful degradation

    func testShortChartDropsLabelsAndKeepsTheTitle() {
        let result = layout(title: "Title", in: CGSize(width: 400, height: 90))
        XCTAssertTrue(result.annotations.isEmpty)
        XCTAssertGreaterThan(result.headerFrame.height, 0)
        XCTAssertEqual(result.marks.count, 3)
    }

    func testVeryShortChartAlsoDropsTheTitle() {
        let result = layout(title: "Title", in: CGSize(width: 400, height: 50))
        XCTAssertTrue(result.annotations.isEmpty)
        XCTAssertEqual(result.headerFrame, .zero)
        XCTAssertEqual(result.marks.count, 3)
    }

    func testSmallestChartDropsAxisLabelsToo() {
        let result = layout(in: CGSize(width: 400, height: 40)) {
            $0.valueAxis = ChartValueAxis()
            $0.style.annotation.isVisible = false
        }
        XCTAssertTrue(result.tickLabelFrames.allSatisfy { $0 == .zero })
        XCTAssertEqual(result.marks.count, 3)
    }

    func testMarksSurviveAnyPositiveHeight() {
        for height in [CGFloat(1), 2, 5, 10, 20, 31, 33] {
            let result = layout(title: "Title", in: CGSize(width: 300, height: height))
            XCTAssertEqual(result.marks.count, 3, "\(height)")
            assertGeometryIsValid(result, context: "height \(height)")
        }
    }

    func testNarrowChartStaysInBounds() {
        for width in [CGFloat(1), 5, 20, 44, 80] {
            let result = layout(in: CGSize(width: width, height: 300))
            assertGeometryIsValid(result, context: "width \(width)")
        }
    }

    /// A title taller than the chart must not count as fitting just because the minimum plot
    /// height is zero, which was a bug the fuzz test found.
    func testTitleTallerThanTheChartIsDroppedEvenWithNoMinimumPlotHeight() {
        var measurer = StubMeasurer()
        measurer.header = CGSize(width: 100, height: 320)
        let result = layout(title: "Title", in: CGSize(width: 100, height: 10), measurer: measurer) {
            $0.layout.minimumPlotHeight = 0
        }
        XCTAssertEqual(result.headerFrame, .zero)
        assertGeometryIsValid(result)
    }

    func testVeryThickLinesAndLongTicksStayInsideTheChart() {
        let result = layout(Fixtures.points([5, -5]), in: CGSize(width: 100, height: 50)) {
            $0.style.baseline.thickness = 5000
            $0.valueAxis = ChartValueAxis(gridline: ChartLineStyle(color: .gray, thickness: 5000))
            $0.referenceLines = [ChartReferenceLine(value: 1, style: ChartLineStyle(color: .gray, thickness: 5000))]
            $0.categoryTicks = ChartCategoryTicks(points: [0], length: 5000)
        }
        assertGeometryIsValid(result)
    }

    func testMinimumPlotHeightIsConfigurable() {
        let lenient = layout(in: CGSize(width: 400, height: 120)) { $0.layout.minimumPlotHeight = 0 }
        let strict = layout(in: CGSize(width: 400, height: 120)) { $0.layout.minimumPlotHeight = 200 }
        XCTAssertFalse(lenient.annotations.isEmpty)
        XCTAssertTrue(strict.annotations.isEmpty)
    }

    // MARK: - Aspect ratios

    func testEveryAspectRatioStaysValid() {
        let sizes = [
            CGSize(width: 1000, height: 60),
            CGSize(width: 60, height: 1000),
            CGSize(width: 2000, height: 2000),
            CGSize(width: 320, height: 240),
            CGSize(width: 240, height: 320),
            CGSize(width: 1366, height: 200)
        ]
        for size in sizes {
            assertGeometryIsValid(layout(Fixtures.mixed, title: "Title", in: size), context: "\(size)")
        }
    }

    func testTallChartUsesItsHeight() {
        let short = layout(in: CGSize(width: 300, height: 200)).plotFrame.height
        let tall = layout(in: CGSize(width: 300, height: 800)).plotFrame.height
        XCTAssertEqual(tall - short, 600, accuracy: 1)
    }

    func testWideChartUsesItsWidth() {
        let result = layout(in: CGSize(width: 1000, height: 300))
        XCTAssertEqual(result.marks[1].center.x, 500, accuracy: 0.5)
    }

    // MARK: - Value axis

    private func axisLayout(
        _ points: [ChartDataPoint] = Fixtures.points(Fixtures.editorialValues),
        in size: CGSize? = nil,
        measurer: StubMeasurer? = nil,
        configure: (inout ChartConfiguration) -> Void = { _ in }
    ) -> ChartLayoutResult {
        layout(points, in: size, measurer: measurer) {
            $0.valueAxis = ChartValueAxis()
            $0.style.annotation.isVisible = false
            configure(&$0)
        }
    }

    func testGridlinesAreEvenlySpacedAndSpanTheChart() {
        let result = axisLayout()
        XCTAssertEqual(result.gridlineFrames.count, 6)
        let gaps = zip(result.gridlineFrames, result.gridlineFrames.dropFirst()).map { $0.minY - $1.minY }
        for gap in gaps {
            XCTAssertEqual(gap, gaps[0], accuracy: 1)
        }
        XCTAssertEqual(result.gridlineFrames[0].minX, 0)
        XCTAssertEqual(result.gridlineFrames[0].maxX, 400)
    }

    func testZeroGridlineAlignsWithTheBaseline() {
        let result = axisLayout()
        XCTAssertEqual(result.gridlineFrames[2].midY, result.baselineFrame.midY, accuracy: 0.5)
    }

    func testOuterGridlinesAreAtTheEdgesOfThePlot() {
        let result = axisLayout()
        XCTAssertEqual(result.gridlineFrames[0].midY, result.plotFrame.maxY, accuracy: 0.5)
        XCTAssertEqual(result.gridlineFrames[5].midY, result.plotFrame.minY, accuracy: 0.5)
    }

    func testTickLabelsSitAboveTheirGridlines() {
        let result = axisLayout()
        for (label, line) in zip(result.tickLabelFrames, result.gridlineFrames) {
            XCTAssertLessThanOrEqual(label.maxY, line.minY + 0.5)
        }
    }

    func testTopTickLabelStaysInsideTheChart() {
        XCTAssertGreaterThanOrEqual(axisLayout().tickLabelFrames.last?.minY ?? -1, 0)
    }

    func testFirstPointClearsTheTickLabels() {
        let result = axisLayout()
        let labelsEnd = result.tickLabelFrames.map(\.maxX).max() ?? 0
        XCTAssertGreaterThanOrEqual(result.marks[0].center.x, labelsEnd)
    }

    func testPointsMoveRightToMakeRoomForTickLabels() {
        let plain = layout(Fixtures.points(Fixtures.editorialValues)) { $0.style.annotation.isVisible = false }
        XCTAssertGreaterThan(axisLayout().marks[0].center.x, plain.marks[0].center.x)
    }

    func testVeryWideTickLabelsAreDropped() {
        var measurer = StubMeasurer()
        measurer.tickLabel = CGSize(width: 300, height: 12)
        let result = axisLayout(measurer: measurer)
        XCTAssertTrue(result.tickLabelFrames.allSatisfy { $0 == .zero })
        XCTAssertFalse(result.marks.isEmpty)
    }

    func testTicksThinOutInAShortChartAndKeepZero() {
        let result = axisLayout(in: CGSize(width: 400, height: 60))
        let visible = result.gridlineFrames.filter { !$0.isEmpty }
        XCTAssertLessThan(visible.count, 6)
        XCTAssertFalse(result.gridlineFrames[2].isEmpty, "The zero gridline must be kept")
    }

    func testVisibleTickLabelsNeverOverlap() {
        for height in stride(from: CGFloat(40), through: 300, by: 7) {
            let labels = axisLayout(in: CGSize(width: 400, height: height)).tickLabelFrames.filter { !$0.isEmpty }
            for (first, second) in zip(labels, labels.dropFirst()) {
                XCTAssertFalse(first.intersects(second), "height \(height)")
            }
        }
    }

    /// With labels this tall, no two ticks can both have one, so only zero should remain. The
    /// stride asked for here is well past the number of ticks, which is the capped path.
    func testVeryTallTickLabelsLeaveOnlyTheZeroTick() {
        var measurer = StubMeasurer()
        measurer.tickLabel = CGSize(width: 10, height: 280)
        let result = axisLayout(in: CGSize(width: 400, height: 300), measurer: measurer) {
            $0.layout.minimumPlotHeight = 0
        }
        let visible = result.gridlineFrames.enumerated().filter { !$0.element.isEmpty }.map(\.offset)
        XCTAssertEqual(visible, [2], "Only the zero tick, third of six, should remain")
        assertGeometryIsValid(result)
    }

    func testHiddenGridlinesKeepTheirLabels() {
        let result = axisLayout { $0.valueAxis?.gridline.isVisible = false }
        XCTAssertTrue(result.gridlineFrames.allSatisfy { $0.height == 0 })
        XCTAssertTrue(result.tickLabelFrames.contains { !$0.isEmpty })
    }

    func testHiddenTickLabelsLeaveNoZone() {
        let result = axisLayout { $0.valueAxis?.showsLabels = false }
        XCTAssertTrue(result.tickLabelFrames.allSatisfy { $0 == .zero })
        XCTAssertEqual(result.marksFrame.minX, 0)
    }

    func testSingleTickNeedsNoThinning() {
        let result = axisLayout(Fixtures.points([1])) {
            $0.scale = .fixed(lower: 0, upper: 1)
            $0.valueAxis?.desiredTickCount = 2
        }
        XCTAssertFalse(result.gridlineFrames.isEmpty)
    }

    // MARK: - Reference lines

    private let lineStyle = ChartLineStyle(color: .red, thickness: 3)

    func testReferenceLineIsAtItsValue() throws {
        let result = layout(Fixtures.points([10, -10])) {
            $0.referenceLines = [ChartReferenceLine(value: 5, style: self.lineStyle)]
        }
        let line = try XCTUnwrap(result.referenceLineFrames.first)
        let expected = result.plotFrame.minY + result.plotFrame.height * 0.25
        XCTAssertEqual(line.midY, expected, accuracy: 0.5)
        XCTAssertEqual(line.height, 3)
    }

    func testReferenceLineSpansTheChartByDefault() throws {
        let result = layout { $0.referenceLines = [ChartReferenceLine(value: 1, style: self.lineStyle)] }
        let line = try XCTUnwrap(result.referenceLineFrames.first)
        XCTAssertEqual(line.minX, 0)
        XCTAssertEqual(line.maxX, 400)
    }

    func testReferenceLineCanSpanARunOfPoints() throws {
        let result = layout(Fixtures.points([1, 2, 3, 4])) {
            $0.referenceLines = [ChartReferenceLine(value: 1, points: 1...2, style: self.lineStyle)]
        }
        let line = try XCTUnwrap(result.referenceLineFrames.first)
        XCTAssertEqual(line.minX, result.marks[1].center.x)
        XCTAssertEqual(line.maxX, result.marks[2].center.x)
    }

    /// Running from a point's centre to that same centre used to produce no line at all.
    func testReferenceLineOverOnePointSpansItsShareOfTheWidth() throws {
        let result = layout(Fixtures.points([1, 2, 3, 4])) {
            $0.referenceLines = [ChartReferenceLine(value: 1, points: 2...2, style: self.lineStyle)]
        }
        let line = try XCTUnwrap(result.referenceLineFrames.first)
        XCTAssertGreaterThan(line.width, 0)
        XCTAssertEqual(line.midX, result.marks[2].center.x, accuracy: 0.5)
        XCTAssertEqual(line.width, result.marks[3].center.x - result.marks[2].center.x, accuracy: 1)
    }

    func testReferenceLineOverTheOnlyPointSpansTheChart() throws {
        let result = layout(Fixtures.points([5])) {
            $0.referenceLines = [ChartReferenceLine(value: 2, points: 0...0, style: self.lineStyle)]
        }
        let line = try XCTUnwrap(result.referenceLineFrames.first)
        XCTAssertEqual(line.minX, 0)
        XCTAssertEqual(line.maxX, 400)
    }

    func testInvalidReferenceLineThicknessFallsBack() throws {
        let result = layout {
            $0.referenceLines = [ChartReferenceLine(value: 1, style: ChartLineStyle(color: .red, thickness: .nan))]
        }
        XCTAssertEqual(try XCTUnwrap(result.referenceLineFrames.first).height, 1)
    }

    // MARK: - Regions

    func testRegionBetweenPointsStopsAtTheSlotBoundaries() throws {
        let result = layout(Fixtures.points([1, 2, 3, 4])) {
            $0.regions = [ChartRegion(points: 1...2, color: .gray)]
        }
        let region = try XCTUnwrap(result.regionFrames.first)
        XCTAssertEqual(region.minX, (result.marks[0].center.x + result.marks[1].center.x) / 2, accuracy: 1)
        XCTAssertEqual(region.maxX, (result.marks[2].center.x + result.marks[3].center.x) / 2, accuracy: 1)
    }

    func testRegionStopsAtThePointWhenEdgeToEdge() throws {
        let result = layout(Fixtures.points([1, 2, 3, 4])) {
            $0.layout.pointDistribution = .edgeToEdge
            $0.regions = [ChartRegion(points: 1...2, color: .gray)]
        }
        let region = try XCTUnwrap(result.regionFrames.first)
        XCTAssertEqual(region.minX, result.marks[1].center.x, accuracy: 0.5)
        XCTAssertEqual(region.maxX, result.marks[2].center.x, accuracy: 0.5)
    }

    func testRegionIncludingTheEndsReachesTheChartEdges() throws {
        let result = layout(Fixtures.points([1, 2, 3])) {
            $0.layout.insets = EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            $0.regions = [ChartRegion(points: 0...2, color: .gray)]
        }
        let region = try XCTUnwrap(result.regionFrames.first)
        XCTAssertEqual(region.minX, 0)
        XCTAssertEqual(region.maxX, 400)
    }

    func testRegionFillsTheHeightBelowTheTitle() throws {
        let titled = layout(title: "Title") { $0.regions = [ChartRegion(points: 0...2, color: .gray)] }
        XCTAssertEqual(try XCTUnwrap(titled.regionFrames.first).minY, 32)
        XCTAssertEqual(try XCTUnwrap(titled.regionFrames.first).maxY, 300)

        let untitled = layout { $0.regions = [ChartRegion(points: 0...2, color: .gray)] }
        XCTAssertEqual(try XCTUnwrap(untitled.regionFrames.first).minY, 0)
    }

    func testRegionStopsAtTheAxisWhenThereAreCategoryTicks() throws {
        let result = layout {
            $0.regions = [ChartRegion(points: 0...2, color: .gray)]
            $0.categoryTicks = ChartCategoryTicks(points: [1])
        }
        XCTAssertEqual(try XCTUnwrap(result.regionFrames.first).maxY, result.plotFrame.maxY, accuracy: 0.5)
    }

    // MARK: - Category ticks

    func testCategoryTicksHangBelowThePlotAtTheirPoints() throws {
        let result = layout(Fixtures.points([1, 2, 3])) {
            $0.categoryTicks = ChartCategoryTicks(points: [1], length: 8)
        }
        let tick = try XCTUnwrap(result.categoryTickFrames.first)
        XCTAssertEqual(tick.midX, result.marks[1].center.x, accuracy: 0.5)
        XCTAssertEqual(tick.minY, result.plotFrame.maxY, accuracy: 0.5)
        XCTAssertEqual(tick.height, 8)
    }

    /// Hidden ticks used to still reserve space and still stop regions at the axis.
    func testHiddenCategoryTicksHaveNoEffect() throws {
        let hidden = ChartCategoryTicks(points: [0], length: 30, style: ChartLineStyle(isVisible: false, color: .red))
        let plain = layout { $0.regions = [ChartRegion(points: 0...2, color: .gray)] }
        let result = layout {
            $0.regions = [ChartRegion(points: 0...2, color: .gray)]
            $0.categoryTicks = hidden
        }
        XCTAssertEqual(result.plotFrame, plain.plotFrame)
        XCTAssertEqual(result.regionFrames, plain.regionFrames)
    }

    func testCategoryTicksReserveSpace() {
        let plain = layout(Fixtures.points([1, 2])) { $0.style.annotation.isVisible = false }
        let ticked = layout(Fixtures.points([1, 2])) {
            $0.style.annotation.isVisible = false
            $0.categoryTicks = ChartCategoryTicks(points: [0], length: 30)
        }
        XCTAssertLessThan(ticked.plotFrame.maxY, plain.plotFrame.maxY)
        XCTAssertLessThanOrEqual(ticked.categoryTickFrames[0].maxY, 300)
    }

    // MARK: - Accessibility frames

    func testEveryProminentPointHasAFrame() {
        let result = layout(Fixtures.dense(500))
        XCTAssertEqual(result.pointFrames.count, ChartModel.prominentPointLimit)
    }

    func testPointFrameCoversTheMarkAndVisibleLabel() {
        let result = layout()
        XCTAssertTrue(result.pointFrames[0].contains(result.marks[0].bounds))
        XCTAssertTrue(result.pointFrames[0].contains(result.annotations[0].frame))
    }

    func testPointFrameIgnoresAHiddenLabel() {
        let result = layout { $0.style.annotation.isVisible = false }
        XCTAssertEqual(result.pointFrames[0], result.marks[0].bounds)
    }

    /// A zero-size element cannot receive VoiceOver focus.
    func testPointFrameIsNeverEmpty() {
        let result = layout(Fixtures.points([0])) {
            $0.style.marker.isVisible = false
            $0.style.annotation.isVisible = false
        }
        XCTAssertGreaterThanOrEqual(result.pointFrames[0].width, 1)
        XCTAssertGreaterThanOrEqual(result.pointFrames[0].height, 1)
    }

    func testSummaryCoversTheChart() {
        XCTAssertEqual(layout(title: "Title").summaryFrame, CGRect(origin: .zero, size: size))
    }

    // MARK: - Roles

    func testEachRoleResolvesToItsFrame() {
        let result = layout(title: "Title") {
            $0.valueAxis = ChartValueAxis()
            $0.referenceLines = [ChartReferenceLine(value: 1, style: self.lineStyle)]
            $0.regions = [ChartRegion(points: 0...1, color: .gray)]
            $0.categoryTicks = ChartCategoryTicks(points: [0])
        }
        XCTAssertEqual(result.frame(for: .unassigned), .zero)
        XCTAssertEqual(result.frame(for: .header), result.headerFrame)
        XCTAssertEqual(result.frame(for: .marks), result.marksFrame)
        XCTAssertEqual(result.frame(for: .baseline), result.baselineFrame)
        XCTAssertEqual(result.frame(for: .summary), result.summaryFrame)
        XCTAssertEqual(result.frame(for: .region(0)), result.regionFrames[0])
        XCTAssertEqual(result.frame(for: .gridline(0)), result.gridlineFrames[0])
        XCTAssertEqual(result.frame(for: .tickLabel(0)), result.tickLabelFrames[0])
        XCTAssertEqual(result.frame(for: .referenceLine(0)), result.referenceLineFrames[0])
        XCTAssertEqual(result.frame(for: .categoryTick(0)), result.categoryTickFrames[0])
        XCTAssertEqual(result.frame(for: .annotation(0)), result.annotations[0].frame)
        XCTAssertEqual(result.frame(for: .point(0)), result.pointFrames[0])
    }

    func testOutOfRangeRolesResolveToNothing() {
        let result = layout()
        XCTAssertEqual(result.frame(for: .region(9)), .zero)
        XCTAssertEqual(result.frame(for: .annotation(9)), .zero)
        XCTAssertEqual(result.frame(for: .point(-1)), .zero)
    }

    func testHiddenAnnotationResolvesToZero() {
        let result = layout(Fixtures.dense(200), in: CGSize(width: 300, height: 300))
        let hidden = result.annotations.first { !$0.isVisible }
        XCTAssertEqual(result.frame(for: .annotation(hidden?.index ?? -1)), .zero)
    }

    // MARK: - Display scales

    func testLayoutIsValidAtEveryDisplayScale() {
        for displayScale in [CGFloat(1), 2, 3] {
            let result = makeEngine(Fixtures.mixed, title: "Title", displayScale: displayScale)
                .layout(in: CGSize(width: 317.3, height: 233.7), measuring: measurer)
            assertGeometryIsValid(result, context: "scale \(displayScale)")
        }
    }

    func testLayoutIsDeterministic() {
        XCTAssertEqual(layout(Fixtures.mixed, title: "Title"), layout(Fixtures.mixed, title: "Title"))
    }
}

/// Records the widths that labels are offered.
private final class WidthRecorder: ChartElementMeasuring {
    /// A box, because `ChartElementMeasuring` methods are not mutating.
    final class Box {
        var value: [CGFloat] = []
    }

    let widths = Box()

    func headerSize(proposedWidth: CGFloat) -> CGSize {
        .zero
    }

    func annotationSize(at index: Int, proposedWidth: CGFloat) -> CGSize {
        widths.value.append(proposedWidth)
        return CGSize(width: 40, height: 20)
    }

    func tickLabelSize(at index: Int) -> CGSize {
        .zero
    }
}

/// Reports a fixed tick label size, so the axis takes up a known width.
private struct TickSizedRecorder: ChartElementMeasuring {
    let base: WidthRecorder
    let tickWidth: CGFloat

    func headerSize(proposedWidth: CGFloat) -> CGSize {
        .zero
    }

    func annotationSize(at index: Int, proposedWidth: CGFloat) -> CGSize {
        base.annotationSize(at: index, proposedWidth: proposedWidth)
    }

    func tickLabelSize(at index: Int) -> CGSize {
        CGSize(width: tickWidth, height: 12)
    }
}
