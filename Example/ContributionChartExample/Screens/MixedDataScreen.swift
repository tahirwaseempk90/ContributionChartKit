import ContributionChart
import SwiftUI

/// Positive and negative values, with each scaling mode.
struct MixedDataScreen: View {
    private enum ScaleChoice: String, CaseIterable, Identifiable {
        case proportional = "Proportional"
        case symmetric = "Symmetric"
        case fixed = "Fixed ±20"

        var id: String { rawValue }

        var mode: ChartScaleMode {
            switch self {
            case .proportional: return .proportional
            case .symmetric: return .symmetric
            case .fixed: return .fixed(lower: -20, upper: 20)
            }
        }
    }

    @State private var scale = ScaleChoice.proportional

    var body: some View {
        ExamplePage(title: ExampleScenario.mixed.title) {
            ExampleCard(title: "Eight points", detail: "Equal magnitudes are equally long on both sides.") {
                VStack(spacing: 12) {
                    Picker("Scale", selection: $scale) {
                        ForEach(ScaleChoice.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("mixed.scale")

                    ContributionChart(
                        points: SampleData.mixed,
                        title: "Sector contributions",
                        configuration: ChartConfiguration(scale: scale.mode).identified("chart.mixed")
                    )
                    .frame(height: 320)
                }
            }

            ExampleCard(title: "With a value axis", detail: "The axis rounds the scale outward to tidy values.") {
                ContributionChart(
                    points: SampleData.mixed,
                    configuration: ChartConfiguration(valueAxis: ChartValueAxis()).identified("chart.mixed.axis")
                )
                .frame(height: 280)
            }
        }
    }
}

#Preview {
    NavigationStack { MixedDataScreen() }
}
