import Foundation

struct PremiumAccessDecision: Equatable {
    var isAllowed: Bool
    var title: String
    var detail: String

    static let allowed = PremiumAccessDecision(
        isAllowed: true,
        title: "Allowed",
        detail: ""
    )
}

struct PremiumAccessPolicy {
    let freeShelfItemLimit = 5
    let freeVisibleReportLimit = 1
    let freeIngredientFindingLimit = 1

    func routineAlternativesDecision(isPremium: Bool) -> PremiumAccessDecision {
        guard !isPremium else { return .allowed }

        return PremiumAccessDecision(
            isAllowed: false,
            title: "Premium alternatives",
            detail: "Premium unlocks ranked product swaps that keep the routine strategy intact."
        )
    }

    func shelfStatusDecision(
        isPremium: Bool,
        trackedShelfItemCount: Int,
        currentStatus: ProductShelfStatus,
        requestedStatus: ProductShelfStatus
    ) -> PremiumAccessDecision {
        if isPremium || requestedStatus == .none || requestedStatus == .avoided || currentStatus != .none {
            return .allowed
        }

        guard trackedShelfItemCount < freeShelfItemLimit else {
            return PremiumAccessDecision(
                isAllowed: false,
                title: "Shelf limit reached",
                detail: "Free keeps \(freeShelfItemLimit) tracked products. Premium unlocks unlimited shelf tracking and deeper comparisons."
            )
        }

        return .allowed
    }

    func visibleReports(
        from reports: [SkinReport],
        isPremium: Bool
    ) -> [SkinReport] {
        let sortedReports = reports.sorted { lhs, rhs in
            lhs.createdAt > rhs.createdAt
        }

        guard !isPremium else { return sortedReports }
        return Array(sortedReports.prefix(freeVisibleReportLimit))
    }

    func hiddenReportCount(
        in reports: [SkinReport],
        isPremium: Bool
    ) -> Int {
        guard !isPremium else { return 0 }
        return max(0, reports.count - freeVisibleReportLimit)
    }

    func visibleIngredientFindings(
        from findings: [IngredientCompatibilityFinding],
        isPremium: Bool
    ) -> [IngredientCompatibilityFinding] {
        guard !isPremium else { return findings }
        let safetyFindings = findings.filter { $0.severity != .info }
        guard safetyFindings.isEmpty else { return safetyFindings }
        return Array(findings.prefix(freeIngredientFindingLimit))
    }

    func hiddenIngredientFindingCount(
        in findings: [IngredientCompatibilityFinding],
        isPremium: Bool
    ) -> Int {
        guard !isPremium else { return 0 }
        let visibleIDs = Set(visibleIngredientFindings(from: findings, isPremium: false).map(\.id))
        return findings.filter { !visibleIDs.contains($0.id) }.count
    }
}
