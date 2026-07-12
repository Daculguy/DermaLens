import Foundation

struct PrivacyExportPayload: Codable, Equatable {
    struct Counts: Codable, Equatable {
        var reports: Int
        var routineCompletionRecords: Int
        var routineSwapOverrides: Int
        var productShelfItems: Int
        var customProducts: Int
        var progressJournalEntries: Int
    }

    struct Profile: Codable, Equatable {
        var skinType: String
        var baselineSkinFeel: String
        var sensitivity: Int
        var routineComplexity: String
        var budget: String
        var avoidsFragrance: Bool
        var avoidsRetinoids: Bool
        var knownIrritants: [String]
        var retinoidSafetyContext: String
        var shouldAvoidRetinoids: Bool
        var currentGoals: [String]
    }

    struct Report: Codable, Equatable {
        var id: UUID
        var createdAt: Date
        var confidenceLevel: String
        var scanQualityAverage: Double
        var depthGuidanceAvailable: Bool
        var evidenceFrameCount: Int
        var evidenceCoverageScore: Double
        var evidenceCoveredRegions: [String]
        var evidenceRequiredRegions: [String]
        var evidenceComplete: Bool
        var createdFromImageEvidence: Bool
        var regionEvidence: [RegionEvidence]
        var analysisProviderName: String
        var analysisKind: String
        var analysisRunsOnDevice: Bool
        var analysisRetainsImages: Bool
        var analysisRemoteUploadAttempted: Bool
        var analysisUsedFallback: Bool
        var analysisFallbackReason: String?
        var analysisModelVersion: String
        var analysisRequestID: String?
        var analysisValidationStatus: String
        var blockingIssues: [String]
        var topConcerns: [Concern]
        var summary: String
    }

    struct RegionEvidence: Codable, Equatable {
        var region: String
        var frameCount: Int
        var freshGuidedFrameCount: Int
        var verifiedFrameCount: Int
        var averageQuality: Double
        var confidence: String
        var captured: Bool
        var freshGuidedCapture: Bool
        var verified: Bool
        var verificationStatus: String
    }

    struct Concern: Codable, Equatable {
        var concern: String
        var score: Int
        var confidence: String
        var primaryRegion: String
        var explanation: String
    }

    struct Routine: Codable, Equatable {
        var id: UUID
        var generatedAt: Date
        var focus: [String]
        var steps: [RoutineStep]
        var weeklyNotes: [String]
    }

    struct RoutineStep: Codable, Equatable {
        var id: UUID
        var moment: String
        var order: Int
        var category: String
        var productID: String
        var productName: String
        var productBrand: String
        var productCatalogSource: String
        var productEvidenceLevel: String
        var productIngredientListCoverage: String
        var productCommercialStatus: String
        var productRecommendationReadiness: String
        var productSourceLabel: String
        var productSourceURL: URL?
        var productSourceLastCheckedAt: Date?
        var productINCIVerifiedAt: Date?
        var productSourceReviewer: String?
        var productTrustGrade: String
        var productTrustScore: Int
        var productTrustStrengths: [String]
        var productTrustLimitations: [String]
        var instruction: String
        var caution: String?
        var fitScore: Int?
        var selectionReasons: [String]
    }

    struct RoutineSwap: Codable, Equatable {
        var slotID: String
        var moment: String
        var order: Int
        var category: String
        var productID: String
        var replacedProductID: String
        var updatedAt: Date
    }

    struct RoutineCompletion: Codable, Equatable {
        var dayKey: String
        var routinePlanID: UUID
        var routineGeneratedAt: Date
        var stepKey: String
        var moment: String
        var completedAt: Date
    }

    struct ShelfItem: Codable, Equatable {
        var productID: String
        var status: String
        var updatedAt: Date
        var note: String?
    }

