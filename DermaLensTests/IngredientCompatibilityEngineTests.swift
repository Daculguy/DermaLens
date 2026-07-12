import XCTest
@testable import DermaLens

final class IngredientCompatibilityEngineTests: XCTestCase {
    func testFindsMissingSunscreenWarning() {
        let plan = RoutinePlan(
            generatedAt: Date(),
            focus: [.darkSpots],
            steps: [
                RoutineStep(
                    moment: .morning,
                    order: 1,
                    category: .treatment,
                    product: SampleData.products.first { $0.id == "treatment-niacinamide" }!,
                    instruction: "Use",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )

        let findings = IngredientCompatibilityEngine().analyze(plan: plan, profile: .default)

        XCTAssertTrue(findings.contains { $0.severity == .warning && $0.title == "SPF is missing" })
        XCTAssertTrue(findings.contains { $0.title == "SPF is missing" && $0.recommendation.localizedCaseInsensitiveContains("sunscreen") })
    }

    func testSensitiveProfileWarnsOnExfoliant() {
        var profile = UserProfile.default
        profile.sensitivity = 5
        let exfoliant = SampleData.products.first { $0.id == "exfoliant-pha" }!
        let plan = RoutinePlan(
            generatedAt: Date(),
            focus: [.texture],
            steps: [
                RoutineStep(
                    moment: .evening,
                    order: 1,
                    category: .exfoliant,
                    product: exfoliant,
                    instruction: "Use",
                    caution: nil
                ),
                RoutineStep(
                    moment: .morning,
                    order: 1,
                    category: .sunscreen,
                    product: SampleData.products.first { $0.category == .sunscreen }!,
                    instruction: "Use",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )

        let findings = IngredientCompatibilityEngine().analyze(plan: plan, profile: profile)

        XCTAssertTrue(findings.contains { $0.title == "Sensitive profile needs slower active ramp" })
        XCTAssertTrue(findings.contains { $0.title == "Sensitive profile needs slower active ramp" && $0.recommendation.localizedCaseInsensitiveContains("recovery") })
    }

    func testKnownAcidFlagWarnsOnExfoliant() {
        var profile = UserProfile.default
        profile.knownIrritants.insert(.exfoliatingAcids)
        let exfoliant = SampleData.products.first { $0.id == "exfoliant-pha" }!
        let plan = RoutinePlan(
            generatedAt: Date(),
            focus: [.texture],
            steps: [
                RoutineStep(
                    moment: .evening,
                    order: 1,
                    category: .exfoliant,
                    product: exfoliant,
                    instruction: "Use",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )

        let findings = IngredientCompatibilityEngine().analyze(plan: plan, profile: profile)

        XCTAssertTrue(findings.contains { $0.title == "Acid sensitivity flag" })
    }

    func testRetinoidSafetyContextWarnsOnRetinoid() {
        var profile = UserProfile.default
        profile.avoidsRetinoids = false
        profile.retinoidSafetyContext = .pregnantNursingTrying
        let retinoid = SampleData.products.first { $0.id == "treatment-retinal" }!
        let plan = RoutinePlan(
            generatedAt: Date(),
            focus: [.texture],
            steps: [
                RoutineStep(
                    moment: .evening,
                    order: 1,
                    category: .treatment,
                    product: retinoid,
                    instruction: "Use",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )

        let findings = IngredientCompatibilityEngine().analyze(plan: plan, profile: profile)

        XCTAssertTrue(findings.contains { finding in
            finding.title == "Retinoid safety conflict"
            && finding.detail.localizedCaseInsensitiveContains("pregnancy")
            && finding.recommendation.localizedCaseInsensitiveContains("swap")
        })
    }

    func testRetinoidSafetyContextUsesFullIngredientList() {
        var profile = UserProfile.default
        profile.avoidsRetinoids = false
        profile.retinoidSafetyContext = .pregnantNursingTrying
        let retinoid = fixtureProduct(
            id: "hidden-retinoid",
            category: .treatment,
            heroIngredients: ["peptides"],
            fullIngredients: ["water", "glycerin", "tretinoin"],
            ingredientListCoverage: .completeINCI
        )
        let plan = RoutinePlan(
            generatedAt: Date(),
            focus: [.texture],
            steps: [
                RoutineStep(
                    moment: .evening,
                    order: 1,
                    category: .treatment,
                    product: retinoid,
                    instruction: "Use",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )

        let findings = IngredientCompatibilityEngine().analyze(plan: plan, profile: profile)

        XCTAssertTrue(findings.contains { finding in
            finding.title == "Retinoid safety conflict"
            && finding.relatedProductIDs == [retinoid.id]
        })
    }

    func testPartialIngredientDataProducesLimitedConfidenceFinding() {
        let product = fixtureProduct(
            id: "partial-product",
            category: .treatment,
            heroIngredients: ["niacinamide"],
            ingredientListCoverage: .userEnteredPartial
        )
        let plan = RoutinePlan(
            generatedAt: Date(),
            focus: [.texture],
            steps: [
                RoutineStep(
                    moment: .evening,
                    order: 1,
                    category: .treatment,
                    product: product,
                    instruction: "Use",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )

        let findings = IngredientCompatibilityEngine().analyze(plan: plan, profile: .default)

        XCTAssertTrue(findings.contains { finding in
            finding.title == "Ingredient data is partial"
            && finding.recommendation.localizedCaseInsensitiveContains("complete INCI")
            && finding.relatedProductIDs == [product.id]
        })
    }

    func testFragranceFreeRoutineProducesPositiveFinding() {
        let plan = SampleData.previewRoutine
        var profile = UserProfile.default
        profile.avoidsFragrance = true

        let findings = IngredientCompatibilityEngine().analyze(plan: plan, profile: profile)

        XCTAssertTrue(findings.contains { finding in
            finding.title == "Fragrance preference appears respected"
            && finding.detail.localizedCaseInsensitiveContains("partial")
        })
        XCTAssertTrue(findings.allSatisfy { !$0.recommendation.isEmpty })
    }
}

private func fixtureProduct(
    id: String,
    category: ProductCategory,
    heroIngredients: [String],
    fullIngredients: [String] = [],
    ingredientListCoverage: IngredientListCoverage = .heroOnly
) -> SkincareProduct {
    SkincareProduct(
        id: id,
        name: id.capitalized,
        brand: "Fixture",
        category: category,
        price: 20,
        budgetTier: .balanced,
        heroIngredients: heroIngredients,
        fullIngredients: fullIngredients,
        ingredientListCoverage: ingredientListCoverage,
        concernFit: [.texture],
        fragranceFree: true,
        sensitivityScore: 4,
        usageNote: "Use",
        whyItMatches: "Fixture"
    )
}
