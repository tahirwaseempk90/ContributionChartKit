import SwiftUI

/// The chart as VoiceOver sees it: a summary, followed by one element per point.
///
/// These are transparent views separate from the visible text. Each is laid out over the
/// point it describes, so a point stays reachable when its label is hidden for lack of room,
/// and direction is spoken in words instead of being conveyed by colour or an arrow.
struct ChartPlotAccessibility: View {
    let model: ChartModel

    private var options: ChartAccessibilityOptions { model.configuration.accessibility }

    /// Reads the summary first and then the points in display order. SwiftUI would otherwise
    /// order them by position, which would mix up points at different heights.
    private var summaryPriority: Double {
        Double(model.prominentPoints.count + 1)
    }

    var body: some View {
        summaryElement.chartRole(.summary)
        ForEach(model.prominentPoints.indices, id: \.self) { index in
            ChartPointAccessibilityElement(
                point: model.prominentPoints[index],
                identifierPrefix: options.identifier,
                sortPriority: Double(model.prominentPoints.count - index)
            )
            .chartRole(.point(index))
        }
    }

    @ViewBuilder private var summaryElement: some View {
        let summary = ChartAccessibilityDescriber.summary(for: model.dataset, title: model.title)
        let text = ChartAccessibilityDescriber.summaryText(
            for: summary,
            options: options,
            formatter: model.configuration.valueFormatter
        )
        let element = Color.clear
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(ChartAccessibilityDescriber.chartLabel(title: model.title, options: options))
            .accessibilityValue(text)
            .accessibilityAddTraits(model.title == nil ? .isStaticText : [.isStaticText, .isHeader])
            .accessibilityIdentifier("\(options.identifier).summary")
            .accessibilitySortPriority(summaryPriority)

        if options.isAudioGraphEnabled {
            element.accessibilityChartDescriptor(
                ChartAudioGraphDescriptor(
                    title: ChartAccessibilityDescriber.chartLabel(title: model.title, options: options),
                    summary: text,
                    dataset: model.dataset,
                    scale: model.scale,
                    tickValues: model.ticks.map(\.value),
                    formatter: model.configuration.valueFormatter,
                    options: options
                )
            )
        } else {
            element
        }
    }
}

/// The VoiceOver element for one point.
struct ChartPointAccessibilityElement: View {
    let point: ChartModel.Point
    let identifierPrefix: String
    let sortPriority: Double

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(point.entry.point.title)
            .accessibilityValue(point.accessibilityValue)
            // Required on macOS, which only exposes an element's value if it is static text.
            .accessibilityAddTraits(.isStaticText)
            .accessibilityIdentifier("\(identifierPrefix).point.\(point.entry.id)")
            .accessibilitySortPriority(sortPriority)
    }
}
