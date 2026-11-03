import SwiftUI

/// The appearance of a line: the baseline, gridlines, reference lines, and category ticks.
public struct ChartLineStyle: Sendable, Equatable {
    /// Whether the line is drawn.
    public var isVisible: Bool
    /// The line colour.
    public var color: Color
    /// The line thickness in points.
    public var thickness: CGFloat
    /// Alternating dash and gap lengths in points. Empty draws a solid line.
    public var dash: [CGFloat]

    /// Creates a line style.
    public init(isVisible: Bool = true, color: Color, thickness: CGFloat = 1, dash: [CGFloat] = []) {
        self.isVisible = isVisible
        self.color = color
        self.thickness = thickness
        self.dash = dash
    }
}

/// The appearance of a ``ContributionChart``.
///
/// The defaults suit any background: labels use semantic colours that follow light and dark
/// appearance, and the default marker colours keep at least 4.5:1 contrast on both pure
/// white and pure black. Change only what you need:
///
/// ```swift
/// var style = ChartStyle()
/// style.positive = .init(color: .blue)
/// style.marker.diameter = 16
/// style.baseline.thickness = 2
/// ```
public struct ChartStyle: Sendable, Equatable {
    /// The colours used for one side of the baseline.
    public struct PolarityStyle: Sendable, Equatable {
        /// The marker fill colour.
        public var markerColor: Color
        /// The stem colour, before ``StemStyle/opacity`` is applied.
        public var stemColor: Color
        /// The colour of the value text.
        public var valueColor: Color

        /// Uses one colour for the marker, stem, and value text.
        public init(color: Color) {
            self.init(markerColor: color, stemColor: color, valueColor: color)
        }

        /// Sets each colour separately.
        public init(markerColor: Color, stemColor: Color, valueColor: Color) {
            self.markerColor = markerColor
            self.stemColor = stemColor
            self.valueColor = valueColor
        }
    }

    /// The circular marker at the end of each stem.
    public struct MarkerStyle: Sendable, Equatable {
        /// Whether markers are drawn.
        public var isVisible: Bool
        /// The diameter in points, when the points are far enough apart to allow it.
        public var diameter: CGFloat
        /// The smallest diameter markers may shrink to in dense charts.
        public var minimumDiameter: CGFloat
        /// The largest share of the distance between neighbouring points that a marker may
        /// occupy, from 0 to 1. Lower values shrink markers sooner as points get closer.
        public var maximumSpacingFraction: CGFloat

        /// Creates a marker style.
        public init(
            isVisible: Bool = true,
            diameter: CGFloat = 12,
            minimumDiameter: CGFloat = 3,
            maximumSpacingFraction: CGFloat = 0.7
        ) {
            self.isVisible = isVisible
            self.diameter = diameter
            self.minimumDiameter = minimumDiameter
            self.maximumSpacingFraction = maximumSpacingFraction
        }
    }

    /// The vertical line connecting a marker to the baseline.
    public struct StemStyle: Sendable, Equatable {
        /// Whether stems are drawn.
        public var isVisible: Bool
        /// The stem width in points. It shrinks in step with the marker in dense charts.
        public var width: CGFloat
        /// The opacity applied to the stem colour, from 0 to 1.
        public var opacity: Double
        /// The smallest distance between a non-zero value and the baseline, in points.
        ///
        /// This keeps a very small value on its own side of the baseline instead of looking
        /// like zero. Set it to 0 to draw every value strictly to scale.
        public var minimumLength: CGFloat

        /// Creates a stem style.
        public init(
            isVisible: Bool = true,
            width: CGFloat = 4,
            opacity: Double = 0.5,
            minimumLength: CGFloat = 6
        ) {
            self.isVisible = isVisible
            self.width = width
            self.opacity = opacity
            self.minimumLength = minimumLength
        }
    }

    /// Short symbols that show direction without relying on colour.
    public struct DirectionIndicators: Sendable, Equatable {
        /// The symbol before a positive value.
        public var positive: String?
        /// The symbol before a negative value.
        public var negative: String?
        /// The symbol before a zero value.
        public var zero: String?

        /// Creates a set of indicators. Pass `nil` to omit one.
        public init(positive: String? = "↑", negative: String? = "↓", zero: String? = nil) {
            self.positive = positive
            self.negative = negative
            self.zero = zero
        }
    }