    struct CustomProduct: Codable, Equatable {
        var id: String
        var name: String
        var brand: String
        var category: String
        var price: Int
        var budgetTier: String
        var heroIngredients: [String]
        var fullIngredients: [String]
        var ingredientListCoverage: String
        var concernFit: [String]
        var fragranceFree: Bool
        var sensitivityScore: Int
        var usageNote: String
        var whyItMatches: String
        var catalogSource: String
        var evidenceLevel: String
        var commercialStatus: String
        var recommendationReadiness: String
        var sourceLabel: String
        var sourceURL: URL?
        var sourceLastCheckedAt: Date?
        var inciVerifiedAt: Date?
        var sourceReviewer: String?
        var trustGrade: String
        var trustScore: Int
        var trustStrengths: [String]
        var trustLimitations: [String]
    }

    struct JournalEntry: Codable, Equatable {
        var id: UUID
        var createdAt: Date
        var dayID: String
        var reportID: UUID?
        var reportCreatedAt: Date?
        var reportTopConcerns: [String]
        var routinePlanID: UUID?
        var comfortRating: Int?
        var skinFeel: String
        var tags: [String]
        var note: String
    }

    struct ReminderTime: Codable, Equatable {
        var hour: Int
        var minute: Int
        var clockText: String
        var displayText: String
    }

    struct ReminderPreferences: Codable, Equatable {
        var morning: ReminderTime
        var evening: ReminderTime
    }

    var schemaVersion: String
    var exportedAt: Date
    var storageNotice: String
    var excludedData: [String]
    var remoteAnalysisConsentGranted: Bool
    var remoteAnalysisHost: String?
    var remoteAnalysisConsentHost: String?
    var remoteAnalysisConsentCopyVersion: String?
    var remoteAnalysisConsentGrantedAt: Date?
    var routineReminderPreferences: ReminderPreferences
    var counts: Counts
    var profile: Profile
    var reports: [Report]
    var routine: Routine?
    var routineCompletionRecords: [RoutineCompletion]
    var routineSwapOverrides: [RoutineSwap]
    var productShelfItems: [ShelfItem]
    var customProducts: [CustomProduct]
    var progressJournalEntries: [JournalEntry]
}

struct PrivacyExportBuilder {
    let schemaVersion = "dermalens.privacy-export.v10"

