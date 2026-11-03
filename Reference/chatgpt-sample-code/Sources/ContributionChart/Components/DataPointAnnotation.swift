import SwiftUI

struct DataPointAnnotation: View {
    let point: ChartDataPoint
    let color: Color
    let configuration: ChartConfiguration

    var body: some View {
        VStack(spacing: 2) {
            Text(point.title)
                .font(.system(size: configuration.labelFontSize, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(configuration.valueFormatter(point.value))
                .font(.system(size: configuration.valueFontSize, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(color)
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(point.title), \(configuration.valueFormatter(point.value))")
    }
}
