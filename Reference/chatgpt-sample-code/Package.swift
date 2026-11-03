// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ContributionChart",
    platforms: [
        .iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)
    ],
    products: [
        .library(name: "ContributionChart", targets: ["ContributionChart"])
    ],
    targets: [
        .target(name: "ContributionChart"),
        .testTarget(name: "ContributionChartTests", dependencies: ["ContributionChart"])
    ],
    swiftLanguageModes: [.v6]
)
