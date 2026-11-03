import SwiftUI

/// Everything about a chart that does not depend on its size.
///
/// Built once per `body` from the public inputs. Layout and rendering both read from it, so
/// neither has to validate input or format text again.
struct ChartModel: Sendable {
    /// The most points that get a label or their own VoiceOver element.
    ///
    /// Far fewer labels than this can ever fit, and swiping through more elements than this
    /// is not a usable experience. The Audio Graph still gives access to every point.
    static let prominentPointLimit = 100

    struct Tick: Sendable, Equatable {
        let ordinal: Int
        let value: Double
        let label: String
    }

    struct Point: Sendable, Equatable {
        let entry: ChartDataset.Entry
        /// The text under the title, such as "↑ 11.05%".
        let annotationValue: String
        let accessibilityValue: String

        var polarity: ChartDataPoint.Polarity { entry.point.polarity }
    }

    struct ReferenceLine: Sendable, Equatable {
        let value: Double
        /// `nil` spans the whole chart.
        let positions: ClosedRange<Int>?
        let style: ChartLineStyle
    }

    struct Region: Sendable, Equatable {
        let positions: ClosedRange<Int>
        let color: Color
    }

    let title: String?
    let dataset: ChartDataset
    /// The plotted values, kept separately because the canvas reads them on every draw.
    let values: [Double]
    let configuration: ChartConfiguration
    let metrics: ChartMetrics
    let scale: ChartScale
    let ticks: [Tick]
    let prominentPoints: [Point]
    let referenceLines: [ReferenceLine]
    let regions: [Region]
    let categoryTickPositions: [Int]

    init(points: [ChartDataPoint], title: String?, configuration: ChartConfiguration) {
        let dataset = ChartDataset(points: points)
        self.dataset = dataset
        self.values = dataset.entries.map(\.point.value)
        self.title = title?.isEmpty == true ? nil : title
        self.configuration = configuration
        self.metrics = ChartMetrics(configuration)

        // Resolved before the scale, because a line that won't be drawn mustn't stretch it.
        let referenceLines = configuration.referenceLines.compactMap { Self.resolve($0, in: dataset) }
        let output = ChartScaleCalculator.output(
            for: values + referenceLines.map(\.value),
            mode: configuration.scale,
            desiredTickCount: configuration.valueAxis?.desiredTickCount,
            ticksAreLegible: Self.labelsDiffer(axis: configuration.valueAxis)
        )
        self.scale = output.scale
        self.ticks = Self.ticks(from: output, axis: configuration.valueAxis)
        self.prominentPoints = dataset
            .prominentEntries(limit: Self.prominentPointLimit)
            .map { Self.point(for: $0, configuration: configuration) }
        self.referenceLines = referenceLines.filter { output.scale.contains($0.value) }
        self.regions = configuration.regions.compactMap { region in
            dataset.positions(covering: region.points).map { Region(positions: $0, color: region.color) }
        }
        self.categoryTickPositions = (configuration.categoryTicks?.points ?? [])
            .compactMap { dataset.positions(covering: $0...$0)?.lowerBound }
    }

    private static func ticks(from output: ChartScaleCalculator.Output, axis: ChartValueAxis?) -> [Tick] {
        guard let axis, let step = output.step else { return [] }
        let formatter = axis.labelFormatter ?? automaticLabelFormatter(step: step)
        return output.ticks.map { tick in
            Tick(
                ordinal: tick.ordinal,
                value: tick.value,
                label: axis.showsLabels ? formatter.string(for: tick.value) : ""
            )
        }
    }

    /// Shows the digits this spacing needs: a step of 0.002 needs three, and a step of 10 needs none.
    private static func automaticLabelFormatter(step: Double) -> ChartValueFormatter {
        .number(fractionDigits: 0...max(Int(-floor(log10(step))), 0))
    }

    /// With a custom formatter, whether it can tell these ticks apart. The automatic formatter
    /// always can, because its digits come from the spacing.
    private static func labelsDiffer(axis: ChartValueAxis?) -> ([Double]) -> Bool {
        guard let axis, axis.showsLabels, let formatter = axis.labelFormatter else { return { _ in true } }
        return { ticks in Set(ticks.map(formatter.string(for:))).count == ticks.count }
    }

    private static func point(for entry: ChartDataset.Entry, configuration: ChartConfiguration) -> Point {
        let formatted = configuration.valueFormatter.string(for: entry.point.value)
        return Point(
            entry: entry,
            annotationValue: annotationValue(
                formatted,
                polarity: entry.point.polarity,
                indicators: configuration.style.annotation.directionIndicators
            ),
            accessibilityValue: ChartAccessibilityDescriber.pointValue(
                for: entry.point,
                formattedValue: formatted,
                options: configuration.accessibility
            )
        )
    }

    private static func annotationValue(
        _ formatted: String,
        polarity: ChartDataPoint.Polarity,
        indicators: ChartStyle.DirectionIndicators
    ) -> String {
        let indicator: String?
        switch polarity {
        case .positive: indicator = indicators.positive
        case .negative: indicator = indicators.negative
        case .zero: indicator = indicators.zero
        }
        guard let indicator, !indicator.isEmpty else { return formatted }
        return "\(indicator) \(formatted)"
    }

    /// The line in terms of plotted positions, or `nil` if it can't be drawn at all.
    private static func resolve(_ line: ChartReferenceLine, in dataset: ChartDataset) -> ReferenceLine? {
        guard line.style.isVisible, line.value.isFinite else { return nil }
        guard let points = line.points else {
            return ReferenceLine(value: line.value, positions: nil, style: line.style)
        }
        return dataset.positions(covering: points).map {
            ReferenceLine(value: line.value, positions: $0, style: line.style)
        }
    }
}
