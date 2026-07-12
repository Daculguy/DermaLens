import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var journalSheet: JournalSheetContext?
    private let premiumPolicy = PremiumAccessPolicy()
    private let progressComparisonEngine = ProgressComparisonEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if appState.hasCompletedScan {
                        reportHeader
                        analysisNotice
                        clinicianEscalationNotice
                        SkinMapView(report: appState.latestReport)
                        scanEvidence
                        priorities
                        progressHistory
                        journalSection
                        explanations
                        premiumPanel
                    } else {
                        NoScanInsightsState {
                            appState.selectedTab = .scan
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Insights")
            .sheet(item: $journalSheet) { context in
                JournalEntrySheet(report: context.report)
                    .environmentObject(appState)
                    .presentationDetents([.large])
            }
        }
    }

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Skin report")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text(appState.latestReport.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(width: 48, height: 48)
                    .background(Theme.moss.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Text(appState.latestReport.summary)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricPill(
                    title: "Confidence",
                    value: appState.latestReport.evidenceSummary.confidenceLevel(for: appState.latestReport.scanQuality).label,
                    symbolName: "checkmark.seal",
                    tint: Theme.leaf
                )

                MetricPill(
                    title: "Framing",
                    value: appState.latestReport.scanQuality.depthGuidanceAvailable ? "Assist on" : "Standard",
                    symbolName: "camera.viewfinder",
                    tint: Theme.moss
                )

                MetricPill(
                    title: "Evidence",
                    value: appState.latestReport.evidenceSummary.coverageLabel,
                    symbolName: appState.latestReport.evidenceSummary.isComplete ? "camera.viewfinder" : "camera.badge.ellipsis",
                    tint: appState.latestReport.evidenceSummary.isComplete ? Theme.leaf : Theme.amber
                )

                MetricPill(
                    title: "Analyzer",
                    value: appState.latestReport.analysisMetadata.title,
                    symbolName: appState.latestReport.analysisMetadata.usedFallback ? "arrow.triangle.2.circlepath" : "network",
                    tint: appState.latestReport.analysisMetadata.usedFallback ? Theme.amber : Theme.lavender
                )
            }
        }
        .softCard(padding: 16)
    }

    private var clinicianEscalationNotice: some View {
        AnalysisNoticeCard(
            title: "When to get human care",
            detail: "See a clinician promptly for painful, changing, bleeding, suspicious, infected, rapidly worsening, or urgent skin concerns. DermaLens is cosmetic guidance, not diagnosis.",
            symbolName: "cross.case",
            tint: Theme.coral
        )
    }

    @ViewBuilder
    private var analysisNotice: some View {
        let metadata = appState.latestReport.analysisMetadata

        switch metadata.kind {
        case .remote:
            if metadata.validationStatus == .internallyValidated {
                EmptyView()
            } else {
                AnalysisNoticeCard(
                    title: "Remote analyzer validation",
                    detail: "\(metadata.providerName) returned this report with \(metadata.validationStatus.title.lowercased()) validation. Treat recommendations as cosmetic guidance until validation evidence is reviewed.",
                    symbolName: "network",
                    tint: Theme.amber
                )
            }
        case .remoteFallback:
            AnalysisNoticeCard(
                title: "Remote analyzer unavailable",
                detail: "This report used local fallback analysis after \(metadata.providerName) failed. \(metadata.fallbackReason ?? "No failure reason was provided.") Treat the result as a provisional scan.",
                symbolName: "arrow.triangle.2.circlepath",
                tint: Theme.amber
            )
        case .remoteConsentNotGranted:
            AnalysisNoticeCard(
                title: "Scan stayed on device",
                detail: metadata.fallbackReason ?? "Remote analysis is configured, but scan-frame upload consent is off. This report used the local prototype analyzer.",
                symbolName: "hand.raised",
                tint: Theme.moss
            )
        case .simulatedLocal:
            AnalysisNoticeCard(
                title: "Prototype analyzer active",
                detail: "This report uses DermaLens' simulated local analyzer. It is useful for testing capture, routine, and paywall flows, but production should use a validated model or provider.",
                symbolName: "wrench.and.screwdriver",
                tint: Theme.lavender
            )
        case .legacy:
            AnalysisNoticeCard(
                title: "Legacy report",
                detail: "This saved report predates the current analyzer provenance fields. Rescan before making product changes from it.",
                symbolName: "clock.arrow.circlepath",
                tint: Theme.amber
            )
        }
    }

    private var priorities: some View {
        let metadata = appState.latestReport.analysisMetadata

        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Priority scores",
                subtitle: "\(metadata.scoreSourceLabel). Higher means more visible in this scan, not more medically serious."
            )

            ForEach(appState.latestReport.priorityScores) { score in
                ConcernRow(
                    score: score,
                    scoreSourceLabel: metadata.scoreSourceLabel
                )
            }
        }
    }

    private var scanEvidence: some View {
        let report = appState.latestReport
        let evidence = report.evidenceSummary

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Scan evidence",
                subtitle: "The report is limited by capture quality, guided-capture coverage, and analyzer source."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricPill(
                    title: "Frames",
                    value: "\(evidence.capturedFrameCount)",
                    symbolName: "photo.stack",
                    tint: Theme.moss
                )
                MetricPill(
                    title: "Guided",
                    value: evidence.coverageLabel,
                    symbolName: evidence.isComplete ? "camera.viewfinder" : "camera.badge.ellipsis",
                    tint: evidence.isComplete ? Theme.leaf : Theme.amber
                )
                MetricPill(
                    title: "Analyzer",
                    value: report.analysisMetadata.kind == .remote ? "Remote" : "Local",
                    symbolName: report.analysisMetadata.usedFallback ? "arrow.triangle.2.circlepath" : "network",
                    tint: report.analysisMetadata.usedFallback ? Theme.amber : Theme.lavender
                )
                MetricPill(
                    title: "Photos",
                    value: report.analysisMetadata.retainsImages ? "May retain" : "Not saved",
                    symbolName: report.analysisMetadata.retainsImages ? "photo.badge.exclamationmark" : "photo.badge.checkmark",
                    tint: report.analysisMetadata.retainsImages ? Theme.coral : Theme.leaf
                )
            }
            .softCard(padding: 14)

            VStack(spacing: 10) {
                ForEach(evidence.regionEvidence) { region in
                    RegionEvidenceRow(evidence: region)
                }
            }

            Label("Guided captures are fresh prompted frames, not Face ID or biometric region verification.", systemImage: "faceid")
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var explanations: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "What looks strong", subtitle: "Positive signals matter too.")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(appState.latestReport.visibleStrengths, id: \.self) { strength in
                    Label(strength, systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                }
            }
            .softCard(padding: 14)
        }
    }

    private var progressHistory: some View {
        let visibleReports = premiumPolicy.visibleReports(
            from: appState.scanHistory,
            isPremium: subscriptionManager.isPremium
        )
        let hiddenReportCount = premiumPolicy.hiddenReportCount(
            in: appState.scanHistory,
            isPremium: subscriptionManager.isPremium
        )
        let comparison = progressComparisonEngine.latestComparison(in: appState.scanHistory)

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Progress history",
                subtitle: "Saved local reports help compare trends without storing raw photos."
            )

            if appState.scanHistory.count < 2 {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Run another scan in similar lighting to compare scores.", systemImage: "calendar.badge.clock")
                    Label("DermaLens keeps the latest 12 reports on this device.", systemImage: "internaldrive")
                }
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .softCard(padding: 14)
            } else {
                VStack(spacing: 12) {
                    if subscriptionManager.isPremium, let comparison {
                        ProgressComparisonCard(comparison: comparison)
                    }

                    ForEach(visibleReports) { report in
                        HistoryRow(report: report)
                    }

                    if hiddenReportCount > 0 {
                        LockedUpsellCard(
                            title: "\(hiddenReportCount) more report\(hiddenReportCount == 1 ? "" : "s") hidden",
                            detail: "Premium unlocks progress comparisons across saved scans.",
                            action: { appState.showingPaywall = true }
                        )
                    }
                }
            }
        }
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Progress journal",
                subtitle: "Capture context the scan cannot see.",
                actionTitle: "Add",
                action: { journalSheet = JournalSheetContext(report: appState.latestReport) }
            )

            HStack(spacing: 12) {
                MetricPill(
                    title: "Notes",
                    value: "\(appState.progressJournalSummary.totalEntries)",
                    symbolName: "note.text",
                    tint: Theme.moss
                )
                Divider()
                    .frame(height: 42)
                MetricPill(
                    title: "Recent",
                    value: appState.progressJournalSummary.recentLabel,
                    symbolName: "calendar",
                    tint: Theme.leaf
                )
            }
            .softCard(padding: 14)

            let latestEntry = appState.progressJournalSummary.latestEntry
            if let latestEntry {
                JournalEntryRow(entry: latestEntry, delete: {
                    appState.deleteProgressJournalEntry(latestEntry)
                })
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Label("No notes yet", systemImage: "note.text")
                        .font(.headline.weight(.bold))
                    Text("Add a short note after scans or routine changes so score shifts have real-world context.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Theme.ink)
                .softCard(padding: 14)
            }

            let linkedEntries = appState.journalEntries(for: appState.latestReport).filter { entry in
                entry.id != latestEntry?.id
            }
            if !linkedEntries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("For this report")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.muted)
                    ForEach(linkedEntries.prefix(2)) { entry in
                        JournalEntryRow(entry: entry, delete: {
                            appState.deleteProgressJournalEntry(entry)
                        })
                    }
                }
            }
        }
    }

    private var premiumPanel: some View {
        let visibleFindings = premiumPolicy.visibleIngredientFindings(
            from: appState.ingredientFindings,
            isPremium: subscriptionManager.isPremium
        )
        let hiddenFindingCount = premiumPolicy.hiddenIngredientFindingCount(
            in: appState.ingredientFindings,
            isPremium: subscriptionManager.isPremium
        )

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Ingredient report", subtitle: subscriptionManager.isPremium ? "Premium analysis is unlocked." : "Free keeps safety findings visible and previews one deeper finding.")

            if !visibleFindings.isEmpty {
                VStack(spacing: 12) {
                    ForEach(visibleFindings) { finding in
                        IngredientFindingCard(
                            finding: finding,
                            relatedProducts: relatedProducts(for: finding)
                        )
                    }
                }
            }

            if hiddenFindingCount > 0 {
                LockedUpsellCard(
                    title: "\(hiddenFindingCount) deeper finding\(hiddenFindingCount == 1 ? "" : "s") locked",
                    detail: "Premium unlocks full ingredient reasoning, product alternatives, and progress comparisons.",
                    action: { appState.showingPaywall = true }
                )
            } else if !subscriptionManager.isPremium {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unlock ingredient-level reasoning, product alternatives by budget, and progress comparisons.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                    PrimaryButton(title: "View premium", symbolName: "lock.open") {
                        appState.showingPaywall = true
                    }
                }
                .softCard(padding: 14)
            }
        }
    }

    private func relatedProducts(for finding: IngredientCompatibilityFinding) -> [SkincareProduct] {
        finding.relatedProductIDs.compactMap { productID in
            guard let product = appState.productCatalog.first(where: { $0.id == productID }) else {
                return nil
            }
            return product
        }
    }
}

