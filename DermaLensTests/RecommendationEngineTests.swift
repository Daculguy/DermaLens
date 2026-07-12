import XCTest
@testable import DermaLens

final class RecommendationEngineTests: XCTestCase {
    func testScanQualityBlocksClearlyWeakCapture() {
        let weakQuality = ScanQuality(
            lighting: 0.4,
            alignment: 0.5,
            stability: 0.91,
            clarity: 0.42,
            depthGuidanceAvailable: false
        )

        XCTAssertFalse(weakQuality.isUsableForAnalysis)
        XCTAssertEqual(Set(weakQuality.blockingIssues), [.lighting, .alignment, .clarity])
    }

    func testRetinoidAvoidanceKeepsRetinoidProductsOutOfRoutine() {
        let report = SkinReport(
            createdAt: Date(),
            scanQuality: .preview,
            scores: [
                ConcernScore(
                    concern: .texture,
                    score: 92,
                    confidence: .high,
                    primaryRegion: .forehead,
                    explanation: "Texture-heavy fixture"
                ),
                ConcernScore(
                    concern: .pores,
                    score: 78,
                    confidence: .high,
                    primaryRegion: .nose,
                    explanation: "Pore-heavy fixture"
                )
            ],
            visibleStrengths: [],
            summary: "Fixture"
        )
        var profile = UserProfile.default
        profile.avoidsRetinoids = true
        profile.currentGoals = [.texture, .pores]

        let plan = RecommendationEngine().buildRoutine(for: report, profile: profile)

        XCTAssertFalse(plan.steps.contains { step in
            step.product.hasIngredientSignal(matching: ["retinal", "retinol", "retinoid", "retinyl", "adapalene", "tretinoin"])
        })
    }

    func testRetinoidAvoidanceUsesFullIngredientList() {
        var profile = UserProfile.default
        profile.avoidsRetinoids = true
        profile.currentGoals = [.texture]

        let retinoid = fixtureProduct(
            id: "hidden-retinoid",
            category: .treatment,
            ingredients: ["peptides"],
            fullIngredients: ["water", "glycerin", "adapalene"],
            ingredientListCoverage: .completeINCI,
            concerns: [.texture]
        )
        let nonRetinoid = fixtureProduct(
            id: "azelaic",
            category: .treatment,
            ingredients: ["azelaic acid"],
            concerns: [.texture]
        )

        let plan = RecommendationEngine(catalog: [retinoid, nonRetinoid]).buildRoutine(
            for: SampleData.previewReport,
            profile: profile
        )

        XCTAssertFalse(plan.steps.contains { $0.product.id == retinoid.id })
        XCTAssertTrue(plan.steps.contains { $0.product.id == nonRetinoid.id })
    }

    func testRetinoidSafetyContextHardExcludesRetinoids() {
        var profile = UserProfile.default
        profile.avoidsRetinoids = false
        profile.retinoidSafetyContext = .pregnantNursingTrying
        profile.currentGoals = [.texture]

        let plan = RecommendationEngine(catalog: [
            fixtureProduct(id: "retinal", category: .treatment, ingredients: ["retinaldehyde"], concerns: [.texture]),
            fixtureProduct(id: "moisturizer", category: .moisturizer, ingredients: ["ceramides"], concerns: [.barrier]),
            fixtureProduct(id: "sunscreen", category: .sunscreen, ingredients: ["zinc oxide"], concerns: [.darkSpots])
        ]).buildRoutine(for: SampleData.previewReport, profile: profile)

        XCTAssertFalse(plan.steps.contains { $0.product.id == "retinal" })
        XCTAssertTrue(plan.weeklyNotes.contains { $0.localizedCaseInsensitiveContains("Retinoids are avoided") })
    }

    func testMinimalRoutineSkipsOptionalExfoliant() {
        var profile = UserProfile.default
        profile.routineComplexity = .minimal
        profile.currentGoals = [.texture]

        let plan = RecommendationEngine(catalog: [
            fixtureProduct(id: "exfoliant", category: .exfoliant, ingredients: ["PHA"], concerns: [.texture]),
            fixtureProduct(id: "moisturizer", category: .moisturizer, ingredients: ["ceramides"], concerns: [.barrier]),
            fixtureProduct(id: "sunscreen", category: .sunscreen, ingredients: ["zinc oxide"], concerns: [.darkSpots])
        ]).buildRoutine(for: SampleData.previewReport, profile: profile)

        XCTAssertFalse(plan.steps.contains { $0.category == .exfoliant })
        XCTAssertTrue(plan.weeklyNotes.contains { $0.localizedCaseInsensitiveContains("minimal") })
    }

