import ContributionChart
import SwiftUI

/// The chart adapting to whatever frame and container it is given.
struct ResponsiveLayoutScreen: View {
    @State private var width: Double = 340
    @State private var height: Double = 240
    @State private var isShowingSheet = false

    var body: some View {
        ExamplePage(title: ExampleScenario.responsiveLayout.title) {
            resizableCard
            fixedSizesCard
            containersCard
            scrollingCard
        }
        .sheet(isPresented: $isShowingSheet) { sheetContent }
    }

    private var resizableCard: some View {
        ExampleCard(title: "Resize freely", detail: "Labels, then the title, drop away as the frame shrinks.") {
            VStack(spacing: 12) {
                labelledSlider("Width \(Int(width))", value: $width, range: 60...860, id: "responsive.width")
                labelledSlider("Height \(Int(height))", value: $height, range: 30...420, id: "responsive.height")
                chart(SampleData.mixed, title: "Resizable chart", id: "resizable")
                    .frame(maxWidth: width)
                    .frame(height: height)
                    .border(Color.secondary.opacity(0.4))
            }
        }
    }

    private func labelledSlider(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        id: String
    ) -> some View {
        HStack {
            Text(label)
                .font(.footnote.monospacedDigit())
                .frame(width: 96, alignment: .leading)
            Slider(value: value, in: range)
                .accessibilityIdentifier(id)
        }
    }

    private var fixedSizesCard: some View {
        ExampleCard(title: "Fixed frames", detail: "Compact, small, wide, and tall.") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    framed("compact", width: 110, height: 70)
                    framed("small", width: 180, height: 120)
                }
                framed("wide", width: nil, height: 110)
                framed("tall", width: 200, height: 320)
            }
        }
    }

    private func framed(_ id: String, width: CGFloat?, height: CGFloat) -> some View {
        chart(SampleData.contributors, id: id)
            .frame(width: width, height: height)
            .border(Color.secondary.opacity(0.4))
    }

    private var containersCard: some View {
        ExampleCard(title: "Inside containers", detail: "HStack, Grid, List, and a sheet.") {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    chart(SampleData.contributors, id: "hstack.left").frame(height: 170)
                    chart(SampleData.positiveOnly, id: "hstack.right").frame(height: 170)
                }
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        chart(SampleData.positiveOnly, id: "grid.a").frame(height: 150)
                        chart(SampleData.negativeOnly, id: "grid.b").frame(height: 150)
                    }
                }
                List {
                    // No height: a list row asks the chart for its ideal size.
                    chart(SampleData.contributors, title: "In a List", id: "list")
                }
                .frame(height: 340)
                Button("Show in a sheet") { isShowingSheet = true }
                    .accessibilityIdentifier("responsive.sheet")
            }
        }
    }

    private var scrollingCard: some View {
        ExampleCard(
            title: "Scrolling",
            detail: "With no width proposed, a dense chart picks a width that gives each point room."
        ) {
            ScrollView(.horizontal) {
                chart(SampleData.dense(count: 200), id: "horizontal-scroll")
                    .frame(height: 240)
            }
        }
    }

    private var sheetContent: some View {
        NavigationStack {
            chart(SampleData.mixed, title: "In a sheet", id: "sheet")
                .padding()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isShowingSheet = false }
                            .accessibilityIdentifier("responsive.sheet.done")
                    }
                }
        }
    }

    private func chart(_ points: [ChartDataPoint], title: String? = nil, id: String) -> some View {
        ContributionChart(
            points: points,
            title: title,
            configuration: ChartConfiguration().identified("chart.responsive.\(id)")
        )
    }
}

#Preview {
    NavigationStack { ResponsiveLayoutScreen() }
}
