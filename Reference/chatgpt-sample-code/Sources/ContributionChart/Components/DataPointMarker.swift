import SwiftUI

struct DataPointMarker: View {
    let color: Color
    let size: CGFloat
    var body: some View {
        Circle().fill(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
