import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var privacyLock: PrivacyLockManager
    @State private var journalSheet: JournalSheetContext?

    var body: some View {
        NavigationStack {
            ScrollView {
                if appState.hasCompletedScan {
                    dashboardContent
                } else {
                    preScanHome
                }
            }
            .appBackground()
            .navigationTitle("DermaLens")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            privacyLock.lock()
                        } label: {
                            Label("Lock journal now", systemImage: "lock.shield")
                        }

                        Button {
                            appState.showingPrivacyCenter = true
                        } label: {
                            Label("Privacy center", systemImage: "hand.raised")
                        }

                        Button {
                            appState.showingDiagnostics = true
                        } label: {
                            Label("Beta diagnostics", systemImage: "stethoscope")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel("Open app menu")
                }

                if appState.hasCompletedScan {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            appState.showingPaywall = true
                        } label: {
                            Image(systemName: subscriptionManager.isPremium ? "checkmark.seal.fill" : "lock.open")
                        }
                        .accessibilityLabel(subscriptionManager.isPremium ? "Premium active" : "Open premium")
                    }
                }
            }
            .sheet(item: $journalSheet) { context in
                JournalEntrySheet(report: context.report)
                    .environmentObject(appState)
                    .presentationDetents([.large])
            }
        }
    }

    private var dashboardContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            hero
            scanStatus
            prioritySection
            routinePreview
            todayCheckIn
            trustSection
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }

    private var preScanHome: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                Label("Baseline required", systemImage: "viewfinder")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.moss)
                    .textCase(.uppercase)

                Text("Start your baseline scan")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your profile is saved. DermaLens does not create a report, routine, or product picks until the guided pass captures fresh frames for all five regions.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(
                    title: "Start guided scan",
                    symbolName: "camera.viewfinder",
                    action: { appState.selectedTab = .scan }
                )
            }
            .softCard(padding: 18)

            preScanStatus
            preScanChecklist
            trustSection
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }

    private var preScanStatus: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricPill(title: "Profile", value: "Saved", symbolName: "person.crop.circle", tint: Theme.leaf)
            MetricPill(title: "Report", value: "Not created", symbolName: "doc.text.magnifyingglass", tint: Theme.amber)
            MetricPill(title: "Evidence", value: "0/5 captures", symbolName: "camera.badge.ellipsis", tint: Theme.amber)
            MetricPill(title: "Routine", value: "Waiting", symbolName: "checklist", tint: Theme.moss)
        }
        .softCard(padding: 14)
    }

    private var preScanChecklist: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "What happens next",
                subtitle: "One complete capture unlocks the real dashboard."
            )

            VStack(alignment: .leading, spacing: 10) {
                Label("Forehead, both cheeks, T-zone, and chin are required.", systemImage: "face.smiling")
                Label("No demo report or routine is used before this capture.", systemImage: "checkmark.shield")
                Label("Face ID is not used; the front camera only guides framing.", systemImage: "camera.viewfinder")
                Label("Raw camera frames are short-lived and not saved to local history.", systemImage: "trash")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .labelStyle(.titleAndIcon)
            .softCard(padding: 14)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Visible-skin scan")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.moss)
                        .textCase(.uppercase)
                    Text("A clearer routine, without pretending a selfie is a doctor.")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(heroSummary)
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 12) {
                Button {
                    appState.selectedTab = .scan
                } label: {
                    Label("Start scan", systemImage: "viewfinder")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.moss)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    appState.selectedTab = .routine
                } label: {
                    Image(systemName: "checklist")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.moss)
                        .frame(width: 52, height: 50)
                        .background(Theme.moss.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open routine")
            }
        }
        .softCard(padding: 18)
    }

    private var scanStatus: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricPill(
                title: "Scan quality",
                value: appState.latestReport.evidenceSummary.confidenceLevel(for: appState.latestReport.scanQuality).label,
                symbolName: "camera.metering.center.weighted",
                tint: Theme.leaf
            )

            MetricPill(
                title: "Evidence",
                value: appState.latestReport.evidenceSummary.coverageLabel,
                symbolName: appState.latestReport.evidenceSummary.isComplete ? "camera.viewfinder" : "camera.badge.ellipsis",
                tint: appState.latestReport.evidenceSummary.isComplete ? Theme.leaf : Theme.amber
            )

            MetricPill(
                title: "Premium",
                value: subscriptionManager.isPremium ? "Unlocked" : "Preview",
                symbolName: subscriptionManager.isPremium ? "checkmark.seal" : "lock",
                tint: subscriptionManager.isPremium ? Theme.leaf : Theme.amber
            )
        }
        .softCard(padding: 14)
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Top priorities",
                subtitle: "Ranked by visible concern score and scan confidence",
                actionTitle: "Details",
                action: { appState.selectedTab = .results }
            )

            HStack(spacing: 12) {
                ForEach(appState.latestReport.topConcerns) { score in
                    VStack(spacing: 10) {
                        ScoreRing(
                            score: score.score,
                            tint: Theme.concernColor(score.concern),
                            label: score.concern.shortTitle
                        )
                        Text(score.primaryRegion.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var routinePreview: some View {
        let summary = appState.routineAdherenceSummary

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Tonight's plan",
                subtitle: "\(summary.progressLabel) routine steps done today",
                actionTitle: "Open",
                action: { appState.selectedTab = .routine }
            )

            VStack(spacing: 12) {
                ProgressView(value: summary.completionRatio)
                    .tint(summary.isComplete ? Theme.leaf : Theme.moss)

                ForEach(appState.routinePlan.steps(for: .evening).prefix(3)) { step in
                    let isComplete = appState.isRoutineStepCompleted(step)
                    HStack(spacing: 12) {
                        Image(systemName: isComplete ? "checkmark" : "\(step.order).circle")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(isComplete ? .white : Theme.moss)
                            .frame(width: 34, height: 34)
                            .background(isComplete ? Theme.leaf : Theme.moss.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.category.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.muted)
                            Text(step.product.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.ink)
                        }

                        Spacer()
                    }
                }
            }
            .softCard(padding: 14)
        }
    }

    private var heroSummary: String {
        appState.latestReport.summary
    }

    private var todayCheckIn: some View {
        let latestEntry = appState.latestJournalEntryForToday
        let linkedReport = appState.scanHistory.first

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Today's check-in",
                subtitle: latestEntry == nil ? "Add context your scan cannot see." : "\(appState.progressJournalSummary.recentLabel) logged",
                actionTitle: "Add",
                action: { journalSheet = JournalSheetContext(report: linkedReport) }
            )

            if let latestEntry {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: latestEntry.skinFeel.symbolName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                        .frame(width: 38, height: 38)
                        .background(Theme.moss.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(latestEntry.skinFeel.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.ink)
                        Text(latestEntry.note.isEmpty ? "No note added" : latestEntry.note)
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .softCard(padding: 14)
            } else {
                VStack(alignment: .leading, spacing: 9) {
                    Label(linkedReport == nil ? "Add an unlinked note" : "Link a note to your latest scan", systemImage: "note.text")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text("Track skin feel, routine comfort, and context like sleep, travel, or new products.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .softCard(padding: 14)
            }
        }
    }

    private var trustSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Trust model",
                subtitle: "What the app uses and what it refuses to claim"
            )

            VStack(alignment: .leading, spacing: 10) {
                Label("Face ID data is not accessed. Camera framing guidance only helps capture quality.", systemImage: "camera.viewfinder")
                Label("Journal lock is \(privacyLock.isJournalLockEnabled ? "on" : "optional") and only gates access to private app data.", systemImage: privacyLock.biometrySymbolName)
                Label("Recommendations explain ingredients and confidence instead of hiding behind an AI score.", systemImage: "text.magnifyingglass")
                Label("Medical diagnosis language is intentionally avoided in this version.", systemImage: "cross.case")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .labelStyle(.titleAndIcon)
            .softCard(padding: 14)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.preview())
        .environmentObject(PrivacyLockManager())
}

#Preview("No scan") {
    HomeView()
        .environmentObject(AppState(seedPreviewData: false))
        .environmentObject(SubscriptionManager.preview())
        .environmentObject(PrivacyLockManager())
}
