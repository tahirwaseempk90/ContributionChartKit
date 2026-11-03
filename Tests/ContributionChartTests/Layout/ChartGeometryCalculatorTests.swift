import SwiftUI
import XCTest
@testable import ContributionChart

final class ChartGeometryCalculatorTests: XCTestCase {
    private func calculator(
        _ values: [Double],
        scale: ChartScale? = nil,
        displayScale: CGFloat = 2,
        configure: (inout ChartConfiguration) -> Void = { _ in }
    ) -> ChartGeometryCalculator {
        var configuration = ChartConfiguration()
        configure(&configuration)
        return ChartGeometryCalculator(
            values: values,
            scale: scale ?? ChartScaleCalculator.domain(for: values, mode: .proportional),
            metrics: ChartMetrics(configuration),
            grid: PixelGrid(scale: displayScale)
        )
    }

    private let size = CGSize(width: 200, height: 100)

    // MARK: - Horizontal distribution

    func testSlotsCenterPointsInEqualColumns() {
        let layout = calculator([1, 2]).layout(in: size)
        // A 12-point marker leaves a 188-point plot from x = 6, so each slot is 94 wide.
        XCTAssertEqual(layout.spacing, 94)
        XCTAssertEqual(layout.marks.map(\.center.x), [53, 147])
    }

    func testEdgeToEdgePutsEndPointsOnThePlotEdges() {
        let layout = calculator([1, 2, 3]) { $0.layout.pointDistribution = .edgeToEdge }.layout(in: size)
        XCTAssertEqual(layout.spacing, 94)
        XCTAssertEqual(layout.marks.map(\.center.x), [6, 100, 194])
    }

    func testSinglePointIsCenteredInEitherDistribution() {
        let slots = calculator([1]).layout(in: size)
        XCTAssertEqual(slots.marks.first?.center.x, 100)
        XCTAssertEqual(slots.spacing, .infinity)
        let edges = calculator([1]) { $0.layout.pointDistribution = .edgeToEdge }.layout(in: size)
        XCTAssertEqual(edges.marks.first?.center.x, 100)
        XCTAssertEqual(edges.spacing, .infinity)
    }

    func testPointsAreEvenlySpaced() {
        let layout = calculator(Array(repeating: 1, count: 10)).layout(in: CGSize(width: 1000, height: 100))
        let gaps = zip(layout.marks, layout.marks.dropFirst()).map { $1.center.x - $0.center.x }
        XCTAssertTrue(gaps.allSatisfy { abs($0 - layout.spacing) <= 0.5 }, "\(gaps)")
    }

    func testPointsStayInOrderAndKeepTheirPositions() {
        let layout = calculator([1, -1, 0]).layout(in: size)
        XCTAssertEqual(layout.marks.map(\.position), [0, 1, 2])
        XCTAssertEqual(layout.marks.map(\.polarity), [.positive, .negative, .zero])
    }

    // MARK: - Vertical positioning

    func testLargestValuesReachThePlotEdges() {
        let layout = calculator([10, -10]).layout(in: size)
        XCTAssertEqual(layout.marks[0].center.y, 6)
        XCTAssertEqual(layout.marks[1].center.y, 94)
    }

    func testPositiveValuesAreAboveAndNegativeBelowTheBaseline() {
        let layout = calculator([4, -3]).layout(in: size)
        XCTAssertLessThan(layout.marks[0].center.y, layout.baselineFrame.minY)
        XCTAssertGreaterThan(layout.marks[1].center.y, layout.baselineFrame.maxY)
    }

    func testZeroSitsOnTheBaseline() {
        let layout = calculator([5, 0, -5]).layout(in: size)
        XCTAssertEqual(layout.marks[1].center.y, layout.baselineFrame.midY)
        XCTAssertNil(layout.marks[1].stem)
    }

    func testBaselineFollowsTheScale() {
        XCTAssertEqual(calculator([1, 2]).layout(in: size).baselineFrame.midY, 94)
        XCTAssertEqual(calculator([-1, -2]).layout(in: size).baselineFrame.midY, 6)
        XCTAssertEqual(calculator([5, -5]).layout(in: size).baselineFrame.midY, 50)
    }

    func testAsymmetricDataUsesTheSameScaleOnBothSides() {
        let layout = calculator([30, -10]).layout(in: CGSize(width: 200, height: 412))
        let baseline = layout.baselineFrame.midY
        let above = baseline - layout.marks[0].center.y
        let below = layout.marks[1].center.y - baseline
        XCTAssertEqual(above / below, 3, accuracy: 0.02)
    }

