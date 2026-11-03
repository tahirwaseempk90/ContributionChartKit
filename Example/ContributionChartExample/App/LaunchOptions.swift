import SwiftUI

/// The colour scheme the app forces, if any.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Launch arguments that let UI tests and screenshot runs open a specific state directly,
/// for example `-scenario reference -appearance dark`. They read from `UserDefaults`, which
/// picks up command-line arguments automatically.
enum LaunchOptions {
    static var scenario: ExampleScenario? {
        UserDefaults.standard.string(forKey: "scenario").flatMap(ExampleScenario.init(rawValue:))
    }

    static var appearance: AppAppearance {
        UserDefaults.standard.string(forKey: "appearance").flatMap(AppAppearance.init(rawValue:)) ?? .system
    }

    /// See `VoiceOverTreeProbe`.
    static var exposesVoiceOverTree: Bool {
        UserDefaults.standard.bool(forKey: "exposeVoiceOverTree")
    }
}
