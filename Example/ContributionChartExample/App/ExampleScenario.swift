import SwiftUI

/// The demonstration screens, in the order they appear in the sidebar.
enum ExampleScenario: String, CaseIterable, Identifiable, Hashable {
    case reference
    case mixed
    case positiveOnly
    case negativeOnly
    case customStyling
    case responsiveLayout
    case edgeCases
    case accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reference: return "Reference Chart"
        case .mixed: return "Mixed Data"
        case .positiveOnly: return "Positive Only"
        case .negativeOnly: return "Negative Only"
        case .customStyling: return "Custom Styling"
        case .responsiveLayout: return "Responsive Layout"
        case .edgeCases: return "Edge Cases"
        case .accessibility: return "Accessibility"
        }
    }

    var symbol: String {
        switch self {
        case .reference: return "chart.bar.xaxis"
        case .mixed: return "plusminus"
        case .positiveOnly: return "arrow.up"
        case .negativeOnly: return "arrow.down"
        case .customStyling: return "paintbrush"
        case .responsiveLayout: return "rectangle.expand.vertical"
        case .edgeCases: return "exclamationmark.triangle"
        case .accessibility: return "accessibility"
        }
    }

    @MainActor @ViewBuilder var screen: some View {
        switch self {
        case .reference: ReferenceChartScreen()
        case .mixed: MixedDataScreen()
        case .positiveOnly: PositiveOnlyScreen()
        case .negativeOnly: NegativeOnlyScreen()
        case .customStyling: CustomStylingScreen()
        case .responsiveLayout: ResponsiveLayoutScreen()
        case .edgeCases: EdgeCasesScreen()
        case .accessibility: AccessibilityScreen()
        }
    }
}
