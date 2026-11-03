import SwiftUI
import XCTest
@testable import ContributionChart

final class ChartConfigurationTests: XCTestCase {
    func testDefaultConfiguration() {
        let configuration = ChartConfiguration()
        XCTAssertEqual(configuration.scale, .proportional)
        XCTAssertEqual(configuration.layout.pointDistribution, .slots)
        XCTAssertNil(configuration.valueAxis)
        XCTAssertNil(configuration.categoryTicks)
        XCTAssertTrue(configuration.referenceLines.isEmpty)
        XCTAssertTrue(configuration.regions.isEmpty)
        XCTAssertEqual(configuration.accessibility.identifier, "contribution-chart")
        XCTAssertTrue(configuration.accessibility.isAudioGraphEnabled)
    }

    func testDefaultStyleShowsEveryElement() {
        let style = ChartStyle()
        XCTAssertTrue(style.marker.isVisible)
        XCTAssertTrue(style.stem.isVisible)
        XCTAssertTrue(style.baseline.isVisible)
        XCTAssertTrue(style.annotation.isVisible)
    }

    func testCustomConfigurationIsPreserved() {
        var style = ChartStyle()
        style.marker.diameter = 30
        let configuration = ChartConfiguration(
            scale: .symmetric,
            style: style,
            layout: ChartLayoutOptions(pointDistribution: .edgeToEdge),
            valueAxis: ChartValueAxis(desiredTickCount: 3),
            categoryTicks: ChartCategoryTicks(points: [1])
        )
        XCTAssertEqual(configuration.scale, .symmetric)
        XCTAssertEqual(configuration.style.marker.diameter, 30)
        XCTAssertEqual(configuration.layout.pointDistribution, .edgeToEdge)
        XCTAssertEqual(configuration.valueAxis?.desiredTickCount, 3)
        XCTAssertEqual(configuration.categoryTicks?.points, [1])
    }

    func testPolarityStyleConvenienceUsesOneColour() {
        let style = ChartStyle.PolarityStyle(color: .blue)
        XCTAssertEqual(style.markerColor, .blue)
        XCTAssertEqual(style.stemColor, .blue)
        XCTAssertEqual(style.valueColor, .blue)
    }

    func testStyleReturnsColorsForEachPolarity() {
        var style = ChartStyle()
        style.positive = .init(color: .blue)
        style.negative = .init(color: .orange)
        style.zero = .init(color: .gray)
        XCTAssertEqual(style.colors(for: .positive).markerColor, .blue)
        XCTAssertEqual(style.colors(for: .negative).markerColor, .orange)
        XCTAssertEqual(style.colors(for: .zero).markerColor, .gray)
    }

    // MARK: - Invalid values

    func testValidValuesPassThroughUnchanged() {
        var configuration = ChartConfiguration()
        configuration.style.marker.diameter = 20
        configuration.style.stem.width = 7
        configuration.style.baseline.thickness = 3
        configuration.layout.insets = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        let metrics = ChartMetrics(configuration)
        XCTAssertEqual(metrics.markerDiameter, 20)
        XCTAssertEqual(metrics.markExtent(width: 200, count: 2), 10)
        XCTAssertEqual(metrics.stemWidth, 7)
        XCTAssertEqual(metrics.baselineThickness, 3)
        XCTAssertEqual(metrics.horizontalInsets, 6)
        XCTAssertEqual(metrics.verticalInsets, 4)
    }

    func testMarkExtentAllowsForAStemWiderThanTheMarker() {
        var configuration = ChartConfiguration()
        configuration.style.marker.diameter = 4
        configuration.style.stem.width = 10
        XCTAssertEqual(ChartMetrics(configuration).markExtent(width: 200, count: 2), 5)
    }

    func testMarkExtentIgnoresStemWidthThatTheSpacingWillNotAllow() {
        var configuration = ChartConfiguration()
        configuration.style.marker.diameter = 2
        configuration.style.stem.width = 300
        let metrics = ChartMetrics(configuration)
        XCTAssertEqual(metrics.markExtent(width: 100, count: 10), 5)
        XCTAssertEqual(metrics.markExtent(width: 100, count: 0), 150)
    }

    func testBoundaryValuesAreAccepted() {
        var configuration = ChartConfiguration()
        configuration.style.marker.diameter = 0
        configuration.style.marker.maximumSpacingFraction = 1
        configuration.layout.minimumPlotHeight = 0
        let metrics = ChartMetrics(configuration)
        XCTAssertEqual(metrics.markerDiameter, 0)
        XCTAssertEqual(metrics.markerSpacingFraction, 1)
        XCTAssertEqual(metrics.minimumPlotHeight, 0)
    }