private struct IngredientFindingCard: View {
    var finding: IngredientCompatibilityFinding
    var relatedProducts: [SkincareProduct]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: finding.severity.symbolName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(finding.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Theme.ink)
                        Text(finding.severity.title)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(tint.opacity(0.10))
                            .clipShape(Capsule())
                    }

                    Text(finding.detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Label(finding.recommendation, systemImage: "arrow.turn.down.right")
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            if !relatedProducts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Related product context")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.muted)

                    ForEach(relatedProducts) { product in
                        RelatedProductTrustRow(product: product)
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }
        .softCard(padding: 14)
    }

    private var tint: Color {
        switch finding.severity {
        case .info: Theme.leaf
        case .caution: Theme.amber
        case .warning: Theme.coral
        }
    }
}

private struct RelatedProductTrustRow: View {
    var product: SkincareProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.brand)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                    Text(product.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Text(product.category.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.moss)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Theme.moss.opacity(0.09))
                    .clipShape(Capsule())
            }

            ProductTrustChips(product: product, compact: true)
            ProductTrustSummaryView(summary: product.trustSummary, compact: true)
            ProductSourceDisclosureView(metadata: product.sourceMetadata, compact: true)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var accessibilityLabel: String {
        let summary = product.trustSummary
        return [
            "\(product.brand) \(product.name)",
            product.disclosureSummary,
            "Trust \(summary.headline)",
            "Score \(summary.score)"
        ].joined(separator: ", ")
    }
}

