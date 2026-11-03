import SwiftUI

/// Draws every stem and marker in a single `Canvas`.
///
/// A chart may have a thousand points, and one canvas avoids thousands of views. Text stays
/// in SwiftUI views, because canvas text cannot be read by VoiceOver.
struct ChartMarksCanvas: View {
    let geometry: ChartGeometryCalculator
    let style: ChartStyle

    var body: some View {
        Canvas { context, size in
            ChartMarksRenderer(style: style).draw(geometry.layout(in: size), in: &context)
        }
        // SwiftUI mirrors where a `Layout` places this canvas, but not what it draws inside.
        .flipsForRightToLeftLayoutDirection(true)
        .accessibilityHidden(true)
    }
}

struct ChartMarksRenderer {
    let style: ChartStyle

    /// One path for each colour of stems and markers.
    private struct PolarityPaths {
        var stems = Path()
        var markers = Path()
    }

    func draw(_ layout: ChartMarksLayout, in context: inout GraphicsContext) {
        var positive = PolarityPaths()
        var negative = PolarityPaths()
        var zero = PolarityPaths()

        for mark in layout.marks {
            switch mark.polarity {
            case .positive: append(mark, to: &positive)
            case .negative: append(mark, to: &negative)
            case .zero: append(mark, to: &zero)
            }
        }

        // Filling one combined path per colour keeps overlapping translucent stems in a dense
        // chart from building up darker bands, and stems go first so none cover a marker.
        let groups = [(positive, style.positive), (negative, style.negative), (zero, style.zero)]
        for (paths, colors) in groups {
            context.fill(paths.stems, with: .color(colors.stemColor.opacity(sanitizedOpacity)))
        }
        for (paths, colors) in groups {
            context.fill(paths.markers, with: .color(colors.markerColor))
        }
    }

    private var sanitizedOpacity: Double {
        let opacity = style.stem.opacity
        return opacity.isFinite ? min(max(opacity, 0), 1) : ChartStyle.StemStyle().opacity
    }

    private func append(_ mark: ChartMark, to paths: inout PolarityPaths) {
        if let stem = mark.stem {
            paths.stems.addRect(stem)
        }
        if mark.markerDiameter > 0 {
            paths.markers.addEllipse(in: mark.markerFrame)
        }
    }
}

/// A horizontal line through the middle of its frame, used for dashed lines.
struct ChartHorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// A solid or dashed line that fills the frame the layout gives it.
struct ChartLineView: View {
    let style: ChartLineStyle

    var body: some View {
        Group {
            if dash.isEmpty {
                Rectangle().fill(style.color)
            } else {
                ChartHorizontalLine().stroke(
                    style.color,
                    style: StrokeStyle(lineWidth: style.thickness.sanitizedLength(fallback: 1), dash: dash)
                )
            }
        }
        .accessibilityHidden(true)
    }

    /// The dash pattern, or nothing if it can't be used. Core Graphics rejects negative lengths,
    /// and a pattern with no positive length would draw nothing at all. Removing just the bad
    /// values would draw a pattern nobody asked for, so the line falls back to solid instead.
    private var dash: [CGFloat] {
        let isUsable = style.dash.allSatisfy { $0.isFinite && $0 >= 0 } && style.dash.contains { $0 > 0 }
        return isUsable ? style.dash : []
    }
}
