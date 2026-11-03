import SwiftUI

/// A scrolling page of demonstration cards.
struct ExamplePage<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.gray.opacity(0.12))
        .inlineNavigationTitle(title)
    }
}

/// A titled card. The chart supplies no background of its own, so each card gives it one.
struct ExampleCard<Content: View, Background: ShapeStyle>: View {
    let title: String
    var detail: String?
    let background: Background
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(background, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

extension ExampleCard where Background == BackgroundStyle {
    init(title: String, detail: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, detail: detail, background: BackgroundStyle(), content: content)
    }
}

extension View {
    /// Uses the compact title style where there is one.
    @ViewBuilder func inlineNavigationTitle(_ title: String) -> some View {
        #if os(iOS)
        navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        #else
        navigationTitle(title)
        #endif
    }
}
