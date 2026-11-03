import SwiftUI
import ContributionChart

@main
struct ContributionChartExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleView()
        }
    }
}

struct ExampleView: View {
    private let sample: [ChartDataPoint] = [
        .init(id: "vfiax", title: "VFIAX", value: 11.05),
        .init(id: "vtnix", title: "VTNIX", value: 6.31),
        .init(id: "vtsax", title: "VTSAX", value: -2.70)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Your biggest contributors & detractors")
                        .font(.headline)
                    ContributionChart(points: sample)
                        .frame(height: 300)
                        .padding()
                        .background(Color.yellow.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))

                    Text("Compact")
                        .font(.headline)
                    ContributionChart(points: sample)
                        .frame(height: 190)
                        .padding()
                        .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Chart Example")
        }
    }
}
