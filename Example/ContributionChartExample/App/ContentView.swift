import SwiftUI

/// The sidebar of scenarios. It collapses to a push navigation stack on iPhone.
struct ContentView: View {
    @State private var selection = LaunchOptions.scenario
    @State private var appearance = LaunchOptions.appearance

    var body: some View {
        NavigationSplitView {
            List(ExampleScenario.allCases, selection: $selection) { scenario in
                NavigationLink(value: scenario) {
                    Label(scenario.title, systemImage: scenario.symbol)
                }
                .accessibilityIdentifier("scenario.\(scenario.rawValue)")
            }
            .navigationTitle("Examples")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AppearancePicker(selection: $appearance)
                }
            }
        } detail: {
            NavigationStack {
                if let selection {
                    selection.screen
                } else {
                    Text("Select a scenario")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .preferredColorScheme(appearance.colorScheme)
        #if canImport(UIKit)
        .overlay(alignment: .bottomTrailing) {
            if LaunchOptions.exposesVoiceOverTree {
                VoiceOverTreeProbe()
            }
        }
        #endif
    }
}

/// Switches between light and dark so that both can be checked side by side with the system.
private struct AppearancePicker: View {
    @Binding var selection: AppAppearance

    var body: some View {
        Menu {
            Picker("Appearance", selection: $selection) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }
        } label: {
            Label("Appearance", systemImage: "circle.lefthalf.filled")
        }
        .accessibilityIdentifier("appearance.menu")
    }
}
