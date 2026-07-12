import Foundation

struct IngredientCompatibilityEngine {
    func analyze(plan: RoutinePlan, profile: UserProfile) -> [IngredientCompatibilityFinding] {
        var findings: [IngredientCompatibilityFinding] = []
        let products = uniqueProducts(from: plan)

        findings.append(contentsOf: sunscreenFindings(products: products))
        findings.append(contentsOf: retinoidFindings(plan: plan, profile: profile))
        findings.append(contentsOf: exfoliantFindings(plan: plan, profile: profile))
        findings.append(contentsOf: fragranceFindings(products: products, profile: profile))
        findings.append(contentsOf: knownIrritantFindings(products: products, profile: profile))
        findings.append(contentsOf: ingredientCoverageFindings(products: products))
        findings.append(contentsOf: duplicateActiveFindings(products: products))
        findings.append(contentsOf: positiveFitFindings(products: products, focus: plan.focus))

        return findings.sorted { lhs, rhs in
            severityRank(lhs.severity) > severityRank(rhs.severity)
        }
    }

    private func uniqueProducts(from plan: RoutinePlan) -> [SkincareProduct] {
        var seen: Set<String> = []
        var products: [SkincareProduct] = []
        for step in plan.steps where !seen.contains(step.product.id) {
            seen.insert(step.product.id)
            products.append(step.product)
        }
        return products
    }

    private func sunscreenFindings(products: [SkincareProduct]) -> [IngredientCompatibilityFinding] {
        guard products.contains(where: { $0.category == .sunscreen }) else {
            return [
                IngredientCompatibilityFinding(
                    severity: .warning,
                    title: "SPF is missing",
                    detail: "Dark spots, redness, and texture plans need daily sunscreen to be credible.",
                    recommendation: "Add a sunscreen step before judging whether tone or redness products are working.",
                    relatedProductIDs: []
                )
            ]
        }

        return [
            IngredientCompatibilityFinding(
                severity: .info,
                title: "SPF supports visible progress",
                detail: "The routine includes sunscreen, which is the highest-confidence support step for uneven tone.",
                recommendation: "Keep SPF as the final morning step and rescan in similar lighting after two weeks.",
                relatedProductIDs: products.filter { $0.category == .sunscreen }.map(\.id)
            )
        ]
    }

    private func retinoidFindings(plan: RoutinePlan, profile: UserProfile) -> [IngredientCompatibilityFinding] {
        let retinoidSteps = plan.steps.filter {
            containsAny($0.product, tokens: ["retinal", "retinol", "retinoid", "retinyl", "adapalene", "tretinoin"])
        }
        guard !retinoidSteps.isEmpty else { return [] }

        if profile.shouldAvoidRetinoids {
            let detail = profile.retinoidSafetyContext == .pregnantNursingTrying
                ? "Your profile marked pregnancy, nursing, or trying to conceive. Retinoids should be avoided unless a qualified clinician approves."
                : "Your profile avoids retinoids, so this active should be swapped before the routine is trusted."
            return [
                IngredientCompatibilityFinding(
                    severity: .warning,
                    title: "Retinoid safety conflict",
                    detail: detail,
                    recommendation: "Swap this product before using the routine, or ask a qualified clinician if retinoids are appropriate.",
                    relatedProductIDs: retinoidSteps.map(\.product.id)
                )
            ]
        }

        return [
            IngredientCompatibilityFinding(
                severity: .caution,
                title: "Introduce retinoid slowly",
                detail: "Use retinoids only at night and avoid combining them with exfoliants on the same evening.",
                recommendation: "Start two nights weekly, moisturize after, and pause if skin feels hot, tight, or flaky.",
                relatedProductIDs: retinoidSteps.map(\.product.id)
            )
        ]
    }

    private func exfoliantFindings(plan: RoutinePlan, profile: UserProfile) -> [IngredientCompatibilityFinding] {
        let exfoliantSteps = plan.steps.filter { step in
            step.product.category == .exfoliant
            || containsAny(step.product, tokens: ["pha", "aha", "bha", "glycolic", "lactic", "salicylic"])
        }
        guard !exfoliantSteps.isEmpty else { return [] }

        var findings = [
            IngredientCompatibilityFinding(
                severity: .caution,
                title: "Limit exfoliation frequency",
                detail: "Keep exfoliation to one or two nights weekly until the routine proves comfortable.",
                recommendation: "Schedule exfoliation away from retinoids and stop first if irritation appears.",
                relatedProductIDs: exfoliantSteps.map(\.product.id)
            )
        ]

        if profile.sensitivity >= 4 {
            findings.append(IngredientCompatibilityFinding(
                severity: .warning,
                title: "Sensitive profile needs slower active ramp",
                detail: "High sensitivity plus exfoliation raises irritation risk. Start once weekly or skip until redness calms.",
                recommendation: "Use moisturizer-only recovery nights between active nights.",
                relatedProductIDs: exfoliantSteps.map(\.product.id)
            ))
        }

        if profile.knownIrritants.contains(.exfoliatingAcids) {
            findings.append(IngredientCompatibilityFinding(
                severity: .warning,
                title: "Acid sensitivity flag",
                detail: "Your profile flags exfoliating acids, so acid steps should be removed or reviewed before use.",
                recommendation: "Swap the acid step for a barrier-supporting product unless you already know this ingredient is tolerated.",
                relatedProductIDs: exfoliantSteps.map(\.product.id)
            ))
        }

        return findings
    }

