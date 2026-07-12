import SwiftUI

struct PrivacyCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var privacyLock: PrivacyLockManager
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    storageSummary
                    journalLock
                    analysisTransfer
                    promises
                    legalSection
                    exportSection
                    deleteSection
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Privacy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete local DermaLens data?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete local data", role: .destructive) {
                    privacyLock.setJournalLockEnabled(false)
                    appState.deleteAllLocalData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes saved profile choices, reports, journal notes, routine completion history, routine reminders, and the journal-lock preference on this device.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your face data deserves boring honesty.")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("This prototype stores profile choices and generated scan reports locally with UserDefaults. Production cloud analysis should require explicit opt-in and short media retention.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard(padding: 16)
    }

    private var storageSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Stored locally", subtitle: "Current on-device prototype state")

            HStack(spacing: 12) {
                MetricPill(title: "Reports", value: "\(appState.scanHistory.count)", symbolName: "doc.text.magnifyingglass", tint: Theme.moss)
                MetricPill(title: "Photos", value: "Not saved", symbolName: "photo", tint: Theme.leaf)
            }
            .softCard(padding: 14)

            HStack {
                MetricPill(
                    title: "Routine",
                    value: appState.routineAdherenceSummary.progressLabel,
                    symbolName: "checkmark.square",
                    tint: Theme.leaf
                )
                Spacer()
            }
            .softCard(padding: 14)

            HStack {
                MetricPill(
                    title: "Shelf",
                    value: "\(appState.productShelfState.items.count) items, \(appState.customProducts.count) custom",
                    symbolName: "shippingbox",
                    tint: Theme.amber
                )
                Spacer()
            }
            .softCard(padding: 14)

            HStack {
                MetricPill(
                    title: "Journal",
                    value: "\(appState.progressJournalEntries.count) notes",
                    symbolName: "note.text",
                    tint: Theme.lavender
                )
                Spacer()
            }
            .softCard(padding: 14)

            HStack {
                MetricPill(
                    title: "Reminders",
                    value: appState.routineReminderStatus.title,
                    symbolName: appState.routineReminderStatus.symbolName,
                    tint: Theme.moss
                )
                Spacer()
            }
            .softCard(padding: 14)
        }
    }

    private var promises: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Trust boundaries")

            VStack(alignment: .leading, spacing: 10) {
                Label("Face ID is only for unlocking the private journal.", systemImage: "faceid")
                Label("The app does not receive enrolled Face ID templates.", systemImage: "lock.shield")
                Label("Scan results are cosmetic guidance and not medical diagnosis.", systemImage: "cross.case")
                Label("See a clinician for painful, changing, bleeding, suspicious, or urgent skin concerns.", systemImage: "exclamationmark.triangle")
                Label("Raw camera frames are not persisted in this prototype.", systemImage: "camera")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .softCard(padding: 14)
        }
    }

    private var journalLock: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Journal lock", subtitle: "Optional device authentication for private reports and notes.")

            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: journalLockBinding) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Require \(privacyLock.biometryLabel) or passcode")
                            .font(.subheadline.weight(.semibold))
                        Text("When enabled, DermaLens locks on launch and when the app leaves the foreground.")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.moss)

                Label("This protects access to reports, routines, and journal notes. It is not used to analyze your skin.", systemImage: privacyLock.biometrySymbolName)
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .softCard(padding: 14)
        }
    }

    private var journalLockBinding: Binding<Bool> {
        Binding(
            get: { privacyLock.isJournalLockEnabled },
            set: { privacyLock.setJournalLockEnabled($0) }
        )
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Policies", subtitle: "Bundled draft text for beta review.")
            LegalDocumentLinks()
        }
    }

    private var analysisTransfer: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Analysis transfer", subtitle: appState.isRemoteAnalysisConfigured ? "Remote analyzer is configured for this build." : "This build is local-only.")

            VStack(alignment: .leading, spacing: 10) {
                if appState.isRemoteAnalysisConfigured {
                    Toggle(isOn: remoteAnalysisConsentBinding) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Allow scan-frame upload")
                                .font(.subheadline.weight(.semibold))
                            Text(remoteConsentDetail)
                                .font(.caption)
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    .tint(Theme.moss)

                    Label("Turning this off keeps future scans on device with the prototype analyzer.", systemImage: "hand.raised")
                } else {
                    Label("No remote analyzer endpoint is configured.", systemImage: "checkmark.shield")
                    Label("Guided scan frames stay local and are not saved in scan history.", systemImage: "photo.badge.checkmark")
                }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .softCard(padding: 14)
        }
    }

    private var remoteAnalysisConsentBinding: Binding<Bool> {
        Binding(
            get: { appState.remoteAnalysisConsentGranted },
            set: { appState.setRemoteAnalysisConsent($0) }
        )
    }

    private var remoteConsentDetail: String {
        RemoteAnalysisDisclosure.consentDetail(host: appState.remoteAnalyzerHost)
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Export", subtitle: "Share a structured copy of the local prototype data.")

            VStack(alignment: .leading, spacing: 10) {
                Label("Includes profile choices, generated reports, routine state, shelf statuses, and journal notes.", systemImage: "doc.text")
                Label("Excludes raw camera frames, saved face photos, Face ID templates, and payment details.", systemImage: "eye.slash")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .softCard(padding: 14)

            ShareLink(
                item: appState.privacyExportText,
                subject: Text("DermaLens privacy export"),
                message: Text("Structured local data export from DermaLens.")
            ) {
                Label("Export local data", systemImage: "square.and.arrow.up")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.moss)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Reset")

            Text("Delete local data before handing the phone to someone else, changing test accounts, or starting a clean beta run. This also clears journal notes, routine completion history, and cancels DermaLens routine reminders.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete local data", systemImage: "trash")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.coral)
        }
    }
}

#Preview {
    PrivacyCenterView()
        .environmentObject(AppState())
        .environmentObject(PrivacyLockManager())
}
