/// One labelled value plotted by ``ContributionChart``.
///
/// Positive values rise above the zero baseline and negative values fall below it.
/// The type is deliberately domain neutral: map your own models to it with `map`.
///
/// ```swift
/// let points = holdings.map { ChartDataPoint(id: $0.ticker, title: $0.ticker, value: $0.returnPercent) }
/// ```
///
/// ## Input validation
///
/// Non-finite values (`.nan`, `.infinity`, `-.infinity`) cannot be positioned on a linear
/// scale, so the chart leaves them out and reports how many it skipped to assistive
/// technologies. Check ``isPlottable`` to detect them yourself.
public struct ChartDataPoint: Identifiable, Hashable, Sendable {
    /// The side of the zero baseline on which a value is plotted.
    public enum Polarity: Hashable, Sendable {
        /// The value is greater than zero and is plotted above the baseline.
        case positive
        /// The value is less than zero and is plotted below the baseline.
        case negative
        /// The value is zero, or is not a number, and has no direction.
        case zero

        init(value: Double) {
            if value > 0 {
                self = .positive
            } else if value < 0 {
                self = .negative
            } else {
                self = .zero
            }
        }
    }

    /// A stable identifier. Defaults to ``title``.
    ///
    /// The default keeps identity stable when the same data is rebuilt, which a generated
    /// UUID would not. If several points share an identifier they are all still drawn.
    public let id: String

    /// The name shown next to the marker and read by VoiceOver.
    public let title: String

    /// The signed value that sets the marker's distance from the baseline.
    public let value: Double

    /// Creates a data point.
    ///
    /// - Parameters:
    ///   - id: A stable identifier. Pass one when titles can repeat. Defaults to `title`.
    ///   - title: The name shown next to the marker.
    ///   - value: The signed value to plot.
    public init(id: String? = nil, title: String, value: Double) {
        self.id = id ?? title
        self.title = title
        self.value = value
    }

    /// The side of the baseline on which the value belongs.
    ///
    /// Both zeroes and `.nan` report ``Polarity-swift.enum/zero``.
    public var polarity: Polarity {
        Polarity(value: value)
    }

    /// Whether the value is finite and can therefore be drawn.
    public var isPlottable: Bool {
        value.isFinite
    }

    // Written by hand because `Double.nan != Double.nan` would otherwise make a point
    // unequal to itself, breaking the reflexivity that `Hashable` requires.
    public static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && (lhs.value == rhs.value || (lhs.value.isNaN && rhs.value.isNaN))
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(value.isNaN ? Double.nan : value)
    }
}
