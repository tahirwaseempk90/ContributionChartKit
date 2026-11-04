import XCTest
@testable import ContributionChart

final class ChartScaleTests: XCTestCase {
    func testEndpointsMapToTheEdgesOfThePlot() {
        let scale = ChartScale(lower: -20, upper: 30)
        XCTAssertEqual(scale.fraction(of: -20), 0)
        XCTAssertEqual(scale.fraction(of: 30), 1)
    }

    func testMappingIsLinear() {
        let scale = ChartScale(lower: -20, upper: 30)
        XCTAssertEqual(scale.fraction(of: 5), 0.5, accuracy: 1e-12)
        XCTAssertEqual(scale.fraction(of: 0), 0.4, accuracy: 1e-12)
    }

    func testBaselineFraction() {
        XCTAssertEqual(ChartScale(lower: -20, upper: 30).baselineFraction, 0.4, accuracy: 1e-12)
        XCTAssertEqual(ChartScale(lower: 0, upper: 10).baselineFraction, 0)
        XCTAssertEqual(ChartScale(lower: -10, upper: 0).baselineFraction, 1)
        XCTAssertEqual(ChartScale(lower: -10, upper: 10).baselineFraction, 0.5)
    }

    func testValuesOutsideTheRangeClampToItsEdges() {
        let scale = ChartScale(lower: -1, upper: 1)
        XCTAssertEqual(scale.fraction(of: 100), 1)
        XCTAssertEqual(scale.fraction(of: -100), 0)
    }

    func testNonFiniteValuesMapToTheBaseline() {
        let scale = ChartScale(lower: -20, upper: 30)
        for value in [Double.nan, .infinity, -.infinity] {
            XCTAssertEqual(scale.fraction(of: value), scale.baselineFraction, accuracy: 1e-12)
        }
    }

    /// Subtracting these bounds directly would overflow to infinity.
    func testExtremeRangeDoesNotOverflow() {
        let scale = ChartScale(lower: -.greatestFiniteMagnitude, upper: .greatestFiniteMagnitude)
        XCTAssertEqual(scale.fraction(of: 0), 0.5, accuracy: 1e-12)
        XCTAssertEqual(scale.fraction(of: .greatestFiniteMagnitude), 1)
        XCTAssertEqual(scale.fraction(of: -.greatestFiniteMagnitude), 0)
    }

    func testSmallestRepresentableRange() {
        let scale = ChartScale(lower: 0, upper: .leastNonzeroMagnitude)
        XCTAssertEqual(scale.fraction(of: .leastNonzeroMagnitude), 1)
        XCTAssertEqual(scale.fraction(of: 0), 0)
    }

    func testAValueFarLargerThanATinyRangeStaysFinite() {
        let scale = ChartScale(lower: 0, upper: .leastNormalMagnitude)
        XCTAssertEqual(scale.fraction(of: .greatestFiniteMagnitude), 1)
    }

    func testDegenerateScalesStayInTheMiddle() {
        XCTAssertEqual(ChartScale(lower: 0, upper: 0).fraction(of: 5), 0.5)
        XCTAssertEqual(ChartScale(lower: 5, upper: 5).fraction(of: 5), 0.5)
    }

    func testContains() {
        let scale = ChartScale(lower: -1, upper: 1)
        XCTAssertTrue(scale.contains(0))
        XCTAssertTrue(scale.contains(1))
        XCTAssertTrue(scale.contains(-1))
        XCTAssertFalse(scale.contains(1.1))
        XCTAssertFalse(scale.contains(.nan))
    }
}

final class ChartScaleCalculatorTests: XCTestCase {
    private func domain(_ values: [Double], _ mode: ChartScaleMode = .proportional) -> ChartScale {
        ChartScaleCalculator.domain(for: values, mode: mode)
    }

    private func output(
        _ values: [Double],
        _ mode: ChartScaleMode = .proportional,
        ticks: Int = 6
    ) -> ChartScaleCalculator.Output {
        ChartScaleCalculator.output(for: values, mode: mode, desiredTickCount: ticks)
    }

    // MARK: - Proportional

    func testPositiveOnlyDataStartsAtZero() {
        XCTAssertEqual(domain([3, 7, 1]), ChartScale(lower: 0, upper: 7))
    }

    func testNegativeOnlyDataEndsAtZero() {
        XCTAssertEqual(domain([-3, -7, -1]), ChartScale(lower: -7, upper: 0))
    }

