import XCTest
@testable import ContributionChart

final class ChartValueFormatterTests: XCTestCase {
    private let english = Locale(identifier: "en_US")

    private func percent(_ value: Double, digits: Int = 2, locale: Locale? = nil) -> String {
        ChartValueFormatter.percent(fractionDigits: digits, locale: locale ?? english).string(for: value)
    }

    private func number(_ value: Double, digits: ClosedRange<Int> = 0...2, locale: Locale? = nil) -> String {
        ChartValueFormatter.number(fractionDigits: digits, locale: locale ?? english).string(for: value)
    }

    // MARK: - Percent

    func testPositivePercent() {
        XCTAssertEqual(percent(11.05), "11.05%")
    }

    /// The value is already a percentage, so it must not be multiplied by 100.
    func testPercentDoesNotScaleTheValue() {
        XCTAssertEqual(percent(1), "1.00%")
        XCTAssertEqual(percent(100), "100.00%")
    }

    func testNegativePercent() {
        XCTAssertEqual(percent(-2.70), "-2.70%")
    }

    func testZeroPercent() {
        XCTAssertEqual(percent(0), "0.00%")
    }

    /// `-0.0` comes easily from rounding a small negative value, as in `(x * 100).rounded() / 100`.
    func testNegativeZeroHasNoSign() {
        XCTAssertEqual(percent(-0.0), "0.00%")
        XCTAssertEqual(number(-0.0), "0")
    }

    func testPercentPrecision() {
        XCTAssertEqual(percent(11.056, digits: 1), "11.1%")
        XCTAssertEqual(percent(11.056, digits: 0), "11%")
        XCTAssertEqual(percent(11.056, digits: 3), "11.056%")
    }

    func testOutOfRangeDigitsAreClamped() {
        XCTAssertEqual(percent(1.5, digits: -3), "2%")
        XCTAssertFalse(percent(1.5, digits: 500).isEmpty)
    }

    // MARK: - Number

    func testNumberUsesOnlyTheDigitsItNeeds() {
        XCTAssertEqual(number(10), "10")
        XCTAssertEqual(number(10.5), "10.5")
        XCTAssertEqual(number(-10.25), "-10.25")
        XCTAssertEqual(number(0), "0")
    }

    func testNumberPrecisionRange() {
        XCTAssertEqual(number(10.123, digits: 0...1), "10.1")
        XCTAssertEqual(number(10, digits: 2...2), "10.00")
    }

    func testNumberWithNegativeDigitRangeIsClamped() {
        XCTAssertEqual(number(10.6, digits: -2...(-1)), "11")
    }

    // MARK: - Locale

    func testGermanDecimalSeparator() {
        let text = percent(11.05, locale: Locale(identifier: "de_DE"))
        XCTAssertTrue(text.contains("11,05"), text)
    }

    func testFrenchPercentSpacing() {
        let text = percent(11.05, locale: Locale(identifier: "fr_FR"))
        XCTAssertTrue(text.contains("11,05"), text)
        XCTAssertTrue(text.hasSuffix("%"), text)
        XCTAssertFalse(text.contains("11,05%"), "French separates the symbol from the number: \(text)")
    }

    func testTurkishPercentComesFirst() {
        let text = percent(11.05, locale: Locale(identifier: "tr_TR"))
        XCTAssertTrue(text.hasPrefix("%"), text)
    }

    func testNumberUsesLocaleSeparators() {
        XCTAssertEqual(number(1234.5, locale: Locale(identifier: "de_DE")), "1.234,5")
    }

    func testArabicLocaleProducesText() {
        XCTAssertFalse(percent(11.05, locale: Locale(identifier: "ar_EG")).isEmpty)
    }

    // MARK: - Extreme values

    /// `0.00%` next to an up arrow would contradict itself.
    func testVerySmallValuesAreNotRoundedAwayToZero() {
        XCTAssertEqual(percent(0.004), "0.004%")
        XCTAssertEqual(percent(-0.0012), "-0.0012%")
        XCTAssertEqual(number(0.0012), "0.0012")
    }

    func testValueAtTheVisibleLimitUsesFixedDigits() {
        XCTAssertEqual(percent(0.01), "0.01%")
    }

    func testVanishinglySmallValuesUseScientificNotation() {
        let text = percent(1e-300)
        XCTAssertLessThan(text.count, 12, text)
        XCTAssertTrue(text.contains("E"), text)
        XCTAssertLessThan(number(-.leastNonzeroMagnitude).count, 14)
    }

    func testMillionsUseCompactNotation() {
        XCTAssertEqual(number(4_200_000), "4.2M")
        XCTAssertEqual(percent(-4_200_000), "-4.2M%")
    }

    func testValueJustBelowTheCompactThresholdIsPrintedInFull() {
        XCTAssertEqual(number(999_999), "999,999")
    }

    func testHugeValuesUseScientificNotation() {
        for value in [1e15, 9.9e300, Double.greatestFiniteMagnitude, -Double.greatestFiniteMagnitude] {
            let text = number(value)
            XCTAssertLessThan(text.count, 12, text)
            XCTAssertTrue(text.contains("E"), text)
        }
    }

    // MARK: - Custom

    func testCustomFormatter() {
        let formatter = ChartValueFormatter { "\(Int($0)) units" }
        XCTAssertEqual(formatter.string(for: 3), "3 units")
    }

    func testDefaultLocaleProducesText() {
        XCTAssertFalse(ChartValueFormatter.percent().string(for: 1).isEmpty)
        XCTAssertFalse(ChartValueFormatter.number().string(for: 1).isEmpty)
    }
}
