import SwiftUI

@main
struct ContributionChartExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 800)
        #endif
    }
}
