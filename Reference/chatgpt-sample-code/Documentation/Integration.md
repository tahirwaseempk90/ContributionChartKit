# Integration

## Add the package

In Xcode choose **File → Add Package Dependencies → Add Local…** and select the
`ContributionChartKit` directory. Add the `ContributionChart` product to your app target.

## Basic use

```swift
import SwiftUI
import ContributionChart

struct PortfolioView: View {
    private let points = [
        ChartDataPoint(title: "VFIAX", value: 11.05),
        ChartDataPoint(title: "VTNIX", value: 6.31),
        ChartDataPoint(title: "VTSAX", value: -2.70)
    ]

    var body: some View {
        ContributionChart(points: points)
            .frame(maxWidth: .infinity)
            .frame(height: 260)
    }
}
```

The parent view owns sizing. Use `.frame(height:)` or a parent layout to give the
chart a meaningful drawing area. The chart adapts its point spacing and scale to
that area.
