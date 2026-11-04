import CoreGraphics

/// The results of measuring a chart's text.
struct ChartMeasuredElements: Sendable, Equatable {
    let pointCount: Int
    let header: CGSize
    /// The width labels were measured with, which they must also be placed with.
    let annotationProposedWidth: CGFloat
    let annotationSizes: [CGSize]
    /// The tallest label on points drawn above their marker.
    let maximumHeightAbove: CGFloat
    /// The tallest label on points drawn below their marker.
    let maximumHeightBelow: CGFloat
    /// Empty when tick labels are not shown.
    let tickLabelSizes: [CGSize]
    /// The width reserved for tick labels at the leading edge.
    let axisZoneWidth: CGFloat
    let categoryTickLength: CGFloat
}

/// How a chart's height is divided between its title, labels, and plot.
struct ChartVerticalPlan: Sendable, Equatable {
    /// The optional elements to include.
    struct Options: Sendable, Equatable {
        var showsHeader: Bool
        var showsAnnotations: Bool
        var showsAxisLabels: Bool

        static let all = Options(showsHeader: true, showsAnnotations: true, showsAxisLabels: true)
    }

    let options: Options
    /// The title's height and its spacing, or zero when hidden.
    let headerBlock: CGFloat
    /// The margin that keeps marks inside the plot area.
    let markInset: CGFloat
    /// The space from the top of the plot area to the highest marker centre.
    let topReserve: CGFloat
    /// The space from the lowest marker centre to the bottom of the plot area.
    let bottomReserve: CGFloat
    /// The height left for marker centres. Negative when the content does not fit.
    let plotHeight: CGFloat

    init(contentSize: CGSize, elements: ChartMeasuredElements, metrics: ChartMetrics, options: Options) {
        let hasHeader = options.showsHeader && elements.header.height > 0
        let headerBlock = hasHeader ? elements.header.height + metrics.headerSpacing : 0
        let available = max(contentSize.height - headerBlock, 0)
        let extent = metrics.markExtent(width: contentSize.width, count: elements.pointCount)
        let inset = min(extent, contentSize.width / 2, available / 2)

        let gap = inset + metrics.annotationMarkerSpacing
        let labelAbove = options.showsAnnotations && elements.maximumHeightAbove > 0
            ? gap + elements.maximumHeightAbove
            : 0
        let labelBelow = options.showsAnnotations && elements.maximumHeightBelow > 0
            ? gap + elements.maximumHeightBelow
            : 0
        // A tick label sits above its gridline, so the top gridline needs room for one.
        let tickLabel = options.showsAxisLabels
            ? (elements.tickLabelSizes.map(\.height).max() ?? 0) + metrics.axisLabelSpacing
            : 0

        self.options = options
        self.headerBlock = headerBlock
        self.markInset = inset
        self.topReserve = max(inset, labelAbove, tickLabel)
        self.bottomReserve = max(inset, labelBelow, elements.categoryTickLength)
        // Not based on `available`, which stops at zero: a title taller than the chart has to
        // come out negative here, or it would count as fitting when no plot height is required.
        self.plotHeight = contentSize.height - headerBlock - topReserve - bottomReserve
    }

    /// The richest plan whose plot is still tall enough.
    ///
    /// Elements are dropped in order of how much the chart can do without them: labels first,
    /// because every value stays available to VoiceOver, then the title, and then the axis.
    /// The marks themselves are always kept.
    static func best(
        contentSize: CGSize,
        elements: ChartMeasuredElements,
        metrics: ChartMetrics
    ) -> ChartVerticalPlan {
        let fallbacks: [Options] = [
            .all,
            Options(showsHeader: true, showsAnnotations: false, showsAxisLabels: true),
            Options(showsHeader: false, showsAnnotations: false, showsAxisLabels: true)
        ]
        for options in fallbacks {
            let plan = ChartVerticalPlan(
                contentSize: contentSize,
                elements: elements,
                metrics: metrics,
                options: options
            )
            if plan.plotHeight >= metrics.minimumPlotHeight {
                return plan
            }
        }
        return ChartVerticalPlan(
            contentSize: contentSize,
            elements: elements,
            metrics: metrics,
            options: Options(showsHeader: false, showsAnnotations: false, showsAxisLabels: false)
        )
    }
}