    func testMixedDataUsesItsExtremes() {
        XCTAssertEqual(domain([11.05, 6.31, -2.70]), ChartScale(lower: -2.70, upper: 11.05))
    }

    func testEqualValuesStillReachZero() {
        XCTAssertEqual(domain([5, 5, 5]), ChartScale(lower: 0, upper: 5))
    }

    func testZeroValuesUseTheUnitScale() {
        XCTAssertEqual(domain([0, 0, -0.0]), .unit)
    }

    func testNoValuesUseTheUnitScale() {
        XCTAssertEqual(domain([]), .unit)
    }

    func testInvalidValuesAreIgnored() {
        XCTAssertEqual(domain([.nan, 3, .infinity, -.infinity, -1]), ChartScale(lower: -1, upper: 3))
        XCTAssertEqual(domain([.nan]), .unit)
    }

    func testVerySmallValuesKeepTheirRange() {
        XCTAssertEqual(domain([1e-300, -1e-300]), ChartScale(lower: -1e-300, upper: 1e-300))
        XCTAssertEqual(domain([.leastNonzeroMagnitude]).upper, .leastNonzeroMagnitude)
    }

    func testVeryLargeValuesKeepTheirRange() {
        let extreme = Double.greatestFiniteMagnitude
        XCTAssertEqual(domain([extreme, -extreme]), ChartScale(lower: -extreme, upper: extreme))
    }

    // MARK: - Symmetric

    func testSymmetricExtendsEquallyBothWays() {
        XCTAssertEqual(domain([11, -2], .symmetric), ChartScale(lower: -11, upper: 11))
        XCTAssertEqual(domain([3, -9], .symmetric), ChartScale(lower: -9, upper: 9))
    }

    func testSymmetricCentersTheBaselineForOneSidedData() {
        XCTAssertEqual(domain([4, 8], .symmetric).baselineFraction, 0.5)
        XCTAssertEqual(domain([-4, -8], .symmetric).baselineFraction, 0.5)
    }

    func testSymmetricWithZeroValuesUsesTheUnitScale() {
        XCTAssertEqual(domain([0], .symmetric), .unit)
    }

    // MARK: - Fixed

    func testFixedUsesTheGivenRange() {
        XCTAssertEqual(domain([100], .fixed(lower: -5, upper: 10)), ChartScale(lower: -5, upper: 10))
    }

    func testFixedRangeIsExtendedToReachZero() {
        XCTAssertEqual(domain([], .fixed(lower: 5, upper: 10)), ChartScale(lower: 0, upper: 10))
        XCTAssertEqual(domain([], .fixed(lower: -10, upper: -5)), ChartScale(lower: -10, upper: 0))
    }

    func testFixedRangeInReverseIsCorrected() {
        XCTAssertEqual(domain([], .fixed(lower: 10, upper: -5)), ChartScale(lower: -5, upper: 10))
    }

    func testInvalidFixedRangesFallBackToTheUnitScale() {
        XCTAssertEqual(domain([], .fixed(lower: .nan, upper: 10)), .unit)
        XCTAssertEqual(domain([], .fixed(lower: 0, upper: .infinity)), .unit)
        XCTAssertEqual(domain([], .fixed(lower: -.infinity, upper: 0)), .unit)
        XCTAssertEqual(domain([], .fixed(lower: 0, upper: 0)), .unit)
    }

    // MARK: - Nice steps

    func testNiceStepChoosesRoundMultiples() {
        let cases: [(lower: Double, upper: Double, expected: Double)] = [
            (0, 10, 2),
            (0, 9, 2),
            (0, 12, 5),
            (0, 20, 5),
            (0, 50, 10),
            (0, 100, 20),
            (0, 1, 0.2),
            (-18.1, 23.2, 10)
        ]
        for testCase in cases {
            let step = ChartScaleCalculator.niceStep(lower: testCase.lower, upper: testCase.upper, desiredCount: 6)
            XCTAssertEqual(try XCTUnwrap(step), testCase.expected, accuracy: 1e-9, "\(testCase)")
        }
    }

    func testNiceStepAtEachMultiplierBoundary() throws {
        // A range of five intervals, so the rough step equals the value under test.
        for (rough, expected) in [(1.0, 1.0), (2.0, 2.0), (2.5, 5.0), (5.0, 5.0), (7.0, 10.0)] {
            let step = try XCTUnwrap(ChartScaleCalculator.niceStep(lower: 0, upper: rough * 5, desiredCount: 6))
            XCTAssertEqual(step, expected, accuracy: 1e-9, "\(rough)")
        }
    }

