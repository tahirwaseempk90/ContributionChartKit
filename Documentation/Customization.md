# Customization

Every example starts from a default configuration and changes only what it needs:

```swift
var configuration = ChartConfiguration()
// ...changes...
ContributionChart(points: points, configuration: configuration)
```

The chart has no background of its own, so it takes on whatever is behind it. Give it a background
with an ordinary SwiftUI modifier:

```swift
ContributionChart(points: points)
    .frame(height: 260)
    .padding()
    .background(.yellow, in: RoundedRectangle(cornerRadius: 16))
```

## Colours

```swift
// One colour for the marker, stem, and value text.
configuration.style.positive = .init(color: .blue)
configuration.style.negative = .init(color: .orange)

// Or separately.
configuration.style.negative = .init(markerColor: .red, stemColor: .pink, valueColor: .primary)

// Values of exactly zero.
configuration.style.zero = .init(color: .gray)
```

The default marker colours keep at least 4.5:1 contrast on both pure white and pure black. Check the
contrast of your own colours against your background, especially for value text. Blue and orange are
easier than green and red for people with colour blindness.

## Fonts

Text styles scale with Dynamic Type. A fixed size doesn't, so prefer text styles.

```swift
configuration.style.annotation.titleFont = .subheadline.weight(.bold)
configuration.style.annotation.titleColor = .secondary
configuration.style.annotation.valueFont = .system(.caption, design: .rounded)
configuration.style.annotation.titleLineLimit = 1

configuration.style.header.font = .title2.weight(.bold)
configuration.style.header.alignment = .center
```

## Markers

```swift
configuration.style.marker.diameter = 18
configuration.style.marker.isVisible = false      // Hide them

// In a dense chart, markers shrink to fit. This is how far.
configuration.style.marker.maximumSpacingFraction = 0.5
configuration.style.marker.minimumDiameter = 2
```

## Stems

```swift
configuration.style.stem.width = 2
configuration.style.stem.opacity = 1
configuration.style.stem.isVisible = false        // Hide them

// Draw every value strictly to scale, even if a tiny value then looks like zero.
configuration.style.stem.minimumLength = 0
```

To draw bars, hide the markers and widen the stems:

```swift
configuration.style.marker.isVisible = false
configuration.style.stem.width = 14
configuration.style.stem.opacity = 1
```

## Baseline

```swift
configuration.style.baseline = ChartLineStyle(color: .secondary, thickness: 2, dash: [6, 4])
configuration.style.baseline.isVisible = false    // Hide it
```

## Labels

```swift
configuration.style.annotation.isVisible = false  // Marks only. VoiceOver can still reach each point.
configuration.style.annotation.markerSpacing = 8
configuration.style.annotation.directionIndicators = .init(positive: "▲", negative: "▼")
configuration.style.annotation.directionIndicators = .init(positive: nil, negative: nil)
```

Direction indicators mean a reader doesn't have to rely on colour alone. If you remove them, keep
the sign in the value text.

## Formatting

```swift
configuration.valueFormatter = .percent(fractionDigits: 1)
configuration.valueFormatter = .number(fractionDigits: 0...2)
configuration.valueFormatter = ChartValueFormatter { value in
    value.formatted(.currency(code: "USD"))
}
```

The formatter also supplies the text VoiceOver reads.

## Scale

```swift
configuration.scale = .symmetric                     // Baseline always centred
configuration.scale = .fixed(lower: -20, upper: 20)  // The same scale across several charts
```

## Axis, reference lines, and regions

```swift
// Gridlines and tick labels. The scale rounds outward to tidy values.
configuration.valueAxis = ChartValueAxis(labelFormatter: .number(fractionDigits: 0...0))

// A line at a value of interest, across the chart or a run of points.
configuration.referenceLines = [
    ChartReferenceLine(value: 5.2, points: 0...19, style: ChartLineStyle(color: .purple, thickness: 2, dash: [3, 2]))
]

// A background band, such as a time period.
configuration.regions = [ChartRegion(points: 20...29, color: .gray.opacity(0.1))]

// Tick marks below the plot to separate groups.
configuration.categoryTicks = ChartCategoryTicks(points: [10, 20])
```

Indices refer to positions in the `points` array you pass, even if the chart leaves some of those
points out as invalid.

The `editorial` configuration in
[`EditorialChartStyle.swift`](../Example/ContributionChartExample/Support/EditorialChartStyle.swift)
combines all of these.

## Empty state

```swift
// Change the wording.
ContributionChart(points: points) {
    ChartEmptyState(message: "No holdings yet")
}

// Or use any view.
ContributionChart(points: points) {
    Label("Add a holding to get started", systemImage: "plus.circle")
}
```

## Accessibility

The default wording is English. All of it can be replaced, which is also how to localise it:

```swift
configuration.accessibility.label = String(localized: "Biggest contributors and detractors")
configuration.accessibility.summary = { summary in
    String(localized: "\(summary.positiveCount) up, \(summary.negativeCount) down")
}
configuration.accessibility.pointValue = { point, formatted in
    point.value >= 0 ? String(localized: "Up \(formatted)") : String(localized: "Down \(formatted)")
}
configuration.accessibility.categoryAxisTitle = String(localized: "Funds")
configuration.accessibility.valueAxisTitle = String(localized: "Return")
configuration.accessibility.identifier = "portfolio-chart"
```

## Responsive sizing

The parent decides the size, and the chart adapts its layout to fit.

```swift
// A fixed height, filling the width.
ContributionChart(points: points).frame(height: 260)

// A fixed shape.
ContributionChart(points: points).aspectRatio(16 / 9, contentMode: .fit)

// In a ScrollView or List, with no frame: chooses an ideal height that grows with Dynamic Type.
ScrollView {
    ContributionChart(points: points)
}

// A dense chart that scrolls: chooses a width that gives each point room.
ScrollView(.horizontal) {
    ContributionChart(points: manyPoints).frame(height: 240)
}
```

To adjust the sizes the chart chooses for itself:

```swift
configuration.layout.idealPlotHeight = 200
configuration.layout.idealWidth = 400
configuration.layout.minimumPointSpacing = 16
```

### What happens in a small frame

When the plot would be shorter than `minimumPlotHeight`, the chart gives up elements in this order:

1. Labels, as every value stays available to VoiceOver.
2. The title, which VoiceOver still announces.
3. Axis labels.

Marks are always kept. Lower `minimumPlotHeight` to keep labels in tighter spaces.

### What happens with dense data

Marks shrink as points get closer. Labels are placed largest value first, and any that would overlap
another label or mark is left out, so the chart never shows unreadable overlapping text. The 100
largest values get their own VoiceOver elements, and every value is available in the Audio Graph.

To label every point in a dense chart, give it room to scroll, or increase `minimumPointSpacing`.
