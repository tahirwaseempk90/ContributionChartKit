import ContributionChart
import SwiftUI

/// Every point above the baseline.
struct PositiveOnlyScreen: View {
    var body: some View {
        ExamplePage(title: ExampleScenario.positiveOnly.title) {
            ExampleCard(title: "Proportional", detail: "The baseline drops to the bottom to use all the height.") {
                ContributionChart(
                    points: SampleData.positiveOnly,
                    title: "Regional growth",
                    configuration: ChartConfiguration().identified("chart.positive")
                )
                .frame(height: 280)
            }
            ExampleCard(title: "Symmetric", detail: "The baseline stays centred, leaving the lower half empty.") {
                ContributionChart(
                    points: SampleData.positiveOnly,
                    configuration: ChartConfiguration(scale: .symmetric).identified("chart.positive.symmetric")
                )
                .frame(height: 280)
            }
        }
    }
}

#Preview {
    NavigationStack { PositiveOnlyScreen() }
}