    func testNiceStepRejectsAnEmptyRange() {
        XCTAssertNil(ChartScaleCalculator.niceStep(lower: 0, upper: 0, desiredCount: 6))
        XCTAssertNil(ChartScaleCalculator.niceStep(lower: 5, upper: 1, desiredCount: 6))
    }

    func testNiceStepRejectsARangeWithNoFiniteStep() {
        let extreme = Double.greatestFiniteMagnitude
        XCTAssertNil(ChartScaleCalculator.niceStep(lower: -extreme, upper: extreme, desiredCount: 2))
        XCTAssertNil(ChartScaleCalculator.niceStep(lower: 0, upper: .infinity, desiredCount: 6))
    }

    func testNiceStepRejectsARangeTooSmallToSubdivide() {
        XCTAssertNil(ChartScaleCalculator.niceStep(lower: 0, upper: .leastNonzeroMagnitude, desiredCount: 6))
    }

    func testNiceStepHandlesLowTickCounts() {
        XCTAssertNotNil(ChartScaleCalculator.niceStep(lower: 0, upper: 10, desiredCount: 0))
        XCTAssertNotNil(ChartScaleCalculator.niceStep(lower: 0, upper: 10, desiredCount: 1))
        XCTAssertNotNil(ChartScaleCalculator.niceStep(lower: 0, upper: 10, desiredCount: -5))
    }

    // MARK: - Ticks

    func testNoTickCountMeansNoTicks() {
        let result = ChartScaleCalculator.output(for: [1, -1], mode: .proportional)
        XCTAssertTrue(result.ticks.isEmpty)
    }

    func testReferenceDataRoundsToTheAxisInTheScreenshot() {
        let result = output(Fixtures.editorialValues)
        XCTAssertEqual(result.scale, ChartScale(lower: -20, upper: 30))
        XCTAssertEqual(result.ticks.map(\.value), [-20, -10, 0, 10, 20, 30])
        XCTAssertEqual(result.ticks.map(\.ordinal), [-2, -1, 0, 1, 2, 3])
    }

    func testTicksAlwaysIncludeZero() {
        for values in [[1.0, 2.0], [-1.0, -2.0], [3.3, -7.7], [0.001, -0.002], [12345.0, -6789.0]] {
            XCTAssertTrue(output(values).ticks.contains { $0.value == 0 }, "\(values)")
        }
    }

    func testZeroTickIsNotNegativeZero() throws {
        let zero = try XCTUnwrap(output([-5, 5]).ticks.first { $0.ordinal == 0 })
        XCTAssertEqual(zero.value.sign, .plus)
    }

    func testRoundedAxisKeepsAllDataInRange() {
        let values = [-18.1, 23.2]
        let scale = output(values).scale
        XCTAssertTrue(values.allSatisfy(scale.contains))
    }

    func testRoundedSymmetricAxisStaysSymmetric() {
        let scale = output([23, -4], .symmetric).scale
        XCTAssertEqual(scale.lower, -scale.upper)
    }

    func testFixedAxisDoesNotExpandItsRange() {
        let result = output([100], .fixed(lower: -7, upper: 13))
        XCTAssertEqual(result.scale, ChartScale(lower: -7, upper: 13))
        XCTAssertTrue(result.ticks.allSatisfy { $0.value >= -7 && $0.value <= 13 })
        XCTAssertTrue(result.ticks.contains { $0.value == 0 })
    }

    func testAllZeroAxisHasTicks() {
        XCTAssertFalse(output([0, 0]).ticks.isEmpty)
    }

    func testExtremeRangeHasNoTicksRatherThanInvalidOnes() {
        let extreme = Double.greatestFiniteMagnitude
        let result = output([extreme, -extreme], ticks: 2)
        XCTAssertTrue(result.ticks.isEmpty)
        XCTAssertEqual(result.scale, ChartScale(lower: -extreme, upper: extreme))
    }

    func testRoundingThatWouldOverflowKeepsTheExactRange() {
        let extreme = Double.greatestFiniteMagnitude
        let result = output([extreme], ticks: 6)
        XCTAssertTrue(result.scale.upper.isFinite)
        XCTAssertTrue(result.ticks.allSatisfy { $0.value.isFinite })
    }

    func testTickCountIsBounded() {
        for desired in [1, 2, 6, 20, 1000, 1_000_000] {
            XCTAssertLessThanOrEqual(output([1, -1], ticks: desired).ticks.count, 64, "\(desired)")
        }
    }

