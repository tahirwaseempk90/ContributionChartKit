import Foundation

/// Locale-aware text for chart values, including values too extreme to print in full.
enum NumericFormatting {
    private typealias Precision = NumberFormatStyleConfiguration.Precision
    private typealias Notation = NumberFormatStyleConfiguration.Notation

    private struct Presentation {
        let precision: Precision
        let notation: Notation
    }

    private static let compactThreshold = 1e6
    private static let scientificUpperThreshold = 1e15
    private static let scientificLowerThreshold = 1e-6
    private static let maximumFractionDigits = 15

    static func percent(_ value: Double, fractionDigits: Int, locale: Locale) -> String {
        let value = withoutNegativeZero(value)
        let digits = clampedDigits(fractionDigits)
        let presentation = presentation(for: value, fractionDigits: digits...digits)
        // `.scale(1)` because the value is already a percentage; the style would otherwise
        // multiply by 100.
        return value.formatted(
            .percent
                .scale(1)
                .precision(presentation.precision)
                .notation(presentation.notation)
                .locale(locale)
        )
    }

    static func number(_ value: Double, fractionDigits: ClosedRange<Int>, locale: Locale) -> String {
        let value = withoutNegativeZero(value)
        let digits = clampedDigits(fractionDigits.lowerBound)...clampedDigits(fractionDigits.upperBound)
        let presentation = presentation(for: value, fractionDigits: digits)
        return value.formatted(
            .number
                .precision(presentation.precision)
                .notation(presentation.notation)
                .locale(locale)
        )
    }

    private static func presentation(for value: Double, fractionDigits: ClosedRange<Int>) -> Presentation {
        let magnitude = abs(value)
        if magnitude >= scientificUpperThreshold || (magnitude > 0 && magnitude < scientificLowerThreshold) {
            return Presentation(precision: .significantDigits(1...3), notation: .scientific)
        }
        if magnitude >= compactThreshold {
            return Presentation(precision: .fractionLength(0...2), notation: .compactName)
        }
        // Fixed digits would print a real but tiny change as zero.
        let smallestVisibleValue = pow(10, -Double(fractionDigits.upperBound))
        if magnitude > 0 && magnitude < smallestVisibleValue {
            return Presentation(precision: .significantDigits(1...2), notation: .automatic)
        }
        return Presentation(precision: .fractionLength(fractionDigits), notation: .automatic)
    }

    /// Rounding a small negative value easily produces `-0.0`, which would print as "-0.00%".
    private static func withoutNegativeZero(_ value: Double) -> Double {
        value == 0 ? 0 : value
    }

    private static func clampedDigits(_ digits: Int) -> Int {
        min(max(digits, 0), maximumFractionDigits)
    }
}
