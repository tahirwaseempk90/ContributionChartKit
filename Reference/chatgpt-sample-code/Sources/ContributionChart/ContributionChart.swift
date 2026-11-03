import SwiftUI

/// A responsive zero-baseline chart for positive contributors and negative detractors.
///
/// The chart distributes points evenly across its available width and scales their
/// vertical distance relative to the largest absolute value. Pass an explicit
/// height from the parent when a particular aspect ratio is required.
public struct ContributionChart: View {
    private let points: [ChartDataPoint]
    private let configuration: ChartConfiguration

    public init(
        points: [ChartDataPoint],
        configuration: ChartConfiguration = .init()
    ) {
        self.points = points
        self.configuration = configuration
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let geometries = ChartLayoutEngine(configuration: configuration)
                .makeGeometry(points: points, size: size)

            ZStack(alignment: .topLeading) {
                if !points.isEmpty {
                    ZeroBaseline(
                        color: configuration.baselineColor,
                        width: configuration.baselineWidth
                    )
                    .frame(width: size.width)
                    .position(x: size.width / 2, y: ChartScaleCalculator.baselineY(
                        height: size.height,
                        topInset: configuration.verticalInset,
                        bottomInset: configuration.verticalInset
                    ))

                    if configuration.showsBaselineValue {
                        Text("0%")
                            .font(.system(size: configuration.valueFontSize))
                            .foregroundStyle(.secondary)
                            .position(x: 14, y: ChartScaleCalculator.baselineY(
                                height: size.height,
                                topInset: configuration.verticalInset,
                                bottomInset: configuration.verticalInset
                            ) - 12)
                    }

                    ForEach(geometries, id: \.point.id) { item in
                        let stemHeight = abs(item.baselineY - item.y)
                        DataPointStem(
                            color: item.color,
                            width: configuration.stemWidth,
                            height: stemHeight
                        )
                        .position(x: item.x, y: (item.y + item.baselineY) / 2)

                        DataPointMarker(color: item.color, size: configuration.markerSize)
                            .position(x: item.x, y: item.y)

                        DataPointAnnotation(
                            point: item.point,
                            color: item.color,
                            configuration: configuration
                        )
                        .position(
                            x: item.x,
                            y: item.point.value >= 0
                                ? max(28, item.y - configuration.markerSize / 2 - 30)
                                : min(size.height - 28, item.y + configuration.markerSize / 2 + 30)
                        )
                    }
                } else {
                    Text("No chart data")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(width: size.width, height: size.height)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Contribution and detractor chart")
    }
}
