import SwiftUI

struct ZeroBaseline: View {
    let color: Color
    let width: CGFloat
    var body: some View {
        Rectangle().fill(color).frame(height: max(0.5, width))
            .accessibilityHidden(true)
    }
}
