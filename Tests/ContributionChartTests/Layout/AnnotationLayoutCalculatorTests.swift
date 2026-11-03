import XCTest
@testable import ContributionChart

final class AnnotationLayoutCalculatorTests: XCTestCase {
    private let bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
    private let labelSize = CGSize(width: 40, height: 20)

    private func calculator(padding: CGFloat = 0) -> AnnotationLayoutCalculator {
        AnnotationLayoutCalculator(bounds: bounds, markerSpacing: 4, collisionPadding: padding)
    }

    private func mark(
        _ position: Int,
        x: CGFloat,
        y: CGFloat,
        polarity: ChartDataPoint.Polarity = .positive,
        stem: CGRect? = nil
    ) -> ChartMark {
        ChartMark(position: position, polarity: polarity, center: CGPoint(x: x, y: y), markerDiameter: 10, stem: stem)
    }

    private func request(_ position: Int, magnitude: Double = 1, size: CGSize? = nil) -> AnnotationLayoutCalculator.Request {
        .init(index: position, position: position, magnitude: magnitude, size: size ?? labelSize)
    }

    // MARK: - Placement

    func testPositiveLabelSitsAboveItsMarker() {
        let frame = calculator().frame(for: labelSize, next: mark(0, x: 200, y: 200))
        XCTAssertEqual(frame, CGRect(x: 180, y: 171, width: 40, height: 20))
    }

    func testNegativeLabelSitsBelowItsMarker() {
        let frame = calculator().frame(for: labelSize, next: mark(0, x: 200, y: 200, polarity: .negative))
        XCTAssertEqual(frame, CGRect(x: 180, y: 209, width: 40, height: 20))
    }

    func testZeroLabelSitsAboveItsMarker() {
        let frame = calculator().frame(for: labelSize, next: mark(0, x: 200, y: 200, polarity: .zero))
        XCTAssertLessThan(frame.maxY, 200)
    }

    func testLabelIsCenteredOnItsMarker() {
        XCTAssertEqual(calculator().frame(for: labelSize, next: mark(0, x: 123, y: 200)).midX, 123)
    }

    func testLabelsShiftInwardRatherThanClipAtEachEdge() {
        let calculator = calculator()
        XCTAssertEqual(calculator.frame(for: labelSize, next: mark(0, x: 5, y: 200)).minX, 0)
        XCTAssertEqual(calculator.frame(for: labelSize, next: mark(0, x: 395, y: 200)).maxX, 400)
        XCTAssertEqual(calculator.frame(for: labelSize, next: mark(0, x: 200, y: 5)).minY, 0)
        XCTAssertEqual(calculator.frame(for: labelSize, next: mark(0, x: 200, y: 395, polarity: .negative)).maxY, 400)
    }

    // MARK: - Collisions

    func testSeparatedLabelsAreAllShown() {
        let marks = [mark(0, x: 100, y: 200), mark(1, x: 300, y: 200)]
        let placements = calculator().placements(for: [request(0), request(1)], marks: marks)
        XCTAssertEqual(placements.map(\.isVisible), [true, true])
    }

    func testOverlappingLabelsKeepTheLargestValue() {
        let marks = [mark(0, x: 100, y: 200), mark(1, x: 110, y: 200)]
        let placements = calculator().placements(
            for: [request(0, magnitude: 1), request(1, magnitude: 9)],
            marks: marks
        )
        XCTAssertEqual(placements.map(\.isVisible), [false, true])
    }

    func testEqualValuesKeepTheEarlierPoint() {
        let marks = [mark(0, x: 100, y: 200), mark(1, x: 110, y: 200)]
        let placements = calculator().placements(for: [request(0), request(1)], marks: marks)
        XCTAssertEqual(placements.map(\.isVisible), [true, false])
    }

    func testLabelsAtDifferentHeightsCanShareTheSameColumn() {
        let marks = [mark(0, x: 100, y: 100), mark(1, x: 300, y: 300)]
        let close = [mark(0, x: 100, y: 100), mark(1, x: 110, y: 300)]
        let requests = [request(0), request(1)]
        XCTAssertEqual(calculator().placements(for: requests, marks: marks).map(\.isVisible), [true, true])
        XCTAssertEqual(calculator().placements(for: requests, marks: close).map(\.isVisible), [true, true])
    }

