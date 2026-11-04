import SwiftUI

/// The standard message shown when a chart has nothing to plot.
///
/// Use it to change the wording, or pass your own view to
/// ``ContributionChart/init(points:title:configuration:emptyState:)``.
public struct ChartEmptyState: View {
    private let message: String

    /// Creates an empty state.
    ///
    /// - Parameter message: The text to show. Pass localized text.
    public init(message: String = "No data available") {
        self.message = message
    }

    /// The message.
    public var body: some View {
        Text(verbatim: message)
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

/// Arranges the optional title and the empty state.
struct ChartEmptyContainer<Content: View>: View {
    let model: ChartModel
    @ViewBuilder let content: Content

    private var identifier: String { model.configuration.accessibility.identifier }

    var body: some View {
        VStack(spacing: model.metrics.headerSpacing) {
            if let title = model.title {
                ChartHeader(title: title, style: model.configuration.style.header)
                    .accessibilityIdentifier("\(identifier).header")
            }
            // Asks for the ideal plot height so the chart doesn't change size when data
            // arrives, while still accepting less in a short frame.
            content
                .frame(maxWidth: .infinity, idealHeight: model.metrics.idealPlotHeight, maxHeight: .infinity)
                // A container of its own, so that this identifier doesn't replace any that the
                // caller put on their custom content.
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("\(identifier).empty")
        }
        .padding(model.metrics.insets)
    }
}
