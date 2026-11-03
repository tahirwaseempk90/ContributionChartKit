# Integration

## Add the package

The package has no dependencies, and needs Swift 6 tools, which means Xcode 16 or later.

### From GitHub in Xcode

1. Choose **File > Add Package Dependencies**.
2. Enter `https://github.com/tahirwaseempk90/ContributionChartKit`.
3. Choose a version rule. **Up to Next Major Version** from `1.0.0` is the usual choice.
4. Add the `ContributionChart` library to your app target.

### From a local folder in Xcode

Use this to work on the package and your app together.

1. Choose **File > Add Package Dependencies**, then **Add Local**.
2. Select this folder, the one containing `Package.swift`.
3. In your target's **General** settings, add `ContributionChart` under
   **Frameworks, Libraries, and Embedded Content**.

### In `Package.swift`

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyFeature",
    platforms: [.iOS(.v16), .macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/tahirwaseempk90/ContributionChartKit.git", from: "1.0.0")
        // Or a local copy:
        // .package(path: "../ContributionChartKit")
    ],
    targets: [
        .target(
            name: "MyFeature",
            dependencies: [.product(name: "ContributionChart", package: "ContributionChartKit")]
        )
    ]
)
```

Two names are involved. `package:` is the last part of the URL or folder path, `ContributionChartKit`, because
that's how Swift Package Manager identifies a dependency. `name:` is the library, `ContributionChart`, which is
also what you import.

## Use the chart

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
            .frame(maxWidth: .infinity)
            .frame(height: 260)
    }
}
```

To plot your own types, map them to `ChartDataPoint`:

```swift
let points = holdings.map { ChartDataPoint(id: $0.ticker, title: $0.ticker, value: $0.returnPercent) }
```

Pass an `id` when titles can repeat. Otherwise the title is used as the identifier.

## Name conflicts

The chart type has the same name as its module, so `ContributionChart.ChartDataPoint` doesn't refer to
the module's type. If something else you use also declares `ChartDataPoint`, use a module selector
(verified with Swift 6.4):

```swift
let point = ContributionChart::ChartDataPoint(title: "VFIAX", value: 11.05)
```

On a compiler without module selectors, you can resolve a conflict between two imported modules with a
type alias, in a file that imports only this package:

```swift
import ContributionChart

typealias ContributionPoint = ChartDataPoint
```

## Versioning

The package follows [Semantic Versioning](https://semver.org):

| Change | Version | Examples |
|---|---|---|
| Breaking | Major | Removing or renaming public API, raising the minimum platform, changing a default in a way that alters existing charts significantly |
| Additive | Minor | A new configuration property with a default value, a new platform |
| Fix | Patch | A correction that doesn't change the API |

A visual fix can still change how charts look. If you compare screenshots in your own tests, expect to
re-record them when updating.

Release a version by tagging it: `git tag 1.0.0 && git push origin 1.0.0`.

## Binary distribution

The package is designed to be distributed as source, through Swift Package Manager.

Building with library evolution has been verified with Swift 6.4, whose `.swiftinterface` files use
module selectors and compile back cleanly. Earlier compilers are known to write interfaces they can't
read back when a type shares its module's name, so verify an XCFramework yourself if you need one built
with an older toolchain.

## The example app

[`Example/`](../Example/README.md) is a complete app that uses the package the way yours would, through
a local package reference.