    func testRetinoidTreatmentSkipsExfoliantPairing() {
        var profile = UserProfile.default
        profile.avoidsRetinoids = false
        profile.retinoidSafetyContext = .comfortable
        profile.routineComplexity = .advanced
        profile.currentGoals = [.texture]

        let plan = RecommendationEngine(catalog: [
            fixtureProduct(id: "retinal", category: .treatment, ingredients: ["retinaldehyde"], concerns: [.texture]),
            fixtureProduct(id: "exfoliant", category: .exfoliant, ingredients: ["PHA"], concerns: [.texture]),
            fixtureProduct(id: "moisturizer", category: .moisturizer, ingredients: ["ceramides"], concerns: [.barrier]),
            fixtureProduct(id: "sunscreen", category: .sunscreen, ingredients: ["zinc oxide"], concerns: [.darkSpots])
        ]).buildRoutine(for: SampleData.previewReport, profile: profile)

        XCTAssertTrue(plan.steps.contains { $0.product.id == "retinal" })
        XCTAssertFalse(plan.steps.contains { $0.category == .exfoliant })
    }

    func testLowQualityScanAddsRescanGuardrail() {
        let report = SkinReport(
            createdAt: Date(),
            scanQuality: ScanQuality(
                lighting: 0.45,
                alignment: 0.5,
                stability: 0.56,
                clarity: 0.48,
                depthGuidanceAvailable: false
            ),
            scores: [
                ConcernScore(
                    concern: .redness,
                    score: 72,
                    confidence: .low,
                    primaryRegion: .leftCheek,
                    explanation: "Low confidence fixture"
                )
            ],
            visibleStrengths: [],
            summary: "Fixture"
        )

        let plan = RecommendationEngine().buildRoutine(for: report, profile: .default)

        XCTAssertTrue(plan.weeklyNotes.contains { note in
            note.localizedCaseInsensitiveContains("retake")
        })
    }

    func testAvoidedProductsAreExcludedFromRoutine() {
        let baselinePlan = RecommendationEngine().buildRoutine(for: SampleData.previewReport, profile: .default)
        let avoidedProduct = baselinePlan.steps.first { $0.category == .cleanser }!.product

        let plan = RecommendationEngine().buildRoutine(
            for: SampleData.previewReport,
            profile: .default,
            productShelfStatuses: [avoidedProduct.id: .avoided]
        )

        XCTAssertFalse(plan.steps.contains { $0.product.id == avoidedProduct.id })
    }

    func testUsingProductGetsPreferenceWhenCompatible() {
        let report = SkinReport(
            createdAt: Date(),
            scanQuality: .preview,
            scores: [
                ConcernScore(
                    concern: .barrier,
                    score: 80,
                    confidence: .high,
                    primaryRegion: .leftCheek,
                    explanation: "Barrier fixture"
                )
            ],
            visibleStrengths: [],
            summary: "Fixture"
        )
        var profile = UserProfile.default
        profile.currentGoals = []
        profile.budget = .balanced

        let balanced = SkincareProduct(
            id: "cleanser-balanced",
            name: "Balanced Cleanser",
            brand: "Fixture",
            category: .cleanser,
            price: 24,
            budgetTier: .balanced,
            heroIngredients: ["glycerin"],
            concernFit: [.barrier],
            fragranceFree: true,
            sensitivityScore: 3,
            usageNote: "Use",
            whyItMatches: "Fixture"
        )
        let premiumUsing = SkincareProduct(
            id: "cleanser-using",
            name: "Using Cleanser",
            brand: "Fixture",
            category: .cleanser,
            price: 42,
            budgetTier: .premium,
            heroIngredients: ["glycerin"],
            concernFit: [.barrier],
            fragranceFree: true,
            sensitivityScore: 3,
            usageNote: "Use",
            whyItMatches: "Fixture"
        )

        let plan = RecommendationEngine(catalog: [balanced, premiumUsing]).buildRoutine(
            for: report,
            profile: profile,
            productShelfStatuses: [premiumUsing.id: .using]
        )

        XCTAssertEqual(plan.steps.first?.product.id, premiumUsing.id)
    }