private struct AnalysisNoticeCard: View {
    var title: String
    var detail: String
    var symbolName: String
    var tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .softCard(padding: 14)
    }
}

private struct NoScanInsightsState: View {
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("No report yet", systemImage: "sparkle.magnifyingglass")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Complete a guided scan before DermaLens shows concern scores, region maps, progress comparisons, or ingredient reasoning.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Label("No demo report is used for your real baseline.", systemImage: "checkmark.shield")
                Label("Scan quality and evidence coverage will appear here after capture.", systemImage: "camera.viewfinder")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)

            PrimaryButton(title: "Start guided scan", symbolName: "camera.viewfinder", action: action)
        }
        .softCard(padding: 16)
    }
}

private struct LockedUpsellCard: View {
    var title: String
    var detail: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(width: 36, height: 36)
                    .background(Theme.moss.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            PrimaryButton(title: "View premium", symbolName: "lock.open", action: action)
        }
        .softCard(padding: 14)
    }
}

struct JournalSheetContext: Identifiable, Hashable {
    var report: SkinReport?
    var id: String { report?.id.uuidString ?? "unlinked" }
}

struct JournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    var report: SkinReport?
    @State private var skinFeel: JournalSkinFeel = .calm
    @State private var comfortRating = 3
    @State private var selectedTags: Set<JournalContextTag> = []
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    feelPicker
                    tagPicker
                    noteEditor
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        appState.addProgressJournalEntry(
                            skinFeel: skinFeel,
                            tags: selectedTags,
                            note: note,
                            linkedReport: report,
                            comfortRating: comfortRating
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Report context")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text(report?.createdAt.formatted(date: .abbreviated, time: .shortened) ?? "Unlinked note")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
            Text("Journal notes stay on this device and are for personal context. They do not change scan scores or provide medical diagnosis.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard(padding: 16)
    }

    private var feelPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "How skin felt", subtitle: "Choose the closest non-medical description.")

            Picker("Skin feel", selection: $skinFeel) {
                ForEach(JournalSkinFeel.allCases) { feel in
                    Label(feel.title, systemImage: feel.symbolName)
                    .tag(feel)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.moss)
            .softCard(padding: 14)

            Stepper(value: $comfortRating, in: 1...5) {
                Label("Routine comfort \(comfortRating)/5", systemImage: "hand.thumbsup")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
            }
            .softCard(padding: 14)
        }
    }

    private var tagPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Context tags", subtitle: "Optional clues that may explain changes.")

            FlowLayout(spacing: 8) {
                ForEach(JournalContextTag.allCases) { tag in
                    JournalTagButton(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        action: { toggle(tag) }
                    )
                }
            }
            .softCard(padding: 14)
        }
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Note", subtitle: "Short, private, and stored on this device.")

            TextEditor(text: $note)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .frame(minHeight: 120)
                .padding(10)
                .background(Color.white.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.moss.opacity(0.16), lineWidth: 1)
                )

            Text("\(min(note.count, 280))/280")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
        }
        .softCard(padding: 14)
        .onChange(of: note) { _, newValue in
            if newValue.count > 280 {
                note = String(newValue.prefix(280))
            }
        }
    }

    private func toggle(_ tag: JournalContextTag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

private struct JournalTagButton: View {
    var tag: JournalContextTag
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(tag.title, systemImage: tag.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Theme.moss)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.moss : Theme.moss.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct JournalEntryRow: View {
    var entry: ProgressJournalEntry
    var delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: entry.skinFeel.symbolName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(width: 36, height: 36)
                    .background(Theme.moss.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.skinFeel.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()

                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete journal entry")
            }

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let comfortRating = entry.comfortRating {
                Label("Routine comfort \(comfortRating)/5", systemImage: "hand.thumbsup")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.leaf)
            }

            if !entry.tags.isEmpty {
                FlowLayout(spacing: 7) {
                    ForEach(entry.tags.sorted { $0.title < $1.title }) { tag in
                        Text(tag.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.moss)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Theme.moss.opacity(0.09))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .softCard(padding: 14)
    }
}

private struct ConcernRow: View {
    var score: ConcernScore
    var scoreSourceLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: score.concern.symbolName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.concernColor(score.concern))
                    .frame(width: 38, height: 38)
                    .background(Theme.concernColor(score.concern).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(score.concern.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text("\(score.severityLabel) - \(score.confidence.label) - \(score.primaryRegion.label)")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()

                Text("\(score.score)")
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(Theme.ink)
            }

            ProgressView(value: Double(score.score), total: 100)
                .tint(Theme.concernColor(score.concern))

            Text(score.explanation)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Label(scoreSourceLabel, systemImage: "slider.horizontal.3")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard(padding: 14)
    }
}

private struct RegionEvidenceRow: View {
    var evidence: ScanRegionEvidence

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(evidence.region.label)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            Text(evidence.statusLabel)
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(tint.opacity(0.10))
                .clipShape(Capsule())
        }
        .softCard(padding: 12)
    }

    private var tint: Color {
        if !evidence.isCaptured { return Theme.amber }
        if !evidence.isFreshGuidedCapture { return Theme.amber }
        switch evidence.confidence {
        case .high: Theme.leaf
        case .medium: Theme.moss
        case .low: Theme.amber
        }
    }

    private var symbolName: String {
        if evidence.isVerified { return "checkmark.seal" }
        if evidence.isFreshGuidedCapture { return "checkmark.circle" }
        return evidence.isCaptured ? "exclamationmark.triangle" : "camera.badge.ellipsis"
    }

    private var detail: String {
        guard evidence.isCaptured else { return "No guided frame captured" }
        guard evidence.isFreshGuidedCapture else {
            return "\(frameCountLabel) captured, but no fresh guided frame was accepted."
        }
        let guidedLabel = evidence.freshGuidedFrameCount == 1 ? "fresh guided frame" : "fresh guided frames"
        return "\(evidence.freshGuidedFrameCount) \(guidedLabel) - \(evidence.confidence.label)"
    }

    private var frameCountLabel: String {
        let frameLabel = evidence.frameCount == 1 ? "frame" : "frames"
        return "\(evidence.frameCount) \(frameLabel)"
    }
}

