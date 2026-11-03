/// A linear mapping from values to a vertical fraction of the plot. The range always spans zero.
struct ChartScale: Sendable, Equatable {
    /// Used when the data gives no range at all, such as when every value is zero.
    static let unit = ChartScale(lower: -1, upper: 1)

    let lower: Double
    let upper: Double

    /// The fraction at which a value falls: 0 is the bottom of the plot and 1 is the top.
    ///
    /// Values outside the range clamp to its nearest edge and non-finite values map to the
    /// baseline, so the result is always finite. Dividing everything by the largest magnitude
    /// first keeps extreme ranges such as `-1e308...1e308` from overflowing when subtracted.
    func fraction(of value: Double) -> Double {
        let magnitude = max(abs(lower), abs(upper))
        guard magnitude > 0 else { return Self.middle }
        let low = lower / magnitude
        let span = upper / magnitude - low
        guard span > 0 else { return Self.middle }
        let target = value.isFinite ? value : 0
        return min(max((target / magnitude - low) / span, 0), 1)
    }

    var baselineFraction: Double {
        fraction(of: 0)
    }

    func contains(_ value: Double) -> Bool {
        value >= lower && value <= upper
    }

    private static let middle = 0.5
}