    func testWishlistDoesNotInfluenceRoutineRanking() {
        let report = SkinReport(
            createdAt: Date(),
            scanQuality: .preview,
            scores: [
                ConcernScore(
                    concern: .barrier,
                    score: 80,
                    confidence: .high,
                    primaryRegion: .leftCheek,
                    explanation: "Barrier fixture"
                )
            ],
            visibleStrengths: [],
            summary: "Fixture"
        )
        var profile = UserProfile.default
        profile.currentGoals = []
        profile.budget = .balanced

        let balanced = SkincareProduct(
            id: "cleanser-balanced",
            name: "Balanced Cleanser",
            brand: "Fixture",
            category: .cleanser,
            price: 24,
            budgetTier: .balanced,
            heroIngredients: ["glycerin"],
            concernFit: [.barrier],
            fragranceFree: true,
            sensitivityScore: 3,
            usageNote: "Use",
            whyItMatches: "Fixture"
        )
        let premiumWishlist = SkincareProduct(
            id: "cleanser-wishlist",
            name: "Wishlist Cleanser",
            brand: "Fixture",
            category: .cleanser,
            price: 42,
            budgetTier: .premium,
            heroIngredients: ["glycerin"],
            concernFit: [.barrier],
            fragranceFree: true,
            sensitivityScore: 3,
            usageNote: "Use",
            whyItMatches: "Fixture"
        )

        let plan = RecommendationEngine(catalog: [balanced, premiumWishlist]).buildRoutine(
            for: report,
            profile: profile,
            productShelfStatuses: [premiumWishlist.id: .wishlist]
        )

        XCTAssertEqual(plan.steps.first?.product.id, balanced.id)
    }

    func testKnownIrritantInFullIngredientListIsDownranked() throws {
        var profile = UserProfile.default
        profile.knownIrritants = [.dryingAlcohol]
        profile.currentGoals = [.texture]

        let unsafe = fixtureProduct(
            id: "alcohol-serum",
            category: .treatment,
            ingredients: ["niacinamide"],
            fullIngredients: ["water", "alcohol denat", "niacinamide"],
            ingredientListCoverage: .completeINCI,
            concerns: [.texture]
        )
        let safer = fixtureProduct(
            id: "calm-serum",
            category: .treatment,
            ingredients: ["centella"],
            concerns: [.texture]
        )

        let plan = RecommendationEngine(catalog: [unsafe, safer]).buildRoutine(
            for: SampleData.previewReport,
            profile: profile
        )

        XCTAssertEqual(try XCTUnwrap(plan.steps.first { $0.category == .treatment }?.product.id), safer.id)
    }

    func testRoutineProductsCarryRecommendationDisclosureDefaults() {
        let plan = RecommendationEngine().buildRoutine(for: SampleData.previewReport, profile: .default)

        XCTAssertFalse(plan.steps.isEmpty)
        XCTAssertTrue(plan.steps.allSatisfy { $0.product.catalogSource == .curatedPrototype })
        XCTAssertTrue(plan.steps.allSatisfy { $0.product.evidenceLevel == .labelBased })
        XCTAssertTrue(plan.steps.allSatisfy { $0.product.commercialStatus == .independent })
        XCTAssertTrue(plan.steps.allSatisfy { $0.product.recommendationReadiness == .prototypeOnly })
    }

    func testRoutineStepsCarryFitScoreAndSelectionReasons() {
        let plan = RecommendationEngine().buildRoutine(for: SampleData.previewReport, profile: .default)

        XCTAssertFalse(plan.steps.isEmpty)
        XCTAssertTrue(plan.steps.allSatisfy { $0.fitScore != nil })
        XCTAssertTrue(plan.steps.allSatisfy { !$0.selectionReasons.isEmpty })
        XCTAssertTrue(plan.steps.contains { step in
            step.selectionReasons.contains { $0.localizedCaseInsensitiveContains("scan focus") }
        })
        XCTAssertTrue(plan.steps.allSatisfy { step in
            step.selectionReasons.contains { $0.localizedCaseInsensitiveContains("prototype-only") }
        })
    }

