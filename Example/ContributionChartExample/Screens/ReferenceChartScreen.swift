import ContributionChart
import SwiftUI

/// Screen 1: the two reference appearances.
///
/// The supplied screenshot and the written brief describe different charts, so this screen
/// shows both, each configured only through the package's public API.
struct ReferenceChartScreen: View {
    /// The pixel aspect ratio of `Reference/chart.jpeg`.
    private let screenshotAspectRatio: CGFloat = 1400 / 760

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ExamplePage(title: ExampleScenario.reference.title) {
            ExampleCard(
                title: "Supplied screenshot",
                detail: "Value axis, shaded period, dotted period averages, and no labels."
            ) {
                ContributionChart(
                    points: SampleData.referenceSeries,
                    configuration: .referenceScreenshot(for: colorScheme).identified("chart.reference")
                )
                .aspectRatio(screenshotAspectRatio, contentMode: .fit)
            }

            ExampleCard(
                title: "Written brief",
                detail: "Green and red markers, named labels, and a yellow background from the app.",
                background: Color(hex: 0xFFD633)
            ) {
                ContributionChart(
                    points: SampleData.contributors,
                    title: "Your Biggest Contributors & Detractors",
                    configuration: briefConfiguration
                )
                .environment(\.colorScheme, .light)
                .frame(height: 300)
            }
        }
    }

    /// Darker stems and labels than the defaults, to stay readable on saturated yellow.
    private var briefConfiguration: ChartConfiguration {
        var configuration = ChartConfiguration().identified("chart.brief")
        configuration.style.positive = .init(color: Color(hex: 0x006B2F))
        configuration.style.negative = .init(color: Color(hex: 0xB00020))
        configuration.style.stem.opacity = 0.7
        return configuration
    }
}

#Preview {
    NavigationStack { ReferenceChartScreen() }
}
