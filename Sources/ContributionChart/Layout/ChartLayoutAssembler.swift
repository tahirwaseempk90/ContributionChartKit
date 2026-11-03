import CoreGraphics

/// Positions every chart element once the vertical plan has been decided.
struct ChartLayoutAssembler {
    let engine: ChartLayoutEngine
    let bounds: CGRect
    let content: CGRect
    let elements: ChartMeasuredElements
    let plan: ChartVerticalPlan

    private var model: ChartModel { engine.model }
    private var metrics: ChartMetrics { model.metrics }
    private var grid: PixelGrid { engine.grid }

    /// The area below the title.
    private var plotZone: CGRect {
        CGRect(
            x: content.minX,
            y: content.minY + plan.headerBlock,
            width: content.width,
            height: max(content.height - plan.headerBlock, 0)
        )
    }

    func assemble() -> ChartLayoutResult {
        let marksFrame = marksFrame()
        let marksLayout = engine.geometry.layout(in: marksFrame.size).offsetBy(marksFrame.origin)
        let lineMaxX = lineMaxX(marks: marksLayout.marks)
        let annotations = annotationPlacements(marks: marksLayout.marks)
        let gridlines = gridlineLayout(plot: marksLayout.plotFrame, lineMaxX: lineMaxX)

        var result = ChartLayoutResult(bounds: bounds)
        result.headerFrame = headerFrame()
        result.marksFrame = marksFrame
        result.plotFrame = marksLayout.plotFrame
        result.baselineFrame = baselineFrame(from: marksLayout, lineMaxX: lineMaxX)
        result.summaryFrame = content
        result.marks = marksLayout.marks
        result.annotations = annotations
        result.annotationProposedWidth = elements.annotationProposedWidth
        result.gridlineFrames = gridlines.lines
        result.tickLabelFrames = gridlines.labels
        result.referenceLineFrames = referenceLineFrames(layout: marksLayout, lineMaxX: lineMaxX)
        result.regionFrames = regionFrames(
            marks: marksLayout.marks,
            spacing: marksLayout.spacing,
            plot: marksLayout.plotFrame
        )
        result.categoryTickFrames = categoryTickFrames(marks: marksLayout.marks, plot: marksLayout.plotFrame)
        result.pointFrames = pointFrames(marks: marksLayout.marks, annotations: annotations)
        return result
    }

    // MARK: - Containers

    private func headerFrame() -> CGRect {
        guard plan.headerBlock > 0 else { return .zero }
        return CGRect(x: content.minX, y: content.minY, width: content.width, height: elements.header.height)
    }

    /// The canvas frame: the plot area plus room for the marker radius on every side.
    ///
    /// Aligned to pixels so that marks aligned within the canvas are also aligned on screen.
    private func marksFrame() -> CGRect {
        let inset = plan.markInset
        let minX = content.minX + max(elements.axisZoneWidth - inset, 0)
        let frame = CGRect(
            x: minX,
            y: plotZone.minY + plan.topReserve - inset,
            width: content.maxX - minX,
            height: max(plan.plotHeight, 0) + inset * 2
        )
        return grid.snapInward(contained(frame, in: plotZone))
    }

    /// Lines end under the last marker when points run edge to edge, otherwise at the content
    /// edge. A single point sits in the middle of the chart, so it doesn't mark an edge.
    private func lineMaxX(marks: [ChartMark]) -> CGFloat {
        guard metrics.pointDistribution == .edgeToEdge, marks.count > 1, let last = marks.last else {
            return content.maxX
        }
        return last.center.x
    }

    private func baselineFrame(from layout: ChartMarksLayout, lineMaxX: CGFloat) -> CGRect {
        guard layout.baselineFrame.height > 0 else { return .zero }
        return contained(
            CGRect(
                x: content.minX,
                y: layout.baselineFrame.minY,
                width: max(lineMaxX - content.minX, 0),
                height: layout.baselineFrame.height
            )
        )
    }

