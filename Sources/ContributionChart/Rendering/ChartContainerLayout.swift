import SwiftUI

/// Connects the pure layout engine to SwiftUI: it measures subviews and places them.
///
/// A `Layout` is used rather than a `GeometryReader` because it receives the parent's actual
/// proposal, including an open dimension. A `GeometryReader` takes all the space it is
/// offered and collapses inside a `ScrollView`, whereas this answers with an ideal size.
struct ChartContainerLayout: Layout {
    /// The positions of subviews whose text must be measured, looked up by index.
    struct Cache {
        var header: Int?
        var annotations: [Int: Int] = [:]
        var tickLabels: [Int: Int] = [:]
    }

    let engine: ChartLayoutEngine

    func makeCache(subviews: Subviews) -> Cache {
        var cache = Cache()
        for (position, subview) in subviews.enumerated() {
            switch subview[ChartElementRoleKey.self] {
            case .header: cache.header = position
            case let .annotation(index): cache.annotations[index] = position
            case let .tickLabel(index): cache.tickLabels[index] = position
            default: break
            }
        }
        return cache
    }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache = makeCache(subviews: subviews)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        engine.size(for: proposal, measuring: SubviewMeasurer(subviews: subviews, cache: cache))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let layout = engine.layout(in: bounds.size, measuring: SubviewMeasurer(subviews: subviews, cache: cache))
        for subview in subviews {
            let role = subview[ChartElementRoleKey.self]
            let frame = layout.frame(for: role)
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: layout.proposal(for: role)
            )
        }
    }
}

private struct SubviewMeasurer: ChartElementMeasuring {
    let subviews: LayoutSubviews
    let cache: ChartContainerLayout.Cache

    func headerSize(proposedWidth: CGFloat) -> CGSize {
        size(ofSubviewAt: cache.header, proposal: ProposedViewSize(width: proposedWidth, height: nil))
    }

    func annotationSize(at index: Int, proposedWidth: CGFloat) -> CGSize {
        size(ofSubviewAt: cache.annotations[index], proposal: ProposedViewSize(width: proposedWidth, height: nil))
    }

    func tickLabelSize(at index: Int) -> CGSize {
        size(ofSubviewAt: cache.tickLabels[index], proposal: .unspecified)
    }

    private func size(ofSubviewAt position: Int?, proposal: ProposedViewSize) -> CGSize {
        guard let position else { return .zero }
        return subviews[position].sizeThatFits(proposal)
    }
}

private struct ChartElementRoleKey: LayoutValueKey {
    static let defaultValue = ChartElementRole.unassigned
}

extension View {
    func chartRole(_ role: ChartElementRole) -> some View {
        layoutValue(key: ChartElementRoleKey.self, value: role)
    }
}

/// Lets a parent layout hide a text view that it has measured.
///
/// A `Layout` cannot change a subview's opacity or remove it, and must place every subview.
/// It can only propose a size, and text ignores a zero proposal. This wrapper makes a zero
/// proposal mean zero size, and clipping to that size then hides the content.
struct CollapsibleLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        guard proposal != .zero, let child = subviews.first else { return .zero }
        return child.sizeThatFits(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: proposal)
    }
}

extension View {
    /// Wraps a view so that a parent layout can hide it by proposing a size of zero.
    func collapsible() -> some View {
        CollapsibleLayout { self }.clipped()
    }
}
