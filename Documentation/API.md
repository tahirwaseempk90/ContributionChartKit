# API Reference

Everything here is also available as documentation comments in Xcode, and as a DocC catalog:
choose **Product > Build Documentation**.

## `ContributionChart`

The chart view.

```swift
// Shows a standard message when there is nothing to plot.
ContributionChart(points: [ChartDataPoint], title: String? = nil, configuration: ChartConfiguration = .init())

// Shows your own view when there is nothing to plot.
ContributionChart(points: [ChartDataPoint], title: String? = nil, configuration: ChartConfiguration = .init()) {
    Text("Nothing yet")
}
```

| Parameter | Description |
|---|---|
| `points` | The values to plot, in display order. |
| `title` | An optional title above the plot. Pass localized text. |
| `configuration` | Appearance and behaviour. |
| `emptyState` | The view shown when `points` has no finite values. |

The parent controls the frame. See [Responsive sizing](Customization.md#responsive-sizing).

## `ChartDataPoint`

One labelled value.

```swift
ChartDataPoint(id: String? = nil, title: String, value: Double)
```

| Property | Type | Description |
|---|---|---|
| `id` | `String` | A stable identifier. Defaults to `title`. |
| `title` | `String` | The name next to the marker, also read by VoiceOver. |
| `value` | `Double` | The signed value. |
| `polarity` | `Polarity` | `.positive`, `.negative`, or `.zero`. |
| `isPlottable` | `Bool` | Whether the value is finite. |

### Validation policy

| Input | Behaviour |
|---|---|
| `.nan`, `.infinity`, `-.infinity` | Left out, and the spoken summary reports how many. Other points close the gap. |
| Only non-finite values, or none | Shows the empty state. |
| `0` or `-0.0` | Drawn on the baseline with no stem. |
| Repeated `id` or `title` | All points are drawn. Later ones get a suffixed internal identity such as `a#2`. |

To plot your own types, use `map`:

```swift
let points = holdings.map { ChartDataPoint(id: $0.ticker, title: $0.ticker, value: $0.returnPercent) }
```

## `ChartConfiguration`

All properties are mutable, and every initializer parameter has a default.

| Property | Type | Default | Description |
|---|---|---|---|
| `scale` | `ChartScaleMode` | `.proportional` | How values map to height. |
| `style` | `ChartStyle` | `ChartStyle()` | Colours, sizes, and fonts. |
| `layout` | `ChartLayoutOptions` | `ChartLayoutOptions()` | Spacing and sizing. |
| `valueFormatter` | `ChartValueFormatter` | `.percent()` | How values are written and read aloud. |
| `valueAxis` | `ChartValueAxis?` | `nil` | Gridlines and tick labels. |
| `referenceLines` | `[ChartReferenceLine]` | `[]` | Lines at values of interest. |
| `regions` | `[ChartRegion]` | `[]` | Background bands behind runs of points. |
| `categoryTicks` | `ChartCategoryTicks?` | `nil` | Tick marks below the plot. |
| `accessibility` | `ChartAccessibilityOptions` | Default options | VoiceOver text and identifiers. |

Numeric settings that make no sense, such as a negative diameter or `.nan`, fall back to a safe
value rather than producing invalid geometry.

## `ChartScaleMode`

| Case | Behaviour |
|---|---|
| `.proportional` | Fits the data, so the baseline moves to wherever zero falls. The default. |
| `.symmetric` | Extends equally in both directions, keeping the baseline centred. |
| `.fixed(lower:upper:)` | Uses exactly this range, extended to include zero if needed. Values outside it are drawn at the nearest edge, and their labels keep the real value. Non-finite bounds fall back to `-1...1`. |

## `ChartStyle`

Create one with `ChartStyle()` and change what you need.

| Property | Type | Description |
|---|---|---|
| `positive`, `negative`, `zero` | `PolarityStyle` | Colours for each side of the baseline. |
| `marker` | `MarkerStyle` | The circular markers. |
| `stem` | `StemStyle` | The lines from markers to the baseline. |
| `baseline` | `ChartLineStyle` | The zero line. |
| `annotation` | `AnnotationStyle` | The name and value labels. |
| `header` | `HeaderStyle` | The title. |

### `PolarityStyle`

```swift
PolarityStyle(color: Color)                                               // One colour for everything
PolarityStyle(markerColor: Color, stemColor: Color, valueColor: Color)
```

### `MarkerStyle`

| Property | Default | Description |
|---|---|---|
| `isVisible` | `true` | Whether markers are drawn. |
| `diameter` | `12` | The diameter in points, when there is room. |
| `minimumDiameter` | `3` | The smallest size in dense charts. |
| `maximumSpacingFraction` | `0.7` | The largest share of the distance between points a marker may use. |

### `StemStyle`

| Property | Default | Description |
|---|---|---|
| `isVisible` | `true` | Whether stems are drawn. |
| `width` | `4` | The width in points. Shrinks in step with markers. |
| `opacity` | `0.5` | Applied to the stem colour. |
| `minimumLength` | `6` | The smallest distance from a non-zero value to the baseline. 0 draws strictly to scale. |

### `AnnotationStyle`

| Property | Default | Description |
|---|---|---|
| `isVisible` | `true` | Whether labels are drawn. VoiceOver can reach points either way. |
| `titleFont` | `.footnote.weight(.semibold)` | The name's font. |
| `titleColor` | `.primary` | The name's colour. |
| `titleLineLimit` | `2` | Lines before a long name truncates. |
| `valueFont` | `.caption` | The value's font. |
| `lineSpacing` | `1` | Space between the name and the value. |
| `markerSpacing` | `4` | Space between the marker and the label. |
| `minimumWidth` | `56` | The narrowest width a label is offered in dense charts. |
| `collisionPadding` | `2` | Clear space kept around a label. |
| `directionIndicators` | `↑`, `↓`, none | The symbols before a value. |

### `HeaderStyle`

| Property | Default | Description |
|---|---|---|
| `font` | `.headline` | The title's font. |
| `color` | `.primary` | The title's colour. |
| `alignment` | `.leading` | The title's alignment. |
| `spacing` | `12` | Space between the title and the plot. |

## `ChartLineStyle`

Used for the baseline, gridlines, reference lines, and category ticks.

```swift
ChartLineStyle(isVisible: Bool = true, color: Color, thickness: CGFloat = 1, dash: [CGFloat] = [])
```

`dash` holds alternating dash and gap lengths. An invalid pattern, such as one with a negative
length, draws a solid line.

## `ChartValueFormatter`

```swift
ChartValueFormatter.percent(fractionDigits: 2, locale: .autoupdatingCurrent)   // 11.05 → "11.05%"
ChartValueFormatter.number(fractionDigits: 0...2, locale: .autoupdatingCurrent) // 11.05 → "11.05"
ChartValueFormatter { value in "\(Int(value)) pts" }                            // Your own
```

`percent` takes values that are already percentages, so `11.05` means 11.05%.

Both built-in formatters adapt to extreme values so a label stays readable:

| Value | Example | Reason |
|---|---|---|
| Too small for the fixed digits | `0.004%` | So that a real change isn't displayed as `0.00%`. |
| At least one million | `4.2M%` | Compact notation. |
| At least 1e15, or below 1e-6 | `9.9E300%` | Scientific notation. |

## `ChartLayoutOptions`

| Property | Default | Description |
|---|---|---|
| `pointDistribution` | `.slots` | `.slots` centres each point in an equal slot. `.edgeToEdge` puts the end points at the plot's edges. |
| `insets` | Zero | Space between the frame and the content. |
| `idealWidth` | `320` | The width when the parent leaves it open. |
| `idealPlotHeight` | `140` | The plot height when the parent leaves it open. Title and labels are added on top. |
| `minimumPointSpacing` | `8` | Width per point when the parent leaves it open, for horizontal scrolling. The chosen width stops at 16,384 pixels, the usual GPU texture limit. |
| `minimumPlotHeight` | `32` | Below this, the chart drops labels, then the title, then axis labels. |

## `ChartValueAxis`

Showing an axis rounds the scale outward to tidy values, unless the scale is `.fixed`.

| Property | Default | Description |
|---|---|---|
| `desiredTickCount` | `6` | Roughly how many ticks to aim for. |
| `gridline` | `.secondary` at 35% | The gridline style. |
| `showsLabels` | `true` | Whether tick labels are shown. |
| `labelFont` | `.caption2` | The tick label font. |
| `labelColor` | `.secondary` | The tick label colour. |
| `labelFormatter` | `nil` | How tick values are written. `nil` shows as many digits as the spacing between ticks needs. With your own formatter, ticks are spaced so no two labels read the same, and if that isn't possible only zero is labelled. |
| `labelSpacing` | `2` | Space between a label and the gridline below it. |
| `labelTrailingSpacing` | `4` | Space between the labels and the first point. |

## `ChartReferenceLine`

```swift
ChartReferenceLine(value: Double, points: ClosedRange<Int>? = nil, style: ChartLineStyle)
```

A line at a value of interest, drawn above the markers. `points` limits it to a run of indices in
the `points` array, and a line over a single point takes that point's share of the width. Proportional
and symmetric scales grow to include it. With a fixed scale, a line outside the range isn't drawn.

## `ChartRegion`

```swift
ChartRegion(points: ClosedRange<Int>, color: Color)
```

A background band behind a run of indices in the `points` array. A region that includes the first
or last point extends to that edge of the chart.

## `ChartCategoryTicks`

```swift
ChartCategoryTicks(points: [Int], length: CGFloat = 5, style: ChartLineStyle = .init(color: .primary))
```

Short tick marks below the plot, at indices in the `points` array.

## `ChartEmptyState`

```swift
ChartEmptyState(message: String = "No data available")
```

The standard empty state. Use it directly to change the wording.

## `ChartAccessibilityOptions`

| Property | Default | Description |
|---|---|---|
| `identifier` | `"contribution-chart"` | The chart's identifier. Children add suffixes. |
| `label` | `nil` | The spoken name. Falls back to the title, then "Contribution chart". |
| `summary` | `nil` | Replaces the spoken description. |
| `pointValue` | `nil` | Replaces each point's spoken value. |
| `isAudioGraphEnabled` | `true` | Offers the data as a VoiceOver Audio Graph. |
| `categoryAxisTitle` | `"Items"` | The Audio Graph's horizontal axis name. |
| `valueAxisTitle` | `"Value"` | The Audio Graph's vertical axis name. |

### Identifiers

| Element | Identifier |
|---|---|
| The chart | `contribution-chart` |
| The spoken summary | `contribution-chart.summary` |
| A point | `contribution-chart.point.<id>` |
| The empty state | `contribution-chart.empty` |
| The title, in the empty state | `contribution-chart.header` |

## `ChartAccessibilitySummary`

Passed to the `summary` closure.

| Property | Type |
|---|---|
| `title` | `String?` |
| `pointCount`, `positiveCount`, `negativeCount`, `zeroCount`, `invalidCount` | `Int` |
| `largestPositive`, `largestNegative` | `ChartDataPoint?` |
