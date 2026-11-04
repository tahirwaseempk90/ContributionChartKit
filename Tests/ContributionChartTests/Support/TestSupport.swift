import SwiftUI
import XCTest
@testable import ContributionChart

/// Fixed text sizes, so that layout can be verified without rendering any text.
struct StubMeasurer: ChartElementMeasuring {
    var header = CGSize(width: 200, height: 20)
    var annotation = CGSize(width: 50, height: 30)
    var annotationOverrides: [Int: CGSize] = [:]
    var tickLabel = CGSize(width: 20, height: 12)

    func headerSize(proposedWidth: CGFloat) -> CGSize {
        CGSize(width: min(header.width, proposedWidth), height: header.height)
    }

    func annotationSize(at index: Int, proposedWidth: CGFloat) -> CGSize {
        let size = annotationOverrides[index] ?? annotation
        return CGSize(width: min(size.width, proposedWidth), height: size.height)
    }

    func tickLabelSize(at index: Int) -> CGSize {
        tickLabel
    }
}

enum Fixtures {
    static let contributors = [
        ChartDataPoint(title: "VFIAX", value: 11.05),
        ChartDataPoint(title: "VTNIX", value: 6.31),
        ChartDataPoint(title: "VTSAX", value: -2.70)
    ]

    static let mixed = [
        ChartDataPoint(title: "Alpha", value: 8.4),
        ChartDataPoint(title: "Bravo", value: -3.2),
        ChartDataPoint(title: "Charlie", value: 5.1),
        ChartDataPoint(title: "Delta", value: -6.8),
        ChartDataPoint(title: "Echo", value: 2.2),
        ChartDataPoint(title: "Foxtrot", value: -1.1),
        ChartDataPoint(title: "Golf", value: 9.7),
        ChartDataPoint(title: "Hotel", value: -4.4)
    ]

    static func points(_ values: [Double]) -> [ChartDataPoint] {
        values.enumerated().map { ChartDataPoint(id: "p\($0.offset)", title: "P\($0.offset)", value: $0.element) }
    }

    static func dense(_ count: Int) -> [ChartDataPoint] {
        // Separate steps, because older compilers time out type-checking this as one expression.
        let values: [Double] = (0..<count).map { index in
            let position = Double(index)
            let fast: Double = sin(position * 0.7) * 10
            let slow: Double = cos(position * 0.13) * 6
            return fast + slow
        }
        return points(values)
    }

    /// The values behind the editorial look on the example app's first screen.
    static let editorialValues: [Double] = [
        17.5, 9.7, 13.7, 17.9, 1.3, -6.5, -1.2, -9.9, -12.6, 23.2,
        18.2, 12.3, 17.4, -8.1, -3.2, 5.7, -4.1, 5.0, 10.3, -1.9,
        -4.7, -10.5, -8.6, -18.1, -11.8, -2.4, -6.5, -8.5, -2.8, -12.5
    ]

