import SwiftUI
import XCTest

/// Compares a rendered view against a stored reference image.
///
/// Built on `ImageRenderer` rather than a snapshot library so that the package stays free of
/// dependencies. The whole harness is this file.
///
/// Text rendering differs between operating systems, so references are kept per platform and
/// major OS version in `__Snapshots__/<platform>-<version>/`. On a combination with no
/// references, these tests skip rather than report false failures.
///
/// To record: `SNAPSHOT_RECORD=1 swift test --filter SnapshotTests`. With `xcodebuild`, set
/// `TEST_RUNNER_SNAPSHOT_RECORD=1` so the variable reaches the simulator.
@MainActor
func assertSnapshot<V: View>(
    of view: V,
    named name: String,
    size: CGSize,
    environment: RenderEnvironment = RenderEnvironment(),
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    let image = try XCTUnwrap(
        ChartRendering.image(of: view, proposal: ProposedViewSize(size), environment: environment),
        "The view did not render",
        file: file,
        line: line
    )
    let reference = SnapshotLocation.directory.appendingPathComponent("\(name).png")

    if ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" {
        try PNGFile.write(image, to: reference)
        return
    }
    guard FileManager.default.fileExists(atPath: SnapshotLocation.directory.path) else {
        throw XCTSkip("No snapshots recorded for \(SnapshotLocation.directory.lastPathComponent).")
    }
    guard let stored = PNGFile.read(from: reference) else {
        XCTFail("Missing snapshot \(name). Record it with SNAPSHOT_RECORD=1.", file: file, line: line)
        return
    }
    try compare(image, to: stored, name: name, file: file, line: line)
}

@MainActor
private func compare(
    _ actual: CGImage,
    to reference: CGImage,
    name: String,
    file: StaticString,
    line: UInt
) throws {
    let actualPixels = try XCTUnwrap(PixelBuffer(actual), file: file, line: line)
    let referencePixels = try XCTUnwrap(PixelBuffer(reference), file: file, line: line)
    guard actual.width == reference.width, actual.height == reference.height else {
        XCTFail(
            "\(name): size changed from \(reference.width)x\(reference.height) to \(actual.width)x\(actual.height).",
            file: file,
            line: line
        )
        return
    }
    let difference = actualPixels.differingFraction(
        from: referencePixels,
        channelTolerance: SnapshotLocation.channelTolerance
    )
    if difference > SnapshotLocation.maximumDifferingFraction {
        let failed = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name)-actual.png")
        try PNGFile.write(actual, to: failed)
        XCTFail(
            "\(name): \(String(format: "%.3f", difference * 100))% of pixels differ. Actual image: \(failed.path)",
            file: file,
            line: line
        )
    }
}

enum SnapshotLocation {
    /// Allows for small rendering noise but catches any visible change.
    static let channelTolerance = 12
    /// A shift of even a thin line changes more pixels than this.
    static let maximumDifferingFraction = 0.0005

    static var directory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent("\(platform)-\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
    }

    private static var platform: String {
        #if targetEnvironment(macCatalyst)
        return "macCatalyst"
        #elseif os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "visionOS"
        #endif
    }
}
