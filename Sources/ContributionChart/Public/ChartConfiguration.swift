import SwiftUI

/// Everything that customises a ``ContributionChart``.
///
/// All settings are optional, so `ContributionChart(points:)` works without one. Numeric
/// settings that make no sense, such as a negative diameter or `.nan`, fall back to a safe
/// value rather than producing invalid geometry.
///
/// ```swift
/// var configuration = ChartConfiguration()
/// configuration.scale = .symmetric
/// configuration.style.marker.diameter = 16
/// configuration.valueFormatter = .number(fractionDigits: 0...1)
/// ```
public struct ChartConfiguration: Sendable {
    /// How values map to vertical positions.
    public var scale: ChartScaleMode
    /// Colours, sizes, and fonts.
    public var style: ChartStyle
    /// Spacing and sizing behaviour.
    public var layout: ChartLayoutOptions
    /// How values are written on labels and read by VoiceOver.
    public var valueFormatter: ChartValueFormatter
    /// An optional value axis with gridlines and tick labels. `nil` hides it.
    public var valueAxis: ChartValueAxis?
    /// Horizontal lines marking values of interest, such as an average.
    public var referenceLines: [ChartReferenceLine]
    /// Background bands that highlight a run of points, such as a time period.
    public var regions: [ChartRegion]
    /// Short tick marks below the plot that separate groups of points. `nil` hides them.
    public var categoryTicks: ChartCategoryTicks?
    /// VoiceOver text and accessibility identifiers.
    public var accessibility: ChartAccessibilityOptions

    /// Creates a configuration. Every parameter has a default.
    public init(
        scale: ChartScaleMode = .proportional,
        style: ChartStyle = ChartStyle(),
        layout: ChartLayoutOptions = ChartLayoutOptions(),
        valueFormatter: ChartValueFormatter = .percent(),
        valueAxis: ChartValueAxis? = nil,
        referenceLines: [ChartReferenceLine] = [],
        regions: [ChartRegion] = [],
        categoryTicks: ChartCategoryTicks? = nil,
        accessibility: ChartAccessibilityOptions = ChartAccessibilityOptions()
    ) {
        self.scale = scale
        self.style = style
        self.layout = layout
        self.valueFormatter = valueFormatter
        self.valueAxis = valueAxis
        self.referenceLines = referenceLines
        self.regions = regions
        self.categoryTicks = categoryTicks
        self.accessibility = accessibility
    }
}

/// Spacing and sizing behaviour for a ``ContributionChart``.
///
/// The parent view always controls the chart's frame. The ideal values below are used only
/// when a parent leaves a dimension open, as a `ScrollView` does along its scrolling axis.
public struct ChartLayoutOptions: Sendable, Equatable {
    /// How points spread across the available width.
    public enum PointDistribution: Sendable, Hashable {
        /// Gives each point an equal slot and centres it there. Labels up to the slot width
        /// always fit, and a single point sits in the middle. This is the default.
        case slots
        /// Places the first and last points at the edges of the plot, so a shaded region or
        /// axis can line up with them exactly. Labels at the edges shift inward to stay
        /// inside the chart.
        case edgeToEdge
    }

    /// How points spread across the available width.
    public var pointDistribution: PointDistribution
    /// The space between the chart's frame and its content.
    public var insets: EdgeInsets
    /// The width used when the parent leaves the width open, in points.
    public var idealWidth: CGFloat
    /// The plot height used when the parent leaves the height open, in points.
    ///
    /// The title and labels are added on top, so the plot keeps this size as Dynamic Type
    /// makes the text larger.
    public var idealPlotHeight: CGFloat
    /// The horizontal space per point used when the parent leaves the width open, in points.
    ///
    /// This lets a dense chart in a horizontal `ScrollView` choose a readable width by itself.
    public var minimumPointSpacing: CGFloat
    /// The smallest acceptable plot height, in points.
    ///
    /// When the frame is too short to fit this much plot, the chart drops labels, then the
    /// title, then the axis labels, keeping the marks visible as long as possible.
    public var minimumPlotHeight: CGFloat

