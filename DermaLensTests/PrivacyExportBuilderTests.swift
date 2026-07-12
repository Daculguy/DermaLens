import XCTest
@testable import DermaLens

final class PrivacyExportBuilderTests: XCTestCase {
    func testExportPayloadSummarizesLocalStateWithoutRawScanMedia() throws {
        let report = SampleData.previewReport
        let routine = SampleData.previewRoutine
        let journalEntry = ProgressJournal().makeEntry(
            report: report,
            routinePlanID: routine.id,
            skinFeel: .dry,
            tags: [.poorSleep, .travel],
            note: "Flight day",
            comfortRating: 2,
            date: Date(timeIntervalSince1970: 200)
        )
        let shelf = ProductShelfState(items: [
            ProductShelfItem(
                productID: "custom-export",
                status: .using,
                updatedAt: Date(timeIntervalSince1970: 150),
                note: nil
            )
        ])
        let custom = customProduct(id: "custom-export")
        let completion = RoutineAdherenceTracker().records(
            afterToggling: try XCTUnwrap(routine.steps.first),
            in: routine,
            records: [],
            on: Date(timeIntervalSince1970: 250)
        )
        let swap = RoutineSwapOverride(
            step: try XCTUnwrap(routine.steps.first),
            product: try XCTUnwrap(SampleData.products.first { $0.id == "cleanser-balanced-milk" }),
            updatedAt: Date(timeIntervalSince1970: 275)
        )
        let remoteConsent = RemoteAnalysisConsentRecord(
            host: "analysis.example.com",
            grantedAt: Date(timeIntervalSince1970: 290)
        )
        let reminderPreferences = RoutineReminderPreferences(
            morning: RoutineReminderTime(hour: 7, minute: 30),
            evening: RoutineReminderTime(hour: 22, minute: 15)
        )

        let payload = PrivacyExportBuilder().makePayload(
            userProfile: .default,
            reports: [report],
            routinePlan: routine,
            routineCompletionRecords: completion,
            routineSwapOverrides: [swap],
            productShelfState: shelf,
            customProducts: [custom],
            progressJournalEntries: [journalEntry],
            routineReminderPreferences: reminderPreferences,
            remoteAnalysisConsent: remoteConsent,
            remoteAnalysisHost: "analysis.example.com",
            exportedAt: Date(timeIntervalSince1970: 300)
        )

        XCTAssertEqual(payload.schemaVersion, "dermalens.privacy-export.v10")
        XCTAssertTrue(payload.remoteAnalysisConsentGranted)
        XCTAssertEqual(payload.remoteAnalysisHost, "analysis.example.com")
        XCTAssertEqual(payload.remoteAnalysisConsentHost, "analysis.example.com")
        XCTAssertEqual(payload.remoteAnalysisConsentCopyVersion, RemoteAnalysisConsentRecord.currentCopyVersion)
        XCTAssertEqual(payload.remoteAnalysisConsentGrantedAt, Date(timeIntervalSince1970: 290))
        XCTAssertEqual(payload.routineReminderPreferences.morning.clockText, "07:30")
        XCTAssertEqual(payload.routineReminderPreferences.morning.displayText, "7:30 AM")
        XCTAssertEqual(payload.routineReminderPreferences.evening.clockText, "22:15")
        XCTAssertEqual(payload.routineReminderPreferences.evening.displayText, "10:15 PM")
        XCTAssertEqual(payload.counts.reports, 1)
        XCTAssertEqual(payload.counts.routineCompletionRecords, 1)
        XCTAssertEqual(payload.counts.routineSwapOverrides, 1)
        XCTAssertEqual(payload.counts.productShelfItems, 1)
        XCTAssertEqual(payload.counts.customProducts, 1)
        XCTAssertEqual(payload.counts.progressJournalEntries, 1)
        XCTAssertEqual(payload.profile.baselineSkinFeel, UserProfile.default.baselineSkinFeel.rawValue)
        XCTAssertEqual(payload.profile.routineComplexity, UserProfile.default.routineComplexity.rawValue)
        XCTAssertEqual(payload.profile.knownIrritants, UserProfile.default.knownIrritants.map(\.rawValue).sorted())
        XCTAssertEqual(payload.profile.retinoidSafetyContext, UserProfile.default.retinoidSafetyContext.rawValue)
        let exportedReport = try XCTUnwrap(payload.reports.first)
        XCTAssertEqual(exportedReport.topConcerns.count, 3)
        XCTAssertEqual(exportedReport.evidenceFrameCount, SampleData.previewReport.evidenceSummary.capturedFrameCount)
        XCTAssertEqual(exportedReport.evidenceCoverageScore, 1, accuracy: 0.001)
        XCTAssertEqual(exportedReport.evidenceCoveredRegions, GuidedScanStep.baselineSequence.map { $0.region.rawValue })
        XCTAssertEqual(exportedReport.evidenceRequiredRegions, GuidedScanStep.baselineSequence.map { $0.region.rawValue })
        XCTAssertTrue(exportedReport.evidenceComplete)
        XCTAssertTrue(exportedReport.createdFromImageEvidence)
        XCTAssertEqual(exportedReport.regionEvidence.count, GuidedScanStep.baselineSequence.count)
        XCTAssertTrue(exportedReport.regionEvidence.allSatisfy(\.captured))
        XCTAssertTrue(exportedReport.regionEvidence.allSatisfy(\.freshGuidedCapture))
        XCTAssertTrue(exportedReport.regionEvidence.allSatisfy { !$0.verified })
        XCTAssertTrue(exportedReport.regionEvidence.allSatisfy { $0.freshGuidedFrameCount == $0.frameCount })
        XCTAssertTrue(exportedReport.regionEvidence.allSatisfy { $0.verifiedFrameCount == 0 })
        XCTAssertTrue(exportedReport.regionEvidence.allSatisfy { $0.verificationStatus == "freshGuidedCapture" })
        XCTAssertEqual(exportedReport.analysisKind, AnalysisMetadata.Kind.simulatedLocal.rawValue)
        XCTAssertEqual(exportedReport.analysisProviderName, "Simulated local analyzer")
        XCTAssertTrue(exportedReport.analysisRunsOnDevice)
        XCTAssertFalse(exportedReport.analysisRetainsImages)
        XCTAssertFalse(exportedReport.analysisRemoteUploadAttempted)
        XCTAssertFalse(exportedReport.analysisUsedFallback)
        XCTAssertEqual(exportedReport.analysisModelVersion, "simulated-rules-v1")
        XCTAssertNil(exportedReport.analysisRequestID)
        XCTAssertEqual(exportedReport.analysisValidationStatus, AnalysisValidationStatus.prototype.rawValue)
        XCTAssertEqual(payload.routineSwapOverrides.first?.productID, "cleanser-balanced-milk")
        XCTAssertEqual(payload.routineSwapOverrides.first?.replacedProductID, routine.steps.first?.product.id)
        XCTAssertEqual(payload.routine?.steps.first?.productCatalogSource, ProductCatalogSource.curatedPrototype.rawValue)
        XCTAssertEqual(payload.routine?.steps.first?.productEvidenceLevel, ProductEvidenceLevel.labelBased.rawValue)
        XCTAssertEqual(payload.routine?.steps.first?.productIngredientListCoverage, IngredientListCoverage.heroOnly.rawValue)
        XCTAssertEqual(payload.routine?.steps.first?.productCommercialStatus, ProductCommercialStatus.independent.rawValue)
        XCTAssertEqual(payload.routine?.steps.first?.productRecommendationReadiness, ProductRecommendationReadiness.prototypeOnly.rawValue)
        XCTAssertEqual(payload.routine?.steps.first?.productSourceLabel, "DermaLens prototype catalog")
        XCTAssertNotNil(payload.routine?.steps.first?.productSourceLastCheckedAt)
        XCTAssertEqual(payload.routine?.steps.first?.productSourceReviewer, "DermaLens product rules v0.1")
        XCTAssertEqual(payload.routine?.steps.first?.productTrustGrade, ProductTrustGrade.provisional.rawValue)
        XCTAssertNotNil(payload.routine?.steps.first?.productTrustScore)
        XCTAssertFalse(payload.routine?.steps.first?.productTrustLimitations.isEmpty ?? true)
        XCTAssertNotNil(payload.routine?.steps.first?.fitScore)
        XCTAssertFalse(payload.routine?.steps.first?.selectionReasons.isEmpty ?? true)
        XCTAssertEqual(payload.productShelfItems.first?.status, ProductShelfStatus.using.rawValue)
        XCTAssertEqual(payload.customProducts.first?.id, custom.id)
        XCTAssertEqual(payload.customProducts.first?.heroIngredients, custom.heroIngredients.sorted())
        XCTAssertEqual(payload.customProducts.first?.fullIngredients, custom.fullIngredients.sorted())
        XCTAssertEqual(payload.customProducts.first?.ingredientListCoverage, custom.ingredientListCoverage.rawValue)
        XCTAssertEqual(payload.customProducts.first?.catalogSource, ProductCatalogSource.userEntered.rawValue)
        XCTAssertEqual(payload.customProducts.first?.evidenceLevel, ProductEvidenceLevel.userProvided.rawValue)
        XCTAssertEqual(payload.customProducts.first?.commercialStatus, ProductCommercialStatus.independent.rawValue)
        XCTAssertEqual(payload.customProducts.first?.recommendationReadiness, ProductRecommendationReadiness.userReviewNeeded.rawValue)
        XCTAssertEqual(payload.customProducts.first?.sourceLabel, ProductSourceMetadata.userEntered.sourceLabel)
        XCTAssertEqual(payload.customProducts.first?.sourceReviewer, ProductSourceMetadata.userEntered.reviewer)
        XCTAssertNotNil(payload.customProducts.first?.trustGrade)
        XCTAssertNotNil(payload.customProducts.first?.trustScore)
        XCTAssertFalse(payload.customProducts.first?.trustLimitations.isEmpty ?? true)
        XCTAssertEqual(payload.progressJournalEntries.first?.note, "Flight day")
        XCTAssertTrue(payload.excludedData.contains("raw camera frames"))
        XCTAssertTrue(payload.excludedData.contains("Face ID biometric templates"))
    }

