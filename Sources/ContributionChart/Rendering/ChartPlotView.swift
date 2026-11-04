import SwiftUI

/// Declares the chart's elements in drawing order, leaving their positions to the layout.
struct ChartPlotView: View {
    let model: ChartModel

    @Environment(\.displayScale) private var displayScale

    private var configuration: ChartConfiguration { model.configuration }
    private var engine: ChartLayoutEngine { ChartLayoutEngine(model: model, displayScale: displayScale) }

    var body: some View {
        ChartContainerLayout(engine: engine) {
            backgroundLayer
            marksLayer
            textLayer
            ChartPlotAccessibility(model: model)
        }
        // The canvas redraws instantly, so animating the views around it would pull them out
        // of step with the marks. This applies only when the marks change, so that animations
        // elsewhere, such as a parent resizing, are left alone.
        .animation(nil, value: engine.geometry)
    }

    /// Regions, gridlines, the baseline, and category ticks all sit below the marks.
    @ViewBuilder private var backgroundLayer: some View {
        ForEach(model.regions.indices, id: \.self) { index in
            Rectangle()
                .fill(model.regions[index].color)
                .accessibilityHidden(true)
                .chartRole(.region(index))
        }
        if let gridline = configuration.valueAxis?.gridline, gridline.isVisible {
            ForEach(model.ticks.indices, id: \.self) { index in
                ChartLineView(style: gridline).chartRole(.gridline(index))
            }
        }
        if configuration.style.baseline.isVisible {
            ChartLineView(style: configuration.style.baseline).chartRole(.baseline)
        }
        if let ticks = configuration.categoryTicks, ticks.style.isVisible {
            ForEach(model.categoryTickPositions.indices, id: \.self) { index in
                ChartLineView(style: ticks.style).chartRole(.categoryTick(index))
            }
        }
    }

    /// Reference lines go above the marks so a line crossing a marker stays visible.
    @ViewBuilder private var marksLayer: some View {
        ChartMarksCanvas(geometry: engine.geometry, style: configuration.style)
            .chartRole(.marks)

        ForEach(model.referenceLines.indices, id: \.self) { index in
            ChartLineView(style: model.referenceLines[index].style).chartRole(.referenceLine(index))
        }
    }

    @ViewBuilder private var textLayer: some View {
        if let title = model.title {
            // Hidden from VoiceOver because the summary element announces the title as the
            // chart's heading. That also keeps it announced when the title is dropped for space.
            ChartHeader(title: title, style: configuration.style.header)
                .accessibilityHidden(true)
                .collapsible()
                .chartRole(.header)
        }
        if let axis = configuration.valueAxis, axis.showsLabels {
            ForEach(model.ticks.indices, id: \.self) { index in
                ChartTickLabel(text: model.ticks[index].label, axis: axis)
                    .collapsible()
                    .chartRole(.tickLabel(index))
            }
        }
        if configuration.style.annotation.isVisible {
            ForEach(model.prominentPoints.indices, id: \.self) { index in
                ChartAnnotation(
                    point: model.prominentPoints[index],
                    style: configuration.style.annotation,
                    valueColor: configuration.style.colors(for: model.prominentPoints[index].polarity).valueColor
                )
                .collapsible()
                .chartRole(.annotation(index))
            }
        }
    }
}