    /// Creates layout options.
    public init(
        pointDistribution: PointDistribution = .slots,
        insets: EdgeInsets = EdgeInsets(),
        idealWidth: CGFloat = 320,
        idealPlotHeight: CGFloat = 140,
        minimumPointSpacing: CGFloat = 8,
        minimumPlotHeight: CGFloat = 32
    ) {
        self.pointDistribution = pointDistribution
        self.insets = insets
        self.idealWidth = idealWidth
        self.idealPlotHeight = idealPlotHeight
        self.minimumPointSpacing = minimumPointSpacing
        self.minimumPlotHeight = minimumPlotHeight
    }
}

/// A value axis drawn as gridlines with tick labels at the leading edge.
///
/// Showing an axis rounds the scale outward to tidy numbers, so that gridlines fall on
/// values such as -20, -10, 0, 10, 20, and 30.
public struct ChartValueAxis: Sendable {
    /// Roughly how many ticks to aim for. The final count depends on where tidy values fall.
    public var desiredTickCount: Int
    /// The gridline appearance.
    public var gridline: ChartLineStyle
    /// Whether tick labels are shown.
    public var showsLabels: Bool
    /// The tick label font.
    public var labelFont: Font
    /// The tick label colour.
    public var labelColor: Color
    /// How tick values are written. By default, labels show as many digits as the spacing
    /// between ticks needs.
    ///
    /// With your own formatter, ticks are spaced so that no two labels read the same. If it can't
    /// show any spacing that suits the data, such as whole numbers for values below 1, only zero
    /// is labelled rather than printing a misleading number.
    public var labelFormatter: ChartValueFormatter?
    /// The space between a tick label and its gridline below it, in points.
    public var labelSpacing: CGFloat
    /// The space between the tick labels and the first point, in points.
    public var labelTrailingSpacing: CGFloat

    /// Creates a value axis.
    public init(
        desiredTickCount: Int = 6,
        gridline: ChartLineStyle = ChartLineStyle(color: .secondary.opacity(0.35)),
        showsLabels: Bool = true,
        labelFont: Font = .caption2,
        labelColor: Color = .secondary,
        labelFormatter: ChartValueFormatter? = nil,
        labelSpacing: CGFloat = 2,
        labelTrailingSpacing: CGFloat = 4
    ) {
        self.desiredTickCount = desiredTickCount
        self.gridline = gridline
        self.showsLabels = showsLabels
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.labelFormatter = labelFormatter
        self.labelSpacing = labelSpacing
        self.labelTrailingSpacing = labelTrailingSpacing
    }
}

/// A horizontal line marking a value of interest, such as an average or a target.
///
/// In ``ChartScaleMode/proportional`` and ``ChartScaleMode/symmetric`` modes the scale grows
/// to include the line. With a ``ChartScaleMode/fixed(lower:upper:)`` scale, a line outside
/// the range is not drawn. Lines are drawn above the markers.
public struct ChartReferenceLine: Sendable, Equatable {
    /// The value at which the line is drawn.
    public var value: Double
    /// The indices in the chart's `points` array that the line spans. `nil` spans the chart.
    public var points: ClosedRange<Int>?
    /// The line appearance.
    public var style: ChartLineStyle

    /// Creates a reference line.
    public init(value: Double, points: ClosedRange<Int>? = nil, style: ChartLineStyle) {
        self.value = value
        self.points = points
        self.style = style
    }
}

/// A background band behind a run of points, such as a time period.
///
/// A region that includes the first or last point extends to that edge of the chart.
public struct ChartRegion: Sendable, Equatable {
    /// The indices in the chart's `points` array that the region covers.
    public var points: ClosedRange<Int>
    /// The fill colour.
    public var color: Color

    /// Creates a region.
    public init(points: ClosedRange<Int>, color: Color) {
        self.points = points
        self.color = color
    }
}

/// Short tick marks below the plot, used to separate groups of points.
public struct ChartCategoryTicks: Sendable, Equatable {
    /// The indices in the chart's `points` array that receive a tick.
    public var points: [Int]
    /// The tick length in points.
    public var length: CGFloat
    /// The tick appearance.
    public var style: ChartLineStyle

    /// Creates category ticks.
    public init(
        points: [Int],
        length: CGFloat = 5,
        style: ChartLineStyle = ChartLineStyle(color: .primary)
    ) {
        self.points = points
        self.length = length
        self.style = style
    }
}