    func testExportTextIsDecodableAndDoesNotExposeRawFrameFields() throws {
        let text = PrivacyExportBuilder().exportText(
            userProfile: .default,
            reports: [SampleData.previewReport],
            routinePlan: SampleData.previewRoutine,
            routineCompletionRecords: [],
            productShelfState: .empty,
            progressJournalEntries: [],
            exportedAt: Date(timeIntervalSince1970: 400)
        )

        let data = try XCTUnwrap(text.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(PrivacyExportPayload.self, from: data)

        XCTAssertEqual(payload.counts.reports, 1)
        XCTAssertFalse(text.contains("jpegData"))
        XCTAssertFalse(text.contains("base64"))
        XCTAssertFalse(text.contains("deviceModel"))
    }

    func testProductSourceURLIsSanitizedForExport() throws {
        let sourceMetadata = ProductSourceMetadata(
            sourceLabel: "Retailer page",
            sourceURL: try XCTUnwrap(URL(string: "https://example.com/product?token=secret#reviews")),
            sourceLastCheckedAt: Date(timeIntervalSince1970: 700),
            reviewer: "QA reviewer"
        )
        let product = customProduct(id: "custom-source", sourceMetadata: sourceMetadata)

        let payload = PrivacyExportBuilder().makePayload(
            userProfile: .default,
            reports: [],
            routinePlan: nil,
            routineCompletionRecords: [],
            productShelfState: .empty,
            customProducts: [product],
            progressJournalEntries: [],
            exportedAt: Date(timeIntervalSince1970: 800)
        )

        XCTAssertEqual(payload.customProducts.first?.sourceURL?.absoluteString, "https://example.com/product")
        XCTAssertEqual(payload.customProducts.first?.sourceLabel, "Retailer page")
        XCTAssertEqual(payload.customProducts.first?.sourceReviewer, "QA reviewer")
    }

    @MainActor
    func testAppStatePrivacyExportReflectsCurrentLocalState() throws {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: ExportNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        appState.scanHistory = [SampleData.previewReport]
        let product = customProduct(id: "custom-state-export", category: .cleanser)
        appState.addCustomProduct(product, initialStatus: .owned)
        appState.addProgressJournalEntry(
            skinFeel: .calm,
            tags: [.stress],
            note: "Settled",
            linkedReport: SampleData.previewReport,
            comfortRating: 4
        )

        let data = try XCTUnwrap(appState.privacyExportText.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(PrivacyExportPayload.self, from: data)

        XCTAssertEqual(payload.counts.reports, 1)
        XCTAssertEqual(payload.counts.productShelfItems, 1)
        XCTAssertEqual(payload.counts.customProducts, 1)
        XCTAssertEqual(payload.counts.progressJournalEntries, 1)
        XCTAssertEqual(payload.customProducts.first?.id, product.id)
        XCTAssertEqual(payload.progressJournalEntries.first?.note, "Settled")
    }

    @MainActor
    func testAppStatePrivacyExportOmitsPreviewRoutineBeforeOnboarding() throws {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: ExportNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )

        let data = try XCTUnwrap(appState.privacyExportText.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(PrivacyExportPayload.self, from: data)

        XCTAssertNil(payload.routine)
        XCTAssertFalse(appState.hasCompletedOnboarding)
    }
}

private func customProduct(
    id: String,
    category: ProductCategory = .treatment,
    sourceMetadata: ProductSourceMetadata = .userEntered
) -> SkincareProduct {
    SkincareProduct(
        id: id,
        name: "Custom \(category.title)",
        brand: "User Shelf",
        category: category,
        price: 22,
        budgetTier: .balanced,
        heroIngredients: ["centella", "niacinamide"],
        fullIngredients: ["water", "glycerin", "centella", "niacinamide"],
        ingredientListCoverage: .completeINCI,
        concernFit: [.redness, .texture, .barrier],
        fragranceFree: true,
        sensitivityScore: 3,
        usageNote: "Use",
        whyItMatches: "Fixture custom product",
        catalogSource: .userEntered,
        evidenceLevel: .userProvided,
        sourceMetadata: sourceMetadata
    )
}

private struct ExportNoopRoutineNotificationScheduler: RoutineNotificationScheduling {
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
