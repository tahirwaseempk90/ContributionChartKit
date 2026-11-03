/// The caller's points after validation: only finite values, each with a unique identity.
struct ChartDataset: Sendable, Equatable {
    struct Entry: Sendable, Equatable {
        /// Unique within the dataset, unlike the point's own `id`, which callers may repeat.
        let id: String
        /// The horizontal position among the plotted points.
        let position: Int
        /// The index in the array the caller passed, which public APIs use to refer to points.
        let sourceIndex: Int
        let point: ChartDataPoint
    }

    let entries: [Entry]
    /// How many points were left out because their values were not finite.
    let invalidCount: Int

    init(points: [ChartDataPoint]) {
        var identities = UniqueIdentityGenerator(capacity: points.count)
        var entries: [Entry] = []
        entries.reserveCapacity(points.count)
        for (sourceIndex, point) in points.enumerated() where point.isPlottable {
            entries.append(
                Entry(
                    id: identities.next(for: point.id),
                    position: entries.count,
                    sourceIndex: sourceIndex,
                    point: point
                )
            )
        }
        self.entries = entries
        self.invalidCount = points.count - entries.count
    }

    var isEmpty: Bool {
        entries.isEmpty
    }

    var count: Int {
        entries.count
    }

    /// The entries with the largest magnitudes, in display order.
    ///
    /// This caps the work done per layout: only so many labels can fit on a chart, so there
    /// is no reason to create and measure text for the remaining points.
    func prominentEntries(limit: Int) -> [Entry] {
        guard entries.count > limit else { return entries }
        return entries
            .sorted { lhs, rhs in
                let (left, right) = (abs(lhs.point.value), abs(rhs.point.value))
                return left == right ? lhs.position < rhs.position : left > right
            }
            .prefix(limit)
            .sorted { $0.position < $1.position }
    }

    /// The range of plotted positions for a range of indices in the caller's array.
    func positions(covering sourceRange: ClosedRange<Int>) -> ClosedRange<Int>? {
        guard
            let first = entries.first(where: { sourceRange.contains($0.sourceIndex) }),
            let last = entries.last(where: { sourceRange.contains($0.sourceIndex) })
        else { return nil }
        return first.position...last.position
    }
}

/// Makes repeated identifiers unique, so that each point has its own accessibility identifier.
private struct UniqueIdentityGenerator {
    private var used: Set<String>
    private var nextSuffix: [String: Int] = [:]
    private static let firstDuplicateSuffix = 2

    init(capacity: Int) {
        used = Set(minimumCapacity: capacity)
    }

    mutating func next(for id: String) -> String {
        if used.insert(id).inserted { return id }
        var suffix = nextSuffix[id, default: Self.firstDuplicateSuffix]
        // A caller may already use an identifier such as "a#2", so keep looking for a free one.
        while !used.insert("\(id)#\(suffix)").inserted {
            suffix += 1
        }
        nextSuffix[id] = suffix + 1
        return "\(id)#\(suffix)"
    }
}
