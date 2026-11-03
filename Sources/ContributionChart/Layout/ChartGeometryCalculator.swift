import CoreGraphics

/// Computes the baseline and marks from nothing more than the size they occupy.
///
/// `Canvas` is handed only a size when it draws. Keeping this calculation a pure function of
/// size means the layout engine and the canvas can call it independently and still agree
/// exactly, with no shared state between the layout pass and the render pass.
struct ChartGeometryCalculator: Sendable, Equatable {
    let values: [Double]
    let scale: ChartScale
    let metrics: ChartMetrics
    let grid: PixelGrid

    /// The sizes of one point's marks after adapting to how close together the points are.
    private struct MarkDimensions {
        let markerDiameter: CGFloat
        let stemWidth: CGFloat
        let minimumStemLength: CGFloat
    }

    /// What every mark in a layout has in common.
    private struct MarkContext {
        /// The area marker centres must stay inside.
        let plot: CGRect
        /// The part of the plot that the scale maps onto.
        let scaledPlot: CGRect
        let spacing: CGFloat
        let dimensions: MarkDimensions
        let baseline: CGRect
    }

    func layout(in size: CGSize) -> ChartMarksLayout {
        let extent = metrics.markExtent(width: size.width, count: values.count)
        let inset = min(extent, size.width / 2, size.height / 2)
        let plot = CGRect(
            x: inset,
            y: inset,
            width: max(size.width - inset * 2, 0),
            height: max(size.height - inset * 2, 0)
        )
        let spacing = Self.spacing(plotWidth: plot.width, count: values.count, metrics: metrics)
        let dimensions = dimensions(spacing: spacing, extentLimit: inset * 2)
        let scaledPlot = scaledPlot(within: plot, minimumStemLength: dimensions.minimumStemLength)
        let baseline = baselineFrame(in: scaledPlot, canvas: size)
        let context = MarkContext(
            plot: plot,
            scaledPlot: scaledPlot,
            spacing: spacing,
            dimensions: dimensions,
            baseline: baseline
        )
        let marks = values.indices.map { mark(at: $0, context: context) }
        return ChartMarksLayout(plotFrame: scaledPlot, baselineFrame: baseline, spacing: spacing, marks: marks)
    }

    /// The part of the plot the scale maps onto.
    ///
    /// With very uneven data such as `[1000, -0.001]`, the baseline lands at the plot's very
    /// edge, which leaves the small value no room on its own side. It would then sit on the
    /// baseline and read as zero. So when a side has values, the scale leaves that side at
    /// least the minimum stem length.
    private func scaledPlot(within plot: CGRect, minimumStemLength: CGFloat) -> CGRect {
        guard minimumStemLength > 0, plot.height > 0 else { return plot }
        let below = CGFloat(scale.baselineFraction) * plot.height
        let above = plot.height - below
        let bottom = values.contains { $0 < 0 } ? min(max(minimumStemLength - below, 0), plot.height) : 0
        let top = values.contains { $0 > 0 } ? min(max(minimumStemLength - above, 0), plot.height - bottom) : 0
        return CGRect(x: plot.minX, y: plot.minY + top, width: plot.width, height: plot.height - top - bottom)
    }

    static func spacing(plotWidth: CGFloat, count: Int, metrics: ChartMetrics) -> CGFloat {
        switch metrics.pointDistribution {
        case .slots:
            return count > 1 ? plotWidth / CGFloat(count) : .infinity
        case .edgeToEdge:
            return count > 1 ? plotWidth / CGFloat(count - 1) : .infinity
        }
    }

    // MARK: - Horizontal

    private func xPosition(at position: Int, plot: CGRect, spacing: CGFloat) -> CGFloat {
        guard values.count > 1 else { return plot.midX }
        switch metrics.pointDistribution {
        case .slots:
            return plot.minX + spacing * (CGFloat(position) + 0.5)
        case .edgeToEdge:
            return plot.minX + spacing * CGFloat(position)
        }
    }

    // MARK: - Sizes

