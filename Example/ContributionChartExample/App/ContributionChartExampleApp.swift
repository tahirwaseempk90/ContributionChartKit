import SwiftUI

@main
struct ContributionChartExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                // A window takes its first size from its content, and the charts need room.
                .frame(minWidth: 820, idealWidth: 1100, minHeight: 620, idealHeight: 820)
                #endif
        }
    }
}
