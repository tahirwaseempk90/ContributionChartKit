import XCTest
@testable import ContributionChart

final class ChartDataPointTests: XCTestCase {
    func testInitializerStoresValues() {
        let point = ChartDataPoint(id: "id", title: "Title", value: 1.5)
        XCTAssertEqual(point.id, "id")
        XCTAssertEqual(point.title, "Title")
        XCTAssertEqual(point.value, 1.5)
    }

    func testIdentifierDefaultsToTitle() {
        XCTAssertEqual(ChartDataPoint(title: "VFIAX", value: 1).id, "VFIAX")
    }

    /// A random default would give the same data a new identity on every view update.
    func testDefaultIdentityIsStableWhenDataIsRebuilt() {
        XCTAssertEqual(ChartDataPoint(title: "A", value: 1).id, ChartDataPoint(title: "A", value: 2).id)
    }

    func testPolarityClassification() {
        XCTAssertEqual(ChartDataPoint(title: "", value: 0.001).polarity, .positive)
        XCTAssertEqual(ChartDataPoint(title: "", value: -0.001).polarity, .negative)
        XCTAssertEqual(ChartDataPoint(title: "", value: 0).polarity, .zero)
    }

    func testNegativeZeroIsZero() {
        XCTAssertEqual(ChartDataPoint(title: "", value: -0.0).polarity, .zero)
    }

    func testPolarityOfNonFiniteValues() {
        XCTAssertEqual(ChartDataPoint(title: "", value: .nan).polarity, .zero)
        XCTAssertEqual(ChartDataPoint(title: "", value: .infinity).polarity, .positive)
        XCTAssertEqual(ChartDataPoint(title: "", value: -.infinity).polarity, .negative)
    }

    func testPolarityOfSmallestRepresentableValues() {
        XCTAssertEqual(ChartDataPoint(title: "", value: .leastNonzeroMagnitude).polarity, .positive)
        XCTAssertEqual(ChartDataPoint(title: "", value: -.leastNonzeroMagnitude).polarity, .negative)
    }

    func testPlottability() {
        XCTAssertTrue(ChartDataPoint(title: "", value: 0).isPlottable)
        XCTAssertTrue(ChartDataPoint(title: "", value: .greatestFiniteMagnitude).isPlottable)
        XCTAssertFalse(ChartDataPoint(title: "", value: .nan).isPlottable)
        XCTAssertFalse(ChartDataPoint(title: "", value: .infinity).isPlottable)
        XCTAssertFalse(ChartDataPoint(title: "", value: -.infinity).isPlottable)
    }

    func testEqualityComparesEveryField() {
        let point = ChartDataPoint(id: "a", title: "A", value: 1)
        XCTAssertEqual(point, ChartDataPoint(id: "a", title: "A", value: 1))
        XCTAssertNotEqual(point, ChartDataPoint(id: "b", title: "A", value: 1))
        XCTAssertNotEqual(point, ChartDataPoint(id: "a", title: "B", value: 1))
        XCTAssertNotEqual(point, ChartDataPoint(id: "a", title: "A", value: 2))
    }

    /// `Equatable` requires reflexivity, which comparing `.nan` directly would break.
    func testNaNPointEqualsItself() {
        let point = ChartDataPoint(title: "A", value: .nan)
        XCTAssertEqual(point, point)
        XCTAssertNotEqual(point, ChartDataPoint(title: "A", value: 1))
    }

    func testEqualPointsHashEqually() {
        let first = ChartDataPoint(id: "a", title: "A", value: 1)
        let second = ChartDataPoint(id: "a", title: "A", value: 1)
        XCTAssertEqual(first.hashValue, second.hashValue)
    }

    func testNaNPointsWorkInSets() {
        let points: Set = [ChartDataPoint(title: "A", value: .nan), ChartDataPoint(title: "A", value: .nan)]
        XCTAssertEqual(points.count, 1)
    }

    func testPositiveAndNegativeZeroAreEqualAndHashEqually() {
        let positive = ChartDataPoint(title: "A", value: 0.0)
        let negative = ChartDataPoint(title: "A", value: -0.0)
        XCTAssertEqual(positive, negative)
        XCTAssertEqual(positive.hashValue, negative.hashValue)
    }

    func testPointsCanCrossConcurrencyDomains() async {
        let point = ChartDataPoint(title: "A", value: 1)
        let title = await Task.detached { point.title }.value
        XCTAssertEqual(title, "A")
    }
}
