import ContributionChart
import SwiftUI

/// Inputs that often break charts.
struct EdgeCasesScreen: View {
    private let densities = [10, 50, 100, 500, 1000]

    @State private var density = 100

    var body: some View {
        ExamplePage(title: ExampleScenario.edgeCases.title) {
            emptyCards
            sparseCards
            extremeCards
            invalidCards
            denseCard
        }
    }

    @ViewBuilder private var emptyCards: some View {
        ExampleCard(title: "Empty", detail: "The standard empty state.") {
            ContributionChart(
                points: [],
                title: "Nothing yet",
                configuration: ChartConfiguration().identified("chart.edge.empty")
            )
            .frame(height: 140)
        }
        ExampleCard(title: "Empty, customised", detail: "Any view can replace the empty state.") {
            ContributionChart(
                points: [],
                configuration: ChartConfiguration().identified("chart.edge.empty-custom")
            ) {
                Label("Add a holding to get started", systemImage: "plus.circle")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("edge.custom-empty")
            }
            .frame(height: 100)
        }
    }

    @ViewBuilder private var sparseCards: some View {
        edgeCard("One point", id: "one", [ChartDataPoint(title: "Only", value: 4.2)])
        edgeCard("Two points", id: "two", [
            ChartDataPoint(title: "Up", value: 4.2),
            ChartDataPoint(title: "Down", value: -1.6)
        ])
        edgeCard("All zero", detail: "Markers sit on a centred baseline.", id: "zero", [
            ChartDataPoint(title: "A", value: 0),
            ChartDataPoint(title: "B", value: 0),
            ChartDataPoint(title: "C", value: 0)
        ])
    }

    @ViewBuilder private var extremeCards: some View {
        edgeCard("Very small values", detail: "Tiny changes stay visible and keep their sign.", id: "small", [
            ChartDataPoint(title: "A", value: 0.0004),
            ChartDataPoint(title: "B", value: -0.0002),
            ChartDataPoint(title: "C", value: 0.0009)
        ])
        edgeCard("Very large values", detail: "Labels switch to compact notation.", id: "large", [
            ChartDataPoint(title: "A", value: 4_200_000_000),
            ChartDataPoint(title: "B", value: -1_300_000_000),
            ChartDataPoint(title: "C", value: 9.9e300)
        ])
        edgeCard("Extremely uneven", detail: "The small value stays on its own side of the baseline.", id: "uneven", [
            ChartDataPoint(title: "Huge", value: 10_000),
            ChartDataPoint(title: "Tiny", value: 0.5),
            ChartDataPoint(title: "Small", value: -3)
        ])
        edgeCard(
            "Long names",
            detail: "Names wrap, then truncate. Values are never cut off.",
            id: "long",
            SampleData.longTitles
        )
    }

    @ViewBuilder private var invalidCards: some View {
        edgeCard("Invalid values", detail: "NaN and infinity are left out.", id: "invalid", [
            ChartDataPoint(title: "Good", value: 2.5),
            ChartDataPoint(title: "NaN", value: .nan),
            ChartDataPoint(title: "Infinity", value: .infinity),
            ChartDataPoint(title: "-Infinity", value: -.infinity),
            ChartDataPoint(title: "Also good", value: -1.5)
        ])
        edgeCard("Duplicate identifiers", detail: "Both points are drawn.", id: "duplicates", [
            ChartDataPoint(id: "same", title: "First", value: 3),
            ChartDataPoint(id: "same", title: "Second", value: -2)
        ])
    }

    private var denseCard: some View {
        ExampleCard(
            title: "Dense data",
            detail: "Marks shrink. The largest values keep their labels and the rest are left out."
        ) {
            VStack(spacing: 12) {
                Picker("Points", selection: $density) {
                    ForEach(densities, id: \.self) { Text(verbatim: "\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("edge.density")

                ContributionChart(
                    points: SampleData.dense(count: density),
                    configuration: ChartConfiguration().identified("chart.edge.dense")
                )
                .frame(height: 300)
            }
        }
    }

    private func edgeCard(
        _ title: String,
        detail: String? = nil,
        id: String,
        _ points: [ChartDataPoint]
    ) -> some View {
        ExampleCard(title: title, detail: detail) {
            ContributionChart(points: points, configuration: ChartConfiguration().identified("chart.edge.\(id)"))
                .frame(height: 220)
        }
    }
}

#Preview {
    NavigationStack { EdgeCasesScreen() }
}