    /// The editorial look, through the public API. Tests cannot import the example app, so
    /// the values of its `editorial` configuration are repeated here.
    static func editorialConfiguration(dark: Bool = false) -> ChartConfiguration {
        func color(_ hex: UInt32) -> Color {
            ChartPalette.Swatch(hex: hex).color
        }
        var configuration = ChartConfiguration()
        configuration.valueFormatter = .number(fractionDigits: 0...1, locale: Locale(identifier: "en_US"))
        configuration.layout.pointDistribution = .edgeToEdge
        configuration.layout.insets = EdgeInsets(top: 2, leading: 0, bottom: 19, trailing: 2)
        let ink = dark ? color(0xF2F2F2) : .black
        configuration.style.positive = .init(markerColor: ink, stemColor: color(dark ? 0x4A4E52 : 0xE1E4E7), valueColor: ink)
        configuration.style.negative = .init(markerColor: color(dark ? 0xE5484D : 0xCD3238), stemColor: color(dark ? 0x6B3A2E : 0xFAD7CA), valueColor: ink)
        configuration.style.marker = .init(diameter: 11, minimumDiameter: 2, maximumSpacingFraction: 0.5)
        configuration.style.stem = .init(width: 5, opacity: 1, minimumLength: 0)
        configuration.style.annotation.isVisible = false
        configuration.style.baseline = ChartLineStyle(color: color(dark ? 0xD0D0D0 : 0x353431))
        configuration.valueAxis = ChartValueAxis(
            desiredTickCount: 6,
            gridline: ChartLineStyle(color: color(dark ? 0x3A3A3C : 0xE6E6E6)),
            labelFont: Font.system(size: 12.5, weight: .thin).width(.condensed),
            labelColor: color(dark ? 0xE5E5E5 : 0x1A1A1A),
            labelFormatter: ChartValueFormatter { "\(Int($0))".replacingOccurrences(of: "-", with: "\u{2212}") },
            labelSpacing: 0.5,
            labelTrailingSpacing: 4
        )
        configuration.regions = [ChartRegion(points: 19...29, color: color(dark ? 0x26272A : 0xEEEFF1))]
        let dotted = ChartLineStyle(color: color(dark ? 0x8E8E5F : 0xB3B37F), thickness: 3.5, dash: [2.75, 2.1])
        configuration.referenceLines = [
            ChartReferenceLine(value: 5.18, points: 0...19, style: dotted),
            ChartReferenceLine(value: -8.76, points: 19...29, style: dotted)
        ]
        configuration.categoryTicks = ChartCategoryTicks(
            points: [9, 19],
            length: 5,
            style: ChartLineStyle(color: color(dark ? 0xD0D0D0 : 0x323232))
        )
        return configuration
    }
}

func makeEngine(
    _ points: [ChartDataPoint],
    title: String? = nil,
    configuration: ChartConfiguration = ChartConfiguration(),
    displayScale: CGFloat = 2
) -> ChartLayoutEngine {
    ChartLayoutEngine(
        model: ChartModel(points: points, title: title, configuration: configuration),
        displayScale: displayScale
    )
}

/// A deterministic generator, so a failing fuzz case can be reproduced from its seed.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var result = state
        result = (result ^ (result >> 30)) &* 0xBF58476D1CE4E5B9
        result = (result ^ (result >> 27)) &* 0x94D049BB133111EB
        return result ^ (result >> 31)
    }
}

extension CGRect {
    var isFiniteRect: Bool {
        minX.isFinite && minY.isFinite && width.isFinite && height.isFinite
    }
}

/// Asserts the guarantees the layout engine makes for any input: every coordinate is finite,
/// and everything drawn stays inside the chart's bounds.
func assertGeometryIsValid(
    _ result: ChartLayoutResult,
    context: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let tolerance: CGFloat = 0.51
    let bounds = result.bounds.insetBy(dx: -tolerance, dy: -tolerance)

    func check(_ rect: CGRect, _ name: String) {
        XCTAssertTrue(rect.isFiniteRect, "\(name) is not finite: \(rect). \(context())", file: file, line: line)
        guard !rect.isEmpty else { return }
        XCTAssertTrue(
            bounds.contains(rect),
            "\(name) \(rect) escapes bounds \(result.bounds). \(context())",
            file: file,
            line: line
        )
    }

    check(result.headerFrame, "header")
    check(result.marksFrame, "marks")
    check(result.baselineFrame, "baseline")
    check(result.summaryFrame, "summary")
    result.marks.forEach { mark in
        check(mark.markerFrame, "marker \(mark.position)")
        if let stem = mark.stem { check(stem, "stem \(mark.position)") }
    }
    result.annotations.filter(\.isVisible).forEach { check($0.frame, "annotation \($0.index)") }
    result.gridlineFrames.forEach { check($0, "gridline") }
    result.tickLabelFrames.forEach { check($0, "tick label") }
    result.referenceLineFrames.forEach { check($0, "reference line") }
    result.regionFrames.forEach { check($0, "region") }
    result.categoryTickFrames.forEach { check($0, "category tick") }
    result.pointFrames.forEach { check($0, "point") }
}
