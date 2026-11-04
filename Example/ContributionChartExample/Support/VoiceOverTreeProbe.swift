#if canImport(UIKit)
import SwiftUI
import UIKit

/// Test support: publishes what VoiceOver would read, so that UI tests can verify it.
///
/// XCUITest's own tree also includes elements hidden from VoiceOver, so it can't show whether
/// a value would be read twice. This walks the `UIAccessibility` tree that VoiceOver actually
/// traverses and exposes the result as the label of an element a UI test can read. Enabled
/// only by the `-exposeVoiceOverTree YES` launch argument.
struct VoiceOverTreeProbe: View {
    @State private var tree = ""

    /// Long enough for the screen and its accessibility nodes to settle.
    private let settleTime = Duration.seconds(1.5)

    var body: some View {
        Text(verbatim: tree)
            .font(.system(size: 1))
            .opacity(0.01)
            .frame(width: 1, height: 1)
            .accessibilityIdentifier("voiceover.tree")
            .task {
                try? await Task.sleep(for: settleTime)
                tree = Self.currentTree()
            }
    }

    private static func currentTree() -> String {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        var lines: [String] = []
        for window in windows {
            walk(window, into: &lines)
        }
        return lines.joined(separator: "\n")
    }

    private static func walk(_ object: NSObject, into lines: inout [String]) {
        if object.accessibilityElementsHidden { return }
        if object.isAccessibilityElement {
            lines.append(description(of: object))
            return
        }
        let count = object.accessibilityElementCount()
        if count != NSNotFound, count > 0 {
            for index in 0..<count {
                if let child = object.accessibilityElement(at: index) as? NSObject {
                    walk(child, into: &lines)
                }
            }
        } else if let children = object.accessibilityElements, !children.isEmpty {
            for case let child as NSObject in children {
                walk(child, into: &lines)
            }
        } else if let view = object as? UIView {
            for subview in view.subviews {
                walk(subview, into: &lines)
            }
        }
    }

    private static func description(of object: NSObject) -> String {
        let heading = object.accessibilityTraits.contains(.header) ? "[heading] " : ""
        let label = object.accessibilityLabel ?? ""
        guard let value = object.accessibilityValue, !value.isEmpty else { return heading + label }
        return "\(heading)\(label) | \(value)"
    }
}
#endif
