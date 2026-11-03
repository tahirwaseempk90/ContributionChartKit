import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import XCTest

/// An image's pixels as 8-bit sRGB, for assertions on what was actually drawn.
struct PixelBuffer {
    struct RGBA: Equatable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8

        var isTransparent: Bool { alpha < 8 }
    }

    let width: Int
    let height: Int
    private let bytes: [UInt8]
    private static let bytesPerPixel = 4

    init?(_ image: CGImage) {
        width = image.width
        height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * Self.bytesPerPixel)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard
                let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                let context = CGContext(
                    data: buffer.baseAddress,
                    width: image.width,
                    height: image.height,
                    bitsPerComponent: 8,
                    bytesPerRow: image.width * Self.bytesPerPixel,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        guard drawn else { return nil }
        bytes = pixels
    }

    func pixel(x: Int, y: Int) -> RGBA {
        let offset = (y * width + x) * Self.bytesPerPixel
        return RGBA(red: bytes[offset], green: bytes[offset + 1], blue: bytes[offset + 2], alpha: bytes[offset + 3])
    }

    /// All pixels that satisfy a condition, as (x, y) positions.
    func positions(where condition: (RGBA) -> Bool) -> [(x: Int, y: Int)] {
        var result: [(x: Int, y: Int)] = []
        for y in 0..<height {
            for x in 0..<width where condition(pixel(x: x, y: y)) {
                result.append((x, y))
            }
        }
        return result
    }

    /// The share of pixels that differ visibly between two same-sized images.
    func differingFraction(from other: PixelBuffer, channelTolerance: Int) -> Double {
        guard width == other.width, height == other.height else { return 1 }
        var differing = 0
        for offset in stride(from: 0, to: bytes.count, by: Self.bytesPerPixel) {
            for channel in 0..<Self.bytesPerPixel
            where abs(Int(bytes[offset + channel]) - Int(other.bytes[offset + channel])) > channelTolerance {
                differing += 1
                break
            }
        }
        return Double(differing) / Double(width * height)
    }

    /// The same image flipped left to right.
    var mirrored: PixelBuffer {
        var result = self
        var flipped = bytes
        for y in 0..<height {
            for x in 0..<width {
                let source = (y * width + x) * Self.bytesPerPixel
                let target = (y * width + (width - 1 - x)) * Self.bytesPerPixel
                for channel in 0..<Self.bytesPerPixel {
                    flipped[target + channel] = bytes[source + channel]
                }
            }
        }
        result = PixelBuffer(width: width, height: height, bytes: flipped)
        return result
    }

    private init(width: Int, height: Int, bytes: [UInt8]) {
        self.width = width
        self.height = height
        self.bytes = bytes
    }
}

/// The conditions a chart is rendered under.
struct RenderEnvironment {
    var colorScheme: ColorScheme = .light
    var layoutDirection: LayoutDirection = .leftToRight
    var dynamicTypeSize: DynamicTypeSize = .large
    var displayScale: CGFloat = 2
    /// `nil` leaves the background transparent.
    var background: Color? = .white
}

@MainActor
enum ChartRendering {
    /// Renders a view with the real SwiftUI layout and drawing passes, without a window.
    static func image<V: View>(
        of view: V,
        proposal: ProposedViewSize,
        environment: RenderEnvironment = RenderEnvironment()
    ) -> CGImage? {
        let content = ZStack {
            if let background = environment.background { background }
            view
        }
        .environment(\.colorScheme, environment.colorScheme)
        .environment(\.layoutDirection, environment.layoutDirection)
        .environment(\.dynamicTypeSize, environment.dynamicTypeSize)
        .environment(\.displayScale, environment.displayScale)

        let renderer = ImageRenderer(content: content)
        renderer.scale = environment.displayScale
        renderer.proposedSize = proposal
        return renderer.cgImage
    }

    static func pixels<V: View>(
        of view: V,
        size: CGSize,
        environment: RenderEnvironment = RenderEnvironment()
    ) -> PixelBuffer? {
        image(of: view, proposal: ProposedViewSize(size), environment: environment).flatMap(PixelBuffer.init)
    }

    /// The size a view chooses for a proposal, measured from the rendered image.
    ///
    /// Uses no background, because `Color` would fill whatever it is offered.
    static func size<V: View>(of view: V, proposal: ProposedViewSize) -> CGSize? {
        let scale: CGFloat = 2
        let renderer = ImageRenderer(content: view.environment(\.displayScale, scale))
        renderer.scale = scale
        renderer.proposedSize = proposal
        return renderer.cgImage.map { CGSize(width: CGFloat($0.width) / scale, height: CGFloat($0.height) / scale) }
    }
}

enum PNGFile {
    static func write(_ image: CGImage, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    static func read(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