private struct HistoryRow: View {
    var report: SkinReport

    private var topScore: ConcernScore? {
        report.topConcerns.first
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(report.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("\(report.evidenceSummary.confidenceLevel(for: report.scanQuality).label) confidence")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                Text(report.evidenceSummary.coverageLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.moss)
            }

            Spacer()

            if let topScore {
                ConcernBadge(concern: topScore.concern, score: topScore.score)
            }
        }
        .softCard(padding: 14)
    }
}

private struct ProgressComparisonCard: View {
    var comparison: ProgressComparison

    private var highlightedDeltas: [ProgressConcernDelta] {
        Array(comparison.deltas.prefix(4))
    }

    private var daysLabel: String {
        switch comparison.daysBetweenReports {
        case 0:
            return "Same-day comparison"
        case 1:
            return "1 day between scans"
        default:
            return "\(comparison.daysBetweenReports) days between scans"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(width: 38, height: 38)
                    .background(Theme.moss.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest comparison")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text(daysLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                }

                Spacer()
            }

            Text(comparison.summary)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                ForEach(highlightedDeltas) { delta in
                    ProgressDeltaRow(delta: delta)
                }
            }
        }
        .softCard(padding: 14)
    }
}

private struct ProgressDeltaRow: View {
    var delta: ProgressConcernDelta

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(delta.concern.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(delta.deltaLabel)
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(tint.opacity(0.10))
                        .clipShape(Capsule())
                }

