import ContributionChart
import SwiftUI

/// Dynamic Type, right-to-left layout, and custom VoiceOver wording.
struct AccessibilityScreen: View {
    @Environment(\.dynamicTypeSize) private var systemTypeSize

    /// `nil` follows the system's text size until the stepper is used.
    @State private var chosenTypeSize: DynamicTypeSize?
    @State private var isRightToLeft = false

    private var typeSize: DynamicTypeSize {
        chosenTypeSize ?? systemTypeSize
    }

    private var typeSizeIndex: Binding<Int> {
        Binding(
            get: { DynamicTypeSize.allCases.firstIndex(of: typeSize) ?? 0 },
            set: { chosenTypeSize = DynamicTypeSize.allCases[$0] }
        )
    }

    var body: some View {
        ExamplePage(title: ExampleScenario.accessibility.title) {
            controlsCard
            dynamicTypeCard
            voiceOverCard
        }
    }

    private var controlsCard: some View {
        ExampleCard(title: "Settings", detail: "These apply only to the first chart below.") {
            VStack(alignment: .leading, spacing: 12) {
                Stepper(
                    "Text size: \(String(describing: typeSize))",
                    value: typeSizeIndex,
                    in: 0...(DynamicTypeSize.allCases.count - 1)
                )
                .accessibilityIdentifier("accessibility.type-size")
                Toggle("Right to left", isOn: $isRightToLeft)
                    .accessibilityIdentifier("accessibility.rtl")
            }
        }
    }

    private var dynamicTypeCard: some View {
        ExampleCard(
            title: "Dynamic Type",
            detail: "With no fixed height, the chart grows with its text and the plot keeps its size."
        ) {
            ContributionChart(
                points: SampleData.contributors,
                title: "Your Biggest Contributors & Detractors",
                configuration: ChartConfiguration().identified("chart.accessibility.type")
            )
            .dynamicTypeSize(typeSize)
            .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
        }
    }

    private var voiceOverCard: some View {
        ExampleCard(
            title: "Custom VoiceOver wording",
            detail: "With VoiceOver on, this chart speaks Spanish. Direction is always spoken, not just shown."
        ) {
            ContributionChart(points: SampleData.contributors, configuration: spanish)
                .frame(height: 240)
        }
    }

    private var spanish: ChartConfiguration {
        var configuration = ChartConfiguration().identified("chart.accessibility.custom")
        configuration.accessibility.label = "Mayores contribuyentes y detractores"
        configuration.accessibility.summary = { summary in
            "\(summary.pointCount) valores: \(summary.positiveCount) positivos y \(summary.negativeCount) negativos."
        }
        configuration.accessibility.pointValue = { point, formatted in
            switch point.polarity {
            case .positive: return "Positivo, \(formatted)"
            case .negative: return "Negativo, \(formatted)"
            case .zero: return "Cero, \(formatted)"
            }
        }
        return configuration
    }
}

#Preview {
    NavigationStack { AccessibilityScreen() }
}