    // MARK: - Labels

    private func annotationPlacements(marks: [ChartMark]) -> [ChartAnnotationPlacement] {
        guard plan.options.showsAnnotations else { return [] }
        let calculator = AnnotationLayoutCalculator(
            bounds: CGRect(
                x: content.minX + elements.axisZoneWidth,
                y: plotZone.minY,
                width: max(content.width - elements.axisZoneWidth, 0),
                height: plotZone.height
            ),
            markerSpacing: metrics.annotationMarkerSpacing,
            collisionPadding: metrics.annotationCollisionPadding
        )
        let requests = zip(model.prominentPoints.indices, elements.annotationSizes).map { index, size in
            let entry = model.prominentPoints[index].entry
            return AnnotationLayoutCalculator.Request(
                index: index,
                position: entry.position,
                magnitude: abs(entry.point.value),
                size: size
            )
        }
        return calculator.placements(for: requests, marks: marks)
    }

    // MARK: - Value axis

    /// Frames for gridlines and their labels.
    ///
    /// When there is too little height for every tick to have a readable label, ticks are
    /// thinned evenly, counting outward from zero so that zero itself is always kept.
    private func gridlineLayout(plot: CGRect, lineMaxX: CGFloat) -> (lines: [CGRect], labels: [CGRect]) {
        let thickness = grid.snapLength(metrics.gridlineThickness)
        let labelSizes = plan.options.showsAxisLabels ? elements.tickLabelSizes : []
        let keepEvery = tickStride(plot: plot, labelHeight: labelSizes.map(\.height).max() ?? 0)

        var lines: [CGRect] = []
        var labels: [CGRect] = []
        for (index, tick) in model.ticks.enumerated() {
            guard tick.ordinal % keepEvery == 0 else {
                lines.append(.zero)
                labels.append(.zero)
                continue
            }
            let y = grid.snap(plot.maxY - CGFloat(model.scale.fraction(of: tick.value)) * plot.height - thickness / 2)
            lines.append(
                contained(CGRect(x: content.minX, y: y, width: max(lineMaxX - content.minX, 0), height: thickness))
            )
            labels.append(labelFrame(size: labelSizes.indices.contains(index) ? labelSizes[index] : .zero, lineY: y))
        }
        return (lines, labels)
    }

