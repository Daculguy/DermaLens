import Foundation

struct ProductAlternative: Identifiable, Hashable {
    var product: SkincareProduct
    var score: Int
    var reasons: [String]

    var id: String { product.id }
}

struct RecommendationEngine {
    private let catalog: [SkincareProduct]

    init(catalog: [SkincareProduct] = SampleData.products) {
        self.catalog = catalog
    }

    func buildRoutine(
        for report: SkinReport,
        profile: UserProfile,
        productShelfStatuses: [String: ProductShelfStatus] = [:],
        catalog overrideCatalog: [SkincareProduct]? = nil
    ) -> RoutinePlan {
        let activeCatalog = overrideCatalog ?? catalog
        let focus = Array(report.topConcerns.map(\.concern))
        let cleanser = bestProduct(category: .cleanser, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses, catalog: activeCatalog)
        let treatment = bestProduct(category: .treatment, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses, catalog: activeCatalog)
        let moisturizer = bestProduct(category: .moisturizer, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses, catalog: activeCatalog)
        let sunscreen = bestProduct(category: .sunscreen, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses, catalog: activeCatalog)
        let hasRetinoidTreatment = treatment.map { containsRetinoid($0) } ?? false
        let exfoliant = shouldSkipExfoliant(for: profile) || hasRetinoidTreatment
            ? nil
            : bestProduct(category: .exfoliant, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses, catalog: activeCatalog)

        var steps: [RoutineStep] = []

        if let cleanser {
            steps.append(RoutineStep(
                moment: .morning,
                order: 1,
                category: .cleanser,
                product: cleanser,
                instruction: "Cleanse lightly or rinse if your skin feels comfortable.",
                caution: nil,
                fitScore: score(cleanser, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                selectionReasons: selectionReasons(for: cleanser, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            ))
        }

        if let treatment {
            steps.append(RoutineStep(
                moment: .morning,
                order: 2,
                category: .treatment,
                product: treatment,
                instruction: morningInstruction(for: treatment),
                caution: treatmentCaution(for: treatment, profile: profile),
                fitScore: score(treatment, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                selectionReasons: selectionReasons(for: treatment, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            ))
        }

        if let moisturizer {
            steps.append(RoutineStep(
                moment: .morning,
                order: 3,
                category: .moisturizer,
                product: moisturizer,
                instruction: "Seal with a thin, even layer.",
                caution: nil,
                fitScore: score(moisturizer, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                selectionReasons: selectionReasons(for: moisturizer, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            ))
        }

        if let sunscreen {
            steps.append(RoutineStep(
                moment: .morning,
                order: 4,
                category: .sunscreen,
                product: sunscreen,
                instruction: "Apply generously as the final morning step.",
                caution: "Reapply when outdoors. Dark spots and redness plans depend on consistent SPF.",
                fitScore: score(sunscreen, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                selectionReasons: selectionReasons(for: sunscreen, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            ))
        }

        if let cleanser {
            steps.append(RoutineStep(
                moment: .evening,
                order: 1,
                category: .cleanser,
                product: cleanser,
                instruction: "Cleanse for 30-45 seconds to remove sunscreen.",
                caution: nil,
                fitScore: score(cleanser, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                selectionReasons: selectionReasons(for: cleanser, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            ))
        }

        if let treatment {
            steps.append(RoutineStep(
                moment: .evening,
                order: 2,
                category: .treatment,
                product: treatment,
                instruction: treatment.usageNote,
                caution: treatmentCaution(for: treatment, profile: profile),
                fitScore: score(treatment, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                selectionReasons: selectionReasons(for: treatment, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            ))
        }

        if let moisturizer {
            steps.append(RoutineStep(
                moment: .evening,
                order: 3,
                category: .moisturizer,
                product: moisturizer,
                instruction: "Use enough to keep skin comfortable through the night.",
                caution: nil,
                fitScore: score(moisturizer, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                selectionReasons: selectionReasons(for: moisturizer, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            ))
        }

        if let exfoliant {
            steps.append(RoutineStep(
                moment: .evening,
                order: 4,
                category: .exfoliant,
                product: exfoliant,
                instruction: "Use once weekly on a non-treatment night.",
                caution: "Skip if skin feels hot, tight, or flaky.",
                fitScore: score(exfoliant, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                selectionReasons: selectionReasons(for: exfoliant, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            ))
        }

        return RoutinePlan(
            generatedAt: Date(),
            focus: focus,
            steps: steps,
            weeklyNotes: weeklyNotes(for: report, profile: profile)
        )
    }

    func alternatives(
        for step: RoutineStep,
        focus: [SkinConcern],
        profile: UserProfile,
        productShelfStatuses: [String: ProductShelfStatus] = [:],
        catalog overrideCatalog: [SkincareProduct]? = nil,
        limit: Int = 5
    ) -> [ProductAlternative] {
        let activeCatalog = overrideCatalog ?? catalog
        return activeCatalog
            .filter {
                $0.category == step.category
                && $0.id != step.product.id
                && productShelfStatuses[$0.id] != .avoided
                && !(profile.shouldAvoidRetinoids && containsRetinoid($0))
            }
            .map { product in
                ProductAlternative(
                    product: product,
                    score: score(product, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses),
                    reasons: alternativeReasons(
                        for: product,
                        replacing: step.product,
                        focus: focus,
                        profile: profile,
                        productShelfStatuses: productShelfStatuses
                    )
                )
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.product.price < rhs.product.price
                }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map { $0 }
    }

    private func bestProduct(
        category: ProductCategory,
        focus: [SkinConcern],
        profile: UserProfile,
        productShelfStatuses: [String: ProductShelfStatus],
        catalog: [SkincareProduct]
    ) -> SkincareProduct? {
        catalog
            .filter {
                $0.category == category
                && productShelfStatuses[$0.id] != .avoided
                && !(profile.shouldAvoidRetinoids && containsRetinoid($0))
            }
            .max { lhs, rhs in
                score(lhs, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses) < score(rhs, focus: focus, profile: profile, productShelfStatuses: productShelfStatuses)
            }
    }

    private func score(
        _ product: SkincareProduct,
        focus: [SkinConcern],
        profile: UserProfile,
        productShelfStatuses: [String: ProductShelfStatus]
    ) -> Int {
        var value = 0
        value += focus.reduce(0) { partial, concern in
            partial + (product.concernFit.contains(concern) ? 18 : 0)
        }
        value += profile.currentGoals.reduce(0) { partial, concern in
            partial + (product.concernFit.contains(concern) ? 6 : 0)
        }
        value += product.fragranceFree && profile.prefersFragranceFree ? 14 : 0
        value += max(0, 6 - abs(product.sensitivityScore - profile.sensitivity)) * 3
        value += product.budgetTier == profile.budget ? 10 : 0
        value -= product.budgetTier == .premium && profile.budget == .value ? 12 : 0
        value -= containsKnownIrritant(product, profile: profile) ? 70 : 0
        value += trustAdjustment(for: product)
        value += readinessAdjustment(for: product, productShelfStatuses: productShelfStatuses)
        value += comfortLift(for: product, profile: profile)
        switch productShelfStatuses[product.id] {
        case .using:
            value += 14
        case .owned:
            value += 8
        default:
            break
        }
        return value
    }

    private func readinessAdjustment(
        for product: SkincareProduct,
        productShelfStatuses: [String: ProductShelfStatus]
    ) -> Int {
        switch product.recommendationReadiness {
        case .purchaseReady:
            return 14
        case .metadataReviewNeeded:
            return -4
        case .userReviewNeeded:
            switch productShelfStatuses[product.id] {
            case .using, .owned:
                return 3
            default:
                return -14
            }
        case .prototypeOnly:
            return -8
        }
    }

    private func trustAdjustment(for product: SkincareProduct) -> Int {
        var value = 0

        switch product.catalogSource {
        case .curatedPrototype:
            value += 0
        case .userEntered:
            value += 2
        case .verifiedRetailer:
            value += 8
        case .clinicianCurated:
            value += 10
        }

        switch product.evidenceLevel {
        case .labelBased:
            value += 0
        case .userProvided:
            value -= 2
        case .thirdPartyVerified:
            value += 8
        case .clinicalReviewed:
            value += 10
        }

        switch product.commercialStatus {
        case .undisclosed:
            value -= 4
        case .independent:
            value += 6
        case .affiliate:
            value -= 6
        case .brandPartner:
            value -= 10
        case .ownedBrand:
            value -= 12
        }

        switch product.ingredientListCoverage {
        case .heroOnly:
            value -= 2
        case .userEnteredPartial:
            value -= 1
        case .completeINCI:
            value += 4
        case .verifiedINCI:
            value += 6
        }

        return value
    }

    private func selectionReasons(
        for product: SkincareProduct,
        focus: [SkinConcern],
        profile: UserProfile,
        productShelfStatuses: [String: ProductShelfStatus]
    ) -> [String] {
        var reasons: [String] = []
        let focusMatches = product.concernFit.intersection(Set(focus))
        if !focusMatches.isEmpty {
            reasons.append("Matches scan focus: \(focusMatches.map(\.shortTitle).sorted().joined(separator: ", "))")
        }

        let goalMatches = product.concernFit.intersection(profile.currentGoals)
        if !goalMatches.isEmpty {
            reasons.append("Supports your goals: \(goalMatches.map(\.shortTitle).sorted().joined(separator: ", "))")
        }

        reasons.append(product.recommendationReadiness.shortReason)

        if product.fragranceFree && profile.prefersFragranceFree {
            reasons.append("Fits fragrance-free preference")
        }

        if product.sensitivityScore >= profile.sensitivity {
            reasons.append("Sensitivity fit \(product.sensitivityScore)/5")
        }

        switch productShelfStatuses[product.id] {
        case .using:
            reasons.append("Already marked using")
        case .owned:
            reasons.append("Already owned")
        default:
            break
        }

        if product.budgetTier == profile.budget {
            reasons.append("Matches \(profile.budget.title.lowercased()) budget")
        }

        if product.commercialStatus == .independent {
            reasons.append("Independent pick")
        }

        if product.evidenceLevel == .thirdPartyVerified || product.evidenceLevel == .clinicalReviewed {
            reasons.append(product.evidenceLevel.title)
        }

        if reasons.isEmpty {
            reasons.append("Best available \(product.category.title.lowercased()) fit from the current catalog")
        }

        return Array(reasons.prefix(4))
    }

    private func morningInstruction(for product: SkincareProduct) -> String {
        if containsRetinoid(product) {
            return "Save this active for evening; use moisturizer instead this morning."
        }
        return product.usageNote
    }

    private func treatmentCaution(for product: SkincareProduct, profile: UserProfile) -> String? {
        if containsRetinoid(product) {
            if profile.retinoidSafetyContext == .pregnantNursingTrying {
                return "Avoid retinoids while pregnant, nursing, or trying to conceive unless a clinician approves."
            }
            return "Introduce slowly and avoid if pregnant or trying to conceive unless a clinician approves."
        }
        if profile.sensitivity >= 4 {
            return "Patch test first and start every other day."
        }
        return nil
    }

    private func containsRetinoid(_ product: SkincareProduct) -> Bool {
        product.hasIngredientSignal(matching: ["retinal", "retinol", "retinoid", "retinyl", "adapalene", "tretinoin"])
    }

    private func shouldSkipExfoliant(for profile: UserProfile) -> Bool {
        profile.routineComplexity == .minimal
        || profile.knownIrritants.contains(.exfoliatingAcids)
        || profile.baselineSkinFeel == .reactive
    }

    private func comfortLift(for product: SkincareProduct, profile: UserProfile) -> Int {
        switch profile.baselineSkinFeel {
        case .dry, .tight, .reactive:
            if product.category == .moisturizer { return 10 }
            if product.category == .cleanser && product.sensitivityScore >= 4 { return 6 }
            return 0
        case .oily:
            if product.category == .moisturizer && product.name.localizedCaseInsensitiveContains("gel") { return 6 }
            if product.category == .sunscreen && product.name.localizedCaseInsensitiveContains("gel") { return 6 }
            return 0
        case .balanced:
            return 0
        }
    }

    private func containsKnownIrritant(_ product: SkincareProduct, profile: UserProfile) -> Bool {
        if profile.knownIrritants.contains(.fragrance) || profile.knownIrritants.contains(.essentialOils) {
            if !product.fragranceFree { return true }
        }

        return profile.knownIrritants.contains { irritant in
            irritant.tokens.contains { token in
                product.hasIngredientSignal(matching: [token])
            }
        }
    }

    private func alternativeReasons(
        for product: SkincareProduct,
        replacing currentProduct: SkincareProduct,
        focus: [SkinConcern],
        profile: UserProfile,
        productShelfStatuses: [String: ProductShelfStatus]
    ) -> [String] {
        var reasons: [String] = []
        let matchedConcerns = product.concernFit.intersection(Set(focus + Array(profile.currentGoals)))
        if !matchedConcerns.isEmpty {
            reasons.append("Matches \(matchedConcerns.map(\.shortTitle).sorted().joined(separator: ", "))")
        }

        reasons.append(product.recommendationReadiness.shortReason)

        if product.fragranceFree && profile.prefersFragranceFree {
            reasons.append("Fits fragrance-free preference")
        }

        if product.sensitivityScore >= profile.sensitivity {
            reasons.append("Sensitivity fit \(product.sensitivityScore)/5")
        }

        switch productShelfStatuses[product.id] {
        case .using:
            reasons.append("Already marked using")
        case .owned:
            reasons.append("Already owned")
        default:
            break
        }

        if product.budgetTier == profile.budget {
            reasons.append("Matches \(profile.budget.title.lowercased()) budget")
        } else if product.price < currentProduct.price {
            reasons.append("Lower price than current pick")
        }

        if product.commercialStatus == .independent {
            reasons.append("Independent pick")
        }

        if product.evidenceLevel == .thirdPartyVerified || product.evidenceLevel == .clinicalReviewed {
            reasons.append(product.evidenceLevel.title)
        }

        if containsKnownIrritant(product, profile: profile) {
            reasons.append("Review ingredient flags before swapping")
        }

        if reasons.isEmpty {
            reasons.append("Same routine category with a different ingredient profile")
        }

        return Array(reasons.prefix(3))
    }

    private func weeklyNotes(for report: SkinReport, profile: UserProfile) -> [String] {
        var notes = [
            "Rescan every 14 days in similar lighting for a fair progress comparison.",
            "Add only one new active at a time so irritation has a clear cause."
        ]

        if report.scanQuality.confidenceLevel != .high {
            notes.append("Your scan quality was not perfect; retake before making expensive product changes.")
        }

        if profile.prefersFragranceFree {
            notes.append("The routine prioritizes fragrance-free products because sensitivity and redness are trust-critical.")
        }

        if profile.routineComplexity == .minimal {
            notes.append("Your routine is intentionally minimal, so optional exfoliation is skipped until the basics feel stable.")
        }

        if !profile.knownIrritants.isEmpty {
            notes.append("Ingredient flags from your profile are treated conservatively when product metadata is available.")
        }

        if profile.retinoidSafetyContext == .pregnantNursingTrying {
            notes.append("Retinoids are avoided because your profile marked pregnancy, nursing, or trying to conceive.")
        }

        return notes
    }
}
