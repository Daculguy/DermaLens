import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var userProfile = UserProfile.default
    @Published var latestReport = SampleData.previewReport
    @Published var scanHistory: [SkinReport] = [SampleData.previewReport]
    @Published var routinePlan = SampleData.previewRoutine
    @Published var routineCompletionRecords: [RoutineCompletionRecord] = []
    @Published var routineSwapOverrides: [RoutineSwapOverride] = []
    @Published var productShelfState = ProductShelfState.empty
    @Published var customProducts: [SkincareProduct] = []
    @Published var progressJournalEntries: [ProgressJournalEntry] = []
    @Published var ingredientFindings: [IngredientCompatibilityFinding] = []
    @Published var isScanning = false
    @Published var hasCompletedOnboarding = false
    @Published var showingPaywall = false
    @Published var showingPrivacyCenter = false
    @Published var showingDiagnostics = false
    @Published private(set) var routineRemindersEnabled = false
    @Published private(set) var routineReminderPreferences: RoutineReminderPreferences = .default
    @Published private(set) var routineReminderStatus: RoutineReminderStatus = .off
    @Published private(set) var isUpdatingRoutineReminders = false
    @Published private(set) var analyzerMode: AppConfiguration.AnalyzerMode
    @Published private(set) var remoteAnalyzerHost: String?
    @Published private(set) var remoteAnalyzerFallbacksToLocal: Bool
    @Published private(set) var remoteAnalysisConsentGranted = false

    private let analyzer: any SkinAnalysisServicing
    private let consentGatedLocalAnalyzer: any SkinAnalysisServicing
    private var remoteAnalysisConsent: RemoteAnalysisConsentRecord?
    private let recommendationEngine: RecommendationEngine
    private let ingredientEngine: IngredientCompatibilityEngine
    private let routineAdherenceTracker: RoutineAdherenceTracker
    private let productShelfManager: ProductShelfManager
    private let progressJournal: ProgressJournal
    private let privacyExportBuilder: PrivacyExportBuilder
    private let premiumAccessPolicy: PremiumAccessPolicy
    private let routineNotificationScheduler: RoutineNotificationScheduling
    private let persistenceStore: PersistenceStore
    private let seedPreviewData: Bool

    init(
        configuration: AppConfiguration = .current,
        consentGatedLocalAnalyzer: any SkinAnalysisServicing = ScanAnalyzer(),
        recommendationEngine: RecommendationEngine = RecommendationEngine(),
        ingredientEngine: IngredientCompatibilityEngine = IngredientCompatibilityEngine(),
        routineAdherenceTracker: RoutineAdherenceTracker = RoutineAdherenceTracker(),
        productShelfManager: ProductShelfManager = ProductShelfManager(),
        progressJournal: ProgressJournal = ProgressJournal(),
        privacyExportBuilder: PrivacyExportBuilder = PrivacyExportBuilder(),
        premiumAccessPolicy: PremiumAccessPolicy = PremiumAccessPolicy(),
        routineNotificationScheduler: RoutineNotificationScheduling = RoutineNotificationScheduler(),
        persistenceStore: PersistenceStore = PersistenceStore(),
        seedPreviewData: Bool = true
    ) {
        self.analyzer = configuration.analyzer
        self.consentGatedLocalAnalyzer = consentGatedLocalAnalyzer
        self.analyzerMode = configuration.analyzerMode
        self.remoteAnalyzerHost = configuration.remoteEndpoint?.host
        self.remoteAnalyzerFallbacksToLocal = configuration.remoteFallbacksToLocal
        self.recommendationEngine = recommendationEngine
        self.ingredientEngine = ingredientEngine
        self.routineAdherenceTracker = routineAdherenceTracker
        self.productShelfManager = productShelfManager
        self.progressJournal = progressJournal
        self.privacyExportBuilder = privacyExportBuilder
        self.premiumAccessPolicy = premiumAccessPolicy
        self.routineNotificationScheduler = routineNotificationScheduler
        self.persistenceStore = persistenceStore
        self.seedPreviewData = seedPreviewData
        restoreSnapshot()
    }

    var hasCompletedScan: Bool {
        !scanHistory.isEmpty
    }

    var routineAdherenceSummary: RoutineAdherenceSummary {
        routineAdherenceTracker.summary(
            for: routinePlan,
            records: routineCompletionRecords,
            on: Date()
        )
    }

    var productShelfSummary: ProductShelfSummary {
        productShelfManager.summary(for: productShelfState)
    }

    var productCatalog: [SkincareProduct] {
        (SampleData.products + customProducts)
            .sorted { lhs, rhs in
                if isCustomProduct(lhs) != isCustomProduct(rhs) {
                    return isCustomProduct(lhs)
                }
                if lhs.category == rhs.category {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.category.rawValue < rhs.category.rawValue
            }
    }

    private var routineProductCatalog: [SkincareProduct] {
        SampleData.products + customProducts.filter { product in
            productShelfStatus(for: product).influencesRoutine
        }
    }

    var progressJournalSummary: ProgressJournalSummary {
        progressJournal.summary(for: progressJournalEntries)
    }

    var latestJournalEntryForToday: ProgressJournalEntry? {
        progressJournal.latestEntryForToday(in: progressJournalEntries)
    }

    var privacyExportText: String {
        privacyExportBuilder.exportText(
            userProfile: userProfile,
            reports: scanHistory,
            routinePlan: hasCompletedOnboarding && hasCompletedScan ? routinePlan : nil,
            routineCompletionRecords: routineCompletionRecords,
            routineSwapOverrides: routineSwapOverrides,
            productShelfState: productShelfState,
            customProducts: customProducts,
            progressJournalEntries: progressJournalEntries,
            routineReminderPreferences: routineReminderPreferences,
            remoteAnalysisConsent: remoteAnalysisConsent,
            remoteAnalysisHost: remoteAnalyzerHost
        )
    }

    var isRemoteAnalysisConfigured: Bool {
        analyzerMode == .remote
    }

    @discardableResult
    func runScan(with capture: ScanCapture) async -> Bool {
        guard capture.evidenceSummary.isComplete else {
            isScanning = false
            return false
        }

        isScanning = true
        let report: SkinReport
        if isRemoteAnalysisConfigured, !remoteAnalysisConsentGranted {
            var localReport = await consentGatedLocalAnalyzer.analyze(capture: capture, profile: userProfile)
            localReport.analysisMetadata = .remoteConsentNotGranted(endpointHost: remoteAnalyzerHost)
            report = localReport
        } else {
            report = await analyzer.analyze(capture: capture, profile: userProfile)
        }
        applyReport(report)
        isScanning = false
        selectedTab = .results
        return true
    }

    func setRemoteAnalysisConsent(_ isGranted: Bool) {
        if isRemoteAnalysisConfigured, isGranted, let remoteAnalyzerHost {
            let record = RemoteAnalysisConsentRecord(host: remoteAnalyzerHost)
            remoteAnalysisConsent = record
            remoteAnalysisConsentGranted = true
        } else {
            remoteAnalysisConsent = nil
            remoteAnalysisConsentGranted = false
        }
        persistSnapshot()
    }

    func updateProfile(goal: SkinConcern, isEnabled: Bool) {
        if isEnabled {
            userProfile.currentGoals.insert(goal)
        } else {
            userProfile.currentGoals.remove(goal)
        }
        rebuildRoutine()
        persistSnapshot()
    }

    func applyProfile(_ profile: UserProfile) {
        userProfile = profile
        rebuildRoutine()
        hasCompletedOnboarding = true
        selectedTab = .scan
        persistSnapshot()
    }

    private func rebuildRoutine() {
        guard hasCompletedScan else {
            routinePlan = emptyRoutinePlan()
            ingredientFindings = []
            rescheduleRoutineRemindersIfNeeded()
            return
        }

        let basePlan = recommendationEngine.buildRoutine(
            for: latestReport,
            profile: userProfile,
            productShelfStatuses: productShelfState.statuses,
            catalog: routineProductCatalog
        )
        routinePlan = routineWithSwapOverridesApplied(to: basePlan)
        refreshIngredientFindings()
        rescheduleRoutineRemindersIfNeeded()
    }

    func deleteAllLocalData() {
        persistenceStore.deleteAll()
        Task {
            await routineNotificationScheduler.cancelReminders()
        }
        userProfile = .default
        latestReport = SampleData.previewReport
        scanHistory = []
        routinePlan = emptyRoutinePlan()
        routineCompletionRecords = []
        routineSwapOverrides = []
        productShelfState = .empty
        customProducts = []
        progressJournalEntries = []
        remoteAnalysisConsent = nil
        remoteAnalysisConsentGranted = false
        refreshIngredientFindings()
        routineRemindersEnabled = false
        routineReminderPreferences = .default
        routineReminderStatus = .off
        hasCompletedOnboarding = false
        selectedTab = .home
    }

    func updateRoutineReminderTime(
        for moment: RoutineMoment,
        to date: Date,
        calendar: Calendar = .current
    ) {
        var preferences = routineReminderPreferences
        preferences.setTime(RoutineReminderTime(date: date, calendar: calendar), for: moment)
        guard preferences != routineReminderPreferences else { return }

        routineReminderPreferences = preferences
        persistSnapshot()
        rescheduleRoutineRemindersIfNeeded()
    }

    func setRoutineRemindersEnabled(_ isEnabled: Bool) async {
        guard !isUpdatingRoutineReminders else { return }

        isUpdatingRoutineReminders = true
        defer { isUpdatingRoutineReminders = false }

        if isEnabled {
            await enableRoutineReminders()
        } else {
            await routineNotificationScheduler.cancelReminders()
            routineRemindersEnabled = false
            routineReminderStatus = .off
            persistSnapshot()
        }
    }

    func isRoutineStepCompleted(_ step: RoutineStep) -> Bool {
        routineAdherenceTracker.isStepCompleted(
            step,
            in: routinePlan,
            records: routineCompletionRecords,
            on: Date()
        )
    }

    func toggleRoutineStepCompletion(_ step: RoutineStep) {
        routineCompletionRecords = routineAdherenceTracker.records(
            afterToggling: step,
            in: routinePlan,
            records: routineCompletionRecords,
            on: Date()
        )
        routineCompletionRecords = routineAdherenceTracker.pruned(
            records: routineCompletionRecords,
            keepingDays: 42,
            from: Date()
        )
        persistSnapshot()
    }

    func productShelfStatus(for product: SkincareProduct) -> ProductShelfStatus {
        productShelfManager.status(for: product.id, in: productShelfState)
    }

    func setProductShelfStatus(_ status: ProductShelfStatus, for product: SkincareProduct) {
        let previousStatus = productShelfStatus(for: product)
        productShelfState = productShelfManager.state(
            afterSetting: status,
            for: product.id,
            in: productShelfState
        )
        if previousStatus.influencesRoutine || status.influencesRoutine {
            rebuildRoutine()
        }
        persistSnapshot()
    }

    func productAlternatives(for step: RoutineStep, limit: Int = 5) -> [ProductAlternative] {
        var alternatives = recommendationEngine.alternatives(
            for: step,
            focus: routinePlan.focus,
            profile: userProfile,
            productShelfStatuses: productShelfState.statuses,
            catalog: productCatalog,
            limit: limit + 3
        )

        if step.category == .treatment, routinePlan.steps.contains(where: { $0.category == .exfoliant }) {
            alternatives.removeAll { containsRetinoid($0.product) }
        }

        return Array(alternatives.prefix(limit))
    }

    @discardableResult
    func swapRoutineStep(_ step: RoutineStep, with product: SkincareProduct, isPremium: Bool = true) -> PremiumAccessDecision {
        let accessDecision = premiumAccessPolicy.routineAlternativesDecision(isPremium: isPremium)
        guard accessDecision.isAllowed else {
            showingPaywall = true
            return accessDecision
        }

        let requestedStepKey = RoutineStepKey(step: step)
        guard let index = routinePlan.steps.firstIndex(where: { $0.id == step.id })
                ?? routinePlan.steps.firstIndex(where: { RoutineStepKey(step: $0) == requestedStepKey }) else {
            return PremiumAccessDecision(
                isAllowed: false,
                title: "Step unavailable",
                detail: "This routine step is no longer in the active plan."
            )
        }
        let activeStep = routinePlan.steps[index]
        guard isValidRoutineSwapProduct(product, for: activeStep) else {
            return PremiumAccessDecision(
                isAllowed: false,
                title: "Product unavailable",
                detail: "This product no longer matches the routine slot or safety guardrails."
            )
        }

        routineCompletionRecords.removeAll {
            $0.stepKey == requestedStepKey
            || $0.stepKey == RoutineStepKey(step: activeStep)
        }

        if shouldPromoteCustomProductForRoutine(product) {
            productShelfState = productShelfManager.state(
                afterSetting: .using,
                for: product.id,
                in: productShelfState
            )
        }

        let override = RoutineSwapOverride(step: activeStep, product: product)
        routineSwapOverrides.removeAll { $0.slotID == override.slotID }
        routineSwapOverrides.append(override)
        routinePlan.steps[index] = replacementStep(for: activeStep, product: product)
        if containsRetinoid(product) {
            removeExfoliantSteps(from: &routinePlan)
        }

        refreshIngredientFindings()
        rescheduleRoutineRemindersIfNeeded()
        persistSnapshot()
        return accessDecision
    }

    func isCustomProduct(_ product: SkincareProduct) -> Bool {
        customProducts.contains { $0.id == product.id }
    }

    func addCustomProduct(_ product: SkincareProduct, initialStatus: ProductShelfStatus) {
        customProducts.removeAll { $0.id == product.id }
        customProducts.insert(product, at: 0)
        if initialStatus != .none {
            productShelfState = productShelfManager.state(
                afterSetting: initialStatus,
                for: product.id,
                in: productShelfState
            )
        }
        rebuildRoutine()
        persistSnapshot()
    }

    func deleteCustomProduct(_ product: SkincareProduct) {
        guard isCustomProduct(product) else { return }
        let previousStatus = productShelfStatus(for: product)
        let wasInRoutine = routinePlan.steps.contains { $0.product.id == product.id }
        customProducts.removeAll { $0.id == product.id }
        routineSwapOverrides.removeAll { $0.productID == product.id || $0.replacedProductID == product.id }
        productShelfState = productShelfManager.state(afterRemoving: product.id, from: productShelfState)
        routineCompletionRecords.removeAll { $0.stepKey.productID == product.id }
        if previousStatus.influencesRoutine || wasInRoutine {
            rebuildRoutine()
        }
        persistSnapshot()
    }

    func journalEntries(for report: SkinReport) -> [ProgressJournalEntry] {
        progressJournal.entries(for: report.id, in: progressJournalEntries)
    }

    func addProgressJournalEntry(
        skinFeel: JournalSkinFeel,
        tags: Set<JournalContextTag>,
        note: String,
        linkedReport: SkinReport? = nil,
        comfortRating: Int? = nil
    ) {
        let entry = progressJournal.makeEntry(
            report: linkedReport,
            routinePlanID: routinePlan.id,
            skinFeel: skinFeel,
            tags: tags,
            note: note,
            comfortRating: comfortRating
        )
        progressJournalEntries.insert(entry, at: 0)
        progressJournalEntries = progressJournal.capped(progressJournalEntries)
        persistSnapshot()
    }

    func deleteProgressJournalEntry(_ entry: ProgressJournalEntry) {
        progressJournalEntries = progressJournal.entries(afterDeleting: entry.id, from: progressJournalEntries)
        persistSnapshot()
    }

    func refreshRoutineReminderAuthorization() async {
        guard routineRemindersEnabled else {
            routineReminderStatus = .off
            return
        }

        switch await routineNotificationScheduler.authorizationState() {
        case .granted:
            await rescheduleRoutineReminders()
        case .notDetermined:
            routineReminderStatus = .permissionRequired
        case .denied:
            routineRemindersEnabled = false
            routineReminderStatus = .permissionDenied
            persistSnapshot()
        }
    }

    private func applyReport(_ report: SkinReport) {
        latestReport = report
        scanHistory.insert(report, at: 0)
        scanHistory = Array(scanHistory.prefix(12))
        let basePlan = recommendationEngine.buildRoutine(
            for: report,
            profile: userProfile,
            productShelfStatuses: productShelfState.statuses,
            catalog: routineProductCatalog
        )
        routinePlan = routineWithSwapOverridesApplied(to: basePlan)
        refreshIngredientFindings()
        rescheduleRoutineRemindersIfNeeded()
        persistSnapshot()
    }

    private func restoreSnapshot() {
        let snapshot = persistenceStore.load()
        userProfile = snapshot.userProfile
        hasCompletedOnboarding = snapshot.hasCompletedOnboarding
        scanHistory = snapshot.reports.sorted { $0.createdAt > $1.createdAt }
        if scanHistory.isEmpty, seedPreviewData {
            scanHistory = [SampleData.previewReport]
        }
        latestReport = scanHistory.first ?? SampleData.previewReport
        routineCompletionRecords = snapshot.routineCompletionRecords
        routineSwapOverrides = snapshot.routineSwapOverrides
        productShelfState = snapshot.productShelfState
        customProducts = snapshot.customProducts
        progressJournalEntries = progressJournal.capped(snapshot.progressJournalEntries)
        routineReminderPreferences = snapshot.routineReminderPreferences
        remoteAnalysisConsent = validRemoteAnalysisConsent(from: snapshot.remoteAnalysisConsent)
        remoteAnalysisConsentGranted = remoteAnalysisConsent != nil
        if hasCompletedScan {
            let basePlan = recommendationEngine.buildRoutine(
                for: latestReport,
                profile: userProfile,
                productShelfStatuses: productShelfState.statuses,
                catalog: routineProductCatalog
            )
            routinePlan = routineWithSwapOverridesApplied(to: basePlan)
        } else {
            routinePlan = emptyRoutinePlan()
            routineCompletionRecords = []
            routineSwapOverrides = []
        }
        routineRemindersEnabled = hasCompletedScan && snapshot.routineRemindersEnabled
        routineReminderStatus = routineRemindersEnabled ? .permissionRequired : .off
        refreshIngredientFindings()
    }

    private func persistSnapshot() {
        persistenceStore.save(PersistedAppSnapshot(
            userProfile: userProfile,
            reports: scanHistory,
            hasCompletedOnboarding: hasCompletedOnboarding,
            routinePlan: routinePlan,
            routineRemindersEnabled: routineRemindersEnabled,
            routineReminderPreferences: routineReminderPreferences,
            routineCompletionRecords: routineCompletionRecords,
            routineSwapOverrides: routineSwapOverrides,
            productShelfState: productShelfState,
            customProducts: customProducts,
            progressJournalEntries: progressJournalEntries,
            remoteAnalysisConsent: remoteAnalysisConsent
        ))
    }

    private func validRemoteAnalysisConsent(from record: RemoteAnalysisConsentRecord?) -> RemoteAnalysisConsentRecord? {
        guard isRemoteAnalysisConfigured,
              let record,
              record.host == remoteAnalyzerHost,
              record.copyVersion == RemoteAnalysisConsentRecord.currentCopyVersion else {
            return nil
        }

        return record
    }

    private func refreshIngredientFindings() {
        guard hasCompletedScan else {
            ingredientFindings = []
            return
        }

        ingredientFindings = ingredientEngine.analyze(plan: routinePlan, profile: userProfile)
    }

    private func emptyRoutinePlan() -> RoutinePlan {
        RoutinePlan(
            generatedAt: Date(),
            focus: [],
            steps: [],
            weeklyNotes: [
                "Run a guided scan before DermaLens builds a routine."
            ]
        )
    }

    private func routineWithSwapOverridesApplied(to plan: RoutinePlan) -> RoutinePlan {
        var nextPlan = plan
        var retainedOverrides: [RoutineSwapOverride] = []

        for override in sortedRoutineSwapOverrides() {
            guard let index = nextPlan.steps.firstIndex(where: { routineSlotMatches($0, override: override) }),
                  let product = productCatalog.first(where: { $0.id == override.productID }),
                  isValidRoutineSwapProduct(product, for: nextPlan.steps[index]) else {
                continue
            }

            let step = nextPlan.steps[index]
            nextPlan.steps[index] = replacementStep(for: step, product: product)
            retainedOverrides.removeAll { $0.slotID == override.slotID }
            retainedOverrides.append(override)

            if containsRetinoid(product) {
                removeExfoliantSteps(from: &nextPlan, removeSwapOverrides: false)
                retainedOverrides.removeAll { $0.category == .exfoliant }
            }
        }

        routineSwapOverrides = retainedOverrides.filter { override in
            nextPlan.steps.contains {
                routineSlotMatches($0, override: override)
                && $0.product.id == override.productID
            }
        }
        return nextPlan
    }

    private func sortedRoutineSwapOverrides() -> [RoutineSwapOverride] {
        routineSwapOverrides.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.slotID < rhs.slotID
            }
            return lhs.updatedAt < rhs.updatedAt
        }
    }

    private func routineSlotMatches(_ step: RoutineStep, override: RoutineSwapOverride) -> Bool {
        step.moment == override.moment
        && step.order == override.order
        && step.category == override.category
    }

    private func isValidRoutineSwapProduct(_ product: SkincareProduct, for step: RoutineStep) -> Bool {
        product.category == step.category
        && productShelfStatus(for: product) != .avoided
        && !(userProfile.shouldAvoidRetinoids && containsRetinoid(product))
    }

    private func shouldPromoteCustomProductForRoutine(_ product: SkincareProduct) -> Bool {
        guard isCustomProduct(product) else { return false }
        switch productShelfStatus(for: product) {
        case .none, .wishlist:
            return true
        case .owned, .using, .avoided:
            return false
        }
    }

    private func removeExfoliantSteps(from plan: inout RoutinePlan, removeSwapOverrides: Bool = true) {
        let removedStepKeys = plan.steps
            .filter { $0.category == .exfoliant }
            .map(RoutineStepKey.init(step:))

        guard !removedStepKeys.isEmpty else { return }

        plan.steps.removeAll { $0.category == .exfoliant }
        routineCompletionRecords.removeAll { removedStepKeys.contains($0.stepKey) }

        if removeSwapOverrides {
            routineSwapOverrides.removeAll { $0.category == .exfoliant }
        }
    }

    private func replacementStep(for step: RoutineStep, product: SkincareProduct) -> RoutineStep {
        RoutineStep(
            id: step.id,
            moment: step.moment,
            order: step.order,
            category: step.category,
            product: product,
            instruction: replacementInstruction(for: step, product: product),
            caution: replacementCaution(for: product),
            fitScore: nil,
            selectionReasons: replacementSelectionReasons(for: step, product: product)
        )
    }

    private func replacementSelectionReasons(for step: RoutineStep, product: SkincareProduct) -> [String] {
        var reasons = [
            "User-selected alternative",
            "Keeps the \(step.category.title.lowercased()) role in this routine"
        ]

        if isCustomProduct(product) {
            reasons.append("From your product shelf")
        }

        if product.commercialStatus == .independent {
            reasons.append("Independent pick")
        } else {
            reasons.append(product.commercialStatus.title)
        }

        return Array(reasons.prefix(4))
    }

    private func replacementInstruction(for step: RoutineStep, product: SkincareProduct) -> String {
        switch step.category {
        case .treatment, .exfoliant, .mask:
            product.usageNote
        case .sunscreen:
            "Apply generously as the final morning step."
        case .moisturizer:
            "Use enough to keep skin comfortable."
        case .cleanser:
            step.moment == .morning
                ? "Cleanse lightly or rinse if your skin feels comfortable."
                : "Cleanse for 30-45 seconds to remove sunscreen."
        }
    }

    private func replacementCaution(for product: SkincareProduct) -> String? {
        if containsRetinoid(product) {
            return "Introduce slowly and avoid combining with exfoliants on the same evening."
        }
        if userProfile.sensitivity >= 4, (product.category == .treatment || product.category == .exfoliant) {
            return "Patch test first and start slowly."
        }
        return nil
    }

    private func containsRetinoid(_ product: SkincareProduct) -> Bool {
        product.hasIngredientSignal(matching: ["retinal", "retinol", "retinoid", "retinyl", "adapalene", "tretinoin"])
    }

    private func enableRoutineReminders() async {
        do {
            _ = try await routineNotificationScheduler.scheduleReminders(
                for: routinePlan,
                preferences: routineReminderPreferences
            )
            routineRemindersEnabled = true
            routineReminderStatus = .scheduled
        } catch RoutineNotificationSchedulerError.authorizationDenied {
            routineRemindersEnabled = false
            routineReminderStatus = .permissionDenied
        } catch RoutineNotificationSchedulerError.noRoutineSteps {
            routineRemindersEnabled = false
            routineReminderStatus = .unavailable
        } catch {
            routineRemindersEnabled = false
            routineReminderStatus = .unavailable
        }

        persistSnapshot()
    }

    private func rescheduleRoutineReminders() async {
        switch await routineNotificationScheduler.authorizationState() {
        case .granted:
            break
        case .notDetermined:
            routineReminderStatus = .permissionRequired
            return
        case .denied:
            routineRemindersEnabled = false
            routineReminderStatus = .permissionDenied
            persistSnapshot()
            return
        }

        do {
            _ = try await routineNotificationScheduler.scheduleReminders(
                for: routinePlan,
                preferences: routineReminderPreferences
            )
            routineReminderStatus = .scheduled
        } catch RoutineNotificationSchedulerError.authorizationDenied {
            routineRemindersEnabled = false
            routineReminderStatus = .permissionDenied
            persistSnapshot()
        } catch RoutineNotificationSchedulerError.noRoutineSteps {
            routineReminderStatus = .unavailable
        } catch {
            routineReminderStatus = .unavailable
        }
    }

    private func rescheduleRoutineRemindersIfNeeded() {
        guard routineRemindersEnabled else { return }

        Task { [weak self] in
            await self?.rescheduleRoutineReminders()
        }
    }
}

