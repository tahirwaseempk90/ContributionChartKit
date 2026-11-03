import SwiftUI

struct DataPointStem: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        Rectangle().fill(color.opacity(0.22))
            .frame(width: max(0.5, width), height: max(0, height))
            .accessibilityHidden(true)
    }
}
