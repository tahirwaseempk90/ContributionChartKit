/// Produces the text VoiceOver reads for a chart. Pure, so it can be tested without a view.
enum ChartAccessibilityDescriber {
    private static let defaultChartName = "Contribution chart"

    /// The chart's spoken name: a custom label, then the title, then a generic name.
    static func chartLabel(title: String?, options: ChartAccessibilityOptions) -> String {
        options.label ?? title ?? defaultChartName
    }

    static func summary(for dataset: ChartDataset, title: String?) -> ChartAccessibilitySummary {
        var positiveCount = 0
        var negativeCount = 0
        var zeroCount = 0
        var largestPositive: ChartDataPoint?
        var largestNegative: ChartDataPoint?

        for point in dataset.entries.map(\.point) {
            switch point.polarity {
            case .positive:
                positiveCount += 1
                if point.value > largestPositive?.value ?? 0 { largestPositive = point }
            case .negative:
                negativeCount += 1
                if point.value < largestNegative?.value ?? 0 { largestNegative = point }
            case .zero:
                zeroCount += 1
            }
        }
        return ChartAccessibilitySummary(
            title: title,
            pointCount: dataset.count,
            positiveCount: positiveCount,
            negativeCount: negativeCount,
            zeroCount: zeroCount,
            invalidCount: dataset.invalidCount,
            largestPositive: largestPositive,
            largestNegative: largestNegative
        )
    }

    /// The description of the chart's contents, such as "3 data points: 2 contributors and
    /// 1 detractor. Largest contributor: VFIAX, 11.05%. Largest detractor: VTSAX, -2.70%."
    static func summaryText(
        for summary: ChartAccessibilitySummary,
        options: ChartAccessibilityOptions,
        formatter: ChartValueFormatter
    ) -> String {
        if let custom = options.summary {
            return custom(summary)
        }
        var sentences = [countsSentence(for: summary)]
        if let point = summary.largestPositive {
            sentences.append("Largest contributor: \(point.title), \(formatter.string(for: point.value)).")
        }
        if let point = summary.largestNegative {
            sentences.append("Largest detractor: \(point.title), \(formatter.string(for: point.value)).")
        }
        if summary.invalidCount > 0 {
            let noun = summary.invalidCount == 1 ? "value" : "values"
            sentences.append("\(summary.invalidCount) invalid \(noun) not shown.")
        }
        return sentences.joined(separator: " ")
    }

    /// The spoken value of a point, stating its direction in words rather than through the
    /// colour or arrow alone.
    static func pointValue(
        for point: ChartDataPoint,
        formattedValue: String,
        options: ChartAccessibilityOptions
    ) -> String {
        if let custom = options.pointValue {
            return custom(point, formattedValue)
        }
        switch point.polarity {
        case .positive: return "Positive, \(formattedValue)"
        case .negative: return "Negative, \(formattedValue)"
        case .zero: return "Zero, \(formattedValue)"
        }
    }

    private static func countsSentence(for summary: ChartAccessibilitySummary) -> String {
        var parts: [String] = []
        if summary.positiveCount > 0 {
            parts.append(counted(summary.positiveCount, singular: "contributor", plural: "contributors"))
        }
        if summary.negativeCount > 0 {
            parts.append(counted(summary.negativeCount, singular: "detractor", plural: "detractors"))
        }
        if summary.zeroCount > 0 {
            parts.append("\(summary.zeroCount) unchanged")
        }
        let total = counted(summary.pointCount, singular: "data point", plural: "data points")
        return parts.isEmpty ? "\(total)." : "\(total): \(listed(parts))."
    }

    private static func counted(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    private static func listed(_ parts: [String]) -> String {
        let leading = parts.dropLast()
        guard !leading.isEmpty else { return parts.joined() }
        return "\(leading.joined(separator: ", ")) and \(parts[leading.count])"
    }
}
