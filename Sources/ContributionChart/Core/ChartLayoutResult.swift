import SwiftUI

/// The stem and marker of one point.
struct ChartMark: Sendable, Equatable {
    let position: Int
    let polarity: ChartDataPoint.Polarity
    /// The marker's centre, which is the point's position on the scale.
    let center: CGPoint
    let markerDiameter: CGFloat
    /// `nil` when stems are hidden, the value is zero, or the marker reaches the baseline.
    let stem: CGRect?

    var markerFrame: CGRect {
        CGRect(
            x: center.x - markerDiameter / 2,
            y: center.y - markerDiameter / 2,
            width: markerDiameter,
            height: markerDiameter
        )
    }

    /// Everything drawn for this point, used to keep labels off it.
    var bounds: CGRect {
        stem.map { $0.union(markerFrame) } ?? markerFrame
    }

    func offsetBy(_ origin: CGPoint) -> ChartMark {
        ChartMark(
            position: position,
            polarity: polarity,
            center: CGPoint(x: center.x + origin.x, y: center.y + origin.y),
            markerDiameter: markerDiameter,
            stem: stem?.offsetBy(dx: origin.x, dy: origin.y)
        )
    }
}

/// The marks and baseline in one coordinate space. See ``ChartGeometryCalculator``.
struct ChartMarksLayout: Sendable, Equatable {
    /// The area in which marker centres can fall.
    let plotFrame: CGRect
    /// The baseline's vertical extent. Its height is zero when the baseline is hidden.
    let baselineFrame: CGRect
    /// The horizontal distance between neighbouring points. Infinite for a single point.
    let spacing: CGFloat
    let marks: [ChartMark]

    func offsetBy(_ origin: CGPoint) -> ChartMarksLayout {
        ChartMarksLayout(
            plotFrame: plotFrame.offsetBy(dx: origin.x, dy: origin.y),
            baselineFrame: baselineFrame.offsetBy(dx: origin.x, dy: origin.y),
            spacing: spacing,
            marks: marks.map { $0.offsetBy(origin) }
        )
    }
}

/// Where a label goes, and whether it fits.
struct ChartAnnotationPlacement: Sendable, Equatable {
    /// The index in ``ChartModel/prominentPoints``.
    let index: Int
    let frame: CGRect
    let isVisible: Bool
}

/// The position of every element in a chart, in the chart's own coordinates.
///
/// A hidden element has a zero frame. It remains a subview of the layout, so the layout asks
/// it to take up no space instead of removing it.
struct ChartLayoutResult: Sendable, Equatable {
    var bounds: CGRect
    var headerFrame: CGRect = .zero
    var marksFrame: CGRect = .zero
    var plotFrame: CGRect = .zero
    var baselineFrame: CGRect = .zero
    var summaryFrame: CGRect = .zero
    var marks: [ChartMark] = []
    var annotations: [ChartAnnotationPlacement] = []
    var annotationProposedWidth: CGFloat = 0
    var gridlineFrames: [CGRect] = []
    var tickLabelFrames: [CGRect] = []
    var referenceLineFrames: [CGRect] = []
    var regionFrames: [CGRect] = []
    var categoryTickFrames: [CGRect] = []
    var pointFrames: [CGRect] = []

    func frame(for role: ChartElementRole) -> CGRect {
        switch role {
        case .unassigned: return .zero
        case .header: return headerFrame
        case .marks: return marksFrame
        case .baseline: return baselineFrame
        case .summary: return summaryFrame
        case let .region(index): return regionFrames.element(at: index)
        case let .gridline(index): return gridlineFrames.element(at: index)
        case let .tickLabel(index): return tickLabelFrames.element(at: index)
        case let .referenceLine(index): return referenceLineFrames.element(at: index)
        case let .categoryTick(index): return categoryTickFrames.element(at: index)
        case let .annotation(index): return annotationFrame(at: index)
        case let .point(index): return pointFrames.element(at: index)
        }
    }

    /// The size to offer an element when placing it.
    ///
    /// A label gets the proposal it was measured with rather than its measured size. A label can
    /// be wider than its proposal, because values never truncate. Offering that extra width
    /// would let its name reflow into fewer lines, shrinking the text within its frame and leaving
    /// a gap above the marker.
    func proposal(for role: ChartElementRole) -> ProposedViewSize {
        if case let .annotation(index) = role, annotations.indices.contains(index), annotations[index].isVisible {
            return ProposedViewSize(width: annotationProposedWidth, height: nil)
        }
        return ProposedViewSize(frame(for: role).size)
    }

    private func annotationFrame(at index: Int) -> CGRect {
        guard annotations.indices.contains(index), annotations[index].isVisible else { return .zero }
        return annotations[index].frame
    }
}

/// Identifies each child of the chart's layout, so it can be given its frame.
enum ChartElementRole: Hashable, Sendable {
    case unassigned
    case header
    case marks
    case baseline
    case summary
    case region(Int)
    case gridline(Int)
    case tickLabel(Int)
    case referenceLine(Int)
    case categoryTick(Int)
    case annotation(Int)
    case point(Int)
}

private extension Array where Element == CGRect {
    func element(at index: Int) -> CGRect {
        indices.contains(index) ? self[index] : .zero
    }
}