enum RoutineReminderStatus: Hashable {
    case off
    case scheduled
    case permissionRequired
    case permissionDenied
    case unavailable

    var title: String {
        switch self {
        case .off:
            "Reminders off"
        case .scheduled:
            "Daily reminders on"
        case .permissionRequired:
            "Permission needed"
        case .permissionDenied:
            "Notifications blocked"
        case .unavailable:
            "Reminders unavailable"
        }
    }

    var detail: String {
        switch self {
        case .off:
            "Turn on gentle morning and evening nudges for your plan."
        case .scheduled:
            "DermaLens will remind you without showing skin findings on the lock screen."
        case .permissionRequired:
            "Allow notifications to schedule your routine reminders."
        case .permissionDenied:
            "Enable notifications in Settings to use routine reminders."
        case .unavailable:
            "Create a routine before enabling reminders."
        }
    }

    var symbolName: String {
        switch self {
        case .off:
            "bell"
        case .scheduled:
            "bell.badge"
        case .permissionRequired:
            "bell.badge"
        case .permissionDenied:
            "bell.slash"
        case .unavailable:
            "exclamationmark.triangle"
        }
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case scan
    case results
    case routine
    case shelf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Today"
        case .scan: "Scan"
        case .results: "Insights"
        case .routine: "Routine"
        case .shelf: "Shelf"
        }
    }

    var symbolName: String {
        switch self {
        case .home: "sparkles"
        case .scan: "viewfinder"
        case .results: "chart.xyaxis.line"
        case .routine: "checklist"
        case .shelf: "shippingbox"
        }
    }
}