    /// Shrinks markers once points get close, and scales stems by the same ratio so that
    /// a dense chart keeps the proportions of a sparse one.
    private func dimensions(spacing: CGFloat, extentLimit: CGFloat) -> MarkDimensions {
        // A single point has infinite spacing, and infinity times a fraction of 0 is NaN.
        let spacingLimit = spacing.isFinite ? spacing * metrics.markerSpacingFraction : .infinity
        let shrink: CGFloat
        let diameter: CGFloat
        if metrics.markerDiameter > 0 {
            let allowed = max(spacingLimit, metrics.minimumMarkerDiameter)
            diameter = min(metrics.markerDiameter, allowed, extentLimit)
            shrink = diameter / metrics.markerDiameter
        } else {
            diameter = 0
            shrink = metrics.stemWidth > 0 ? min(spacingLimit / metrics.stemWidth, 1) : 1
        }
        let stemLimit = min(extentLimit, spacing)
        let stemWidth = metrics.stemWidth > 0 ? max(min(metrics.stemWidth * shrink, stemLimit), 1 / grid.scale) : 0
        return MarkDimensions(
            markerDiameter: grid.snapLength(diameter),
            stemWidth: grid.snapLength(stemWidth),
            minimumStemLength: metrics.minimumStemLength * shrink
        )
    }

    // MARK: - Baseline

    /// Kept inside the canvas here rather than clipped later, because stems end at its edges.
    private func baselineFrame(in plot: CGRect, canvas: CGSize) -> CGRect {
        let center = plot.maxY - CGFloat(scale.baselineFraction) * plot.height
        let thickness = min(grid.snapLength(metrics.baselineThickness), canvas.height)
        let minY = max(min(grid.snap(center - thickness / 2), canvas.height - thickness), 0)
        return CGRect(x: 0, y: minY, width: canvas.width, height: thickness)
    }

    // MARK: - Marks

    private func mark(at position: Int, context: MarkContext) -> ChartMark {
        let value = values[position]
        let polarity = ChartDataPoint.Polarity(value: value)
        let center = markCenter(
            x: xPosition(at: position, plot: context.plot, spacing: context.spacing),
            y: scaledY(for: value, polarity: polarity, context: context),
            plot: context.plot,
            stemWidth: context.dimensions.stemWidth
        )
        return ChartMark(
            position: position,
            polarity: polarity,
            center: center,
            markerDiameter: context.dimensions.markerDiameter,
            stem: stem(center: center, polarity: polarity, dimensions: context.dimensions, baseline: context.baseline)
        )
    }

    private func markCenter(x: CGFloat, y: CGFloat, plot: CGRect, stemWidth: CGFloat) -> CGPoint {
        // Align the stem's edges to pixels, then centre the marker on the result: a marker
        // aligned on its own could sit half a pixel off its stem.
        let alignedX = grid.snap(x - stemWidth / 2) + stemWidth / 2
        return CGPoint(x: clamp(alignedX, plot.minX, plot.maxX), y: clamp(y, plot.minY, plot.maxY))
    }

    private func scaledY(
        for value: Double,
        polarity: ChartDataPoint.Polarity,
        context: MarkContext
    ) -> CGFloat {
        let plot = context.scaledPlot
        let baseline = context.baseline.midY
        let scaled = plot.maxY - CGFloat(scale.fraction(of: value)) * plot.height
        let minimum = context.dimensions.minimumStemLength
        // Keeps a very small value on its own side of the baseline instead of looking like zero.
        switch polarity {
        case .positive: return grid.snap(min(scaled, baseline - minimum))
        case .negative: return grid.snap(max(scaled, baseline + minimum))
        case .zero: return baseline
        }
    }

    private func stem(
        center: CGPoint,
        polarity: ChartDataPoint.Polarity,
        dimensions: MarkDimensions,
        baseline: CGRect
    ) -> CGRect? {
        guard dimensions.stemWidth > 0, polarity != .zero else { return nil }
        let inset = stemInset(markerDiameter: dimensions.markerDiameter, stemWidth: dimensions.stemWidth)
        let top: CGFloat
        let bottom: CGFloat
        // The stem stops at the baseline's edge rather than its centre. If it overlapped, a
        // translucent stem would visibly darken the line where they meet.
        if polarity == .positive {
            top = center.y + inset
            bottom = baseline.minY
        } else {
            top = baseline.maxY
            bottom = center.y - inset
        }
        guard bottom > top else { return nil }
        return CGRect(x: center.x - dimensions.stemWidth / 2, y: top, width: dimensions.stemWidth, height: bottom - top)
    }

    /// How far from the marker's centre the stem can stop and still be hidden under it.
    ///
    /// A stem running to the centre would show through a translucent marker. Stopping where
    /// the stem's corners meet the circle avoids that, and one extra pixel of overlap avoids a
    /// hairline gap from antialiasing.
    private func stemInset(markerDiameter: CGFloat, stemWidth: CGFloat) -> CGFloat {
        guard markerDiameter > 0 else { return 0 }
        let radius = markerDiameter / 2
        let halfWidth = stemWidth / 2
        let chord = (max(radius * radius - halfWidth * halfWidth, 0)).squareRoot()
        return max(chord - 1 / grid.scale, 0)
    }

    private func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }
}
