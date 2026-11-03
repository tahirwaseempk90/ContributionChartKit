import CoreGraphics

/// Pure scale calculations, kept independent from SwiftUI rendering.
enum ChartScaleCalculator {
    static func maximumMagnitude(in values: [Double]) -> Double {
        max(values.map { abs($0.isFinite ? $0 : 0) }.max() ?? 0, 1)
    }

    static func baselineY(height: CGFloat, topInset: CGFloat, bottomInset: CGFloat) -> CGFloat {
        let usable = max(0, height - topInset - bottomInset)
        return topInset + usable / 2
    }

    static func yPosition(
        value: Double,
        maximumMagnitude: Double,
        baselineY: CGFloat,
        drawableHalfHeight: CGFloat
    ) -> CGFloat {
        guard maximumMagnitude > 0 else { return baselineY }
        let safeValue = value.isFinite ? value : 0
        let normalized = min(max(safeValue / maximumMagnitude, -1), 1)
        return baselineY - CGFloat(normalized) * drawableHalfHeight
    }
}
