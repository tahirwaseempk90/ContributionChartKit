// swift-tools-version: 6.0
import PackageDescription

// Minimum versions come from the `Layout` protocol (iOS 16 / macOS 13 / tvOS 16 / watchOS 9),
// which the chart uses to measure labels and negotiate its size without a GeometryReader.
let package = Package(
    name: "ContributionChart",
    platforms: [
        .iOS(.v16),
        .macCatalyst(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "ContributionChart", targets: ["ContributionChart"])
    ],
    targets: [
        .target(name: "ContributionChart"),
        .testTarget(
            name: "ContributionChartTests",
            dependencies: ["ContributionChart"],
            exclude: ["__Snapshots__"]
        )
    ],
    swiftLanguageModes: [.v6]
)
