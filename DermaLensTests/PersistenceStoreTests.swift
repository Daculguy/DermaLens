import XCTest
@testable import DermaLens

final class PersistenceStoreTests: XCTestCase {
    @MainActor
    func testProductionStateStartsWithoutPreviewReportOrRoutine() throws {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: PersistenceNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults),
            seedPreviewData: false
        )

        XCTAssertFalse(appState.hasCompletedScan)
        XCTAssertTrue(appState.scanHistory.isEmpty)
        XCTAssertTrue(appState.routinePlan.steps.isEmpty)
        XCTAssertTrue(appState.ingredientFindings.isEmpty)

        let data = try XCTUnwrap(appState.privacyExportText.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(PrivacyExportPayload.self, from: data)

        XCTAssertEqual(payload.counts.reports, 0)
        XCTAssertNil(payload.routine)
    }

    @MainActor
    func testApplyingProfileCompletesOnboardingAndRoutesToScan() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: PersistenceNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults),
            seedPreviewData: false
        )

        appState.applyProfile(.default)

        XCTAssertTrue(appState.hasCompletedOnboarding)
        XCTAssertEqual(appState.selectedTab, .scan)
        XCTAssertFalse(appState.hasCompletedScan)
        XCTAssertTrue(appState.routinePlan.steps.isEmpty)
    }

    @MainActor
    func testRunScanRejectsIncompleteGuidedEvidence() async {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: PersistenceNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults),
            seedPreviewData: false
        )
        let capture = ScanCapture(
            createdAt: Date(timeIntervalSince1970: 1_780_000_000),
            quality: .preview,
            frames: [
                ScanFrame(
                    capturedAt: Date(timeIntervalSince1970: 1_780_000_001),
                    jpegData: Data([0x01]),
                    regionHint: .forehead,
                    qualitySnapshot: .preview,
                    sourceFrameID: 1,
                    verificationStatus: .freshGuidedCapture
                )
            ],
            deviceModel: "Unit Test iPhone"
        )

        let didCreateReport = await appState.runScan(with: capture)

        XCTAssertFalse(didCreateReport)
        XCTAssertFalse(appState.hasCompletedScan)
        XCTAssertEqual(appState.selectedTab, .home)
        XCTAssertTrue(appState.routinePlan.steps.isEmpty)
    }

    func testSaveLoadAndDeleteSnapshot() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PersistenceStore(defaults: defaults)
        let report = SampleData.previewReport
        let routine = SampleData.previewRoutine
        let journalEntry = ProgressJournal().makeEntry(
            report: report,
            routinePlanID: routine.id,
            skinFeel: .dry,
            tags: [.travel],
            note: "Hotel air felt drying",
            comfortRating: 3,
            date: Date(timeIntervalSince1970: 24)
        )
        let snapshot = PersistedAppSnapshot(
            userProfile: .default,
            reports: [report],
            hasCompletedOnboarding: true,
            routinePlan: routine,
            routineReminderPreferences: RoutineReminderPreferences(
                morning: RoutineReminderTime(hour: 7, minute: 30),
                evening: RoutineReminderTime(hour: 22, minute: 15)
            ),
            routineSwapOverrides: [
                RoutineSwapOverride(
                    step: routine.steps[0],
                    product: SampleData.products.first { $0.id == "cleanser-balanced-milk" }!,
                    updatedAt: Date(timeIntervalSince1970: 28)
                )
            ],
            productShelfState: ProductShelfState(items: [
                ProductShelfItem(
                    productID: "cleanser-oat-gel",
                    status: .owned,
                    updatedAt: Date(timeIntervalSince1970: 12),
                    note: nil
                )
            ]),
            customProducts: [customProduct(id: "custom-persist")],
            progressJournalEntries: [journalEntry],
            remoteAnalysisConsent: RemoteAnalysisConsentRecord(
                host: "analysis.example.com",
                grantedAt: Date(timeIntervalSince1970: 30)
            )
        )

        store.save(snapshot)
        let loaded = store.load()

        XCTAssertTrue(loaded.hasCompletedOnboarding)
        XCTAssertEqual(loaded.reports.first?.id, report.id)
        XCTAssertEqual(loaded.userProfile, .default)
        XCTAssertTrue(loaded.routineCompletionRecords.isEmpty)
        XCTAssertEqual(loaded.routineReminderPreferences.morning.clockText, "07:30")
        XCTAssertEqual(loaded.routineReminderPreferences.evening.clockText, "22:15")
        XCTAssertEqual(loaded.routineSwapOverrides.first?.productID, "cleanser-balanced-milk")
        XCTAssertEqual(loaded.productShelfState.items.first?.status, .owned)
        XCTAssertEqual(loaded.customProducts.first?.id, "custom-persist")
        XCTAssertEqual(loaded.progressJournalEntries.first?.id, journalEntry.id)
        XCTAssertEqual(loaded.progressJournalEntries.first?.note, "Hotel air felt drying")
        XCTAssertEqual(loaded.remoteAnalysisConsent?.host, "analysis.example.com")

        store.deleteAll()
        let deleted = store.load()

        XCTAssertFalse(deleted.hasCompletedOnboarding)
        XCTAssertTrue(deleted.reports.isEmpty)
        XCTAssertTrue(deleted.routineSwapOverrides.isEmpty)
        XCTAssertTrue(deleted.customProducts.isEmpty)
        XCTAssertTrue(deleted.progressJournalEntries.isEmpty)
    }

    func testLoadsLegacySnapshotWithoutReminderPreference() throws {
        struct LegacyProfile: Encodable {
            var skinType: String
            var sensitivity: Int
            var budget: BudgetTier
            var avoidsFragrance: Bool
            var avoidsRetinoids: Bool
            var currentGoals: Set<SkinConcern>
        }

        struct LegacyReport: Encodable {
            var createdAt: Date
            var scanQuality: ScanQuality
            var scores: [ConcernScore]
            var visibleStrengths: [String]
            var summary: String
        }

        struct LegacySnapshot: Encodable {
            var userProfile: LegacyProfile
            var reports: [LegacyReport]
            var hasCompletedOnboarding: Bool
            var routinePlan: RoutinePlan?
        }

        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let legacyData = try encoder.encode(LegacySnapshot(
            userProfile: LegacyProfile(
                skinType: "Combination",
                sensitivity: 3,
                budget: .balanced,
                avoidsFragrance: true,
                avoidsRetinoids: false,
                currentGoals: [.blemishes, .redness]
            ),
            reports: [
                LegacyReport(
                    createdAt: SampleData.previewReport.createdAt,
                    scanQuality: SampleData.previewReport.scanQuality,
                    scores: SampleData.previewReport.scores,
                    visibleStrengths: SampleData.previewReport.visibleStrengths,
                    summary: SampleData.previewReport.summary
                )
            ],
            hasCompletedOnboarding: true,
            routinePlan: SampleData.previewRoutine
        ))
        defaults.set(legacyData, forKey: "dermalens.persisted.snapshot.v1")

        let loaded = PersistenceStore(defaults: defaults).load()

        XCTAssertTrue(loaded.hasCompletedOnboarding)
        XCTAssertEqual(loaded.userProfile.baselineSkinFeel, .balanced)
        XCTAssertEqual(loaded.userProfile.routineComplexity, .steady)
        XCTAssertEqual(loaded.userProfile.knownIrritants, [.fragrance])
        XCTAssertEqual(loaded.userProfile.retinoidSafetyContext, .comfortable)
        XCTAssertEqual(loaded.reports.first?.evidenceSummary, .empty)
        XCTAssertEqual(loaded.reports.first?.analysisMetadata.kind, .legacy)
        XCTAssertEqual(loaded.reports.first?.analysisMetadata.modelVersion, "legacy-local")
        XCTAssertEqual(loaded.reports.first?.analysisMetadata.validationStatus, .legacyUnknown)
        XCTAssertFalse(loaded.routineRemindersEnabled)
        XCTAssertEqual(loaded.routineReminderPreferences, .default)
        XCTAssertTrue(loaded.routineCompletionRecords.isEmpty)
        XCTAssertTrue(loaded.routineSwapOverrides.isEmpty)
        XCTAssertTrue(loaded.productShelfState.items.isEmpty)
        XCTAssertTrue(loaded.customProducts.isEmpty)
        XCTAssertTrue(loaded.progressJournalEntries.isEmpty)
        XCTAssertNil(loaded.remoteAnalysisConsent)
    }

    @MainActor
    func testRestoreRebuildsRoutineForProfileSafetyContext() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        var profile = UserProfile.default
        profile.avoidsRetinoids = false
        profile.retinoidSafetyContext = .pregnantNursingTrying
        let unsafeRoutine = RoutinePlan(
            generatedAt: Date(timeIntervalSince1970: 10),
            focus: [.texture],
            steps: [
                RoutineStep(
                    moment: .evening,
                    order: 1,
                    category: .treatment,
                    product: SampleData.products.first { $0.id == "treatment-retinal" }!,
                    instruction: "Use",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )

        PersistenceStore(defaults: defaults).save(PersistedAppSnapshot(
            userProfile: profile,
            reports: [SampleData.previewReport],
            hasCompletedOnboarding: true,
            routinePlan: unsafeRoutine
        ))

        let appState = AppState(
            routineNotificationScheduler: PersistenceNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )

        XCTAssertFalse(appState.routinePlan.steps.contains { $0.product.id == "treatment-retinal" })
    }
}

