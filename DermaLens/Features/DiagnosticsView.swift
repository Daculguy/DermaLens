import SwiftUI

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    scanDiagnostics
                    productDiagnostics
                    appDiagnostics
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Diagnostics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beta diagnostics")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Use this during TestFlight to verify scan confidence, local persistence, and paywall wiring without exposing raw photos.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard(padding: 16)
    }

    private var scanDiagnostics: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Latest scan", subtitle: "Structured report state saved on this device.")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DiagnosticTile(title: "Reports", value: "\(appState.scanHistory.count)", symbolName: "doc.text", tint: Theme.moss)
                DiagnosticTile(title: "Confidence", value: appState.hasCompletedScan ? appState.latestReport.evidenceSummary.confidenceLevel(for: appState.latestReport.scanQuality).label : "No scan", symbolName: "checkmark.seal", tint: appState.hasCompletedScan ? Theme.leaf : Theme.amber)
                DiagnosticTile(title: "Quality", value: appState.hasCompletedScan ? "\(Int(appState.latestReport.scanQuality.average * 100))" : "0", symbolName: "camera.metering.center.weighted", tint: Theme.amber)
                DiagnosticTile(title: "Evidence", value: appState.hasCompletedScan ? appState.latestReport.evidenceSummary.coverageLabel : "0/5 guided captures", symbolName: "camera.viewfinder", tint: appState.hasCompletedScan ? Theme.leaf : Theme.amber)
                DiagnosticTile(title: "Analyzer source", value: appState.hasCompletedScan ? appState.latestReport.analysisMetadata.title : "None", symbolName: "network", tint: Theme.lavender)
                DiagnosticTile(title: "Analyzer fallback", value: appState.hasCompletedScan && appState.latestReport.analysisMetadata.usedFallback ? "Yes" : "No", symbolName: "arrow.triangle.2.circlepath", tint: appState.hasCompletedScan && appState.latestReport.analysisMetadata.usedFallback ? Theme.amber : Theme.leaf)
                DiagnosticTile(title: "Blocks", value: appState.hasCompletedScan ? "\(appState.latestReport.scanQuality.blockingIssues.count)" : "0", symbolName: "exclamationmark.triangle", tint: Theme.coral)
                DiagnosticTile(title: "Ingredient flags", value: "\(appState.ingredientFindings.filter { $0.severity != .info }.count)", symbolName: "cross.case", tint: Theme.lavender)
                DiagnosticTile(title: "Reminders", value: appState.routineReminderStatus.title, symbolName: appState.routineReminderStatus.symbolName, tint: Theme.moss)
                DiagnosticTile(title: "Today done", value: appState.routineAdherenceSummary.progressLabel, symbolName: "checkmark.square", tint: Theme.leaf)
                DiagnosticTile(title: "Shelf items", value: "\(appState.productShelfState.items.count)", symbolName: "shippingbox", tint: Theme.amber)
                DiagnosticTile(title: "Custom products", value: "\(appState.customProducts.count)", symbolName: "plus.app", tint: Theme.moss)
                DiagnosticTile(title: "Journal notes", value: "\(appState.progressJournalEntries.count)", symbolName: "note.text", tint: Theme.lavender)
            }
        }
    }

    private var productDiagnostics: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recommendation state")

            VStack(alignment: .leading, spacing: 10) {
                Label("Routine steps: \(appState.routinePlan.steps.count)", systemImage: "checklist")
                Label("Adherence records: \(appState.routineCompletionRecords.count)", systemImage: "calendar.badge.checkmark")
                Label("Routine streak: \(appState.routineAdherenceSummary.streakLabel)", systemImage: "chart.bar")
                Label("Owned/using products: \(appState.productShelfSummary.ownedCount + appState.productShelfSummary.usingCount)", systemImage: "shippingbox")
                Label("Custom products: \(appState.customProducts.count)", systemImage: "plus.app")
                Label("Avoided products: \(appState.productShelfSummary.avoidedCount)", systemImage: "nosign")
                Label("Journal notes: \(appState.progressJournalEntries.count)", systemImage: "note.text")
                Label("Recent notes: \(appState.progressJournalSummary.recentLabel)", systemImage: "calendar")
                Label("Captured regions: \(capturedRegionLabel)", systemImage: "camera.viewfinder")
                Label("Goals: \(appState.userProfile.currentGoals.map(\.shortTitle).sorted().joined(separator: ", "))", systemImage: "target")
                Label("Skin feel: \(appState.userProfile.baselineSkinFeel.title)", systemImage: appState.userProfile.baselineSkinFeel.symbolName)
                Label("Routine style: \(appState.userProfile.routineComplexity.title)", systemImage: "slider.horizontal.3")
                Label("Ingredient flags: \(ingredientFlagLabel)", systemImage: "exclamationmark.triangle")
                Label("Retinoids: \(appState.userProfile.retinoidSafetyContext.title)", systemImage: "cross.case")
                Label("Avoids fragrance: \(appState.userProfile.avoidsFragrance ? "Yes" : "No")", systemImage: "nose")
                Label("Avoids retinoids: \(appState.userProfile.avoidsRetinoids ? "Yes" : "No")", systemImage: "exclamationmark.shield")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .softCard(padding: 14)
        }
    }

    private var appDiagnostics: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "App wiring")

            VStack(alignment: .leading, spacing: 10) {
                Label("Premium entitlement: \(subscriptionManager.isPremium ? "Active" : "Inactive")", systemImage: subscriptionManager.isPremium ? "checkmark.seal" : "lock")
                Label("StoreKit products loaded: \(subscriptionManager.storeProducts.count)", systemImage: "creditcard")
                Label("Analyzer: \(appState.analyzerMode.title)", systemImage: "network")
                Label("Report source: \(appState.hasCompletedScan ? appState.latestReport.analysisMetadata.providerName : "No report")", systemImage: "server.rack")
                Label("Model version: \(appState.hasCompletedScan ? appState.latestReport.analysisMetadata.modelVersion : "No report")", systemImage: "number")
                Label("Validation: \(appState.hasCompletedScan ? appState.latestReport.analysisMetadata.validationStatus.title : "No report")", systemImage: "checkmark.seal")
                Label("Request ID: \(appState.hasCompletedScan ? appState.latestReport.analysisMetadata.requestID ?? "None" : "No report")", systemImage: "number.square")
                Label("Report privacy: \(appState.hasCompletedScan ? appState.latestReport.analysisMetadata.privacyLabel : "No scan data yet")", systemImage: "hand.raised")
                Label("Remote host: \(appState.remoteAnalyzerHost ?? "Not configured")", systemImage: "server.rack")
                Label("Remote upload consent: \(remoteConsentLabel)", systemImage: appState.remoteAnalysisConsentGranted ? "checkmark.shield" : "hand.raised")
                Label("Fallback to local: \(appState.remoteAnalyzerFallbacksToLocal ? "Yes" : "No")", systemImage: "arrow.triangle.2.circlepath")
                Label("Raw photos persisted: No", systemImage: "photo.badge.checkmark")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .softCard(padding: 14)
        }
    }

    private var ingredientFlagLabel: String {
        let flags = appState.userProfile.knownIrritants.map(\.title).sorted()
        return flags.isEmpty ? "None" : flags.joined(separator: ", ")
    }

    private var capturedRegionLabel: String {
        guard appState.hasCompletedScan else { return "None" }
        let regions = appState.latestReport.evidenceSummary.coveredRegions.map(\.label)
        return regions.isEmpty ? "None" : regions.joined(separator: ", ")
    }

    private var remoteConsentLabel: String {
        guard appState.isRemoteAnalysisConfigured else { return "Not configured" }
        return appState.remoteAnalysisConsentGranted ? "Granted" : "Off"
    }
}

private struct DiagnosticTile: View {
    var title: String
    var value: String
    var symbolName: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .font(.headline.weight(.semibold))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard(padding: 14)
    }
}

#Preview {
    DiagnosticsView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.preview())
}