    func testNegativeAndNonFiniteLengthsFallBackToDefaults() {
        for invalid in [CGFloat(-1), .nan, .infinity, -.infinity] {
            var configuration = ChartConfiguration()
            configuration.style.marker.diameter = invalid
            configuration.style.marker.minimumDiameter = invalid
            configuration.style.stem.width = invalid
            configuration.style.stem.minimumLength = invalid
            configuration.style.baseline.thickness = invalid
            configuration.style.header.spacing = invalid
            configuration.style.annotation.markerSpacing = invalid
            configuration.style.annotation.minimumWidth = invalid
            configuration.style.annotation.collisionPadding = invalid
            configuration.layout.idealWidth = invalid
            configuration.layout.idealPlotHeight = invalid
            configuration.layout.minimumPointSpacing = invalid
            configuration.layout.minimumPlotHeight = invalid

            let metrics = ChartMetrics(configuration)
            let defaults = ChartMetrics(ChartConfiguration())
            XCTAssertEqual(metrics.markerDiameter, defaults.markerDiameter, "\(invalid)")
            XCTAssertEqual(metrics.minimumMarkerDiameter, defaults.minimumMarkerDiameter, "\(invalid)")
            XCTAssertEqual(metrics.stemWidth, defaults.stemWidth, "\(invalid)")
            XCTAssertEqual(metrics.minimumStemLength, defaults.minimumStemLength, "\(invalid)")
            XCTAssertEqual(metrics.baselineThickness, 1, "\(invalid)")
            XCTAssertEqual(metrics.headerSpacing, defaults.headerSpacing, "\(invalid)")
            XCTAssertEqual(metrics.annotationMarkerSpacing, defaults.annotationMarkerSpacing, "\(invalid)")
            XCTAssertEqual(metrics.annotationMinimumWidth, defaults.annotationMinimumWidth, "\(invalid)")
            XCTAssertEqual(metrics.annotationCollisionPadding, defaults.annotationCollisionPadding, "\(invalid)")
            XCTAssertEqual(metrics.idealWidth, defaults.idealWidth, "\(invalid)")
            XCTAssertEqual(metrics.idealPlotHeight, defaults.idealPlotHeight, "\(invalid)")
            XCTAssertEqual(metrics.minimumPointSpacing, defaults.minimumPointSpacing, "\(invalid)")
            XCTAssertEqual(metrics.minimumPlotHeight, defaults.minimumPlotHeight, "\(invalid)")
        }
    }

    func testInvalidInsetsBecomeZero() {
        var configuration = ChartConfiguration()
        configuration.layout.insets = EdgeInsets(top: -5, leading: .nan, bottom: .infinity, trailing: -.infinity)
        let metrics = ChartMetrics(configuration)
        XCTAssertEqual(metrics.horizontalInsets, 0)
        XCTAssertEqual(metrics.verticalInsets, 0)
    }

    func testSpacingFractionOutsideTheUnitRangeFallsBack() {
        for invalid in [CGFloat(-0.1), 1.1, .nan, .infinity] {
            var configuration = ChartConfiguration()
            configuration.style.marker.maximumSpacingFraction = invalid
            XCTAssertEqual(
                ChartMetrics(configuration).markerSpacingFraction,
                ChartStyle.MarkerStyle().maximumSpacingFraction,
                "\(invalid)"
            )
        }
    }

    func testHiddenElementsTakeNoSpace() {
        var configuration = ChartConfiguration()
        configuration.style.marker.isVisible = false
        configuration.style.stem.isVisible = false
        configuration.style.baseline.isVisible = false
        configuration.style.annotation.isVisible = false
        configuration.valueAxis = ChartValueAxis(gridline: ChartLineStyle(isVisible: false, color: .red))
        configuration.categoryTicks = ChartCategoryTicks(points: [0], style: ChartLineStyle(isVisible: false, color: .red))
        let metrics = ChartMetrics(configuration)
        XCTAssertEqual(metrics.markerDiameter, 0)
        XCTAssertEqual(metrics.stemWidth, 0)
        XCTAssertEqual(metrics.baselineThickness, 0)
        XCTAssertFalse(metrics.showsAnnotations)
        XCTAssertEqual(metrics.gridlineThickness, 0)
        XCTAssertEqual(metrics.categoryTickThickness, 0)
        XCTAssertEqual(metrics.categoryTickLength, 0)
    }

    func testMissingAxisAndTicksTakeNoSpace() {
        let metrics = ChartMetrics(ChartConfiguration())
        XCTAssertEqual(metrics.gridlineThickness, 0)
        XCTAssertEqual(metrics.axisLabelSpacing, 0)
        XCTAssertEqual(metrics.axisLabelTrailingSpacing, 0)
        XCTAssertEqual(metrics.categoryTickLength, 0)
        XCTAssertEqual(metrics.categoryTickThickness, 0)
    }
}

/// The defaults must stay readable on any background the consuming app chooses.
final class ChartPaletteTests: XCTestCase {
    private func linear(_ channel: Double) -> Double {
        channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }

    private func luminance(_ swatch: ChartPalette.Swatch) -> Double {
        0.2126 * linear(swatch.red) + 0.7152 * linear(swatch.green) + 0.0722 * linear(swatch.blue)
    }

    private func contrast(_ first: Double, _ second: Double) -> Double {
        (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }

    func testDefaultColoursMeetTextContrastOnBothWhiteAndBlack() {
        let minimumTextContrast = 4.5
        let swatches = [ChartPalette.positive, ChartPalette.negative, ChartPalette.neutral]
        for swatch in swatches {
            let value = luminance(swatch)
            XCTAssertGreaterThanOrEqual(contrast(value, 1), minimumTextContrast, "on white: \(swatch)")
            XCTAssertGreaterThanOrEqual(contrast(value, 0), minimumTextContrast, "on black: \(swatch)")
        }
    }

    func testPositiveAndNegativeDiffer() {
        XCTAssertNotEqual(ChartPalette.positive, ChartPalette.negative)
        XCTAssertGreaterThan(ChartPalette.positive.green, ChartPalette.positive.red)
        XCTAssertGreaterThan(ChartPalette.negative.red, ChartPalette.negative.green)
    }

    func testSwatchDecodesHex() {
        let swatch = ChartPalette.Swatch(hex: 0x336699)
        XCTAssertEqual(swatch.red, 0.2, accuracy: 0.001)
        XCTAssertEqual(swatch.green, 0.4, accuracy: 0.001)
        XCTAssertEqual(swatch.blue, 0.6, accuracy: 0.001)
    }
}
