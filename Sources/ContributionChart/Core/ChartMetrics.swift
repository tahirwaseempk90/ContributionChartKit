import SwiftUI

/// The numeric settings the layout depends on, after validation.
///
/// Configuration comes from outside the package, so any value here could be negative or
/// `.nan`. Everything that reaches the layout engine goes through this type first, which is
/// what lets the engine promise finite geometry whatever it is given.
struct ChartMetrics: Sendable, Equatable {
    let insets: EdgeInsets
    let pointDistribution: ChartLayoutOptions.PointDistribution
    let idealWidth: CGFloat
    let idealPlotHeight: CGFloat
    let minimumPointSpacing: CGFloat
    let minimumPlotHeight: CGFloat

    /// Zero when markers are hidden.
    let markerDiameter: CGFloat
    let minimumMarkerDiameter: CGFloat
    let markerSpacingFraction: CGFloat

    /// Zero when stems are hidden.
    let stemWidth: CGFloat
    let minimumStemLength: CGFloat

    /// Zero when the baseline is hidden.
    let baselineThickness: CGFloat
    let headerSpacing: CGFloat

    let showsAnnotations: Bool
    let annotationMarkerSpacing: CGFloat
    let annotationMinimumWidth: CGFloat
    let annotationCollisionPadding: CGFloat

    let gridlineThickness: CGFloat
    let axisLabelSpacing: CGFloat
    let axisLabelTrailingSpacing: CGFloat

    let categoryTickLength: CGFloat
    let categoryTickThickness: CGFloat

    init(_ configuration: ChartConfiguration) {
        let layout = configuration.layout
        let style = configuration.style
        let defaults = ChartLayoutOptions()

        insets = EdgeInsets(
            top: layout.insets.top.sanitizedLength(),
            leading: layout.insets.leading.sanitizedLength(),
            bottom: layout.insets.bottom.sanitizedLength(),
            trailing: layout.insets.trailing.sanitizedLength()
        )
        pointDistribution = layout.pointDistribution
        idealWidth = layout.idealWidth.sanitizedLength(fallback: defaults.idealWidth)
        idealPlotHeight = layout.idealPlotHeight.sanitizedLength(fallback: defaults.idealPlotHeight)
        minimumPointSpacing = layout.minimumPointSpacing.sanitizedLength(fallback: defaults.minimumPointSpacing)
        minimumPlotHeight = layout.minimumPlotHeight.sanitizedLength(fallback: defaults.minimumPlotHeight)

        let marker = ChartStyle.MarkerStyle()
        markerDiameter = style.marker.isVisible
            ? style.marker.diameter.sanitizedLength(fallback: marker.diameter)
            : 0
        minimumMarkerDiameter = style.marker.minimumDiameter.sanitizedLength(fallback: marker.minimumDiameter)
        markerSpacingFraction = style.marker.maximumSpacingFraction
            .sanitizedFraction(fallback: marker.maximumSpacingFraction)

        let stem = ChartStyle.StemStyle()
        stemWidth = style.stem.isVisible ? style.stem.width.sanitizedLength(fallback: stem.width) : 0
        minimumStemLength = style.stem.minimumLength.sanitizedLength(fallback: stem.minimumLength)

        baselineThickness = Self.thickness(of: style.baseline)
        headerSpacing = style.header.spacing.sanitizedLength(fallback: ChartStyle.HeaderStyle().spacing)

        let annotation = ChartStyle.AnnotationStyle()
        showsAnnotations = style.annotation.isVisible
        annotationMarkerSpacing = style.annotation.markerSpacing.sanitizedLength(fallback: annotation.markerSpacing)
        annotationMinimumWidth = style.annotation.minimumWidth.sanitizedLength(fallback: annotation.minimumWidth)
        annotationCollisionPadding = style.annotation.collisionPadding
            .sanitizedLength(fallback: annotation.collisionPadding)

        let axis = configuration.valueAxis
        gridlineThickness = Self.thickness(of: axis?.gridline)
        axisLabelSpacing = (axis?.labelSpacing ?? 0).sanitizedLength()
        axisLabelTrailingSpacing = (axis?.labelTrailingSpacing ?? 0).sanitizedLength()

        categoryTickLength = Self.visibleLength(of: configuration.categoryTicks)
        categoryTickThickness = Self.thickness(of: configuration.categoryTicks?.style)
    }

    private static func visibleLength(of ticks: ChartCategoryTicks?) -> CGFloat {
        guard let ticks, ticks.style.isVisible else { return 0 }
        return ticks.length.sanitizedLength()
    }

    /// Zero for a missing or hidden line.
    private static func thickness(of line: ChartLineStyle?) -> CGFloat {
        guard let line, line.isVisible else { return 0 }
        return line.thickness.sanitizedLength(fallback: 1)
    }

    var horizontalInsets: CGFloat {
        insets.leading + insets.trailing
    }

    var verticalInsets: CGFloat {
        insets.top + insets.bottom
    }

    /// How far marks reach from a point's centre, and so the margin they need from an edge.
    ///
    /// A stem never gets wider than its share of the width, so a generous stem width on a
    /// dense chart doesn't cost margin that the stem will not use.
    func markExtent(width: CGFloat, count: Int) -> CGFloat {
        let widestStem = count > 0 ? min(stemWidth, width / CGFloat(count)) : stemWidth
        return max(markerDiameter, widestStem) / 2
    }
}

extension CGFloat {
    /// This value if it is usable as a length, otherwise the fallback.
    func sanitizedLength(fallback: CGFloat = 0) -> CGFloat {
        isFinite && self >= 0 ? self : fallback
    }

    /// This value if it lies in `0...1`, otherwise the fallback.
    func sanitizedFraction(fallback: CGFloat) -> CGFloat {
        isFinite && self >= 0 && self <= 1 ? self : fallback
    }
}