final class PrivacyLockManagerTests: XCTestCase {
    @MainActor
    func testJournalLockPreferencePersistsAndLocksOnNextLaunch() async {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let manager = PrivacyLockManager(
            defaults: defaults,
            authenticator: MockDeviceAuthenticator(result: true)
        )

        XCTAssertFalse(manager.isJournalLockEnabled)
        XCTAssertFalse(manager.isLocked)

        manager.setJournalLockEnabled(true)

        XCTAssertTrue(manager.isJournalLockEnabled)
        XCTAssertFalse(manager.isLocked)

        let restored = PrivacyLockManager(
            defaults: defaults,
            authenticator: MockDeviceAuthenticator(result: true)
        )

        XCTAssertTrue(restored.isJournalLockEnabled)
        XCTAssertTrue(restored.isLocked)

        await restored.unlock()

        XCTAssertFalse(restored.isLocked)
        XCTAssertNil(restored.lastError)

        restored.lockIfEnabled()

        XCTAssertTrue(restored.isLocked)

        restored.setJournalLockEnabled(false)

        XCTAssertFalse(restored.isJournalLockEnabled)
        XCTAssertFalse(restored.isLocked)
    }

    @MainActor
    func testJournalLockStaysLockedAfterFailedAuthentication() async {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let manager = PrivacyLockManager(
            defaults: defaults,
            authenticator: MockDeviceAuthenticator(result: false)
        )

        manager.lock()
        await manager.unlock()

        XCTAssertTrue(manager.isLocked)
        XCTAssertEqual(manager.lastError, "Authentication failed.")
    }
}

private func customProduct(id: String) -> SkincareProduct {
    SkincareProduct(
        id: id,
        name: "Custom Serum",
        brand: "User Shelf",
        category: .treatment,
        price: 18,
        budgetTier: .balanced,
        heroIngredients: ["niacinamide", "centella"],
        concernFit: [.redness, .texture],
        fragranceFree: true,
        sensitivityScore: 3,
        usageNote: "Use",
        whyItMatches: "Fixture custom product"
    )
}

private struct PersistenceNoopRoutineNotificationScheduler: RoutineNotificationScheduling {
    func authorizationState() async -> RoutineReminderAuthorizationState {
        .granted
    }

    func scheduleReminders(
        for plan: RoutinePlan,
        preferences: RoutineReminderPreferences
    ) async throws -> [RoutineReminderSlot] {
        []
    }

    func cancelReminders() async {}
}

private struct MockDeviceAuthenticator: DeviceAuthenticationServicing {
    var result: Bool
    var biometryLabel = "Face ID"
    var biometrySymbolName = "faceid"

    func authenticate(reason: String) async throws -> Bool {
        result
    }
}
