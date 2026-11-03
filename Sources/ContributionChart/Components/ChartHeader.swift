import SwiftUI

/// The optional title above the plot.
struct ChartHeader: View {
    let title: String
    let style: ChartStyle.HeaderStyle

    var body: some View {
        Text(verbatim: title)
            .font(style.font)
            .foregroundStyle(style.color)
            .multilineTextAlignment(style.alignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .accessibilityAddTraits(.isHeader)
    }

    private var frameAlignment: Alignment {
        switch style.alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}