    func testPaddingKeepsLabelsApart() {
        // These labels end up 2 points apart horizontally.
        let marks = [mark(0, x: 100, y: 200), mark(1, x: 142, y: 200)]
        let requests = [request(0), request(1)]
        XCTAssertEqual(calculator(padding: 0).placements(for: requests, marks: marks).map(\.isVisible), [true, true])
        XCTAssertEqual(calculator(padding: 4).placements(for: requests, marks: marks).map(\.isVisible), [true, false])
    }

    func testResultIsDeterministicAndKeepsRequestOrder() {
        let marks = (0..<20).map { mark($0, x: CGFloat($0) * 15 + 20, y: 200) }
        let requests = (0..<20).map { request($0, magnitude: Double(($0 * 7) % 20)) }
        let first = calculator().placements(for: requests, marks: marks)
        let second = calculator().placements(for: requests, marks: marks)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.map(\.index), Array(0..<20))
    }

    func testVisibleLabelsNeverOverlapInADenseChart() {
        let marks = (0..<200).map { mark($0, x: CGFloat($0) * 2, y: 150 + CGFloat($0 % 17) * 4) }
        let requests = (0..<200).map { request($0, magnitude: Double($0 % 31)) }
        let visible = calculator(padding: 1).placements(for: requests, marks: marks).filter(\.isVisible)
        XCTAssertFalse(visible.isEmpty)
        for (index, first) in visible.enumerated() {
            for second in visible[(index + 1)...] {
                XCTAssertFalse(first.frame.intersects(second.frame), "\(first) overlaps \(second)")
            }
        }
    }

    // MARK: - Other marks

    func testLabelMayNotCoverAnotherPointsMarker() {
        // The neighbouring marker sits exactly where the label would go.
        let marks = [mark(0, x: 100, y: 200), mark(1, x: 110, y: 180)]
        let placements = calculator().placements(for: [request(0, magnitude: 9)], marks: marks)
        XCTAssertEqual(placements.first?.isVisible, false)
    }

    func testLabelMayNotCoverAnotherPointsStem() {
        let stem = CGRect(x: 108, y: 100, width: 4, height: 200)
        let marks = [mark(0, x: 100, y: 200), mark(1, x: 110, y: 100, stem: stem)]
        let placements = calculator().placements(for: [request(0, magnitude: 9)], marks: marks)
        XCTAssertEqual(placements.first?.isVisible, false)
    }

    func testLabelMayPassAboveAShorterNeighbour() {
        let marks = [mark(0, x: 100, y: 200), mark(1, x: 110, y: 300)]
        let placements = calculator().placements(for: [request(0, magnitude: 9)], marks: marks)
        XCTAssertEqual(placements.first?.isVisible, true)
    }

    func testLabelIgnoresItsOwnMarks() {
        let stem = CGRect(x: 98, y: 160, width: 4, height: 200)
        let placements = calculator().placements(for: [request(0)], marks: [mark(0, x: 100, y: 200, stem: stem)])
        XCTAssertEqual(placements.first?.isVisible, true)
    }

    // MARK: - Limits

    func testLabelWiderThanTheBoundsIsHidden() {
        let placements = calculator().placements(
            for: [request(0, size: CGSize(width: 500, height: 20))],
            marks: [mark(0, x: 200, y: 200)]
        )
        XCTAssertEqual(placements.first?.isVisible, false)
    }

    func testLabelTallerThanTheBoundsIsHidden() {
        let placements = calculator().placements(
            for: [request(0, size: CGSize(width: 40, height: 500))],
            marks: [mark(0, x: 200, y: 200)]
        )
        XCTAssertEqual(placements.first?.isVisible, false)
    }

    func testEmptyLabelIsHidden() {
        let placements = calculator().placements(
            for: [request(0, size: .zero)],
            marks: [mark(0, x: 200, y: 200)]
        )
        XCTAssertEqual(placements.first?.isVisible, false)
    }

    func testRequestForAMissingMarkIsSkipped() {
        let placements = calculator().placements(for: [request(5)], marks: [mark(0, x: 200, y: 200)])
        XCTAssertTrue(placements.isEmpty)
    }
}
