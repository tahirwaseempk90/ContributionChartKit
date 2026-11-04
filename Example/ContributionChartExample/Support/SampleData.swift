import ContributionChart
import Foundation

/// Sample values for the demonstration screens. None of this belongs in the package.
enum SampleData {
    /// A small set of values, the same as in the README's Quick Start.
    static let contributors = [
        ChartDataPoint(title: "VFIAX", value: 11.05),
        ChartDataPoint(title: "VTNIX", value: 6.31),
        ChartDataPoint(title: "VTSAX", value: -2.70)
    ]

    /// Thirty periods of values. They have no names of their own, so the points are numbered.
    static let periods: [ChartDataPoint] = [
        17.5, 9.7, 13.7, 17.9, 1.3, -6.5, -1.2, -9.9, -12.6, 23.2,
        18.2, 12.3, 17.4, -8.1, -3.2, 5.7, -4.1, 5.0, 10.3, -1.9,
        -4.7, -10.5, -8.6, -18.1, -11.8, -2.4, -6.5, -8.5, -2.8, -12.5
    ]
    .enumerated()
    .map { ChartDataPoint(id: "period-\($0.offset + 1)", title: "Period \($0.offset + 1)", value: $0.element) }

    static let mixed = [
        ChartDataPoint(title: "Equities", value: 8.4),
        ChartDataPoint(title: "Energy", value: -3.2),
        ChartDataPoint(title: "Bonds", value: 5.1),
        ChartDataPoint(title: "Real Estate", value: -6.8),
        ChartDataPoint(title: "Health", value: 2.2),
        ChartDataPoint(title: "Utilities", value: -1.1),
        ChartDataPoint(title: "Tech", value: 9.7),
        ChartDataPoint(title: "Retail", value: -4.4)
    ]

    static let positiveOnly = [
        ChartDataPoint(title: "North", value: 3.0),
        ChartDataPoint(title: "East", value: 7.5),
        ChartDataPoint(title: "South", value: 1.2),
        ChartDataPoint(title: "West", value: 5.5)
    ]

    static let negativeOnly = positiveOnly.map { ChartDataPoint(title: $0.title, value: -$0.value) }

    static let longTitles = [
        ChartDataPoint(title: "Vanguard Total Stock Market Index Fund Admiral Shares", value: 12.5),
        ChartDataPoint(title: "International Growth & Income Opportunities", value: -7.25),
        ChartDataPoint(title: "Short", value: 3.0)
    ]

    /// Repeatable values with a mix of signs and sizes, for any number of points.
    static func dense(count: Int) -> [ChartDataPoint] {
        (0..<count).map { index in
            let position = Double(index)
            return ChartDataPoint(
                id: "item-\(index)",
                title: "Item \(index + 1)",
                value: sin(position * 0.7) * 10 + cos(position * 0.13) * 6
            )
        }
    }
}
