# ContributionChartKit

A dependency-free SwiftUI package for responsive positive/negative contribution charts.

## Requirements
- Swift 6 toolchain
- iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+

The package declares these platform minimums; validate the exact UI behavior on
each target device family before shipping. The included example is an iOS SwiftUI app.

## Features
- Zero baseline with positive/negative stems and circular markers
- Automatic symmetric vertical scaling around zero
- Even horizontal distribution
- Empty-state handling
- Configurable colors, sizing, insets, and value formatting
- Accessibility labels for data annotations
- No third-party dependencies

## Quick start

```swift
let points = [
    ChartDataPoint(title: "VFIAX", value: 11.05),
    ChartDataPoint(title: "VTNIX", value: 6.31),
    ChartDataPoint(title: "VTSAX", value: -2.70)
]

ContributionChart(points: points)
    .frame(height: 260)
```

See `Documentation/Integration.md` for Xcode integration and `Example/` for sample
usage. Run tests with `swift test`.

## Testing and coverage

Unit tests cover scale and geometry calculations, including empty input, single-point
layout, positive/negative direction, clamping, and non-finite values. Add UI tests
in the consuming Xcode app target for screenshot/layout assertions on supported
simulators. A meaningful 100% coverage claim requires running the suite with the
chosen Xcode/Swift version and inspecting the coverage report; this repository does
not claim an unmeasured percentage.

## Important layout note

This is a chart view, not a full plotting framework. Annotation collision avoidance
for very dense datasets, scrolling, interactive selection, legends, and custom axes
are intentionally outside the initial scope. For the screenshot-like small set of
contributors/detractors, the current API is intentionally simple.