                ProgressView(value: Double(delta.currentScore), total: 100)
                    .tint(Theme.concernColor(delta.concern))

                Text("Prior \(delta.previousScore) to latest \(delta.currentScore)")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(delta.concern.title), \(delta.direction.title), \(delta.deltaLabel)")
    }

    private var tint: Color {
        switch delta.direction {
        case .lessVisible: Theme.leaf
        case .stable: Theme.muted
        case .moreVisible: Theme.amber
        }
    }

    private var symbolName: String {
        switch delta.direction {
        case .lessVisible: "arrow.down.circle.fill"
        case .stable: "minus.circle.fill"
        case .moreVisible: "arrow.up.circle.fill"
        }
    }
}

private struct SkinMapView: View {
    var report: SkinReport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Region map",
                subtitle: "Markers use analyzer primary-region labels, not Face ID or verified anatomical diagnosis."
            )

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.panel, Color.white.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                GeometryReader { proxy in
                    let size = proxy.size

                    FaceSilhouette()
                        .fill(Theme.background)
                        .overlay(FaceSilhouette().stroke(Theme.moss.opacity(0.18), lineWidth: 2))
                        .padding(.horizontal, size.width * 0.22)
                        .padding(.vertical, 24)

                    ForEach(report.priorityScores.prefix(5)) { score in
                        MapMarker(score: score)
                            .position(position(for: score.primaryRegion, in: size))
                    }
                }
            }
            .frame(height: 330)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if report.analysisMetadata.isPrototypeOutput {
                Label("Prototype map: markers are illustrative score context until a validated landmark or region verifier is connected.", systemImage: "exclamationmark.triangle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.amber)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func position(for region: FaceRegion, in size: CGSize) -> CGPoint {
        switch region {
        case .forehead: CGPoint(x: size.width * 0.5, y: size.height * 0.27)
        case .leftCheek: CGPoint(x: size.width * 0.36, y: size.height * 0.52)
        case .rightCheek: CGPoint(x: size.width * 0.64, y: size.height * 0.52)
        case .nose: CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        case .chin: CGPoint(x: size.width * 0.5, y: size.height * 0.73)
        case .underEye: CGPoint(x: size.width * 0.5, y: size.height * 0.42)
        }
    }
}

private struct FaceSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX

        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.maxX * 0.82, y: rect.minY + rect.height * 0.05),
            control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.78),
            control2: CGPoint(x: rect.maxX * 0.72, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.maxX * 0.28, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25),
            control2: CGPoint(x: rect.maxX * 0.18, y: rect.minY + rect.height * 0.05)
        )
        return path
    }
}

private struct MapMarker: View {
    var score: ConcernScore

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: score.concern.symbolName)
                .font(.caption.weight(.bold))
            Text("\(score.score)")
                .font(.caption2.monospacedDigit().weight(.bold))
        }
        .foregroundStyle(.white)
        .frame(width: 46, height: 46)
        .background(Theme.concernColor(score.concern))
        .clipShape(Circle())
        .shadow(color: Theme.concernColor(score.concern).opacity(0.35), radius: 10, x: 0, y: 4)
        .accessibilityLabel("\(score.concern.title) marker, score \(score.score)")
    }
}

#Preview {
    ResultsView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.preview())
}
