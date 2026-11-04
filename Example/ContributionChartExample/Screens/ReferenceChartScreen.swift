import ContributionChart
import SwiftUI

/// Two very different looks, each configured only through the package's public API.
struct ReferenceChartScreen: View {
    /// Wide, so that all 30 points have room.
    private let editorialAspectRatio: CGFloat = 1400 / 760

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ExamplePage(title: ExampleScenario.reference.title) {
            ExampleCard(
                title: "Editorial style",
                detail: "A value axis, a shaded period, dotted averages, and no labels."
            ) {
                ContributionChart(
                    points: SampleData.periods,
                    configuration: .editorial(for: colorScheme).identified("chart.reference")
                )
                .aspectRatio(editorialAspectRatio, contentMode: .fit)
            }

            ExampleCard(
                title: "Labelled style",
                detail: "Named labels and direction arrows, on a background from the app.",
                background: Color(hex: 0xFFD633)
            ) {
                ContributionChart(
                    points: SampleData.contributors,
                    title: "Your Biggest Contributors & Detractors",
                    configuration: labelledConfiguration
                )
                .environment(\.colorScheme, .light)
                .frame(height: 300)
            }
        }
    }

    /// Darker stems and labels than the defaults, to stay readable on saturated yellow.
    private var labelledConfiguration: ChartConfiguration {
        var configuration = ChartConfiguration().identified("chart.labelled")
        configuration.style.positive = .init(color: Color(hex: 0x006B2F))
        configuration.style.negative = .init(color: Color(hex: 0xB00020))
        configuration.style.stem.opacity = 0.7
        return configuration
    }
}

#Preview {
    NavigationStack { ReferenceChartScreen() }
}
