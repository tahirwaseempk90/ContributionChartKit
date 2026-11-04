import SwiftUI
import XCTest
@testable import ContributionChart

/// Visual regression tests. The frames are named for the devices they represent, but the
/// frames, not the devices, are what the chart responds to.
@MainActor
final class SnapshotTests: XCTestCase {
    private let dark = RenderEnvironment(colorScheme: .dark, background: Color(white: 0.08))
    private let title = "Your Biggest Contributors & Detractors"

    private enum Frame {
        static let iPhoneCompact = CGSize(width: 320, height: 240)
        static let iPhoneRegular = CGSize(width: 393, height: 300)
        static let iPhoneLandscape = CGSize(width: 852, height: 220)
        static let iPad = CGSize(width: 768, height: 400)
        static let macWindow = CGSize(width: 900, height: 420)
        static let card = CGSize(width: 350, height: 260)
        static let editorial = CGSize(width: 700, height: 380)
        static let hero = CGSize(width: 880, height: 460)
    }

    /// A fixed locale, so that the images do not depend on the machine running the tests.
    private var configuration: ChartConfiguration {
        ChartConfiguration(valueFormatter: .percent(locale: Locale(identifier: "en_US")))
    }

    // MARK: - Device-sized frames

    func testIPhoneCompact() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: title, configuration: configuration),
            named: "iphone-compact-light",
            size: Frame.iPhoneCompact
        )
    }

    func testIPhoneRegularLight() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: title, configuration: configuration),
            named: "iphone-regular-light",
            size: Frame.iPhoneRegular
        )
    }

    func testIPhoneRegularDark() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: title, configuration: configuration),
            named: "iphone-regular-dark",
            size: Frame.iPhoneRegular,
            environment: dark
        )
    }

    func testIPhoneLandscape() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: title, configuration: configuration),
            named: "iphone-landscape-light",
            size: Frame.iPhoneLandscape
        )
    }

    func testIPadLight() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: title, configuration: configuration),
            named: "ipad-light",
            size: Frame.iPad
        )
    }

    func testIPadDark() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: title, configuration: configuration),
            named: "ipad-dark",
            size: Frame.iPad,
            environment: dark
        )
    }

    func testMacWindowLight() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: title, configuration: configuration),
            named: "mac-window-light",
            size: Frame.macWindow
        )
    }

    func testMacWindowDark() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: title, configuration: configuration),
            named: "mac-window-dark",
            size: Frame.macWindow,
            environment: dark
        )
    }

    // MARK: - The two looks on the example app's first screen

    func testEditorialStyle() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.points(Fixtures.editorialValues), configuration: Fixtures.editorialConfiguration()),
            named: "editorial-light",
            size: Frame.editorial
        )
    }

    func testEditorialStyleDark() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.points(Fixtures.editorialValues), configuration: Fixtures.editorialConfiguration(dark: true)),
            named: "editorial-dark",
            size: Frame.editorial,
            environment: dark
        )
    }

    func testEditorialStyleOnAPhone() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.points(Fixtures.editorialValues), configuration: Fixtures.editorialConfiguration()),
            named: "editorial-phone",
            size: CGSize(width: 393, height: 213)
        )
    }

    func testLabelsOnYellow() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, title: title, configuration: configuration),
            named: "labels-on-yellow",
            size: Frame.card,
            environment: RenderEnvironment(background: Color(.sRGB, red: 1, green: 0.84, blue: 0.2))
        )
    }

    // MARK: - README

    /// The README's hero image comes from these snapshots, so it is always the package's real
    /// output. After recording, copy the iOS versions to `Documentation/Assets`.
    private var heroPoints: [ChartDataPoint] {
        [
            ChartDataPoint(title: "Technology", value: 12.40),
            ChartDataPoint(title: "Energy", value: -4.20),
            ChartDataPoint(title: "Healthcare", value: 7.85),
            ChartDataPoint(title: "Real Estate", value: -6.60),
            ChartDataPoint(title: "Financials", value: 5.30),
            ChartDataPoint(title: "Utilities", value: -1.75),
            ChartDataPoint(title: "Consumer", value: 9.10)
        ]
    }

    private var heroChart: some View {
        var configuration = configuration
        configuration.style.marker.diameter = 18
        configuration.style.stem.width = 6
        configuration.style.annotation.titleFont = .subheadline.weight(.semibold)
        configuration.style.annotation.valueFont = .footnote
        configuration.style.annotation.markerSpacing = 6
        configuration.style.header.font = .title2.weight(.bold)
        configuration.style.header.alignment = .center
        configuration.style.header.spacing = 20
        return ContributionChart(points: heroPoints, title: title, configuration: configuration)
            .padding(28)
    }

    func testReadmeHeroLight() throws {
        try assertSnapshot(of: heroChart, named: "readme-hero-light", size: Frame.hero)
    }

    /// The background matches GitHub's dark theme, so the image has no visible edges there.
    func testReadmeHeroDark() throws {
        let githubDark = Color(.sRGB, red: 13 / 255, green: 17 / 255, blue: 23 / 255)
        try assertSnapshot(
            of: heroChart,
            named: "readme-hero-dark",
            size: Frame.hero,
            environment: RenderEnvironment(colorScheme: .dark, background: githubDark)
        )
    }

    // MARK: - Data shapes

    func testPositiveOnly() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.points([3, 7.5, 1.2, 5.5]), configuration: configuration),
            named: "positive-only",
            size: Frame.card
        )
    }

    func testNegativeOnly() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.points([-3, -7.5, -1.2, -5.5]), configuration: configuration),
            named: "negative-only",
            size: Frame.card
        )
    }

    func testAllZero() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.points([0, 0, 0]), configuration: configuration),
            named: "all-zero",
            size: Frame.card
        )
    }

    func testSinglePoint() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.points([4.2]), configuration: configuration),
            named: "single-point",
            size: Frame.card
        )
    }

    func testVeryUnevenValues() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.points([10_000, 0.5, -3]), configuration: configuration),
            named: "very-uneven",
            size: Frame.card
        )
    }

    func testLongTitles() throws {
        let points = [
            ChartDataPoint(title: "Vanguard Total Stock Market Index Fund Admiral Shares", value: 12.5),
            ChartDataPoint(title: "International Growth & Income Opportunities", value: -7.25),
            ChartDataPoint(title: "Short", value: 3)
        ]
        try assertSnapshot(
            of: ContributionChart(points: points, configuration: configuration),
            named: "long-titles",
            size: Frame.card
        )
    }

    func testEmptyState() throws {
        try assertSnapshot(
            of: ContributionChart(points: [], title: title),
            named: "empty-state",
            size: Frame.card
        )
    }

    // MARK: - Dense data

    func testDense100() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.dense(100), configuration: configuration),
            named: "dense-100-light",
            size: Frame.iPhoneRegular
        )
    }

    func testDense100Dark() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.dense(100), configuration: configuration),
            named: "dense-100-dark",
            size: Frame.iPhoneRegular,
            environment: dark
        )
    }

    func testDense500OnIPad() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.dense(500), configuration: configuration),
            named: "dense-500-ipad",
            size: Frame.iPad
        )
    }

    func testDense1000() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.dense(1000), configuration: configuration),
            named: "dense-1000-light",
            size: Frame.iPhoneRegular
        )
    }

    // MARK: - Constrained frames

    func testShortHeightDropsLabels() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, title: title, configuration: configuration),
            named: "short-height",
            size: CGSize(width: 350, height: 90)
        )
    }

    func testVeryShortHeightKeepsOnlyMarks() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, title: title, configuration: configuration),
            named: "very-short-height",
            size: CGSize(width: 350, height: 44)
        )
    }

    func testNarrowWidth() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, configuration: configuration),
            named: "narrow-width",
            size: CGSize(width: 120, height: 220)
        )
    }

    func testWatchSizedFrame() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, configuration: configuration),
            named: "watch-frame",
            size: CGSize(width: 184, height: 150)
        )
    }

    func testWatchSizedFrameWithManyPoints() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, configuration: configuration),
            named: "watch-frame-mixed",
            size: CGSize(width: 184, height: 150)
        )
    }

    func testTinyFrame() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, title: title, configuration: configuration),
            named: "tiny-frame",
            size: CGSize(width: 44, height: 44)
        )
    }

    // MARK: - Configuration

    func testRightToLeftHebrew() throws {
        var configuration = ChartConfiguration(valueFormatter: .percent(locale: Locale(identifier: "he_IL")))
        configuration.valueAxis = ChartValueAxis(labelFormatter: .number(locale: Locale(identifier: "he_IL")))
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, title: title, configuration: configuration),
            named: "right-to-left",
            size: Frame.card,
            environment: RenderEnvironment(layoutDirection: .rightToLeft)
        )
    }

    func testSymmetricScale() throws {
        var configuration = configuration
        configuration.scale = .symmetric
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, configuration: configuration),
            named: "symmetric-scale",
            size: Frame.card
        )
    }

    func testValueAxis() throws {
        var configuration = configuration
        configuration.valueAxis = ChartValueAxis(labelFormatter: .number(locale: Locale(identifier: "en_US")))
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, configuration: configuration),
            named: "value-axis",
            size: Frame.iPhoneRegular
        )
    }

    func testCustomStyle() throws {
        var configuration = configuration
        configuration.style.positive = .init(color: Color(.sRGB, red: 0.04, green: 0.42, blue: 0.8))
        configuration.style.negative = .init(color: Color(.sRGB, red: 0.76, green: 0.34, blue: 0.05))
        configuration.style.marker.diameter = 18
        configuration.style.stem.width = 2
        configuration.style.stem.opacity = 1
        configuration.style.baseline = ChartLineStyle(color: .gray, thickness: 2, dash: [6, 4])
        configuration.style.header = .init(font: .title3.weight(.bold), alignment: .center)
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, title: "Centred title", configuration: configuration),
            named: "custom-style",
            size: Frame.iPhoneRegular
        )
    }

    func testBars() throws {
        var configuration = configuration
        configuration.style.marker.isVisible = false
        configuration.style.stem.width = 14
        configuration.style.stem.opacity = 1
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, configuration: configuration),
            named: "bars",
            size: Frame.iPhoneRegular
        )
    }

    func testMarkersOnly() throws {
        var configuration = configuration
        configuration.style.stem.isVisible = false
        configuration.style.baseline.isVisible = false
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.mixed, configuration: configuration),
            named: "markers-only",
            size: Frame.iPhoneRegular
        )
    }

    // MARK: - Dynamic Type

    func testLargestAccessibilityTextInAFixedFrame() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, title: title, configuration: configuration),
            named: "dynamic-type-fixed-frame",
            size: Frame.iPhoneRegular,
            environment: RenderEnvironment(dynamicTypeSize: .accessibility5)
        )
    }

    func testAccessibilityTextWithRoomToGrow() throws {
        try assertSnapshot(
            of: ContributionChart(points: Fixtures.contributors, title: title, configuration: configuration),
            named: "dynamic-type-tall-frame",
            size: CGSize(width: 393, height: 620),
            environment: RenderEnvironment(dynamicTypeSize: .accessibility3)
        )
    }
}
