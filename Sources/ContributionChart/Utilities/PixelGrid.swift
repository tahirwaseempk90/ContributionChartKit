import CoreGraphics

/// Aligns geometry to device pixels, so that lines stay crisp at any display scale.
struct PixelGrid: Sendable, Equatable {
    let scale: CGFloat

    init(scale: CGFloat) {
        self.scale = scale.isFinite && scale > 0 ? scale : 1
    }

    /// The nearest pixel boundary.
    func snap(_ value: CGFloat) -> CGFloat {
        (value * scale).rounded() / scale
    }

    /// A whole number of pixels, and never less than one pixel for a positive length, so a
    /// thin line cannot vanish on a low-resolution display.
    func snapLength(_ length: CGFloat) -> CGFloat {
        guard length > 0 else { return 0 }
        return max((length * scale).rounded(), 1) / scale
    }

    /// The largest pixel-aligned rectangle inside `rect`, which therefore stays in its bounds.
    func snapInward(_ rect: CGRect) -> CGRect {
        let minX = (rect.minX * scale).rounded(.up) / scale
        let minY = (rect.minY * scale).rounded(.up) / scale
        let maxX = (rect.maxX * scale).rounded(.down) / scale
        let maxY = (rect.maxY * scale).rounded(.down) / scale
        return CGRect(x: minX, y: minY, width: max(maxX - minX, 0), height: max(maxY - minY, 0))
    }

    /// The pixel-aligned rectangle closest to `rect`.
    func snap(_ rect: CGRect) -> CGRect {
        CGRect(
            x: snap(rect.minX),
            y: snap(rect.minY),
            width: snapLength(rect.width),
            height: snapLength(rect.height)
        )
    }
}