    func testIndependentVerifiedProductOutranksCommerciallyBiasedMatch() throws {
        let report = SkinReport(
            createdAt: Date(),
            scanQuality: .preview,
            scores: [
                ConcernScore(
                    concern: .barrier,
                    score: 80,
                    confidence: .high,
                    primaryRegion: .leftCheek,
                    explanation: "Barrier fixture"
                )
            ],
            visibleStrengths: [],
            summary: "Fixture"
        )
        let independent = fixtureProduct(
            id: "independent",
            category: .moisturizer,
            ingredients: ["ceramides"],
            concerns: [.barrier],
            catalogSource: .verifiedRetailer,
            evidenceLevel: .thirdPartyVerified,
            commercialStatus: .independent
        )
        let partner = fixtureProduct(
            id: "partner",
            category: .moisturizer,
            ingredients: ["ceramides"],
            concerns: [.barrier],
            catalogSource: .curatedPrototype,
            evidenceLevel: .labelBased,
            commercialStatus: .brandPartner
        )

        let plan = RecommendationEngine(catalog: [partner, independent]).buildRoutine(
            for: report,
            profile: .default
        )

        XCTAssertEqual(try XCTUnwrap(plan.steps.first { $0.category == .moisturizer }?.product.id), independent.id)
    }

    func testProductTrustSummarySurfacesDataAndCommercialLimitations() {
        let strong = fixtureProduct(
            id: "verified",
            category: .moisturizer,
            ingredients: ["ceramides"],
            fullIngredients: ["water", "glycerin", "ceramides"],
            ingredientListCoverage: .verifiedINCI,
            concerns: [.barrier],
            catalogSource: .verifiedRetailer,
            evidenceLevel: .thirdPartyVerified,
            commercialStatus: .independent
        )
        let sponsored = fixtureProduct(
            id: "sponsored",
            category: .moisturizer,
            ingredients: ["ceramides"],
            concerns: [.barrier],
            catalogSource: .curatedPrototype,
            evidenceLevel: .labelBased,
            commercialStatus: .brandPartner
        )

        XCTAssertEqual(strong.trustSummary.grade, .strong)
        XCTAssertTrue(strong.trustSummary.strengths.contains { $0.localizedCaseInsensitiveContains("verified") })
        XCTAssertEqual(sponsored.trustSummary.grade, .review)
        XCTAssertTrue(sponsored.trustSummary.limitations.contains { $0.localizedCaseInsensitiveContains("partnership") })
        XCTAssertTrue(sponsored.trustSummary.limitations.contains { $0.localizedCaseInsensitiveContains("key ingredients") })
    }

    func testRecommendationReadinessDistinguishesPrototypeReviewAndPurchaseReadyProducts() {
        let prototype = fixtureProduct(
            id: "prototype",
            category: .moisturizer,
            ingredients: ["ceramides"],
            concerns: [.barrier]
        )
        let verified = fixtureProduct(
            id: "verified",
            category: .moisturizer,
            ingredients: ["ceramides"],
            fullIngredients: ["water", "glycerin", "ceramides"],
            ingredientListCoverage: .completeINCI,
            concerns: [.barrier],
            catalogSource: .verifiedRetailer,
            evidenceLevel: .thirdPartyVerified,
            commercialStatus: .independent,
            sourceMetadata: ProductSourceMetadata(
                sourceLabel: "Verified retailer feed",
                sourceURL: URL(string: "https://retailer.example.com/verified")!,
                sourceLastCheckedAt: Date(timeIntervalSince1970: 1_780_272_000),
                inciVerifiedAt: Date(timeIntervalSince1970: 1_780_272_000),
                reviewer: "Retailer feed QA"
            )
        )
        let affiliate = fixtureProduct(
            id: "affiliate",
            category: .moisturizer,
            ingredients: ["ceramides"],
            fullIngredients: ["water", "glycerin", "ceramides"],
            ingredientListCoverage: .completeINCI,
            concerns: [.barrier],
            catalogSource: .verifiedRetailer,
            evidenceLevel: .thirdPartyVerified,
            commercialStatus: .affiliate,
            sourceMetadata: ProductSourceMetadata(
                sourceLabel: "Verified retailer feed",
                sourceURL: URL(string: "https://retailer.example.com/affiliate")!,
                sourceLastCheckedAt: Date(timeIntervalSince1970: 1_780_272_000),
                inciVerifiedAt: Date(timeIntervalSince1970: 1_780_272_000),
                reviewer: "Retailer feed QA"
            )
        )

        XCTAssertEqual(prototype.recommendationReadiness, .prototypeOnly)
        XCTAssertEqual(verified.recommendationReadiness, .purchaseReady)
        XCTAssertEqual(affiliate.recommendationReadiness, .metadataReviewNeeded)
    }

