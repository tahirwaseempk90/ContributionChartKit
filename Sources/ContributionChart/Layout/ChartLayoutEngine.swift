import SwiftUI

/// Measures the text elements of a chart. SwiftUI subviews provide the real answers in the
/// app, while tests inject fixed sizes so that layout can be verified without rendering.
protocol ChartElementMeasuring {
    func headerSize(proposedWidth: CGFloat) -> CGSize
    func annotationSize(at index: Int, proposedWidth: CGFloat) -> CGSize
    func tickLabelSize(at index: Int) -> CGSize
}

/// Turns a size into a position for every chart element. Pure and deterministic.
///
/// The steps run in dependency order:
/// 1. Horizontal space, which depends only on the width and sets how wide labels can be.
/// 2. Text measurement at those widths.
/// 3. Vertical space, dropping optional elements if the height cannot fit them.
/// 4. Marks, from the resulting plot area.
/// 5. Everything positioned relative to the marks.
struct ChartLayoutEngine: Sendable {
    /// The widest canvas to ask for, in pixels. This is the usual GPU texture limit, so a dense
    /// chart in a horizontal scroll view can't ask for a canvas too large to draw. Only the ideal
    /// width is limited; a parent can still offer more.
    static let maximumIdealPixelWidth: CGFloat = 16384

    let model: ChartModel
    let displayScale: CGFloat

    private var metrics: ChartMetrics { model.metrics }
    var grid: PixelGrid { PixelGrid(scale: displayScale) }

    var geometry: ChartGeometryCalculator {
        ChartGeometryCalculator(
            values: model.values,
            scale: model.scale,
            metrics: metrics,
            grid: grid
        )
    }

    // MARK: - Size negotiation

    /// The chart's size for a parent's proposal. Dimensions the parent specifies are honoured,
    /// including infinity, which is how a parent asks for the most a view can take. Open
    /// dimensions use the ideal size.
    func size(for proposal: ProposedViewSize, measuring measurer: some ChartElementMeasuring) -> CGSize {
        let width = proposal.width.map(Self.sanitizedProposal) ?? idealWidth(measuring: measurer)
        let widthForText = width.isFinite ? width : metrics.idealWidth
        let height = proposal.height.map(Self.sanitizedProposal)
            ?? idealHeight(forWidth: widthForText, measuring: measurer)
        return CGSize(width: width, height: height)
    }

    private static func sanitizedProposal(_ dimension: CGFloat) -> CGFloat {
        dimension.isNaN ? 0 : max(dimension, 0)
    }

    private func idealWidth(measuring measurer: some ChartElementMeasuring) -> CGFloat {
        let tickSizes = measureTickLabels(measurer)
        let pointsWidth = CGFloat(model.dataset.count) * metrics.minimumPointSpacing
        let wanted = metrics.horizontalInsets
            + axisZoneWidth(tickSizes: tickSizes, contentWidth: .greatestFiniteMagnitude)
            + metrics.markerDiameter
            + pointsWidth
        return min(max(metrics.idealWidth, wanted), Self.maximumIdealPixelWidth / grid.scale)
    }

    private func idealHeight(forWidth width: CGFloat, measuring measurer: some ChartElementMeasuring) -> CGFloat {
        let contentWidth = max(width - metrics.horizontalInsets, 0)
        let elements = measuredElements(contentWidth: contentWidth, measuring: measurer)
        let plan = ChartVerticalPlan(
            contentSize: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            elements: elements,
            metrics: metrics,
            options: .all
        )
        // At least the minimum, or the chart's own ideal size would cost it its labels.
        let plotHeight = max(metrics.idealPlotHeight, metrics.minimumPlotHeight)
        let plotBlock = plan.topReserve + plotHeight + plan.bottomReserve
        return metrics.verticalInsets + plan.headerBlock + plotBlock
    }

    // MARK: - Layout