    func exportText(
        userProfile: UserProfile,
        reports: [SkinReport],
        routinePlan: RoutinePlan?,
        routineCompletionRecords: [RoutineCompletionRecord],
        routineSwapOverrides: [RoutineSwapOverride] = [],
        productShelfState: ProductShelfState,
        customProducts: [SkincareProduct] = [],
        progressJournalEntries: [ProgressJournalEntry],
        routineReminderPreferences: RoutineReminderPreferences = .default,
        remoteAnalysisConsent: RemoteAnalysisConsentRecord? = nil,
        remoteAnalysisHost: String? = nil,
        exportedAt: Date = Date()
    ) -> String {
        let payload = makePayload(
            userProfile: userProfile,
            reports: reports,
            routinePlan: routinePlan,
            routineCompletionRecords: routineCompletionRecords,
            routineSwapOverrides: routineSwapOverrides,
            productShelfState: productShelfState,
            customProducts: customProducts,
            progressJournalEntries: progressJournalEntries,
            routineReminderPreferences: routineReminderPreferences,
            remoteAnalysisConsent: remoteAnalysisConsent,
            remoteAnalysisHost: remoteAnalysisHost,
            exportedAt: exportedAt
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(payload),
              let text = String(data: data, encoding: .utf8) else {
            return #"{"schemaVersion":"dermalens.privacy-export.v10","error":"export_failed"}"#
        }

        return text
    }

    func makePayload(
        userProfile: UserProfile,
        reports: [SkinReport],
        routinePlan: RoutinePlan?,
        routineCompletionRecords: [RoutineCompletionRecord],
        routineSwapOverrides: [RoutineSwapOverride] = [],
        productShelfState: ProductShelfState,
        customProducts: [SkincareProduct] = [],
        progressJournalEntries: [ProgressJournalEntry],
        routineReminderPreferences: RoutineReminderPreferences = .default,
        remoteAnalysisConsent: RemoteAnalysisConsentRecord? = nil,
        remoteAnalysisHost: String? = nil,
        exportedAt: Date = Date()
    ) -> PrivacyExportPayload {
        PrivacyExportPayload(
            schemaVersion: schemaVersion,
            exportedAt: exportedAt,
            storageNotice: "DermaLens exports structured local prototype data, including manually entered shelf products. Raw scan frames and Face ID biometric templates are not included.",
            excludedData: [
                "raw camera frames",
                "saved face photos",
                "Face ID biometric templates",
                "payment card details",
                "analytics identifiers"
            ],
            remoteAnalysisConsentGranted: remoteAnalysisConsent != nil,
            remoteAnalysisHost: remoteAnalysisHost,
            remoteAnalysisConsentHost: remoteAnalysisConsent?.host,
            remoteAnalysisConsentCopyVersion: remoteAnalysisConsent?.copyVersion,
            remoteAnalysisConsentGrantedAt: remoteAnalysisConsent?.grantedAt,
            routineReminderPreferences: routineReminderPreferencesExport(from: routineReminderPreferences),
            counts: PrivacyExportPayload.Counts(
                reports: reports.count,
                routineCompletionRecords: routineCompletionRecords.count,
                routineSwapOverrides: routineSwapOverrides.count,
                productShelfItems: productShelfState.items.count,
                customProducts: customProducts.count,
                progressJournalEntries: progressJournalEntries.count
            ),
            profile: profileExport(from: userProfile),
            reports: reports
                .sorted { $0.createdAt > $1.createdAt }
                .map(reportExport),
            routine: routinePlan.map(routineExport),
            routineCompletionRecords: routineCompletionRecords
                .sorted { $0.completedAt > $1.completedAt }
                .map(routineCompletionExport),
            routineSwapOverrides: routineSwapOverrides
                .sorted { lhs, rhs in
                    if lhs.updatedAt == rhs.updatedAt {
                        return lhs.slotID < rhs.slotID
                    }
                    return lhs.updatedAt > rhs.updatedAt
                }
                .map(routineSwapExport),
            productShelfItems: productShelfState.items
                .sorted { lhs, rhs in
                    if lhs.updatedAt == rhs.updatedAt {
                        return lhs.productID < rhs.productID
                    }
                    return lhs.updatedAt > rhs.updatedAt
                }
                .map(shelfItemExport),
            customProducts: customProducts
                .sorted { lhs, rhs in
                    if lhs.category == rhs.category {
                        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                    }
                    return lhs.category.rawValue < rhs.category.rawValue
                }
                .map(customProductExport),
            progressJournalEntries: ProgressJournal()
                .sorted(progressJournalEntries)
                .map(journalEntryExport)
        )
    }

    private func routineReminderPreferencesExport(
        from preferences: RoutineReminderPreferences
    ) -> PrivacyExportPayload.ReminderPreferences {
        PrivacyExportPayload.ReminderPreferences(
            morning: routineReminderTimeExport(from: preferences.morning),
            evening: routineReminderTimeExport(from: preferences.evening)
        )
    }

    private func routineReminderTimeExport(
        from time: RoutineReminderTime
    ) -> PrivacyExportPayload.ReminderTime {
        PrivacyExportPayload.ReminderTime(
            hour: time.hour,
            minute: time.minute,
            clockText: time.clockText,
            displayText: time.displayText
        )
    }

    private func profileExport(from profile: UserProfile) -> PrivacyExportPayload.Profile {
        PrivacyExportPayload.Profile(
            skinType: profile.skinType,
            baselineSkinFeel: profile.baselineSkinFeel.rawValue,
            sensitivity: profile.sensitivity,
            routineComplexity: profile.routineComplexity.rawValue,
            budget: profile.budget.rawValue,
            avoidsFragrance: profile.avoidsFragrance,
            avoidsRetinoids: profile.avoidsRetinoids,
            knownIrritants: profile.knownIrritants
                .map(\.rawValue)
                .sorted(),
            retinoidSafetyContext: profile.retinoidSafetyContext.rawValue,
            shouldAvoidRetinoids: profile.shouldAvoidRetinoids,
            currentGoals: profile.currentGoals
                .map(\.rawValue)
                .sorted()
        )
    }

    private func reportExport(_ report: SkinReport) -> PrivacyExportPayload.Report {
        PrivacyExportPayload.Report(
            id: report.id,
            createdAt: report.createdAt,
            confidenceLevel: report.evidenceSummary.confidenceLevel(for: report.scanQuality).rawValue,
            scanQualityAverage: report.scanQuality.average,
            depthGuidanceAvailable: report.scanQuality.depthGuidanceAvailable,
            evidenceFrameCount: report.evidenceSummary.capturedFrameCount,
            evidenceCoverageScore: report.evidenceSummary.coverageScore,
            evidenceCoveredRegions: report.evidenceSummary.coveredRegions.map(\.rawValue),
            evidenceRequiredRegions: report.evidenceSummary.requiredRegions.map(\.rawValue),
            evidenceComplete: report.evidenceSummary.isComplete,
            createdFromImageEvidence: report.evidenceSummary.createdFromImageEvidence,
            regionEvidence: report.evidenceSummary.regionEvidence.map(regionEvidenceExport),
            analysisProviderName: report.analysisMetadata.providerName,
            analysisKind: report.analysisMetadata.kind.rawValue,
            analysisRunsOnDevice: report.analysisMetadata.runsOnDevice,
            analysisRetainsImages: report.analysisMetadata.retainsImages,
            analysisRemoteUploadAttempted: report.analysisMetadata.remoteUploadAttempted,
            analysisUsedFallback: report.analysisMetadata.usedFallback,
            analysisFallbackReason: report.analysisMetadata.fallbackReason,
            analysisModelVersion: report.analysisMetadata.modelVersion,
            analysisRequestID: report.analysisMetadata.requestID,
            analysisValidationStatus: report.analysisMetadata.validationStatus.rawValue,
            blockingIssues: report.scanQuality.blockingIssues
                .map(\.rawValue)
                .sorted(),
            topConcerns: report.topConcerns.map(concernExport),
            summary: report.summary
        )
    }

    private func regionEvidenceExport(_ evidence: ScanRegionEvidence) -> PrivacyExportPayload.RegionEvidence {
        PrivacyExportPayload.RegionEvidence(
            region: evidence.region.rawValue,
            frameCount: evidence.frameCount,
            freshGuidedFrameCount: evidence.freshGuidedFrameCount,
            verifiedFrameCount: evidence.verifiedFrameCount,
            averageQuality: evidence.averageQuality,
            confidence: evidence.confidence.rawValue,
            captured: evidence.isCaptured,
            freshGuidedCapture: evidence.isFreshGuidedCapture,
            verified: evidence.isVerified,
            verificationStatus: evidence.verificationStatus
        )
    }

    private func concernExport(_ score: ConcernScore) -> PrivacyExportPayload.Concern {
        PrivacyExportPayload.Concern(
            concern: score.concern.rawValue,
            score: score.score,
            confidence: score.confidence.rawValue,
            primaryRegion: score.primaryRegion.rawValue,
            explanation: score.explanation
        )
    }

    private func routineExport(_ routine: RoutinePlan) -> PrivacyExportPayload.Routine {
        PrivacyExportPayload.Routine(
            id: routine.id,
            generatedAt: routine.generatedAt,
            focus: routine.focus
                .map(\.rawValue)
                .sorted(),
            steps: routine.steps
                .sorted { lhs, rhs in
                    if lhs.moment == rhs.moment {
                        return lhs.order < rhs.order
                    }
                    return lhs.moment.rawValue < rhs.moment.rawValue
                }
                .map(routineStepExport),
            weeklyNotes: routine.weeklyNotes
        )
    }

    private func routineStepExport(_ step: RoutineStep) -> PrivacyExportPayload.RoutineStep {
        let trust = step.product.trustSummary
        PrivacyExportPayload.RoutineStep(
            id: step.id,
            moment: step.moment.rawValue,
            order: step.order,
            category: step.category.rawValue,
            productID: step.product.id,
            productName: step.product.name,
            productBrand: step.product.brand,
            productCatalogSource: step.product.catalogSource.rawValue,
            productEvidenceLevel: step.product.evidenceLevel.rawValue,
            productIngredientListCoverage: step.product.ingredientListCoverage.rawValue,
            productCommercialStatus: step.product.commercialStatus.rawValue,
            productRecommendationReadiness: step.product.recommendationReadiness.rawValue,
            productSourceLabel: step.product.sourceMetadata.sourceLabel,
            productSourceURL: step.product.sourceMetadata.sourceURLForExport,
            productSourceLastCheckedAt: step.product.sourceMetadata.sourceLastCheckedAt,
            productINCIVerifiedAt: step.product.sourceMetadata.inciVerifiedAt,
            productSourceReviewer: step.product.sourceMetadata.reviewer,
            productTrustGrade: trust.grade.rawValue,
            productTrustScore: trust.score,
            productTrustStrengths: trust.strengths,
            productTrustLimitations: trust.limitations,
            instruction: step.instruction,
            caution: step.caution,
            fitScore: step.fitScore,
            selectionReasons: step.selectionReasons
        )
    }

    private func routineCompletionExport(_ record: RoutineCompletionRecord) -> PrivacyExportPayload.RoutineCompletion {
        PrivacyExportPayload.RoutineCompletion(
            dayKey: record.dayKey,
            routinePlanID: record.routinePlanID,
            routineGeneratedAt: record.routineGeneratedAt,
            stepKey: record.stepKey.storageID,
            moment: record.moment.rawValue,
            completedAt: record.completedAt
        )
    }

    private func routineSwapExport(_ override: RoutineSwapOverride) -> PrivacyExportPayload.RoutineSwap {
        PrivacyExportPayload.RoutineSwap(
            slotID: override.slotID,
            moment: override.moment.rawValue,
            order: override.order,
            category: override.category.rawValue,
            productID: override.productID,
            replacedProductID: override.replacedProductID,
            updatedAt: override.updatedAt
        )
    }

    private func shelfItemExport(_ item: ProductShelfItem) -> PrivacyExportPayload.ShelfItem {
        PrivacyExportPayload.ShelfItem(
            productID: item.productID,
            status: item.status.rawValue,
            updatedAt: item.updatedAt,
            note: item.note
        )
    }

    private func customProductExport(_ product: SkincareProduct) -> PrivacyExportPayload.CustomProduct {
        let trust = product.trustSummary
        PrivacyExportPayload.CustomProduct(
            id: product.id,
            name: product.name,
            brand: product.brand,
            category: product.category.rawValue,
            price: product.price,
            budgetTier: product.budgetTier.rawValue,
            heroIngredients: product.heroIngredients.sorted(),
            fullIngredients: product.fullIngredients.sorted(),
            ingredientListCoverage: product.ingredientListCoverage.rawValue,
            concernFit: product.concernFit.map(\.rawValue).sorted(),
            fragranceFree: product.fragranceFree,
            sensitivityScore: product.sensitivityScore,
            usageNote: product.usageNote,
            whyItMatches: product.whyItMatches,
            catalogSource: product.catalogSource.rawValue,
            evidenceLevel: product.evidenceLevel.rawValue,
            commercialStatus: product.commercialStatus.rawValue,
            recommendationReadiness: product.recommendationReadiness.rawValue,
            sourceLabel: product.sourceMetadata.sourceLabel,
            sourceURL: product.sourceMetadata.sourceURLForExport,
            sourceLastCheckedAt: product.sourceMetadata.sourceLastCheckedAt,
            inciVerifiedAt: product.sourceMetadata.inciVerifiedAt,
            sourceReviewer: product.sourceMetadata.reviewer,
            trustGrade: trust.grade.rawValue,
            trustScore: trust.score,
            trustStrengths: trust.strengths,
            trustLimitations: trust.limitations
        )
    }

    private func journalEntryExport(_ entry: ProgressJournalEntry) -> PrivacyExportPayload.JournalEntry {
        PrivacyExportPayload.JournalEntry(
            id: entry.id,
            createdAt: entry.createdAt,
            dayID: entry.dayID,
            reportID: entry.reportID,
            reportCreatedAt: entry.reportCreatedAt,
            reportTopConcerns: entry.reportTopConcerns
                .map(\.rawValue)
                .sorted(),
            routinePlanID: entry.routinePlanID,
            comfortRating: entry.comfortRating,
            skinFeel: entry.skinFeel.rawValue,
            tags: entry.tags
                .map(\.rawValue)
                .sorted(),
            note: entry.note
        )
    }
}
