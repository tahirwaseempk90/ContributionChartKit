import ContributionChart
import SwiftUI

/// Screen 5: the same data in different styles, all through `ChartConfiguration`.
struct CustomStylingScreen: View {
    var body: some View {
        ExamplePage(title: ExampleScenario.customStyling.title) {
            card("Colour-blind friendly", "Blue and orange, large markers, a dashed baseline.", ocean, id: "ocean")
            card("Monochrome", "Direction comes from position and symbols alone.", monochrome, id: "monochrome")
            card("Bars", "Wide stems without markers.", bars, id: "bars")
            card("Markers only", "No stems and no baseline.", markersOnly, id: "markers")
            card("Custom formatting", "A currency formatter and no direction symbols.", currency, id: "currency")
            card("Target line", "A reference line and gridlines without labels.", target, id: "target")
            card("Labels off", "Marks only. VoiceOver still reads every point.", labelsOff, id: "labels-off")
        }
    }

    private func card(_ title: String, _ detail: String, _ configuration: ChartConfiguration, id: String) -> some View {
        ExampleCard(title: title, detail: detail) {
            ContributionChart(
                points: SampleData.mixed,
                title: id == "ocean" ? "Centred, rounded title" : nil,
                configuration: configuration.identified("chart.custom.\(id)")
            )
            .frame(height: 260)
        }
    }

    private var ocean: ChartConfiguration {
        var configuration = ChartConfiguration()
        configuration.style.positive = .init(color: Color(hex: 0x0B6BCB))
        configuration.style.negative = .init(color: Color(hex: 0xC2560C))
        configuration.style.marker.diameter = 18
        configuration.style.stem.width = 2
        configuration.style.stem.opacity = 1
        configuration.style.baseline = ChartLineStyle(color: .secondary, thickness: 2, dash: [6, 4])
        configuration.style.header = .init(
            font: .system(.title3, design: .rounded).weight(.bold),
            alignment: .center
        )
        configuration.style.annotation.titleFont = .system(.footnote, design: .rounded).weight(.bold)
        return configuration
    }

    private var monochrome: ChartConfiguration {
        var configuration = ChartConfiguration()
        configuration.style.positive = .init(color: .primary)
        configuration.style.negative = .init(markerColor: .secondary, stemColor: .secondary, valueColor: .primary)
        configuration.style.annotation.directionIndicators = .init(positive: "▲", negative: "▼")
        return configuration
    }

    private var bars: ChartConfiguration {
        var configuration = ChartConfiguration()
        configuration.style.marker.isVisible = false
        configuration.style.stem.width = 14
        configuration.style.stem.opacity = 1
        configuration.style.stem.minimumLength = 2
        return configuration
    }

    private var markersOnly: ChartConfiguration {
        var configuration = ChartConfiguration()
        configuration.style.stem.isVisible = false
        configuration.style.baseline.isVisible = false
        configuration.style.marker.diameter = 16
        return configuration
    }

    private var currency: ChartConfiguration {
        var configuration = ChartConfiguration()
        configuration.valueFormatter = ChartValueFormatter { value in
            (value * 1000).formatted(.currency(code: "USD").precision(.fractionLength(0)))
        }
        configuration.style.annotation.directionIndicators = .init(positive: nil, negative: nil)
        return configuration
    }

    private var target: ChartConfiguration {
        var configuration = ChartConfiguration()
        configuration.valueAxis = ChartValueAxis(showsLabels: false)
        configuration.referenceLines = [
            ChartReferenceLine(value: 7.5, style: ChartLineStyle(color: .purple, thickness: 2, dash: [4, 3]))
        ]
        return configuration
    }

    private var labelsOff: ChartConfiguration {
        var configuration = ChartConfiguration()
        configuration.style.annotation.isVisible = false
        return configuration
    }
}

#Preview {
    NavigationStack { CustomStylingScreen() }
}
