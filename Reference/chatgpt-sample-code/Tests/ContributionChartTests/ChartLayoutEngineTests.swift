import XCTest
@testable import ContributionChart

final class ChartLayoutEngineTests: XCTestCase {
    func testEmptyInputProducesNoGeometry() {
        let engine = ChartLayoutEngine(configuration: .init())
        XCTAssertTrue(engine.makeGeometry(points: [], size: .init(width: 300, height: 180)).isEmpty)
    }

    func testPointsAreEvenlyDistributedHorizontally() {
        let engine = ChartLayoutEngine(configuration: .init(horizontalInset: 20))
        let points = [
            ChartDataPoint(id: "a", title: "A", value: 10),
            ChartDataPoint(id: "b", title: "B", value: 5),
            ChartDataPoint(id: "c", title: "C", value: -2)
        ]
        let result = engine.makeGeometry(points: points, size: .init(width: 300, height: 180))
        XCTAssertEqual(result[0].x, 20, accuracy: 0.001)
        XCTAssertEqual(result[1].x, 150, accuracy: 0.001)
        XCTAssertEqual(result[2].x, 280, accuracy: 0.001)
    }

    func testSinglePointIsCentered() {
        let engine = ChartLayoutEngine(configuration: .init(horizontalInset: 20))
        let result = engine.makeGeometry(
            points: [.init(id: "a", title: "A", value: 5)],
            size: .init(width: 300, height: 180)
        )
        XCTAssertEqual(result.first?.x ?? 0, 150, accuracy: 0.001)
    }

    func testGeometryRemainsInsideVerticalBounds() {
        let engine = ChartLayoutEngine(configuration: .init(verticalInset: 16))
        let result = engine.makeGeometry(
            points: [.init(title: "High", value: 999), .init(title: "Low", value: -999)],
            size: .init(width: 300, height: 180)
        )
        XCTAssertTrue(result.allSatisfy { $0.y >= 16 && $0.y <= 164 })
    }

    func testNonFiniteValueDoesNotProduceInvalidPosition() {
        let engine = ChartLayoutEngine(configuration: .init())
        let result = engine.makeGeometry(
            points: [.init(title: "Invalid", value: .nan)],
            size: .init(width: 300, height: 180)
        )
        XCTAssertTrue(result.first?.y.isFinite == true)
    }
}
