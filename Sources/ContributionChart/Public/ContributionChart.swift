import SwiftUI

/// A responsive chart of positive contributors and negative detractors around a zero baseline.
///
/// Give the chart its data and let the parent decide its frame:
///
/// ```swift
/// ContributionChart(points: [
///     .init(title: "VFIAX", value: 11.05),
///     .init(title: "VTNIX", value: 6.31),
///     .init(title: "VTSAX", value: -2.70)
/// ])
/// .frame(height: 260)
/// ```
///
/// ## Sizing
///
/// The chart fills whatever frame it is offered and adapts its layout to it. When a parent
/// leaves a dimension open, as a `ScrollView` does, the chart uses an ideal size from
/// ``ChartLayoutOptions`` and never grows without limit.
///
/// ## Dense data
///
/// Marks shrink as points get closer. Labels are placed largest value first, and any label
/// that would overlap another label or mark is left out. Every point stays in the Audio Graph,
/// and up to 100 of the largest values are also exposed as individual VoiceOver elements.
public struct ContributionChart<EmptyState: View>: View {
    private let points: [ChartDataPoint]
    private let title: String?
    private let configuration: ChartConfiguration
    private let emptyState: EmptyState

    /// Creates a chart with custom content for when there is nothing to plot.
    ///
    /// - Parameters:
    ///   - points: The values to plot, in display order.
    ///   - title: An optional title above the plot. Pass localized text.
    ///   - configuration: Appearance and behaviour. Defaults to the standard configuration.
    ///   - emptyState: The view shown when `points` has no finite values.
    public init(
        points: [ChartDataPoint],
        title: String? = nil,
        configuration: ChartConfiguration = ChartConfiguration(),
        @ViewBuilder emptyState: () -> EmptyState
    ) {
        self.points = points
        self.title = title
        self.configuration = configuration
        self.emptyState = emptyState()
    }

    /// The chart's content.
    public var body: some View {
        let model = ChartModel(points: points, title: title, configuration: configuration)
        Group {
            if model.dataset.isEmpty {
                ChartEmptyContainer(model: model) { emptyState }
            } else {
                ChartPlotView(model: model)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(configuration.accessibility.identifier)
    }
}

extension ContributionChart where EmptyState == ChartEmptyState {
    /// Creates a chart that shows a standard message when there is nothing to plot.
    ///
    /// - Parameters:
    ///   - points: The values to plot, in display order.
    ///   - title: An optional title above the plot. Pass localized text.
    ///   - configuration: Appearance and behaviour. Defaults to the standard configuration.
    public init(
        points: [ChartDataPoint],
        title: String? = nil,
        configuration: ChartConfiguration = ChartConfiguration()
    ) {
        self.init(points: points, title: title, configuration: configuration) {
            ChartEmptyState()
        }
    }
}