    func layout(in size: CGSize, measuring measurer: some ChartElementMeasuring) -> ChartLayoutResult {
        let bounds = CGRect(
            origin: .zero,
            size: CGSize(width: size.width.sanitizedLength(), height: size.height.sanitizedLength())
        )
        let content = contentFrame(in: bounds)
        guard content.width > 0, content.height > 0, !model.dataset.isEmpty else {
            return ChartLayoutResult(bounds: bounds)
        }
        let elements = measuredElements(contentWidth: content.width, measuring: measurer)
        let plan = ChartVerticalPlan.best(contentSize: content.size, elements: elements, metrics: metrics)
        return ChartLayoutAssembler(engine: self, bounds: bounds, content: content, elements: elements, plan: plan)
            .assemble()
    }

    private func contentFrame(in bounds: CGRect) -> CGRect {
        CGRect(
            x: metrics.insets.leading,
            y: metrics.insets.top,
            width: max(bounds.width - metrics.horizontalInsets, 0),
            height: max(bounds.height - metrics.verticalInsets, 0)
        )
    }

    // MARK: - Measurement

    private func measuredElements(
        contentWidth: CGFloat,
        measuring measurer: some ChartElementMeasuring
    ) -> ChartMeasuredElements {
        let tickSizes = measureTickLabels(measurer)
        let zoneWidth = axisZoneWidth(tickSizes: tickSizes, contentWidth: contentWidth)
        let annotationWidth = annotationWidth(contentWidth: contentWidth, axisZoneWidth: zoneWidth)
        let annotationSizes = measureAnnotations(measurer, proposedWidth: annotationWidth)
        let header = model.title == nil ? .zero : measurer.headerSize(proposedWidth: contentWidth).sanitized
        return ChartMeasuredElements(
            pointCount: model.dataset.count,
            header: header,
            annotationProposedWidth: annotationWidth,
            annotationSizes: annotationSizes,
            maximumHeightAbove: maximumHeight(of: annotationSizes) { $0 != .negative },
            maximumHeightBelow: maximumHeight(of: annotationSizes) { $0 == .negative },
            tickLabelSizes: zoneWidth > 0 ? tickSizes : [],
            axisZoneWidth: zoneWidth,
            categoryTickLength: model.categoryTickPositions.isEmpty ? 0 : metrics.categoryTickLength
        )
    }

    private func measureTickLabels(_ measurer: some ChartElementMeasuring) -> [CGSize] {
        guard model.configuration.valueAxis?.showsLabels == true else { return [] }
        return model.ticks.indices.map { measurer.tickLabelSize(at: $0).sanitized }
    }

    private func measureAnnotations(
        _ measurer: some ChartElementMeasuring,
        proposedWidth: CGFloat
    ) -> [CGSize] {
        guard metrics.showsAnnotations else { return [] }
        return model.prominentPoints.indices.map {
            measurer.annotationSize(at: $0, proposedWidth: proposedWidth).sanitized
        }
    }

    /// The width reserved at the leading edge for tick labels, or zero if they would take up
    /// more than half of the chart.
    private func axisZoneWidth(tickSizes: [CGSize], contentWidth: CGFloat) -> CGFloat {
        guard let widest = tickSizes.map(\.width).max(), widest > 0 else { return 0 }
        let zone = widest + metrics.axisLabelTrailingSpacing
        return zone <= contentWidth / 2 ? zone : 0
    }

    private func annotationWidth(contentWidth: CGFloat, axisZoneWidth: CGFloat) -> CGFloat {
        let available = max(contentWidth - axisZoneWidth - metrics.markerDiameter, 0)
        let spacing = ChartGeometryCalculator.spacing(
            plotWidth: available,
            count: model.dataset.count,
            metrics: metrics
        )
        let slot = max(spacing - metrics.annotationCollisionPadding, metrics.annotationMinimumWidth)
        return min(slot, contentWidth - axisZoneWidth)
    }

    private func maximumHeight(
        of sizes: [CGSize],
        where belongsToSide: (ChartDataPoint.Polarity) -> Bool
    ) -> CGFloat {
        zip(sizes, model.prominentPoints)
            .filter { belongsToSide($0.1.polarity) }
            .map(\.0.height)
            .max() ?? 0
    }
}

private extension CGSize {
    /// Guards against a measurement that is not usable, whatever its source.
    var sanitized: CGSize {
        CGSize(width: width.sanitizedLength(), height: height.sanitizedLength())
    }
}
