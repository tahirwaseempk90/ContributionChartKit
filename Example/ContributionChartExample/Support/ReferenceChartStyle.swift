import ContributionChart
import SwiftUI

extension ChartConfiguration {
    /// Reproduces `Reference/chart.jpeg` using nothing but the package's public API.
    ///
    /// Sizes and colours were measured from the image, in terms of a 700-point-wide chart,
    /// which is the image at 2x. Rendered at that size, every marker lands within one pixel of
    /// the original. On narrower charts the marks shrink in proportion, because
    /// `maximumSpacingFraction` ties them to the distance between points.
    static func referenceScreenshot(for colorScheme: ColorScheme) -> ChartConfiguration {
        let palette = ReferencePalette(colorScheme: colorScheme)
        var configuration = ChartConfiguration()
        configuration.valueFormatter = .number(fractionDigits: 0...1)
        configuration.layout.pointDistribution = .edgeToEdge
        configuration.layout.insets = EdgeInsets(top: 2, leading: 0, bottom: 19, trailing: 2)
        configuration.style = referenceStyle(palette)
        configuration.valueAxis = ChartValueAxis(
            desiredTickCount: 6,
            gridline: ChartLineStyle(color: palette.gridline),
            labelFont: Font.system(size: 12.5, weight: .thin).width(.condensed),
            labelColor: palette.label,
            labelFormatter: ChartValueFormatter { value in
                // The screenshot uses a true minus sign rather than a hyphen.
                "\(Int(value))".replacingOccurrences(of: "-", with: "\u{2212}")
            },
            labelSpacing: 0.5,
            labelTrailingSpacing: 4
        )
        configuration.regions = [ChartRegion(points: 19...29, color: palette.region)]
        let dotted = ChartLineStyle(color: palette.average, thickness: 3.5, dash: [2.75, 2.1])
        configuration.referenceLines = [
            ChartReferenceLine(value: 5.18, points: 0...19, style: dotted),
            ChartReferenceLine(value: -8.76, points: 19...29, style: dotted)
        ]
        configuration.categoryTicks = ChartCategoryTicks(
            points: [9, 19],
            length: 5,
            style: ChartLineStyle(color: palette.tick)
        )
        return configuration
    }

    private static func referenceStyle(_ palette: ReferencePalette) -> ChartStyle {
        var style = ChartStyle()
        style.positive = .init(markerColor: palette.ink, stemColor: palette.positiveStem, valueColor: palette.ink)
        style.negative = .init(markerColor: palette.red, stemColor: palette.negativeStem, valueColor: palette.ink)
        style.marker = .init(diameter: 11, minimumDiameter: 2, maximumSpacingFraction: 0.5)
        // Opaque, as in the screenshot, so stems look the same over the shaded region.
        style.stem = .init(width: 5, opacity: 1, minimumLength: 0)
        style.annotation.isVisible = false
        style.baseline = ChartLineStyle(color: palette.baseline)
        return style
    }

    /// Returns a copy with the given accessibility identifier.
    func identified(_ identifier: String) -> ChartConfiguration {
        var copy = self
        copy.accessibility.identifier = identifier
        return copy
    }
}

/// The screenshot's colours, along with a dark counterpart it doesn't have.
private struct ReferencePalette {
    let ink: Color
    let red: Color
    let positiveStem: Color
    let negativeStem: Color
    let baseline: Color
    let gridline: Color
    let region: Color
    let average: Color
    let label: Color
    let tick: Color

    init(colorScheme: ColorScheme) {
        if colorScheme == .dark {
            ink = Color(hex: 0xF2F2F2)
            red = Color(hex: 0xE5484D)
            positiveStem = Color(hex: 0x4A4E52)
            negativeStem = Color(hex: 0x6B3A2E)
            baseline = Color(hex: 0xD0D0D0)
            gridline = Color(hex: 0x3A3A3C)
            region = Color(hex: 0x26272A)
            average = Color(hex: 0x8E8E5F)
            label = Color(hex: 0xE5E5E5)
            tick = Color(hex: 0xD0D0D0)
        } else {
            ink = .black
            red = Color(hex: 0xCD3238)
            positiveStem = Color(hex: 0xE1E4E7)
            negativeStem = Color(hex: 0xFAD7CA)
            baseline = Color(hex: 0x353431)
            gridline = Color(hex: 0xE6E6E6)
            region = Color(hex: 0xEEEFF1)
            average = Color(hex: 0xB3B37F)
            label = Color(hex: 0x1A1A1A)
            tick = Color(hex: 0x323232)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
