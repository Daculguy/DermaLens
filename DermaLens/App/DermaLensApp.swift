import SwiftUI

@main
struct DermaLensApp: App {
    @StateObject private var appState: AppState

    init() {
        Self.prepareForUITestingIfNeeded()
        _appState = StateObject(wrappedValue: AppState(configuration: .current, seedPreviewData: false))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
        }
    }

    private static func prepareForUITestingIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-dermalensUITesting"),
              arguments.contains("-dermalensResetLocalData"),
              let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return
        }

        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
    }
}