    private func fragranceFindings(products: [SkincareProduct], profile: UserProfile) -> [IngredientCompatibilityFinding] {
        guard profile.prefersFragranceFree else { return [] }
        let fragranceProducts = products.filter { !$0.fragranceFree }
        guard !fragranceProducts.isEmpty else {
            let allSupportAbsenceClaims = products.allSatisfy(\.ingredientListCoverage.supportsAbsenceClaims)
            return [
                IngredientCompatibilityFinding(
                    severity: .info,
                    title: allSupportAbsenceClaims ? "Fragrance preference respected" : "Fragrance preference appears respected",
                    detail: allSupportAbsenceClaims
                        ? "Recommended products have complete ingredient lists that support the fragrance-free match."
                        : "Recommended products are labeled fragrance-free, but at least one ingredient list is partial, so absence claims stay conservative.",
                    recommendation: "Keep fragrance-free as a filter and prefer complete INCI data when adding custom products to the shelf.",
                    relatedProductIDs: products.map(\.id)
                )
            ]
        }

        return [
            IngredientCompatibilityFinding(
                severity: .warning,
                title: "Fragrance preference conflict",
                detail: "One or more products do not match your fragrance-free preference.",
                recommendation: "Swap fragrance-containing products first if redness, stinging, or barrier stress is a priority.",
                relatedProductIDs: fragranceProducts.map(\.id)
            )
        ]
    }

    private func knownIrritantFindings(products: [SkincareProduct], profile: UserProfile) -> [IngredientCompatibilityFinding] {
        profile.knownIrritants.compactMap { irritant in
            guard irritant != .fragrance, irritant != .essentialOils, irritant != .exfoliatingAcids else { return nil }
            let matching = products.filter { product in
                containsAny(product, tokens: irritant.tokens)
            }
            guard !matching.isEmpty else { return nil }

            return IngredientCompatibilityFinding(
                severity: .warning,
                title: "\(irritant.title) sensitivity flag",
                detail: "Your profile flags \(irritant.title.lowercased()). Review or swap matching products before trusting the routine.",
                recommendation: "Patch test carefully and prefer an alternative without this flagged ingredient family.",
                relatedProductIDs: matching.map(\.id)
            )
        }
    }

    private func ingredientCoverageFindings(products: [SkincareProduct]) -> [IngredientCompatibilityFinding] {
        let limitedProducts = products.filter { !$0.ingredientListCoverage.supportsAbsenceClaims }
        guard !limitedProducts.isEmpty else { return [] }

        return [
            IngredientCompatibilityFinding(
                severity: .caution,
                title: "Ingredient data is partial",
                detail: "Some product checks use hero or partial ingredient data, so DermaLens cannot confirm a flagged irritant is absent.",
                recommendation: "Add a complete INCI list for custom products or prefer verified formulas before relying on conflict checks.",
                relatedProductIDs: limitedProducts.map(\.id)
            )
        ]
    }

    private func duplicateActiveFindings(products: [SkincareProduct]) -> [IngredientCompatibilityFinding] {
        let activeGroups: [(String, [String])] = [
            ("niacinamide", ["niacinamide"]),
            ("ceramide", ["ceramide"]),
            ("azelaic acid", ["azelaic"]),
            ("exfoliating acids", ["pha", "aha", "bha", "glycolic", "lactic", "salicylic"])
        ]

        return activeGroups.compactMap { label, tokens in
            let matching = products.filter { containsAny($0, tokens: tokens) }
            guard matching.count >= 2 else { return nil }
            return IngredientCompatibilityFinding(
                severity: .caution,
                title: "Duplicate \(label)",
                detail: "Multiple products contain \(label). This may be fine, but simplify if irritation appears.",
                recommendation: "If comfort drops, keep the gentlest product and remove one duplicate active first.",
                relatedProductIDs: matching.map(\.id)
            )
        }
    }

    private func positiveFitFindings(products: [SkincareProduct], focus: [SkinConcern]) -> [IngredientCompatibilityFinding] {
        let focusSet = Set(focus)
        let matched = products.filter { !$0.concernFit.isDisjoint(with: focusSet) }
        guard !matched.isEmpty else { return [] }

        return [
            IngredientCompatibilityFinding(
                severity: .info,
                title: "Products match scan priorities",
                detail: "The routine includes products mapped to \(focus.map(\.shortTitle).joined(separator: ", ")).",
                recommendation: "Give the routine consistent use before judging score movement.",
                relatedProductIDs: matched.map(\.id)
            )
        ]
    }

    private func containsAny(_ product: SkincareProduct, tokens: [String]) -> Bool {
        product.hasIngredientSignal(matching: tokens)
    }

    private func severityRank(_ severity: IngredientFindingSeverity) -> Int {
        switch severity {
        case .warning: 3
        case .caution: 2
        case .info: 1
        }
    }
}