    func testLargerValuesAreFartherFromTheBaseline() {
        let layout = calculator([1, 2, 3, 4]).layout(in: CGSize(width: 200, height: 400))
        let ys = layout.marks.map(\.center.y)
        XCTAssertEqual(ys, ys.sorted(by: >))
    }

    func testValuesBeyondAFixedScaleClampToThePlot() {
        let scale = ChartScale(lower: -1, upper: 1)
        let layout = calculator([50, -50], scale: scale).layout(in: size)
        XCTAssertEqual(layout.marks[0].center.y, layout.plotFrame.minY)
        XCTAssertEqual(layout.marks[1].center.y, layout.plotFrame.maxY)
    }

    // MARK: - Stems

    /// A translucent stem overlapping the line would show as a dark patch where they meet.
    func testStemsMeetTheBaselineWithoutOverlapOrGap() throws {
        let layout = calculator([5, -5]).layout(in: size)
        let positive = try XCTUnwrap(layout.marks[0].stem)
        let negative = try XCTUnwrap(layout.marks[1].stem)
        XCTAssertEqual(positive.maxY, layout.baselineFrame.minY)
        XCTAssertEqual(negative.minY, layout.baselineFrame.maxY)
    }

    func testStemIsCenteredOnItsMarker() throws {
        for displayScale in [CGFloat(1), 2, 3] {
            let layout = calculator([5, -3, 2], displayScale: displayScale).layout(in: CGSize(width: 317, height: 103))
            for mark in layout.marks {
                let stem = try XCTUnwrap(mark.stem)
                XCTAssertEqual(stem.midX, mark.center.x, accuracy: 0.0001, "scale \(displayScale)")
            }
        }
    }

    /// The stem must end under the marker: not short of it, which would leave a gap, and not
    /// at its centre, which would show through a translucent marker.
    func testStemEndsInsideTheMarkerEdge() throws {
        let layout = calculator([5, -5]).layout(in: size)
        let positive = layout.marks[0]
        let stem = try XCTUnwrap(positive.stem)
        let radius = positive.markerDiameter / 2
        XCTAssertLessThan(stem.minY, positive.center.y + radius)
        XCTAssertGreaterThan(stem.minY, positive.center.y)

        let negative = layout.marks[1]
        let lowerStem = try XCTUnwrap(negative.stem)
        XCTAssertGreaterThan(lowerStem.maxY, negative.center.y - radius)
        XCTAssertLessThan(lowerStem.maxY, negative.center.y)
    }

    func testStemWiderThanTheMarkerRunsToItsCentre() throws {
        let layout = calculator([5, -5]) {
            $0.style.marker.diameter = 4
            $0.style.stem.width = 20
        }.layout(in: size)
        XCTAssertEqual(try XCTUnwrap(layout.marks[0].stem).minY, layout.marks[0].center.y)
    }

    func testNoStemWhenTheMarkerCoversTheGap() {
        // On this scale, 0.1 lands well inside the marker's own radius of the baseline.
        let layout = calculator([100, 0.1]) {
            $0.style.stem.minimumLength = 1
            $0.style.marker.diameter = 40
        }.layout(in: CGSize(width: 200, height: 1000))
        XCTAssertNil(layout.marks[1].stem)
        XCTAssertNotNil(layout.marks[0].stem)
    }

    // MARK: - Minimum stem length

    func testVerySmallValuesAreMovedOffTheBaseline() {
        let layout = calculator([1000, 0.001, -0.001]).layout(in: CGSize(width: 300, height: 400))
        let baseline = layout.baselineFrame.midY
        XCTAssertEqual(baseline - layout.marks[1].center.y, 6, accuracy: 0.5)
        XCTAssertEqual(layout.marks[2].center.y - baseline, 6, accuracy: 0.5)
    }

