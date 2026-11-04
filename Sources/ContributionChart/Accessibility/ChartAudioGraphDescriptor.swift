import Accessibility
import SwiftUI

/// Offers the chart's data to VoiceOver as an Audio Graph.
///
/// VoiceOver users can hear the shape of the data as rising and falling tones and browse
/// every value in a table. This matters most for dense charts, where only the largest values
/// have their own elements.
struct ChartAudioGraphDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let summary: String
    let dataset: ChartDataset
    let scale: ChartScale
    let tickValues: [Double]
    let formatter: ChartValueFormatter
    let options: ChartAccessibilityOptions

    func makeChartDescriptor() -> AXChartDescriptor {
        let categories = categories
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: options.categoryAxisTitle,
            categoryOrder: categories
        )
        let valueFormatter = formatter
        let yAxis = AXNumericDataAxisDescriptor(
            title: options.valueAxisTitle,
            range: scale.lower...scale.upper,
            gridlinePositions: tickValues
        ) { valueFormatter.string(for: $0) }
        let series = AXDataSeriesDescriptor(
            name: title,
            isContinuous: false,
            dataPoints: zip(categories, dataset.entries).map { category, entry in
                AXDataPoint(x: category, y: entry.point.value, additionalValues: [], label: entry.point.title)
            }
        )
        return AXChartDescriptor(
            title: title,
            summary: summary,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }

    /// The name VoiceOver reads for each point's position: its title, numbered if repeated so
    /// that each point keeps its own place on the axis.
    private var categories: [String] {
        var occurrences: [String: Int] = [:]
        return dataset.entries.map { entry in
            let title = entry.point.title
            let occurrence = occurrences[title, default: 0] + 1
            occurrences[title] = occurrence
            return occurrence == 1 ? title : "\(title) (\(occurrence))"
        }
    }
}
