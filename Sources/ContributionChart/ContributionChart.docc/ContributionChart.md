# ``ContributionChart``

Show which values lifted a total and which pulled it down, around a zero baseline.

## Overview

`ContributionChart` is a SwiftUI view that plots positive contributors above a horizontal baseline
and negative detractors below it. Give it your data and let the parent view decide its frame:

```swift
import ContributionChart
import SwiftUI

struct PortfolioView: View {
    private let data: [ChartDataPoint] = [
        .init(title: "VFIAX", value: 11.05),
        .init(title: "VTNIX", value: 6.31),
        .init(title: "VTSAX", value: -2.70)
    ]

    var body: some View {
        ContributionChart(points: data, title: "Your Biggest Contributors & Detractors")
            .frame(height: 260)
    }
}
```

The chart adapts to whatever frame it receives. When there isn't room for everything, it drops
labels first, then the title, and then the axis labels, keeping the marks visible. Every value
remains available to VoiceOver regardless.

## Topics

### Essentials

- ``ContributionChart/ContributionChart``
- ``ChartDataPoint``
- ``ChartConfiguration``

### Appearance

- ``ChartStyle``
- ``ChartLineStyle``
- ``ChartEmptyState``

### Scale and values

- ``ChartScaleMode``
- ``ChartValueFormatter``

### Layout

- ``ChartLayoutOptions``

### Annotating the plot

- ``ChartValueAxis``
- ``ChartReferenceLine``
- ``ChartRegion``
- ``ChartCategoryTicks``

### Accessibility

- ``ChartAccessibilityOptions``
- ``ChartAccessibilitySummary``