    func testLaunchReadyProductOutranksPrototypeWhenOtherwiseEquivalent() throws {
        let report = SkinReport(
            createdAt: Date(),
            scanQuality: .preview,
            scores: [
                ConcernScore(
                    concern: .barrier,
                    score: 80,
                    confidence: .high,
                    primaryRegion: .leftCheek,
                    explanation: "Barrier fixture"
                )
            ],
            visibleStrengths: [],
            summary: "Fixture"
        )
        let prototype = fixtureProduct(
            id: "prototype-match",
            category: .moisturizer,
            ingredients: ["ceramides"],
            concerns: [.barrier]
        )
        let launchReady = fixtureProduct(
            id: "launch-ready",
            category: .moisturizer,
            ingredients: ["ceramides"],
            fullIngredients: ["water", "glycerin", "ceramides"],
            ingredientListCoverage: .verifiedINCI,
            concerns: [.barrier],
            catalogSource: .verifiedRetailer,
            evidenceLevel: .thirdPartyVerified,
            commercialStatus: .independent,
            sourceMetadata: ProductSourceMetadata(
                sourceLabel: "Verified retailer feed",
                sourceURL: URL(string: "https://retailer.example.com/launch-ready")!,
                sourceLastCheckedAt: Date(timeIntervalSince1970: 1_780_272_000),
                inciVerifiedAt: Date(timeIntervalSince1970: 1_780_272_000),
                reviewer: "Retailer feed QA"
            )
        )

        let plan = RecommendationEngine(catalog: [prototype, launchReady]).buildRoutine(
            for: report,
            profile: .default
        )
        let moisturizer = try XCTUnwrap(plan.steps.first { $0.category == .moisturizer })

        XCTAssertEqual(moisturizer.product.id, launchReady.id)
        XCTAssertTrue(moisturizer.selectionReasons.contains { $0.localizedCaseInsensitiveContains("launch-ready") })
    }

    func testAffiliateTrustGradeAlwaysRequiresReview() {
        let affiliate = fixtureProduct(
            id: "affiliate",
            category: .moisturizer,
            ingredients: ["ceramides"],
            fullIngredients: ["water", "ceramides"],
            ingredientListCoverage: .verifiedINCI,
            concerns: [.barrier],
            catalogSource: .clinicianCurated,
            evidenceLevel: .clinicalReviewed,
            commercialStatus: .affiliate
        )

        XCTAssertEqual(affiliate.trustSummary.grade, .review)
        XCTAssertTrue(affiliate.trustSummary.limitations.first?.localizedCaseInsensitiveContains("affiliate") == true)
    }

    func testLegacyProductWithoutCommercialStatusDecodesAsUndisclosed() throws {
        let json = """
        {
          "id": "legacy",
          "name": "Legacy Cream",
          "brand": "Fixture",
          "category": "moisturizer",
          "price": 20,
          "budgetTier": "balanced",
          "heroIngredients": ["ceramides"],
          "concernFit": ["barrier"],
          "fragranceFree": true,
          "sensitivityScore": 4,
          "usageNote": "Use",
          "whyItMatches": "Fixture"
        }
        """.data(using: .utf8)!

        let product = try JSONDecoder().decode(SkincareProduct.self, from: json)

        XCTAssertEqual(product.commercialStatus, .undisclosed)
        XCTAssertEqual(product.sourceMetadata, .missing)
        XCTAssertEqual(product.trustSummary.grade, .review)
        XCTAssertTrue(product.trustSummary.limitations.contains { $0.localizedCaseInsensitiveContains("source") })
    }

    func testSampleCatalogCarriesPrototypeSourceMetadata() {
        XCTAssertTrue(SampleData.products.allSatisfy { product in
            product.sourceMetadata.sourceLabel == ProductSourceMetadata.prototypeCatalog.sourceLabel
                && product.sourceMetadata.sourceLastCheckedAt != nil
                && product.sourceMetadata.reviewer == ProductSourceMetadata.prototypeCatalog.reviewer
        })
    }