    /// The name and value text next to each marker.
    public struct AnnotationStyle: Sendable, Equatable {
        /// Whether labels are drawn. Points stay available to VoiceOver either way.
        public var isVisible: Bool
        /// The font of the name. Text styles scale with Dynamic Type.
        public var titleFont: Font
        /// The colour of the name.
        public var titleColor: Color
        /// The most lines a long name may use before it is truncated.
        public var titleLineLimit: Int
        /// The font of the value.
        public var valueFont: Font
        /// The space between the name and the value, in points.
        public var lineSpacing: CGFloat
        /// The space between the marker and the label, in points.
        public var markerSpacing: CGFloat
        /// The narrowest width a label is offered in dense charts, in points. Names are
        /// truncated to fit but values never are.
        public var minimumWidth: CGFloat
        /// The clear space kept around a label before it counts as overlapping, in points.
        public var collisionPadding: CGFloat
        /// The symbols shown before the value.
        public var directionIndicators: DirectionIndicators

        /// Creates an annotation style.
        public init(
            isVisible: Bool = true,
            titleFont: Font = .footnote.weight(.semibold),
            titleColor: Color = .primary,
            titleLineLimit: Int = 2,
            valueFont: Font = .caption,
            lineSpacing: CGFloat = 1,
            markerSpacing: CGFloat = 4,
            minimumWidth: CGFloat = 56,
            collisionPadding: CGFloat = 2,
            directionIndicators: DirectionIndicators = DirectionIndicators()
        ) {
            self.isVisible = isVisible
            self.titleFont = titleFont
            self.titleColor = titleColor
            self.titleLineLimit = titleLineLimit
            self.valueFont = valueFont
            self.lineSpacing = lineSpacing
            self.markerSpacing = markerSpacing
            self.minimumWidth = minimumWidth
            self.collisionPadding = collisionPadding
            self.directionIndicators = directionIndicators
        }
    }

    /// The optional title above the plot.
    public struct HeaderStyle: Sendable, Equatable {
        /// The title font.
        public var font: Font
        /// The title colour.
        public var color: Color
        /// How the title aligns horizontally.
        public var alignment: TextAlignment
        /// The space between the title and the plot, in points.
        public var spacing: CGFloat

        /// Creates a header style.
        public init(
            font: Font = .headline,
            color: Color = .primary,
            alignment: TextAlignment = .leading,
            spacing: CGFloat = 12
        ) {
            self.font = font
            self.color = color
            self.alignment = alignment
            self.spacing = spacing
        }
    }

    /// The colours for values above the baseline. Green by default.
    public var positive: PolarityStyle
    /// The colours for values below the baseline. Red by default.
    public var negative: PolarityStyle
    /// The colours for values of exactly zero. Grey by default.
    public var zero: PolarityStyle
    /// The marker appearance.
    public var marker: MarkerStyle
    /// The stem appearance.
    public var stem: StemStyle
    /// The zero baseline appearance.
    public var baseline: ChartLineStyle
    /// The label appearance.
    public var annotation: AnnotationStyle
    /// The title appearance.
    public var header: HeaderStyle

    /// Creates the default style. Change its properties to customise it.
    public init() {
        positive = PolarityStyle(color: ChartPalette.positive.color)
        negative = PolarityStyle(color: ChartPalette.negative.color)
        zero = PolarityStyle(color: ChartPalette.neutral.color)
        marker = MarkerStyle()
        stem = StemStyle()
        baseline = ChartLineStyle(color: .primary)
        annotation = AnnotationStyle()
        header = HeaderStyle()
    }

    func colors(for polarity: ChartDataPoint.Polarity) -> PolarityStyle {
        switch polarity {
        case .positive: return positive
        case .negative: return negative
        case .zero: return zero
        }
    }
}

/// The default mark colours.
///
/// A chart can sit on any background, so these are not tuned for light or dark. Each has a
/// relative luminance near 0.179, the point where contrast against white and against black
/// is equal, which gives at least 4.5:1 on both. `ChartPaletteTests` verifies this.
enum ChartPalette {
    struct Swatch: Sendable, Equatable {
        let red: Double
        let green: Double
        let blue: Double

        var color: Color {
            Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
        }

        init(hex: UInt32) {
            let channelMask: UInt32 = 0xFF
            let channelMaximum = Double(channelMask)
            red = Double((hex >> 16) & channelMask) / channelMaximum
            green = Double((hex >> 8) & channelMask) / channelMaximum
            blue = Double(hex & channelMask) / channelMaximum
        }
    }

    static let positive = Swatch(hex: 0x00873C)
    static let negative = Swatch(hex: 0xE5202B)
    static let neutral = Swatch(hex: 0x767676)
}
