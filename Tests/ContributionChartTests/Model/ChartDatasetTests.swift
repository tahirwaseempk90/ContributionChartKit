import XCTest
@testable import ContributionChart

final class ChartDatasetTests: XCTestCase {
    func testEmptyInput() {
        let dataset = ChartDataset(points: [])
        XCTAssertTrue(dataset.isEmpty)
        XCTAssertEqual(dataset.count, 0)
        XCTAssertEqual(dataset.invalidCount, 0)
    }

    func testKeepsOrderOfValidPoints() {
        let dataset = ChartDataset(points: Fixtures.contributors)
        XCTAssertEqual(dataset.entries.map(\.point.title), ["VFIAX", "VTNIX", "VTSAX"])
        XCTAssertEqual(dataset.entries.map(\.position), [0, 1, 2])
    }

    func testLeavesOutNonFiniteValues() {
        let dataset = ChartDataset(points: Fixtures.points([1, .nan, .infinity, -.infinity, -1]))
        XCTAssertEqual(dataset.entries.map(\.point.value), [1, -1])
        XCTAssertEqual(dataset.invalidCount, 3)
    }

    func testAllInvalidInputIsEmpty() {
        let dataset = ChartDataset(points: Fixtures.points([.nan, .infinity]))
        XCTAssertTrue(dataset.isEmpty)
        XCTAssertEqual(dataset.invalidCount, 2)
    }

    func testPositionsCloseGapsButSourceIndicesDoNot() {
        let dataset = ChartDataset(points: Fixtures.points([1, .nan, 2]))
        XCTAssertEqual(dataset.entries.map(\.position), [0, 1])
        XCTAssertEqual(dataset.entries.map(\.sourceIndex), [0, 2])
    }

    func testKeepsZeroValues() {
        XCTAssertEqual(ChartDataset(points: Fixtures.points([0, 0])).count, 2)
    }

    // MARK: - Duplicate identifiers

    func testDuplicateIdentifiersBecomeUnique() {
        let points = [
            ChartDataPoint(id: "a", title: "First", value: 1),
            ChartDataPoint(id: "a", title: "Second", value: 2),
            ChartDataPoint(id: "a", title: "Third", value: 3)
        ]
        let dataset = ChartDataset(points: points)
        XCTAssertEqual(dataset.entries.map(\.id), ["a", "a#2", "a#3"])
        XCTAssertEqual(dataset.entries.map(\.point.title), ["First", "Second", "Third"])
    }

    func testDuplicatesKeepTheCallersOriginalIdentifierOnThePoint() {
        let points = [ChartDataPoint(id: "a", title: "", value: 1), ChartDataPoint(id: "a", title: "", value: 2)]
        XCTAssertEqual(ChartDataset(points: points).entries.map(\.point.id), ["a", "a"])
    }

    func testGeneratedIdentifiersAvoidExistingOnes() {
        let points = [
            ChartDataPoint(id: "a#2", title: "", value: 1),
            ChartDataPoint(id: "a", title: "", value: 2),
            ChartDataPoint(id: "a", title: "", value: 3)
        ]
        let identifiers = ChartDataset(points: points).entries.map(\.id)
        XCTAssertEqual(Set(identifiers).count, 3)
        XCTAssertEqual(identifiers, ["a#2", "a", "a#3"])
    }

    func testRepeatedTitlesWithDefaultIdentifiersAreUnique() {
        let points = (0..<1000).map { ChartDataPoint(title: "Same", value: Double($0)) }
        XCTAssertEqual(Set(ChartDataset(points: points).entries.map(\.id)).count, 1000)
    }

    // MARK: - Prominent entries

    func testProminentEntriesReturnsEverythingUnderTheLimit() {
        let dataset = ChartDataset(points: Fixtures.contributors)
        XCTAssertEqual(dataset.prominentEntries(limit: 3), dataset.entries)
    }

    func testProminentEntriesPicksLargestMagnitudesInDisplayOrder() {
        let dataset = ChartDataset(points: Fixtures.points([1, -9, 2, 8, -3]))
        XCTAssertEqual(dataset.prominentEntries(limit: 2).map(\.point.value), [-9, 8])
    }

    func testProminentEntriesBreaksTiesByPosition() {
        let dataset = ChartDataset(points: Fixtures.points([5, -5, 5]))
        XCTAssertEqual(dataset.prominentEntries(limit: 2).map(\.position), [0, 1])
    }

    // MARK: - Source ranges

    func testPositionsCoveringARange() {
        let dataset = ChartDataset(points: Fixtures.points([1, 2, 3, 4]))
        XCTAssertEqual(dataset.positions(covering: 1...2), 1...2)
    }

    func testPositionsCoveringClampsToAvailablePoints() {
        let dataset = ChartDataset(points: Fixtures.points([1, 2, 3]))
        XCTAssertEqual(dataset.positions(covering: 1...99), 1...2)
        XCTAssertEqual(dataset.positions(covering: -5...0), 0...0)
    }

    func testPositionsCoveringOutsideTheDataIsNil() {
        XCTAssertNil(ChartDataset(points: Fixtures.points([1, 2])).positions(covering: 5...9))
    }

    func testPositionsCoveringMapsPastInvalidPoints() {
        let dataset = ChartDataset(points: Fixtures.points([1, .nan, 2, 3]))
        XCTAssertEqual(dataset.positions(covering: 2...3), 1...2)
        XCTAssertNil(dataset.positions(covering: 1...1))
    }
}