    /// `Int()` traps on values it can't represent, so these must return nothing, not crash.
    func testTickGenerationRefusesCountsItCannotRepresent() {
        let huge = ChartScale(lower: -1e300, upper: 1e300)
        XCTAssertTrue(ChartScaleCalculator.ticks(step: 1e-300, inside: huge).isEmpty, "Overflows to infinity")
        XCTAssertTrue(ChartScaleCalculator.ticks(step: 1, inside: huge).isEmpty, "Finite, but larger than Int")
        XCTAssertTrue(ChartScaleCalculator.ticks(step: 1, inside: ChartScale(lower: -1000, upper: 1000)).isEmpty, "Too many")
        XCTAssertTrue(ChartScaleCalculator.ticks(step: 10, inside: ChartScale(lower: 1, upper: 2)).isEmpty, "None in range")
    }

    func testTickGenerationReturnsMultiplesOfTheStep() {
        let ticks = ChartScaleCalculator.ticks(step: 5, inside: ChartScale(lower: -7, upper: 12))
        XCTAssertEqual(ticks.map(\.value), [-5, 0, 5, 10])
        XCTAssertEqual(ticks.map(\.ordinal), [-1, 0, 1, 2])
    }

    /// `desiredCount - 1` used to overflow, trapping the whole app.
    func testExtremeTickCountsDoNotTrap() {
        XCTAssertFalse(output([1, -1], ticks: .min).ticks.isEmpty)
        XCTAssertFalse(output([1, -1], ticks: .max).ticks.isEmpty)
        XCTAssertNotNil(ChartScaleCalculator.niceStep(lower: 0, upper: 10, desiredCount: .min))
        XCTAssertNotNil(ChartScaleCalculator.niceStep(lower: 0, upper: 10, desiredCount: .max))
    }

    func testOutputReportsItsStep() {
        XCTAssertEqual(output([23.2, -18.1]).step, 10)
        XCTAssertNil(ChartScaleCalculator.output(for: [1], mode: .proportional).step)
    }

    func testIllegibleTicksTryAWiderSpacing() {
        var tried: [Double] = []
        let result = ChartScaleCalculator.output(for: [10, -10], mode: .proportional, desiredTickCount: 6) { ticks in
            tried.append(ticks[1] - ticks[0])
            return ticks[1] - ticks[0] >= 5
        }
        XCTAssertEqual(tried, [5])
        XCTAssertEqual(result.step, 5)

        var attempts = 0
        let widened = ChartScaleCalculator.output(for: [10, -10], mode: .proportional, desiredTickCount: 6) { ticks in
            attempts += 1
            return ticks[1] - ticks[0] >= 10
        }
        XCTAssertEqual(attempts, 2)
        XCTAssertEqual(widened.step, 10)
    }

    func testLegibilityCheckIncludesMultiplesBeyondTheAxis() {
        var checked: [Double] = []
        _ = ChartScaleCalculator.output(for: [1.5, -0.5], mode: .proportional, desiredTickCount: 6) { values in
            checked = values
            return true
        }
        XCTAssertEqual(checked, [-0.5, 0, 0.5, 1, 1.5, 2], "2 is not on this axis, but it reveals rounding at 1.5")
    }

    func testNoLegibleSpacingLeavesOnlyZeroAndTheExactRange() {
        let result = ChartScaleCalculator.output(for: [10, -2], mode: .proportional, desiredTickCount: 6) { _ in false }
        XCTAssertEqual(result.ticks.map(\.value), [0])
        XCTAssertEqual(result.scale, ChartScale(lower: -2, upper: 10))
    }

    /// Asking for too many ticks should give as many as allowed, not make the axis disappear.
    func testVeryLargeTickCountStillProducesAnAxis() {
        for desired in [100, 1000, 1_000_000] {
            XCTAssertGreaterThan(output([17.3, -4.1], ticks: desired).ticks.count, 20, "\(desired)")
        }
    }

    func testEveryTickIsFiniteAcrossExtremes() {
        let values: [Double] = [1e-320, 1e-300, 1e-9, 1, 1e9, 1e300]
        for value in values {
            for result in [output([value]), output([-value]), output([value, -value], .symmetric)] {
                XCTAssertTrue(result.ticks.allSatisfy { $0.value.isFinite }, "\(value)")
                XCTAssertTrue(result.scale.lower.isFinite && result.scale.upper.isFinite, "\(value)")
            }
        }
    }
}