    private func labelFrame(size: CGSize, lineY: CGFloat) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        return contained(
            CGRect(
                x: content.minX + elements.axisZoneWidth - metrics.axisLabelTrailingSpacing - size.width,
                y: max(lineY - metrics.axisLabelSpacing - size.height, plotZone.minY),
                width: size.width,
                height: size.height
            )
        )
    }

    private func tickStride(plot: CGRect, labelHeight: CGFloat) -> Int {
        guard model.ticks.count > 1, labelHeight > 0, plot.height > 0 else { return 1 }
        let fractions = model.ticks.prefix(2).map { CGFloat(model.scale.fraction(of: $0.value)) }
        let spacing = plot.height * (fractions[1] - fractions[0])
        let needed = ((labelHeight + metrics.axisLabelSpacing) / spacing).rounded(.up)
        // Capped first because `Int()` traps on a value too large for it, which a vanishingly
        // small spacing could produce. Keeping every Nth tick for N past the count leaves only zero.
        return max(Int(min(needed, CGFloat(model.ticks.count))), 1)
    }

    // MARK: - Decorations

    private func referenceLineFrames(layout: ChartMarksLayout, lineMaxX: CGFloat) -> [CGRect] {
        let plot = layout.plotFrame
        return model.referenceLines.map { line in
            let thickness = grid.snapLength(line.style.thickness.sanitizedLength(fallback: 1))
            let span = horizontalSpan(of: line, layout: layout, lineMaxX: lineMaxX)
            let center = plot.maxY - CGFloat(model.scale.fraction(of: line.value)) * plot.height
            let y = grid.snap(center - thickness / 2)
            return contained(CGRect(x: span.minX, y: y, width: max(span.maxX - span.minX, 0), height: thickness))
        }
    }

    /// A line runs from its first point to its last. A line over a single point takes that
    /// point's share of the width, because running from its centre to itself would draw nothing.
    private func horizontalSpan(
        of line: ChartModel.ReferenceLine,
        layout: ChartMarksLayout,
        lineMaxX: CGFloat
    ) -> (minX: CGFloat, maxX: CGFloat) {
        guard let positions = line.positions else { return (content.minX, lineMaxX) }
        let first = layout.marks[positions.lowerBound].center.x
        guard positions.lowerBound == positions.upperBound else {
            return (first, layout.marks[positions.upperBound].center.x)
        }
        guard layout.spacing.isFinite else { return (content.minX, content.maxX) }
        return (first - layout.spacing / 2, first + layout.spacing / 2)
    }

    /// Regions reach the chart's edges past the first and last points, and otherwise stop at
    /// the boundary between points: the slot's edge, or the point itself when edge to edge.
    private func regionFrames(marks: [ChartMark], spacing: CGFloat, plot: CGRect) -> [CGRect] {
        let halfSlot = metrics.pointDistribution == .slots && spacing.isFinite ? spacing / 2 : 0
        let top = plan.headerBlock > 0 ? plotZone.minY : bounds.minY
        // With ticks along the bottom, regions stop at the axis so the ticks stay clear.
        let bottom = elements.categoryTickLength > 0 ? plot.maxY : bounds.maxY
        return model.regions.map { region in
            let minX = region.positions.lowerBound == 0
                ? bounds.minX
                : marks[region.positions.lowerBound].center.x - halfSlot
            let maxX = region.positions.upperBound == marks.count - 1
                ? bounds.maxX
                : marks[region.positions.upperBound].center.x + halfSlot
            return grid.snapInward(CGRect(x: minX, y: top, width: max(maxX - minX, 0), height: max(bottom - top, 0)))
        }
    }

    private func categoryTickFrames(marks: [ChartMark], plot: CGRect) -> [CGRect] {
        let thickness = grid.snapLength(metrics.categoryTickThickness)
        return model.categoryTickPositions.map { position in
            contained(
                CGRect(
                    x: grid.snap(marks[position].center.x - thickness / 2),
                    y: grid.snap(plot.maxY),
                    width: thickness,
                    height: grid.snapLength(metrics.categoryTickLength)
                )
            )
        }
    }

    // MARK: - Accessibility

    /// The area VoiceOver highlights for each point: its marks and, when shown, its label.
    private func pointFrames(marks: [ChartMark], annotations: [ChartAnnotationPlacement]) -> [CGRect] {
        model.prominentPoints.enumerated().map { index, point in
            var frame = marks[point.entry.position].bounds
            if annotations.indices.contains(index), annotations[index].isVisible {
                frame = frame.union(annotations[index].frame)
            }
            // A zero-size element cannot be focused, as with a hidden marker on a zero value.
            return contained(frame.insetBy(dx: min(frame.width - 1, 0) / 2, dy: min(frame.height - 1, 0) / 2))
        }
    }

    // MARK: - Containment

    /// Moves a frame inside the chart, trimming it only if it is too large to fit.
    ///
    /// Moving comes first because a line at the chart's edge can round half a pixel outside,
    /// and moving it keeps the whole line visible where clipping would lose part of it.
    private func contained(_ frame: CGRect, in area: CGRect? = nil) -> CGRect {
        let area = area ?? bounds
        let width = min(frame.width, area.width)
        let height = min(frame.height, area.height)
        return CGRect(
            x: max(min(frame.minX, area.maxX - width), area.minX),
            y: max(min(frame.minY, area.maxY - height), area.minY),
            width: width,
            height: height
        )
    }
}