    func testPartialFullIngredientsDoNotHideHeroRiskSignals() {
        let product = fixtureProduct(
            id: "partial-retinoid",
            category: .treatment,
            ingredients: ["retinol"],
            fullIngredients: ["water", "glycerin"],
            ingredientListCoverage: .userEnteredPartial,
            concerns: [.texture]
        )

        XCTAssertTrue(product.hasIngredientSignal(matching: ["retinol"]))
    }

    func testVerifiedINCIOutranksHeroOnlyWhenOtherwiseEquivalent() throws {
        let report = SkinReport(
            createdAt: Date(),
            scanQuality: .preview,
            scores: [
                ConcernScore(
                    concern: .barrier,
                    score: 80,
                    confidence: .high,
                    primaryRegion: .leftCheek,
                    explanation: "Barrier fixture"
                )
            ],
            visibleStrengths: [],
            summary: "Fixture"
        )
        let heroOnly = fixtureProduct(
            id: "hero-only",
            category: .moisturizer,
            ingredients: ["ceramides"],
            concerns: [.barrier]
        )
        let verified = fixtureProduct(
            id: "verified-inci",
            category: .moisturizer,
            ingredients: ["ceramides"],
            fullIngredients: ["water", "glycerin", "ceramides"],
            ingredientListCoverage: .verifiedINCI,
            concerns: [.barrier]
        )

        let plan = RecommendationEngine(catalog: [heroOnly, verified]).buildRoutine(
            for: report,
            profile: .default
        )

        XCTAssertEqual(try XCTUnwrap(plan.steps.first { $0.category == .moisturizer }?.product.id), verified.id)
    }

    func testAlternativesRankCompatibleProductsAndExcludeCurrentAvoidedAndRetinoids() {
        var profile = UserProfile.default
        profile.currentGoals = [.texture]
        profile.avoidsRetinoids = true
        let current = fixtureProduct(id: "current", category: .treatment, ingredients: ["niacinamide"], concerns: [.redness])
        let compatible = fixtureProduct(id: "compatible", category: .treatment, ingredients: ["azelaic"], concerns: [.texture])
        let avoided = fixtureProduct(id: "avoided", category: .treatment, ingredients: ["centella"], concerns: [.texture])
        let retinoid = fixtureProduct(id: "retinoid", category: .treatment, ingredients: ["retinol"], concerns: [.texture])
        let cleanser = fixtureProduct(id: "cleanser", category: .cleanser, ingredients: ["glycerin"], concerns: [.texture])
        let step = RoutineStep(
            moment: .evening,
            order: 1,
            category: .treatment,
            product: current,
            instruction: "Use",
            caution: nil
        )

        let alternatives = RecommendationEngine(catalog: [current, compatible, avoided, retinoid, cleanser])
            .alternatives(
                for: step,
                focus: [.texture],
                profile: profile,
                productShelfStatuses: ["avoided": .avoided]
            )

        XCTAssertEqual(alternatives.map(\.product.id), ["compatible"])
        XCTAssertTrue(alternatives.first?.reasons.contains { $0.localizedCaseInsensitiveContains("texture") } == true)
    }

    private func fixtureProduct(
        id: String,
        category: ProductCategory,
        ingredients: [String],
        fullIngredients: [String] = [],
        ingredientListCoverage: IngredientListCoverage = .heroOnly,
        concerns: Set<SkinConcern>,
        catalogSource: ProductCatalogSource = .curatedPrototype,
        evidenceLevel: ProductEvidenceLevel = .labelBased,
        commercialStatus: ProductCommercialStatus = .independent,
        sourceMetadata: ProductSourceMetadata = .missing
    ) -> SkincareProduct {
        SkincareProduct(
            id: id,
            name: id.capitalized,
            brand: "Fixture",
            category: category,
            price: 20,
            budgetTier: .balanced,
            heroIngredients: ingredients,
            fullIngredients: fullIngredients,
            ingredientListCoverage: ingredientListCoverage,
            concernFit: concerns,
            fragranceFree: true,
            sensitivityScore: 4,
            usageNote: "Use",
            whyItMatches: "Fixture",
            catalogSource: catalogSource,
            evidenceLevel: evidenceLevel,
            commercialStatus: commercialStatus,
            sourceMetadata: sourceMetadata
        )
    }
}
