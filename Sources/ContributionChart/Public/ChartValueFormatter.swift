import Foundation

/// Turns a value into the text shown on a label and read by VoiceOver.
///
/// Use ``percent(fractionDigits:locale:)``, ``number(fractionDigits:locale:)``, or supply
/// your own closure:
///
/// ```swift
/// let dollars = ChartValueFormatter { $0.formatted(.currency(code: "USD")) }
/// ```
public struct ChartValueFormatter: Sendable {
    private let format: @Sendable (Double) -> String

    /// Creates a formatter from a closure. The chart only passes finite values.
    public init(_ format: @escaping @Sendable (Double) -> String) {
        self.format = format
    }

    /// Returns the text for a value.
    public func string(for value: Double) -> String {
        format(value)
    }

    /// Formats a value that is already a percentage, so `11.05` becomes `11.05%`.
    ///
    /// Values too small to show with this many digits switch to significant digits, so a
    /// small change is never displayed as `0.00%`. Very large values switch to compact or
    /// scientific notation, so a label stays short enough to read.
    ///
    /// - Parameters:
    ///   - fractionDigits: The number of digits after the decimal separator. Defaults to 2.
    ///   - locale: The locale used for separators and symbols. Defaults to the user's locale.
    public static func percent(
        fractionDigits: Int = 2,
        locale: Locale = .autoupdatingCurrent
    ) -> ChartValueFormatter {
        ChartValueFormatter { NumericFormatting.percent($0, fractionDigits: fractionDigits, locale: locale) }
    }

    /// Formats a plain number, with the same handling of very small and very large values
    /// as ``percent(fractionDigits:locale:)``.
    ///
    /// - Parameters:
    ///   - fractionDigits: The allowed number of digits after the decimal separator.
    ///   - locale: The locale used for separators. Defaults to the user's locale.
    public static func number(
        fractionDigits: ClosedRange<Int> = 0...2,
        locale: Locale = .autoupdatingCurrent
    ) -> ChartValueFormatter {
        ChartValueFormatter { NumericFormatting.number($0, fractionDigits: fractionDigits, locale: locale) }
    }
}
