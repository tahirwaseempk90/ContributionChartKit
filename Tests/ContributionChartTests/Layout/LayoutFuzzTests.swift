import SwiftUI
import XCTest
@testable import ContributionChart

/// Throws hostile input at the whole pipeline. The promise under test is the one made in the
/// brief: invalid numbers must never reach SwiftUI as invalid geometry.
final class LayoutFuzzTests: XCTestCase {
    private let hostileValues: [Double] = [
        0, -0.0, 1, -1, 2.5, -2.5, 11.05, -2.70,
        1e-320, -1e-320, 1e-300, -1e-300, 1e-9, -1e-9,
        1e9, -1e9, 1e300, -1e300,
        .leastNonzeroMagnitude, -.leastNonzeroMagnitude,
        .greatestFiniteMagnitude, -.greatestFiniteMagnitude,
        .nan, .infinity, -.infinity
    ]

    private let hostileLengths: [CGFloat] = [0, 0.5, 1, 7.3, 44, 100, 320, 1000, -3, .nan, .infinity]
    private let sizes: [CGFloat] = [0, 0.5, 1, 3, 10, 31, 44, 100, 199.7, 320, 768, 1366, 5000]
    private let counts = [0, 1, 2, 3, 5, 10, 30, 101, 500]
    private let distributions: [ChartLayoutOptions.PointDistribution] = [.slots, .edgeToEdge]
    private let displayScales: [CGFloat] = [1, 2, 3]

    private func configuration(using random: inout SplitMix64) -> ChartConfiguration {
        var configuration = ChartConfiguration()
        let modes: [ChartScaleMode] = [
            .proportional, .symmetric, .fixed(lower: -10, upper: 10),
            .fixed(lower: .nan, upper: 1), .fixed(lower: 5, upper: 5), .fixed(lower: 100, upper: -100)
        ]
        configuration.scale = modes.randomElement(using: &random) ?? .proportional
        configuration.layout.pointDistribution = distributions.randomElement(using: &random) ?? .slots
        configuration.style.marker.isVisible = Bool.random(using: &random)
        configuration.style.stem.isVisible = Bool.random(using: &random)
        configuration.style.baseline.isVisible = Bool.random(using: &random)
        configuration.style.annotation.isVisible = Bool.random(using: &random)
        configuration.style.marker.diameter = hostileLengths.randomElement(using: &random) ?? 0
        configuration.style.stem.width = hostileLengths.randomElement(using: &random) ?? 0
        configuration.style.stem.minimumLength = hostileLengths.randomElement(using: &random) ?? 0
        configuration.style.baseline.thickness = hostileLengths.randomElement(using: &random) ?? 0
        configuration.layout.minimumPlotHeight = hostileLengths.randomElement(using: &random) ?? 0
        let inset = hostileLengths.randomElement(using: &random) ?? 0
        configuration.layout.insets = EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
        addDecorations(to: &configuration, using: &random)
        return configuration
    }

    private func addDecorations(to configuration: inout ChartConfiguration, using random: inout SplitMix64) {
        if Bool.random(using: &random) {
            let counts = [Int.min, -1, 0, 1, 2, 6, 30, 1000, Int.max]
            configuration.valueAxis = ChartValueAxis(desiredTickCount: counts.randomElement(using: &random) ?? 6)
        }
        if Bool.random(using: &random) {
            configuration.categoryTicks = ChartCategoryTicks(
                points: [0, 1, 99],
                length: hostileLengths.randomElement(using: &random) ?? 0
            )
            configuration.regions = [ChartRegion(points: 0...1, color: .gray), ChartRegion(points: 2...600, color: .gray)]
            configuration.referenceLines = [
                ChartReferenceLine(value: hostileValues.randomElement(using: &random) ?? 0, style: ChartLineStyle(color: .red)),
                ChartReferenceLine(value: 1, points: 1...3, style: ChartLineStyle(color: .red))
            ]
        }
    }

    private func measurer(using random: inout SplitMix64) -> StubMeasurer {
        var measurer = StubMeasurer()
        measurer.annotation = CGSize(
            width: hostileLengths.randomElement(using: &random) ?? 0,
            height: hostileLengths.randomElement(using: &random) ?? 0
        )
        measurer.tickLabel = CGSize(
            width: hostileLengths.randomElement(using: &random) ?? 0,
            height: hostileLengths.randomElement(using: &random) ?? 0
        )
        measurer.header = CGSize(width: 100, height: hostileLengths.randomElement(using: &random) ?? 0)
        return measurer
    }

    func testHostileInputNeverProducesInvalidGeometry() {
        let iterations = 4000
        for seed in 0..<iterations {
            var random = SplitMix64(seed: UInt64(seed))
            let count = counts.randomElement(using: &random) ?? 0
            let values = (0..<count).map { _ in hostileValues.randomElement(using: &random) ?? 0 }
            let configuration = configuration(using: &random)
            let size = CGSize(
                width: sizes.randomElement(using: &random) ?? 0,
                height: sizes.randomElement(using: &random) ?? 0
            )
            let engine = makeEngine(
                Fixtures.points(values),
                title: Bool.random(using: &random) ? "Title" : nil,
                configuration: configuration,
                displayScale: displayScales.randomElement(using: &random) ?? 1
            )
            let result = engine.layout(in: size, measuring: measurer(using: &random))
            assertGeometryIsValid(result, context: "seed \(seed), size \(size), values \(values)")
        }
    }

    func testIdealSizeIsAlwaysFiniteAndNonNegative() {
        for seed in 0..<500 {
            var random = SplitMix64(seed: UInt64(seed) &+ 100_000)
            let count = counts.randomElement(using: &random) ?? 0
            let values = (0..<count).map { _ in hostileValues.randomElement(using: &random) ?? 0 }
            let size = makeEngine(
                Fixtures.points(values),
                title: Bool.random(using: &random) ? "Title" : nil,
                configuration: configuration(using: &random)
            )
            .size(for: .unspecified, measuring: measurer(using: &random))
            XCTAssertTrue(size.width.isFinite && size.width >= 0, "seed \(seed): \(size)")
            XCTAssertTrue(size.height.isFinite && size.height >= 0, "seed \(seed): \(size)")
        }
    }
}
