import SwiftUI
import XCTest
@testable import ContributionChart

/// Exercises the real view: SwiftUI's layout pass, the `Canvas`, and text. These assertions
/// examine the rendered pixels, because that is the only thing a user ever sees.
@MainActor
final class ContributionChartRenderingTests: XCTestCase {
    private let size = CGSize(width: 350, height: 260)

    private func pixels<V: View>(
        _ view: V,
        size: CGSize? = nil,
        environment: RenderEnvironment = RenderEnvironment(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> PixelBuffer {
        try XCTUnwrap(
            ChartRendering.pixels(of: view, size: size ?? self.size, environment: environment),
            "The view did not render",
            file: file,
            line: line
        )
    }

    private func isGreen(_ color: PixelBuffer.RGBA) -> Bool {
        color.green > 100 && color.red < 40 && color.blue < 90
    }

    private func isRed(_ color: PixelBuffer.RGBA) -> Bool {
        color.red > 190 && color.green < 60 && color.blue < 70
    }

    private func isInk(_ color: PixelBuffer.RGBA) -> Bool {
        color.red < 90 && color.green < 90 && color.blue < 90
    }

    /// The row with the most dark pixels, which is the baseline in a chart without gridlines.
    private func baselineRow(in buffer: PixelBuffer) -> Int {
        (0..<buffer.height).max { first, second in
            let firstCount = (0..<buffer.width).filter { isInk(buffer.pixel(x: $0, y: first)) }.count
            let secondCount = (0..<buffer.width).filter { isInk(buffer.pixel(x: $0, y: second)) }.count
            return firstCount < secondCount
        } ?? 0
    }

    private var labelsOff: ChartConfiguration {
        var configuration = ChartConfiguration()
        configuration.style.annotation.isVisible = false
        return configuration
    }

    // MARK: - The core promise

    func testPositiveMarksAreAboveAndNegativeMarksBelowTheBaseline() throws {
        let buffer = try pixels(ContributionChart(points: Fixtures.contributors, configuration: labelsOff))
        let baseline = baselineRow(in: buffer)
        let green = buffer.positions(where: isGreen)
        let red = buffer.positions(where: isRed)
        XCTAssertFalse(green.isEmpty, "Positive markers should be drawn")
        XCTAssertFalse(red.isEmpty, "Negative markers should be drawn")
        XCTAssertTrue(green.allSatisfy { $0.y < baseline }, "All positive marks belong above row \(baseline)")
        XCTAssertTrue(red.allSatisfy { $0.y > baseline }, "All negative marks belong below row \(baseline)")
    }

    func testBaselineSpansTheFullWidth() throws {
        let buffer = try pixels(ContributionChart(points: Fixtures.contributors, configuration: labelsOff))
        let baseline = baselineRow(in: buffer)
        XCTAssertTrue(isInk(buffer.pixel(x: 0, y: baseline)))
        XCTAssertTrue(isInk(buffer.pixel(x: buffer.width - 1, y: baseline)))
    }

    func testMarksAreSpreadAcrossTheWidth() throws {
        let buffer = try pixels(ContributionChart(points: Fixtures.contributors, configuration: labelsOff))
        let green = buffer.positions(where: isGreen).map(\.x)
        let red = buffer.positions(where: isRed).map(\.x)
        let firstMarker = try XCTUnwrap(green.min())
        let lastMarker = try XCTUnwrap(red.max())
        XCTAssertLessThan(firstMarker, buffer.width / 3)
        XCTAssertGreaterThan(lastMarker, buffer.width * 2 / 3)
    }

    /// Markers at the edges of the chart must keep their full size, not be cut off.
    func testMarkersAtTheEdgesAreNotCropped() throws {
        var configuration = labelsOff
        configuration.layout.pointDistribution = .edgeToEdge
        let buffer = try pixels(
            ContributionChart(points: Fixtures.points([5, 5]), configuration: configuration),
            size: CGSize(width: 200, height: 100)
        )
        let positions = buffer.positions(where: isGreen)
        let expectedWidth = Int(ChartStyle.MarkerStyle().diameter * 2)
        let left = positions.filter { $0.x < buffer.width / 2 }
        let right = positions.filter { $0.x >= buffer.width / 2 }
        for (name, side) in [("left", left), ("right", right)] {
            let xs = side.map(\.x)
            let ys = side.map(\.y)
            let width = try XCTUnwrap(xs.max()) - XCTUnwrap(xs.min()) + 1
            let height = try XCTUnwrap(ys.max()) - XCTUnwrap(ys.min()) + 1
            XCTAssertEqual(width, expectedWidth, accuracy: 2, name)
            XCTAssertEqual(height, expectedWidth, accuracy: 2, name)
        }
    }

    // MARK: - Optional elements

    func testLabelsAreDrawnByDefault() throws {
        let labelled = try pixels(ContributionChart(points: Fixtures.contributors))
        let plain = try pixels(ContributionChart(points: Fixtures.contributors, configuration: labelsOff))
        XCTAssertGreaterThan(labelled.differingFraction(from: plain, channelTolerance: 32), 0.001)
    }

    func testTitleIsDrawnWhenProvided() throws {
        let titled = try pixels(ContributionChart(points: Fixtures.contributors, title: "Chart title"))
        let plain = try pixels(ContributionChart(points: Fixtures.contributors))
        XCTAssertGreaterThan(titled.differingFraction(from: plain, channelTolerance: 32), 0.001)
    }

    func testHidingMarkersRemovesTheirColour() throws {
        var configuration = labelsOff
        configuration.style.marker.isVisible = false
        configuration.style.stem.isVisible = false
        let buffer = try pixels(ContributionChart(points: Fixtures.contributors, configuration: configuration))
        XCTAssertTrue(buffer.positions(where: isGreen).isEmpty)
        XCTAssertTrue(buffer.positions(where: isRed).isEmpty)
    }

    func testHidingStemsLeavesMarkers() throws {
        var configuration = labelsOff
        configuration.style.stem.isVisible = false
        let withoutStems = try pixels(ContributionChart(points: Fixtures.contributors, configuration: configuration))
        let withStems = try pixels(ContributionChart(points: Fixtures.contributors, configuration: labelsOff))
        XCTAssertFalse(withoutStems.positions(where: isGreen).isEmpty)
        XCTAssertGreaterThan(withStems.differingFraction(from: withoutStems, channelTolerance: 16), 0.001)
    }

    func testHidingTheBaselineRemovesIt() throws {
        var configuration = labelsOff
        configuration.style.baseline.isVisible = false
        let buffer = try pixels(ContributionChart(points: Fixtures.contributors, configuration: configuration))
        XCTAssertTrue(buffer.positions(where: isInk).isEmpty)
    }

    func testCustomColoursAreUsed() throws {
        var configuration = labelsOff
        configuration.style.positive = .init(color: Color(.sRGB, red: 0, green: 0, blue: 1))
        let buffer = try pixels(ContributionChart(points: Fixtures.contributors, configuration: configuration))
        let blue = buffer.positions { $0.blue > 200 && $0.red < 40 && $0.green < 40 }
        XCTAssertFalse(blue.isEmpty)
        XCTAssertTrue(buffer.positions(where: isGreen).isEmpty)
    }

    func testDashedBaselineLeavesGaps() throws {
        var configuration = labelsOff
        configuration.style.baseline = ChartLineStyle(color: .black, thickness: 2, dash: [10, 10])
        let buffer = try pixels(ContributionChart(points: Fixtures.points([0, 0]), configuration: configuration))
        let row = baselineRow(in: buffer)
        let ink = (0..<buffer.width).filter { isInk(buffer.pixel(x: $0, y: row)) }.count
        XCTAssertGreaterThan(ink, buffer.width / 4)
        XCTAssertLessThan(ink, buffer.width * 3 / 4)
    }

    func testInvalidDashPatternsDrawASolidLine() throws {
        for dash: [CGFloat] in [[-5, 5], [.nan], [.infinity], [0, 0], []] {
            var configuration = labelsOff
            configuration.style.marker.isVisible = false
            configuration.style.baseline = ChartLineStyle(color: .black, thickness: 2, dash: dash)
            let buffer = try pixels(ContributionChart(points: Fixtures.points([0, 0]), configuration: configuration))
            let row = baselineRow(in: buffer)
            let ink = (0..<buffer.width).filter { isInk(buffer.pixel(x: $0, y: row)) }.count
            XCTAssertEqual(ink, buffer.width, "\(dash)")
        }
    }

    func testStemOpacityFadesTheStem() throws {
        func stemColor(opacity: Double) throws -> PixelBuffer.RGBA {
            var configuration = labelsOff
            configuration.style.stem.opacity = opacity
            configuration.style.stem.width = 8
            let buffer = try pixels(
                ContributionChart(points: Fixtures.points([10]), configuration: configuration),
                size: CGSize(width: 100, height: 100)
            )
            return buffer.pixel(x: buffer.width / 2, y: buffer.height / 2)
        }
        let solid = try stemColor(opacity: 1)
        let faded = try stemColor(opacity: 0.25)
        let invisible = try stemColor(opacity: 0)
        XCTAssertLessThan(solid.red, faded.red)
        XCTAssertEqual(invisible.red, 255)
        XCTAssertEqual(try stemColor(opacity: .nan), try stemColor(opacity: ChartStyle.StemStyle().opacity))
        XCTAssertEqual(try stemColor(opacity: 7), solid, "An opacity above 1 is treated as 1")
    }

    // MARK: - Empty state

    func testEmptyDataShowsTheEmptyState() throws {
        let empty = try pixels(ContributionChart(points: []))
        let custom = try pixels(ContributionChart(points: []) { Text("Custom").font(.largeTitle) })
        XCTAssertTrue(empty.positions(where: isGreen).isEmpty)
        XCTAssertGreaterThan(empty.differingFraction(from: custom, channelTolerance: 32), 0.001)
    }

    func testAllInvalidDataShowsTheEmptyState() throws {
        let invalid = try pixels(ContributionChart(points: Fixtures.points([.nan, .infinity])))
        let empty = try pixels(ContributionChart(points: []))
        XCTAssertEqual(invalid.differingFraction(from: empty, channelTolerance: 0), 0)
    }

    func testEmptyStateMessageCanBeChanged() throws {
        let standard = try pixels(ContributionChart(points: []))
        let custom = try pixels(ContributionChart(points: []) { ChartEmptyState(message: "Nothing here yet") })
        XCTAssertGreaterThan(standard.differingFraction(from: custom, channelTolerance: 32), 0)
    }

    func testEmptyStateShowsTheTitle() throws {
        let titled = try pixels(ContributionChart(points: [], title: "Title"))
        let plain = try pixels(ContributionChart(points: []))
        XCTAssertGreaterThan(titled.differingFraction(from: plain, channelTolerance: 32), 0)
    }

    // MARK: - Size negotiation in the real layout system

    func testFillsTheOfferedFrame() {
        let size = ChartRendering.size(
            of: ContributionChart(points: Fixtures.contributors),
            proposal: ProposedViewSize(width: 333, height: 222)
        )
        XCTAssertEqual(size, CGSize(width: 333, height: 222))
    }

    func testChoosesAnIdealSizeWhenNothingIsProposed() throws {
        let size = try XCTUnwrap(
            ChartRendering.size(of: ContributionChart(points: Fixtures.contributors), proposal: .unspecified)
        )
        XCTAssertEqual(size.width, ChartLayoutOptions().idealWidth)
        XCTAssertGreaterThan(size.height, ChartLayoutOptions().idealPlotHeight)
        XCTAssertLessThan(size.height, 500, "The chart must not grow without limit")
    }

    /// This is how a `ScrollView` or `List` offers space, and where a `GeometryReader` collapses.
    func testChoosesAnIdealHeightForAProposedWidth() throws {
        let size = try XCTUnwrap(
            ChartRendering.size(
                of: ContributionChart(points: Fixtures.contributors),
                proposal: ProposedViewSize(width: 300, height: nil)
            )
        )
        XCTAssertEqual(size.width, 300)
        XCTAssertGreaterThan(size.height, ChartLayoutOptions().idealPlotHeight)
    }

    func testDenseChartChoosesAWidthThatFitsItsPoints() throws {
        let size = try XCTUnwrap(
            ChartRendering.size(
                of: ContributionChart(points: Fixtures.dense(200)),
                proposal: ProposedViewSize(width: nil, height: 200)
            )
        )
        XCTAssertGreaterThanOrEqual(size.width, 1600)
        XCTAssertEqual(size.height, 200)
    }

    func testEmptyStateHasAnIdealSize() throws {
        let size = try XCTUnwrap(
            ChartRendering.size(of: ContributionChart(points: []), proposal: ProposedViewSize(width: 300, height: nil))
        )
        XCTAssertEqual(size.width, 300)
        XCTAssertGreaterThanOrEqual(size.height, ChartLayoutOptions().idealPlotHeight)
    }

    func testTitleTallerThanTheProposedWidthGrowsTheChart() throws {
        let title = String(repeating: "A very long chart title ", count: 6)
        let short = try XCTUnwrap(ChartRendering.size(
            of: ContributionChart(points: Fixtures.contributors),
            proposal: ProposedViewSize(width: 200, height: nil)
        ))
        let long = try XCTUnwrap(ChartRendering.size(
            of: ContributionChart(points: Fixtures.contributors, title: title),
            proposal: ProposedViewSize(width: 200, height: nil)
        ))
        XCTAssertGreaterThan(long.height, short.height + 40)
    }

    // MARK: - Containers

    func testRendersInsideEveryCommonContainer() throws {
        let chart = ContributionChart(points: Fixtures.contributors, title: "Title")
        XCTAssertNotNil(ChartRendering.pixels(of: VStack { chart; chart }, size: size))
        XCTAssertNotNil(ChartRendering.pixels(of: HStack { chart; chart }, size: size))
        XCTAssertNotNil(ChartRendering.pixels(of: ZStack { chart }, size: size))
        XCTAssertNotNil(ChartRendering.pixels(of: ScrollView { chart }, size: size))
        XCTAssertNotNil(ChartRendering.pixels(of: ScrollView(.horizontal) { chart }, size: size))
        XCTAssertNotNil(ChartRendering.pixels(of: Grid { GridRow { chart; chart } }, size: size))
    }

    func testSharesAnHStackEvenly() throws {
        let row = HStack(spacing: 0) {
            ContributionChart(points: Fixtures.points([5]), configuration: labelsOff)
            ContributionChart(points: Fixtures.points([5]), configuration: labelsOff)
        }
        let buffer = try pixels(row, size: CGSize(width: 400, height: 100))
        let xs = Set(buffer.positions(where: isGreen).map(\.x))
        // One point centred in each half.
        XCTAssertTrue(xs.contains(200), "First chart's point should be at 100pt: \(xs.sorted().prefix(3))")
        XCTAssertTrue(xs.contains(600), "Second chart's point should be at 300pt")
    }

    func testFixedSizeUsesTheIdealSizeWithoutGrowingUnbounded() throws {
        let size = try XCTUnwrap(ChartRendering.size(
            of: ContributionChart(points: Fixtures.contributors).fixedSize(),
            proposal: ProposedViewSize(width: 1000, height: 1000)
        ))
        XCTAssertEqual(size.width, ChartLayoutOptions().idealWidth)
    }

    // MARK: - Labels

    /// A name that wraps to fit its slot must keep those line breaks when placed. If it reflowed
    /// into fewer lines, the text would shrink within its frame and leave a gap above the marker.
    func testLabelStaysAgainstItsMarkerWhenTheValueIsWiderThanTheSlot() throws {
        var configuration = ChartConfiguration()
        configuration.style.annotation.collisionPadding = 0
        configuration.style.annotation.minimumWidth = 20
        configuration.style.stem.isVisible = false
        configuration.style.annotation.directionIndicators = .init(positive: nil, negative: nil)
        configuration.valueFormatter = ChartValueFormatter { _ in "1,234,567.89%" }
        // Each slot is narrower than the value, and the name wraps at that width but not at the value's.
        let points = [ChartDataPoint(title: "Ab Cd", value: 5), ChartDataPoint(id: "x", title: "", value: 1)]
        let chart = ContributionChart(points: points, configuration: configuration)
        let buffer = try pixels(chart, size: CGSize(width: 90, height: 200), environment: RenderEnvironment(dynamicTypeSize: .xSmall))

        let marker = try XCTUnwrap(buffer.positions(where: isGreen).filter { $0.x < buffer.width / 2 }.map(\.y).min())
        // Value text is green too, so measure from the first fully green row: the marker's widest
        // part has a long unbroken run, unlike text.
        let rows = Dictionary(grouping: buffer.positions(where: isGreen).filter { $0.x < buffer.width / 2 }, by: \.y)
        let solidRows = rows.filter { $0.value.count >= 20 }.keys.sorted()
        let markerTop = try XCTUnwrap(solidRows.first)
        XCTAssertGreaterThanOrEqual(markerTop, marker)
        let textRows = (0..<markerTop).filter { row in
            (0..<buffer.width / 2).contains { x in
                let pixel = buffer.pixel(x: x, y: row)
                return pixel.red < 200 || pixel.green < 200 || pixel.blue < 200
            }
        }
        let lowestText = try XCTUnwrap(textRows.last)
        let gapInPoints = Double(markerTop - lowestText) / 2
        XCTAssertLessThan(gapInPoints, 8, "The label has floated away from its marker")
    }

    // MARK: - Updates

    /// Real charts get new data. A stale map of the layout's subviews would leave labels
    /// attached to the wrong points, so the result must match a chart drawn fresh.
    func testChangingThePointsMatchesAFreshlyDrawnChart() throws {
        let size = ProposedViewSize(self.size)
        let first = ContributionChart(points: Fixtures.mixed, title: "First")
        let second = ContributionChart(points: Fixtures.contributors, title: "Second")

        let renderer = ImageRenderer(content: first)
        renderer.scale = 2
        renderer.proposedSize = size
        XCTAssertNotNil(renderer.cgImage)

        renderer.content = second
        let updated = try XCTUnwrap(renderer.cgImage.flatMap(PixelBuffer.init))

        let freshRenderer = ImageRenderer(content: second)
        freshRenderer.scale = 2
        freshRenderer.proposedSize = size
        let fresh = try XCTUnwrap(freshRenderer.cgImage.flatMap(PixelBuffer.init))

        XCTAssertEqual(updated.differingFraction(from: fresh, channelTolerance: 2), 0)
    }

    func testGrowingAndShrinkingTheDataKeepsLabelsCorrect() throws {
        let size = ProposedViewSize(self.size)
        let small = ContributionChart(points: Array(Fixtures.mixed.prefix(2)))
        let large = ContributionChart(points: Fixtures.dense(60))

        let renderer = ImageRenderer(content: small)
        renderer.scale = 2
        renderer.proposedSize = size
        XCTAssertNotNil(renderer.cgImage)
        renderer.content = large
        XCTAssertNotNil(renderer.cgImage)
        renderer.content = small
        let result = try XCTUnwrap(renderer.cgImage.flatMap(PixelBuffer.init))

        let freshRenderer = ImageRenderer(content: small)
        freshRenderer.scale = 2
        freshRenderer.proposedSize = size
        let fresh = try XCTUnwrap(freshRenderer.cgImage.flatMap(PixelBuffer.init))
        XCTAssertEqual(result.differingFraction(from: fresh, channelTolerance: 2), 0)
    }

    // MARK: - Right to left

    /// `Layout` mirrors placement automatically but `Canvas` content does not. If they ever
    /// disagreed, markers would no longer line up with the labels and axis around them.
    func testRightToLeftMirrorsTheMarks() throws {
        let chart = ContributionChart(points: Fixtures.contributors, configuration: labelsOff)
        let leftToRight = try pixels(chart)
        let rightToLeft = try pixels(chart, environment: RenderEnvironment(layoutDirection: .rightToLeft))
        XCTAssertEqual(leftToRight.mirrored.differingFraction(from: rightToLeft, channelTolerance: 2), 0, accuracy: 0.001)
    }

    func testRightToLeftMirrorsTheDecorations() throws {
        var configuration = labelsOff
        configuration.layout.pointDistribution = .edgeToEdge
        configuration.regions = [ChartRegion(points: 2...2, color: .gray)]
        configuration.referenceLines = [ChartReferenceLine(value: 1, points: 0...1, style: ChartLineStyle(color: .purple, thickness: 3))]
        configuration.categoryTicks = ChartCategoryTicks(points: [1], length: 8)
        configuration.valueAxis = ChartValueAxis(showsLabels: false)
        let chart = ContributionChart(points: Fixtures.contributors, configuration: configuration)
        let leftToRight = try pixels(chart)
        let rightToLeft = try pixels(chart, environment: RenderEnvironment(layoutDirection: .rightToLeft))
        XCTAssertEqual(leftToRight.mirrored.differingFraction(from: rightToLeft, channelTolerance: 2), 0, accuracy: 0.001)
    }

    func testRightToLeftKeepsMarkersAboveTheBaseline() throws {
        let buffer = try pixels(
            ContributionChart(points: Fixtures.contributors, configuration: labelsOff),
            environment: RenderEnvironment(layoutDirection: .rightToLeft)
        )
        let baseline = baselineRow(in: buffer)
        XCTAssertTrue(buffer.positions(where: isGreen).allSatisfy { $0.y < baseline })
        // The first point is the largest, so it now sits at the right.
        XCTAssertGreaterThan(try XCTUnwrap(buffer.positions(where: isGreen).map(\.x).max()), buffer.width / 2)
    }

    // MARK: - Appearance

    func testDarkAppearanceChangesTheBaseline() throws {
        let chart = ContributionChart(points: Fixtures.contributors, configuration: labelsOff)
        let dark = try pixels(chart, environment: RenderEnvironment(colorScheme: .dark, background: .black))
        let row = (0..<dark.height).max { first, second in
            let count: (Int) -> Int = { row in
                (0..<dark.width).filter { dark.pixel(x: $0, y: row).red > 200 }.count
            }
            return count(first) < count(second)
        } ?? 0
        XCTAssertGreaterThan(dark.pixel(x: 0, y: row).red, 200, "The baseline should be light on black")
    }

    /// Default marker colours are chosen to work on any background, so they must not change.
    func testMarkerColourAndPositionAreTheSameInEitherAppearance() throws {
        let chart = ContributionChart(points: Fixtures.points([5]), configuration: labelsOff)
        let light = try pixels(chart)
        let dark = try pixels(chart, environment: RenderEnvironment(colorScheme: .dark, background: .black))

        let positions = light.positions(where: isGreen)
        let center = try XCTUnwrap(positions.sorted { $0.y < $1.y }.dropFirst(positions.count / 2).first)
        XCTAssertEqual(light.pixel(x: center.x, y: center.y), dark.pixel(x: center.x, y: center.y))
    }

    // MARK: - Display scales

    func testRendersAtEveryDisplayScale() throws {
        for displayScale in [CGFloat(1), 2, 3] {
            let buffer = try pixels(
                ContributionChart(points: Fixtures.contributors),
                size: CGSize(width: 100, height: 100),
                environment: RenderEnvironment(displayScale: displayScale)
            )
            XCTAssertEqual(buffer.width, Int(100 * displayScale))
            XCTAssertFalse(buffer.positions(where: isGreen).isEmpty, "scale \(displayScale)")
        }
    }

    /// A crisp line has solid pixels: antialiased edges would mean it is not pixel-aligned.
    func testLinesAreCrispAtEveryDisplayScale() throws {
        for displayScale in [CGFloat(1), 2, 3] {
            var configuration = labelsOff
            configuration.style.baseline = ChartLineStyle(color: .black, thickness: 1)
            let buffer = try pixels(
                ContributionChart(points: Fixtures.points([5, -3]), configuration: configuration),
                size: CGSize(width: 211, height: 137),
                environment: RenderEnvironment(displayScale: displayScale)
            )
            let thickness = (0..<buffer.height).filter { row in
                let value = buffer.pixel(x: 2, y: row).red
                return value < 250
            }
            XCTAssertEqual(thickness.count, Int(displayScale), "scale \(displayScale): rows \(thickness)")
            for row in thickness {
                XCTAssertLessThan(buffer.pixel(x: 2, y: row).red, 10, "scale \(displayScale): row \(row) is blurred")
            }
        }
    }

    // MARK: - Robustness

    func testExtremeInputRendersWithoutCrashing() {
        let hostile = Fixtures.points([.nan, .infinity, .greatestFiniteMagnitude, -.greatestFiniteMagnitude, 1e-320, 0])
        var configuration = ChartConfiguration()
        configuration.style.marker.diameter = .nan
        configuration.style.stem.width = -5
        configuration.style.annotation.titleLineLimit = -1
        configuration.style.annotation.lineSpacing = .nan
        configuration.style.baseline = ChartLineStyle(color: .black, thickness: .infinity, dash: [1])
        configuration.valueAxis = ChartValueAxis(desiredTickCount: -4)
        let chart = ContributionChart(points: hostile, configuration: configuration)
        for size in [CGSize.zero, CGSize(width: 1, height: 1), CGSize(width: 5000, height: 2), size] {
            _ = ChartRendering.pixels(of: chart, size: size)
        }
    }

    func testHandlesAThousandPoints() throws {
        let buffer = try pixels(ContributionChart(points: Fixtures.dense(1000)))
        XCTAssertFalse(buffer.positions(where: isGreen).isEmpty)
        XCTAssertFalse(buffer.positions(where: isRed).isEmpty)
    }

    func testAudioGraphCanBeDisabled() throws {
        var configuration = ChartConfiguration()
        configuration.accessibility.isAudioGraphEnabled = false
        XCTAssertNotNil(ChartRendering.pixels(of: ContributionChart(points: Fixtures.contributors, configuration: configuration), size: size))
    }

    func testHeaderAlignments() throws {
        func header(_ alignment: TextAlignment) throws -> PixelBuffer {
            var configuration = labelsOff
            configuration.style.header.alignment = alignment
            return try pixels(ContributionChart(points: Fixtures.contributors, title: "T", configuration: configuration))
        }
        func inkX(_ buffer: PixelBuffer) -> Int {
            // Only the title's row range, above the baseline's area.
            let xs = (0..<40).flatMap { row in (0..<buffer.width).filter { isInk(buffer.pixel(x: $0, y: row)) } }
            return xs.min() ?? -1
        }
        XCTAssertLessThan(inkX(try header(.leading)), 40)
        let centered = inkX(try header(.center))
        XCTAssertEqual(Double(centered), Double(350), accuracy: 40)
        XCTAssertGreaterThan(inkX(try header(.trailing)), 600)
    }

    func testEveryDynamicTypeSizeRenders() throws {
        for typeSize in DynamicTypeSize.allCases {
            let buffer = try pixels(
                ContributionChart(points: Fixtures.contributors, title: "Your Biggest Contributors & Detractors"),
                environment: RenderEnvironment(dynamicTypeSize: typeSize)
            )
            XCTAssertFalse(buffer.positions(where: isGreen).isEmpty, "\(typeSize)")
        }
    }
}
