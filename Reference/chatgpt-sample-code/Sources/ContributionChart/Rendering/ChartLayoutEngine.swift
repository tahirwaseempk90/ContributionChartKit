import SwiftUI

/// Maps data to positions inside the available drawing rectangle.
struct ChartLayoutEngine {
    let configuration: ChartConfiguration

    func makeGeometry(points: [ChartDataPoint], size: CGSize) -> [PointGeometry] {
        guard !points.isEmpty else { return [] }

        let inset = max(0, configuration.horizontalInset)
        let usableWidth = max(0, size.width - inset * 2)
        let top = max(0, configuration.verticalInset)
        let bottom = max(0, configuration.verticalInset)
        let halfHeight = max(0, (size.height - top - bottom) / 2)
        let baseline = ChartScaleCalculator.baselineY(
            height: size.height, topInset: top, bottomInset: bottom
        )
        let maxMagnitude = ChartScaleCalculator.maximumMagnitude(in: points.map(\.value))

        return points.enumerated().map { index, point in
            let fraction = points.count == 1 ? 0.5 : CGFloat(index) / CGFloat(points.count - 1)
            let x = inset + usableWidth * fraction
            var y = ChartScaleCalculator.yPosition(
                value: point.value,
                maximumMagnitude: maxMagnitude,
                baselineY: baseline,
                drawableHalfHeight: halfHeight
            )
            if abs(y - baseline) < configuration.minimumStemLength {
                y = baseline + (point.value >= 0 ? -1 : 1) *
                    min(configuration.minimumStemLength, halfHeight)
            }
            return PointGeometry(
                point: point, x: x, y: y, baselineY: baseline,
                color: point.value >= 0 ? configuration.positiveColor : configuration.negativeColor
            )
        }
    }
}