    /// The baseline would otherwise sit at the plot's edge, with no room on the small side.
    func testSmallValueOnTheEmptySideKeepsThatSideOfTheBaseline() {
        let layout = calculator([1000, -0.001]).layout(in: CGSize(width: 300, height: 400))
        XCTAssertGreaterThan(layout.marks[1].center.y, layout.baselineFrame.maxY)
        XCTAssertEqual(layout.marks[1].center.y - layout.baselineFrame.midY, 6, accuracy: 0.5)
        XCTAssertEqual(layout.marks[0].center.y, 6, "The large value still reaches the top")

        let flipped = calculator([-1000, 0.001]).layout(in: CGSize(width: 300, height: 400))
        XCTAssertLessThan(flipped.marks[1].center.y, flipped.baselineFrame.minY)
        XCTAssertEqual(flipped.baselineFrame.midY - flipped.marks[1].center.y, 6, accuracy: 0.5)
    }

    func testSpaceIsOnlyReservedForSidesThatHaveValues() {
        let positive = calculator([1, 2]).layout(in: size)
        XCTAssertEqual(positive.baselineFrame.midY, positive.plotFrame.maxY, accuracy: 0.5)
        XCTAssertEqual(positive.plotFrame, CGRect(x: 6, y: 6, width: 188, height: 88))
    }

    func testReservedSpaceIsLimitedInAVeryShortPlot() {
        let layout = calculator([1000, -0.001]) { $0.style.stem.minimumLength = 500 }.layout(in: CGSize(width: 300, height: 40))
        XCTAssertGreaterThanOrEqual(layout.plotFrame.height, 0)
        XCTAssertTrue(layout.marks.allSatisfy { $0.center.y >= 0 && $0.center.y <= 40 })
    }

    func testZeroMinimumLengthDrawsStrictlyToScale() {
        let layout = calculator([1000, 0.001]) { $0.style.stem.minimumLength = 0 }.layout(in: CGSize(width: 300, height: 400))
        XCTAssertEqual(layout.baselineFrame.midY - layout.marks[1].center.y, 0, accuracy: 0.5)
    }

    func testMinimumLengthNeverAffectsLargerValues() {
        let layout = calculator([100, 50]).layout(in: CGSize(width: 300, height: 400))
        let baseline = layout.baselineFrame.midY
        let large = baseline - layout.marks[0].center.y
        let half = baseline - layout.marks[1].center.y
        XCTAssertEqual(large / half, 2, accuracy: 0.02)
    }

    func testMinimumLengthKeepsTheMarkerInsideTheCanvas() {
        let scale = ChartScale(lower: 0, upper: 1)
        let layout = calculator([-0.5], scale: scale).layout(in: size)
        XCTAssertLessThanOrEqual(layout.marks[0].markerFrame.maxY, size.height)
    }

    // MARK: - Density

    func testMarksUseTheirConfiguredSizeWhenThereIsRoom() throws {
        let layout = calculator([1, 2]).layout(in: size)
        XCTAssertEqual(layout.marks[0].markerDiameter, 12)
        XCTAssertEqual(try XCTUnwrap(layout.marks[0].stem).width, 4)
    }

    func testMarkersShrinkToFitDensePoints() {
        let layout = calculator(Array(repeating: 5, count: 30)).layout(in: CGSize(width: 212, height: 100))
        // Slots of 200 / 30, of which at most 70% can be used.
        XCTAssertEqual(layout.marks[0].markerDiameter, 4.5, accuracy: 0.51)
    }

    func testNeighbouringMarkersDoNotOverlapUntilTheMinimumSize() {
        let layout = calculator(Array(repeating: 5, count: 30)).layout(in: CGSize(width: 212, height: 100))
        XCTAssertLessThan(layout.marks[0].markerDiameter, layout.spacing)
    }

    func testStemsShrinkInProportionToMarkers() throws {
        let layout = calculator(Array(repeating: 5, count: 30)) {
            $0.style.marker.diameter = 20
            $0.style.stem.width = 10
        }.layout(in: CGSize(width: 320, height: 100))
        let mark = layout.marks[0]
        XCTAssertEqual(try XCTUnwrap(mark.stem).width / mark.markerDiameter, 0.5, accuracy: 0.1)
    }

    func testMarkersStopShrinkingAtTheMinimum() {
        let layout = calculator(Array(repeating: 5, count: 1000)).layout(in: CGSize(width: 100, height: 100))
        XCTAssertEqual(layout.marks[0].markerDiameter, 3)
    }

    func testMinimumDoesNotEnlargeASmallerConfiguredMarker() {
        let layout = calculator([5, 6]) {
            $0.style.marker.diameter = 2
            $0.style.marker.minimumDiameter = 5
        }.layout(in: size)
        XCTAssertEqual(layout.marks[0].markerDiameter, 2)
    }

