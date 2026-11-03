import SwiftUI

/// Controls chart spacing, labels, scale, and visual treatment.
public struct ChartConfiguration: Sendable {
    public var positiveColor: Color
    public var negativeColor: Color
    public var baselineColor: Color
    public var baselineWidth: CGFloat
    public var stemWidth: CGFloat
    public var markerSize: CGFloat
    public var horizontalInset: CGFloat
    public var verticalInset: CGFloat
    public var labelFontSize: CGFloat
    public var valueFontSize: CGFloat
    public var minimumStemLength: CGFloat
    public var showsBaselineValue: Bool
    public var valueFormatter: @Sendable (Double) -> String

    public init(
        positiveColor: Color = Color(red: 0.20, green: 0.68, blue: 0.12),
        negativeColor: Color = Color(red: 0.62, green: 0.16, blue: 0.08),
        baselineColor: Color = Color.gray.opacity(0.35),
        baselineWidth: CGFloat = 1,
        stemWidth: CGFloat = 1.5,
        markerSize: CGFloat = 10,
        horizontalInset: CGFloat = 18,
        verticalInset: CGFloat = 16,
        labelFontSize: CGFloat = 13,
        valueFontSize: CGFloat = 12,
        minimumStemLength: CGFloat = 8,
        showsBaselineValue: Bool = true,
        valueFormatter: @escaping @Sendable (Double) -> String = { value in
            let sign = value > 0 ? "+" : ""
            return "\(sign)\(value.formatted(.number.precision(.fractionLength(0...2))))%"
        }
    ) {
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        self.baselineColor = baselineColor
        self.baselineWidth = baselineWidth
        self.stemWidth = stemWidth
        self.markerSize = markerSize
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset
        self.labelFontSize = labelFontSize
        self.valueFontSize = valueFontSize
        self.minimumStemLength = minimumStemLength
        self.showsBaselineValue = showsBaselineValue
        self.valueFormatter = valueFormatter
    }
}
