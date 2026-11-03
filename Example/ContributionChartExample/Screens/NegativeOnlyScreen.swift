import ContributionChart
import SwiftUI

/// Screen 4: every point below the baseline.
struct NegativeOnlyScreen: View {
    var body: some View {
        ExamplePage(title: ExampleScenario.negativeOnly.title) {
            ExampleCard(title: "Proportional", detail: "The baseline rises to the top to use all the height.") {
                ContributionChart(
                    points: SampleData.negativeOnly,
                    title: "Regional decline",
                    configuration: ChartConfiguration().identified("chart.negative")
                )
                .frame(height: 280)
            }
            ExampleCard(title: "Fixed scale", detail: "Shares a range with another chart for direct comparison.") {
                ContributionChart(
                    points: SampleData.negativeOnly,
                    configuration: ChartConfiguration(scale: .fixed(lower: -10, upper: 10))
                        .identified("chart.negative.fixed")
                )
                .frame(height: 280)
            }
        }
    }
}

#Preview {
    NavigationStack { NegativeOnlyScreen() }
}