    func testStemsNeverVanishEvenWhenVeryDense() throws {
        // A 1-point stem at a quarter of the marker's size would be under one pixel wide.
        let layout = calculator(Array(repeating: 5, count: 5000), displayScale: 2) {
            $0.style.stem.width = 1
        }.layout(in: CGSize(width: 100, height: 100))
        XCTAssertEqual(try XCTUnwrap(layout.marks[0].stem).width, 0.5, "One pixel at 2x")
    }

    func testStemsNeverVanishWithAZeroSpacingFraction() throws {
        let layout = calculator([5, 6]) {
            $0.style.marker.isVisible = false
            $0.style.marker.maximumSpacingFraction = 0
        }.layout(in: size)
        XCTAssertEqual(try XCTUnwrap(layout.marks[0].stem).width, 0.5)
    }

    func testStemWiderThanTheMarkerStaysInsideTheChart() throws {
        let layout = calculator([5, 6]) {
            $0.style.marker.diameter = 4
            $0.style.stem.width = 30
            $0.layout.pointDistribution = .edgeToEdge
        }.layout(in: size)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(layout.marks[0].stem).minX, 0)
        XCTAssertLessThanOrEqual(try XCTUnwrap(layout.marks[1].stem).maxX, size.width)
    }

    func testStemsNeverCoverTheirNeighbours() throws {
        let layout = calculator(Array(repeating: 5, count: 10)) {
            $0.style.marker.diameter = 2
            $0.style.stem.width = 300
        }.layout(in: CGSize(width: 100, height: 100))
        XCTAssertLessThanOrEqual(try XCTUnwrap(layout.marks[0].stem).width, layout.spacing + 0.5)
    }

    func testBaselineStaysInsideTheCanvasWhenItIsAtTheEdge() {
        let layout = calculator([1, 2]) {
            $0.style.marker.isVisible = false
            $0.style.stem.isVisible = false
            $0.style.baseline.thickness = 6
        }.layout(in: size)
        XCTAssertLessThanOrEqual(layout.baselineFrame.maxY, size.height)
    }

    func testBaselineThickerThanTheChartIsLimitedToIt() {
        let layout = calculator([1, -1]) { $0.style.baseline.thickness = 5000 }.layout(in: size)
        XCTAssertEqual(layout.baselineFrame.height, size.height)
        XCTAssertEqual(layout.baselineFrame.minY, 0)
    }

    func testMarkerNeverExceedsTheAvailableHeight() {
        let layout = calculator([5]) { $0.style.marker.diameter = 100 }.layout(in: CGSize(width: 200, height: 30))
        XCTAssertLessThanOrEqual(layout.marks[0].markerDiameter, 30)
        XCTAssertGreaterThanOrEqual(layout.marks[0].markerFrame.minY, -0.5)
        XCTAssertLessThanOrEqual(layout.marks[0].markerFrame.maxY, 30.5)
    }

    /// Infinite spacing times a fraction of zero is NaN, a regression this test locks down.
    func testZeroSpacingFractionWithOnePointIsStillFinite() {
        let layout = calculator([5]) { $0.style.marker.maximumSpacingFraction = 0 }.layout(in: size)
        XCTAssertTrue(layout.marks[0].markerDiameter.isFinite)
        XCTAssertEqual(layout.marks[0].markerDiameter, 12)
        XCTAssertTrue(layout.marks[0].center.y.isFinite)
    }

    func testZeroSpacingFractionWithSeveralPointsUsesTheMinimum() {
        let layout = calculator([5, 6]) { $0.style.marker.maximumSpacingFraction = 0 }.layout(in: size)
        XCTAssertEqual(layout.marks[0].markerDiameter, 3)
    }

    // MARK: - Hidden elements

    func testHiddenMarkersHaveNoSize() {
        let layout = calculator([5, -5]) { $0.style.marker.isVisible = false }.layout(in: size)
        XCTAssertEqual(layout.marks[0].markerDiameter, 0)
    }

    func testStemsReachTheValueWhenMarkersAreHidden() throws {
        let layout = calculator([5, -5]) { $0.style.marker.isVisible = false }.layout(in: size)
        XCTAssertEqual(try XCTUnwrap(layout.marks[0].stem).minY, layout.marks[0].center.y)
        XCTAssertEqual(try XCTUnwrap(layout.marks[1].stem).maxY, layout.marks[1].center.y)
    }

    func testStemsAreLimitedBySpacingWhenMarkersAreHidden() throws {
        let layout = calculator(Array(repeating: 5, count: 50)) {
            $0.style.marker.isVisible = false
            $0.style.stem.width = 40
        }.layout(in: size)
        let stem = try XCTUnwrap(layout.marks[0].stem)
        XCTAssertLessThanOrEqual(stem.width, layout.spacing)
    }

    func testHiddenStemsAndMarkersDrawNothing() {
        let layout = calculator([5]) {
            $0.style.marker.isVisible = false
            $0.style.stem.isVisible = false
        }.layout(in: size)
        XCTAssertNil(layout.marks[0].stem)
        XCTAssertEqual(layout.marks[0].bounds.size, .zero)
    }

    func testHiddenBaselineStillMarksZero() {
        let layout = calculator([5, -5]) { $0.style.baseline.isVisible = false }.layout(in: size)
        XCTAssertEqual(layout.baselineFrame.height, 0)
        XCTAssertEqual(layout.baselineFrame.midY, 50)
    }

    // MARK: - Pixel alignment

    func testLinesLandOnPixelBoundariesAtEveryDisplayScale() throws {
        for displayScale in [CGFloat(1), 2, 3] {
            let layout = calculator([7, -3], displayScale: displayScale).layout(in: CGSize(width: 317, height: 203))
            let pixelEdges = [
                layout.baselineFrame.minY,
                layout.baselineFrame.maxY,
                try XCTUnwrap(layout.marks[0].stem).minX,
                try XCTUnwrap(layout.marks[0].stem).maxX
            ]
            for edge in pixelEdges {
                let inPixels = edge * displayScale
                XCTAssertEqual(inPixels, inPixels.rounded(), accuracy: 0.0001, "scale \(displayScale)")
            }
        }
    }

    func testPixelGridGuardsAgainstInvalidScales() {
        XCTAssertEqual(PixelGrid(scale: 0).scale, 1)
        XCTAssertEqual(PixelGrid(scale: -2).scale, 1)
        XCTAssertEqual(PixelGrid(scale: .nan).scale, 1)
        XCTAssertEqual(PixelGrid(scale: .infinity).scale, 1)
    }

    func testPixelGridLengths() {
        let grid = PixelGrid(scale: 2)
        XCTAssertEqual(grid.snap(1.3), 1.5)
        XCTAssertEqual(grid.snapLength(0), 0)
        XCTAssertEqual(grid.snapLength(-1), 0)
        XCTAssertEqual(grid.snapLength(0.01), 0.5, "A thin line must not vanish")
        XCTAssertEqual(grid.snapLength(1.3), 1.5)
    }

    func testPixelGridRectangles() {
        let grid = PixelGrid(scale: 2)
        XCTAssertEqual(
            grid.snapInward(CGRect(x: 0.3, y: 0.3, width: 1, height: 1)),
            CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        )
        XCTAssertEqual(grid.snapInward(CGRect(x: 0.1, y: 0.1, width: 0.1, height: 0.1)).size, .zero)
        XCTAssertEqual(
            grid.snap(CGRect(x: 0.3, y: 0.3, width: 1.3, height: 0.01)),
            CGRect(x: 0.5, y: 0.5, width: 1.5, height: 0.5)
        )
    }

    // MARK: - Degenerate sizes

    func testZeroSizeProducesFiniteMarks() {
        let layout = calculator([1, -1]).layout(in: .zero)
        XCTAssertTrue(layout.marks.allSatisfy { $0.center.x.isFinite && $0.center.y.isFinite })
    }

    func testCanvasAndLayoutAgreeBecauseTheCalculationIsPure() {
        let calculator = calculator([3, -2, 5])
        XCTAssertEqual(calculator.layout(in: size), calculator.layout(in: size))
    }

    func testOffsetMovesEverything() throws {
        let layout = calculator([3, -2]).layout(in: size)
        let moved = layout.offsetBy(CGPoint(x: 10, y: 20))
        XCTAssertEqual(moved.plotFrame.minX, layout.plotFrame.minX + 10)
        XCTAssertEqual(moved.baselineFrame.minY, layout.baselineFrame.minY + 20)
        XCTAssertEqual(moved.marks[0].center.x, layout.marks[0].center.x + 10)
        XCTAssertEqual(try XCTUnwrap(moved.marks[0].stem).minY, try XCTUnwrap(layout.marks[0].stem).minY + 20)
    }
}
