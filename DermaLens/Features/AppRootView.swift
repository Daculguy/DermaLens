import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var privacyLock = PrivacyLockManager()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.symbolName) }
                .tag(AppTab.home)

            GuidedScanView()
                .tabItem { Label(AppTab.scan.title, systemImage: AppTab.scan.symbolName) }
                .tag(AppTab.scan)

            ResultsView()
                .tabItem { Label(AppTab.results.title, systemImage: AppTab.results.symbolName) }
                .tag(AppTab.results)

            RoutineView()
                .tabItem { Label(AppTab.routine.title, systemImage: AppTab.routine.symbolName) }
                .tag(AppTab.routine)

            ShelfView()
                .tabItem { Label(AppTab.shelf.title, systemImage: AppTab.shelf.symbolName) }
                .tag(AppTab.shelf)
        }
        .tint(Theme.moss)
        .environmentObject(subscriptionManager)
        .environmentObject(privacyLock)
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                privacyLock.lockIfEnabled()
            }
        }
        .overlay {
            if privacyLock.isLocked {
                PrivacyLockView()
                    .environmentObject(privacyLock)
            }
        }
        .sheet(isPresented: $appState.showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $appState.showingPrivacyCenter) {
            PrivacyCenterView()
                .environmentObject(appState)
                .environmentObject(privacyLock)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $appState.showingDiagnostics) {
            DiagnosticsView()
                .environmentObject(appState)
                .environmentObject(subscriptionManager)
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            OnboardingView()
                .environmentObject(appState)
                .interactiveDismissDisabled(true)
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !appState.hasCompletedOnboarding },
            set: { _ in }
        )
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppState())
}
