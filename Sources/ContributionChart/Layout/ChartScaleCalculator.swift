import Foundation

/// Works out the numeric range of a chart, and its tick values when an axis is shown.
enum ChartScaleCalculator {
    struct Tick: Sendable, Equatable {
        /// The tick's distance from zero in steps, which stays exact where the value may not.
        let ordinal: Int
        let value: Double
    }

    struct Output: Sendable, Equatable {
        let scale: ChartScale
        let ticks: [Tick]
        /// The spacing between ticks, or `nil` when there are none.
        let step: Double?
    }

    /// A limit on tick generation, so no input can produce an unbounded loop.
    private static let maximumTickCount = 64

    /// More than enough to widen from the finest spacing to the size of the data.
    private static let maximumWidenings = 8

    /// How many multiples of the spacing to test, whether or not they fall on the axis.
    private static let legibilityProbeCount = 5

    /// Computes the scale for a set of finite values.
    ///
    /// - Parameters:
    ///   - values: Everything the scale must include: the data and any reference lines.
    ///   - mode: The scaling behaviour.
    ///   - desiredTickCount: Pass a count when an axis is shown; `nil` means no ticks.
    ///   - ticksAreLegible: Whether labels can tell these values apart. See `legibleOutput`.
    static func output(
        for values: [Double],
        mode: ChartScaleMode,
        desiredTickCount: Int? = nil,
        ticksAreLegible: ([Double]) -> Bool = { _ in true }
    ) -> Output {
        let domain = domain(for: values, mode: mode)
        guard
            let desiredTickCount,
            let step = niceStep(lower: domain.lower, upper: domain.upper, desiredCount: desiredTickCount)
        else {
            return Output(scale: domain, ticks: [], step: nil)
        }
        return legibleOutput(domain: domain, mode: mode, startingStep: step, ticksAreLegible: ticksAreLegible)
    }

    /// Widens the tick spacing until the labels can show it.
    ///
    /// A formatter that shows no decimals can't label ticks 0.5 apart: 1.5 would read "2", which
    /// is a wrong number on a chart. Rounding like this shows up as two values with the same label,
    /// but that second value may not be on the axis, so the check includes the first few multiples
    /// of the spacing too. In this example, 1.5 and 2 both read "2".
    ///
    /// If no spacing within the size of the data works, only zero is labelled. Going further
    /// would flatten the data to fit a tidy axis.
    private static func legibleOutput(
        domain: ChartScale,
        mode: ChartScaleMode,
        startingStep: Double,
        ticksAreLegible: ([Double]) -> Bool
    ) -> Output {
        let largest = max(abs(domain.lower), abs(domain.upper))
        var step = startingStep
        for _ in 0..<maximumWidenings {
            let output = output(domain: domain, mode: mode, step: step)
            let multiples = (0..<legibilityProbeCount).map { Double($0) * step }
            if ticksAreLegible(Set(output.ticks.map(\.value) + multiples).sorted()) {
                return output
            }
            step = widerStep(than: step)
            if step > largest {
                break
            }
        }
        return Output(scale: domain, ticks: [Tick(ordinal: 0, value: 0)], step: startingStep)
    }

    private static func output(domain: ChartScale, mode: ChartScaleMode, step: Double) -> Output {
        if case .fixed = mode {
            return Output(scale: domain, ticks: ticks(step: step, inside: domain), step: step)
        }
        return roundedOutward(domain, step: step)
    }

    /// The next round spacing: 1 becomes 2, 2 becomes 5, and 5 becomes 10.
    private static func widerStep(than step: Double) -> Double {
        let magnitude = pow(10, floor(log10(step)))
        return niceMultiplier(for: step / magnitude * 1.5) * magnitude
    }

    /// The exact range for the data, before any rounding for an axis.
    static func domain(for values: [Double], mode: ChartScaleMode) -> ChartScale {
        switch mode {
        case .proportional:
            return proportionalDomain(for: values)
        case .symmetric:
            let domain = proportionalDomain(for: values)
            let magnitude = max(abs(domain.lower), abs(domain.upper))
            return ChartScale(lower: -magnitude, upper: magnitude)
        case let .fixed(lower, upper):
            return fixedDomain(lower: lower, upper: upper)
        }
    }

    /// A round spacing between ticks: 1, 2, or 5 times a power of ten.
    ///
    /// Multiples of 2.5 are left out on purpose. They need one more digit than the values around
    /// them, so an axis of whole numbers would suddenly have ticks at 2.5 and 7.5.
    ///
    /// Returns `nil` when the range is too extreme for a finite step to exist.
    static func niceStep(lower: Double, upper: Double, desiredCount: Int) -> Double? {
        // Halve before subtracting so that opposite extremes cannot overflow.
        let halfRange = upper / 2 - lower / 2
        guard halfRange > 0, halfRange.isFinite else { return nil }
        // At most `maximumTickCount - 2` intervals, since rounding outward can add one tick at
        // each end. Without this, a very large request would produce no ticks at all.
        let intervals = Double(min(max(desiredCount, 2) - 1, maximumTickCount - 2))
        let roughStep = halfRange / intervals * 2
        guard roughStep > 0, roughStep.isFinite else { return nil }

        let magnitude = pow(10, floor(log10(roughStep)))
        let step = niceMultiplier(for: roughStep / magnitude) * magnitude
        return step.isFinite && step > 0 ? step : nil
    }

    private static func niceMultiplier(for residual: Double) -> Double {
        switch residual {
        case ...1: return 1
        case ...2: return 2
        case ...5: return 5
        default: return 10
        }
    }

    private static func proportionalDomain(for values: [Double]) -> ChartScale {
        var lower = 0.0
        var upper = 0.0
        for value in values where value.isFinite {
            lower = min(lower, value)
            upper = max(upper, value)
        }
        return lower == upper ? .unit : ChartScale(lower: lower, upper: upper)
    }

    private static func fixedDomain(lower: Double, upper: Double) -> ChartScale {
        guard lower.isFinite, upper.isFinite else { return .unit }
        let includingZero = (lower: min(lower, upper, 0), upper: max(lower, upper, 0))
        guard includingZero.lower != includingZero.upper else { return .unit }
        return ChartScale(lower: includingZero.lower, upper: includingZero.upper)
    }

    /// Extends the range to whole steps so that gridlines fall exactly on its edges.
    private static func roundedOutward(_ domain: ChartScale, step: Double) -> Output {
        let lowerOrdinal = floor(domain.lower / step)
        let upperOrdinal = ceil(domain.upper / step)
        let rounded = ChartScale(lower: lowerOrdinal * step, upper: upperOrdinal * step)
        guard rounded.lower.isFinite, rounded.upper.isFinite else {
            return Output(scale: domain, ticks: [], step: nil)
        }
        return Output(scale: rounded, ticks: ticks(step: step, inside: rounded), step: step)
    }

    /// The multiples of `step` inside the range, or none if they can't be counted safely.
    ///
    /// `Int()` traps on values it can't represent, so this checks before converting.
    static func ticks(step: Double, inside domain: ChartScale) -> [Tick] {
        let lowest = ceil(domain.lower / step)
        let highest = floor(domain.upper / step)
        guard
            lowest.isFinite, highest.isFinite,
            lowest <= highest, highest - lowest < Double(maximumTickCount)
        else { return [] }
        return (Int(lowest)...Int(highest)).map { Tick(ordinal: $0, value: Double($0) * step) }
    }
}
