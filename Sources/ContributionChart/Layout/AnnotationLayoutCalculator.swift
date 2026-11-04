import CoreGraphics

/// Places labels next to their markers and decides which ones can be shown.
///
/// Labels are considered from the largest value to the smallest, and a label is kept only if
/// it fits without overlapping an earlier label or another point's marks. In a chart about
/// the biggest values, those are the labels most worth keeping. The result is deterministic:
/// the same input always keeps the same labels.
struct AnnotationLayoutCalculator: Sendable {
    struct Request: Sendable, Equatable {
        /// The index in ``ChartModel/prominentPoints``.
        let index: Int
        let position: Int
        let magnitude: Double
        let size: CGSize
    }

    /// The area labels must stay inside.
    let bounds: CGRect
    let markerSpacing: CGFloat
    let collisionPadding: CGFloat

    /// - Parameters:
    ///   - requests: The labels to place, one per point.
    ///   - marks: All marks, ordered from left to right.
    /// - Returns: One placement per request, in the same order.
    func placements(for requests: [Request], marks: [ChartMark]) -> [ChartAnnotationPlacement] {
        var accepted: [CGRect] = []
        var placements: [Int: ChartAnnotationPlacement] = [:]

        for request in prioritized(requests) {
            guard marks.indices.contains(request.position) else { continue }
            let mark = marks[request.position]
            let frame = frame(for: request.size, next: mark)
            let isVisible = fitsInBounds(request.size)
                && !overlapsAccepted(frame, accepted: accepted)
                && !overlapsOtherMarks(frame, of: mark, marks: marks)
            if isVisible {
                accepted.append(frame)
            }
            placements[request.index] = ChartAnnotationPlacement(
                index: request.index,
                frame: frame,
                isVisible: isVisible
            )
        }
        return requests.compactMap { placements[$0.index] }
    }

    /// The label's frame: above a positive or zero point, below a negative one, and centred
    /// on the marker unless that would take it past the edge of the chart.
    func frame(for size: CGSize, next mark: ChartMark) -> CGRect {
        let radius = mark.markerDiameter / 2
        let idealY = mark.polarity == .negative
            ? mark.center.y + radius + markerSpacing
            : mark.center.y - radius - markerSpacing - size.height
        return CGRect(
            x: clamp(mark.center.x - size.width / 2, from: bounds.minX, to: bounds.maxX - size.width),
            y: clamp(idealY, from: bounds.minY, to: bounds.maxY - size.height),
            width: size.width,
            height: size.height
        )
    }

    private func prioritized(_ requests: [Request]) -> [Request] {
        requests.sorted { lhs, rhs in
            lhs.magnitude == rhs.magnitude ? lhs.position < rhs.position : lhs.magnitude > rhs.magnitude
        }
    }

    private func fitsInBounds(_ size: CGSize) -> Bool {
        size.width > 0 && size.height > 0 && size.width <= bounds.width && size.height <= bounds.height
    }

    private func overlapsAccepted(_ frame: CGRect, accepted: [CGRect]) -> Bool {
        let padded = frame.insetBy(dx: -collisionPadding, dy: -collisionPadding)
        return accepted.contains { $0.intersects(padded) }
    }

    /// Whether the label would cover another point's marks. Marks are ordered by x, so only
    /// those under the label's horizontal span need checking.
    private func overlapsOtherMarks(_ frame: CGRect, of owner: ChartMark, marks: [ChartMark]) -> Bool {
        var index = firstMarkIndex(reaching: frame.minX, marks: marks)
        while index < marks.count {
            let candidate = marks[index]
            if candidate.bounds.minX >= frame.maxX { break }
            if candidate.position != owner.position && candidate.bounds.intersects(frame) {
                return true
            }
            index += 1
        }
        return false
    }

    /// Binary search for the first mark whose right edge reaches `x`.
    private func firstMarkIndex(reaching x: CGFloat, marks: [ChartMark]) -> Int {
        var low = 0
        var high = marks.count
        while low < high {
            let middle = (low + high) / 2
            if marks[middle].bounds.maxX < x {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low
    }

    private func clamp(_ value: CGFloat, from lower: CGFloat, to upper: CGFloat) -> CGFloat {
        // When the label is larger than the bounds, `upper` falls below `lower` and the label
        // is rejected by `fitsInBounds`. Favouring `lower` keeps the frame well defined.
        max(min(value, upper), lower)
    }
}
