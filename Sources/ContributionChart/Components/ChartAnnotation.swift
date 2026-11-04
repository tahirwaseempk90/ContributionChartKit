import SwiftUI

/// The name and value drawn next to a marker.
///
/// Hidden from VoiceOver because ``ChartPointAccessibilityElement`` describes the same point,
/// and works whether or not this label fits on screen.
struct ChartAnnotation: View {
    let point: ChartModel.Point
    let style: ChartStyle.AnnotationStyle
    let valueColor: Color

    var body: some View {
        VStack(spacing: style.lineSpacing.sanitizedLength()) {
            Text(verbatim: point.entry.point.title)
                .font(style.titleFont)
                .foregroundStyle(style.titleColor)
                .multilineTextAlignment(.center)
                .lineLimit(max(style.titleLineLimit, 1))
                .truncationMode(.tail)
            // A truncated number would be misleading, so the value keeps its full width. If
            // that does not fit, the layout hides the whole label rather than cutting it off.
            Text(verbatim: point.annotationValue)
                .font(style.valueFont)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityHidden(true)
    }
}

/// A value next to a gridline. Hidden from VoiceOver, which reads the values themselves.
struct ChartTickLabel: View {
    let text: String
    let axis: ChartValueAxis

    var body: some View {
        Text(verbatim: text)
            .font(axis.labelFont)
            .foregroundStyle(axis.labelColor)
            .lineLimit(1)
            .fixedSize()
            .accessibilityHidden(true)
    }
}
