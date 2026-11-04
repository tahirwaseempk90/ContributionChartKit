/// The facts behind the spoken description of a chart.
///
/// Provide a closure through ``ChartAccessibilityOptions/summary`` to word the description
/// your own way or translate it.
public struct ChartAccessibilitySummary: Sendable, Equatable {
    /// The chart's title, if it has one.
    public let title: String?
    /// The number of points drawn.
    public let pointCount: Int
    /// The number of values above zero.
    public let positiveCount: Int
    /// The number of values below zero.
    public let negativeCount: Int
    /// The number of values equal to zero.
    public let zeroCount: Int
    /// The number of values left out because they were not finite.
    public let invalidCount: Int
    /// The point with the largest positive value.
    public let largestPositive: ChartDataPoint?
    /// The point with the largest negative value.
    public let largestNegative: ChartDataPoint?
}

/// VoiceOver text and accessibility identifiers for a ``ContributionChart``.
///
/// The default wording is English. To localise it, pass your own closures for ``summary`` and
/// ``pointValue``, along with a translated ``label``, ``categoryAxisTitle``, and
/// ``valueAxisTitle``.
public struct ChartAccessibilityOptions: Sendable {
    /// The identifier on the chart. Child elements add a suffix, such as
    /// `contribution-chart.point.VFIAX` and `contribution-chart.summary`.
    public var identifier: String
    /// The spoken name of the chart. Defaults to the title, then to "Contribution chart".
    public var label: String?
    /// Replaces the default description of the chart's contents.
    public var summary: (@Sendable (ChartAccessibilitySummary) -> String)?
    /// Replaces the spoken value of a point. Receives the point and its formatted value.
    public var pointValue: (@Sendable (ChartDataPoint, String) -> String)?
    /// Whether to offer the data to VoiceOver as an Audio Graph, where it is supported.
    public var isAudioGraphEnabled: Bool
    /// The Audio Graph's name for its horizontal axis, which lists the points.
    public var categoryAxisTitle: String
    /// The Audio Graph's name for its vertical axis, which measures the values.
    public var valueAxisTitle: String

    /// Creates accessibility options.
    public init(
        identifier: String = "contribution-chart",
        label: String? = nil,
        summary: (@Sendable (ChartAccessibilitySummary) -> String)? = nil,
        pointValue: (@Sendable (ChartDataPoint, String) -> String)? = nil,
        isAudioGraphEnabled: Bool = true,
        categoryAxisTitle: String = "Items",
        valueAxisTitle: String = "Value"
    ) {
        self.identifier = identifier
        self.label = label
        self.summary = summary
        self.pointValue = pointValue
        self.isAudioGraphEnabled = isAudioGraphEnabled
        self.categoryAxisTitle = categoryAxisTitle
        self.valueAxisTitle = valueAxisTitle
    }
}
