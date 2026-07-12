import XCTest
@testable import DermaLens

final class PremiumAccessPolicyTests: XCTestCase {
    func testFreeShelfAllowsAddingUntilLimit() {
        let policy = PremiumAccessPolicy()

        let decision = policy.shelfStatusDecision(
            isPremium: false,
            trackedShelfItemCount: policy.freeShelfItemLimit - 1,
            currentStatus: .none,
            requestedStatus: .owned
        )

        XCTAssertTrue(decision.isAllowed)
    }

    func testFreeShelfBlocksNewItemsAtLimit() {
        let policy = PremiumAccessPolicy()

        let decision = policy.shelfStatusDecision(
            isPremium: false,
            trackedShelfItemCount: policy.freeShelfItemLimit,
            currentStatus: .none,
            requestedStatus: .wishlist
        )

        XCTAssertFalse(decision.isAllowed)
        XCTAssertEqual(decision.title, "Shelf limit reached")
    }

    func testFreeShelfAllowsAvoidingNewItemsAtLimit() {
        let policy = PremiumAccessPolicy()

        let decision = policy.shelfStatusDecision(
            isPremium: false,
            trackedShelfItemCount: policy.freeShelfItemLimit,
            currentStatus: .none,
            requestedStatus: .avoided
        )

        XCTAssertTrue(decision.isAllowed)
    }

    func testFreeShelfAllowsChangingOrRemovingExistingItemsAtLimit() {
        let policy = PremiumAccessPolicy()

        let changeDecision = policy.shelfStatusDecision(
            isPremium: false,
            trackedShelfItemCount: policy.freeShelfItemLimit,
            currentStatus: .owned,
            requestedStatus: .using
        )
        let removeDecision = policy.shelfStatusDecision(
            isPremium: false,
            trackedShelfItemCount: policy.freeShelfItemLimit,
            currentStatus: .owned,
            requestedStatus: .none
        )

        XCTAssertTrue(changeDecision.isAllowed)
        XCTAssertTrue(removeDecision.isAllowed)
    }

    func testPremiumShelfAllowsNewItemsBeyondLimit() {
        let policy = PremiumAccessPolicy()

        let decision = policy.shelfStatusDecision(
            isPremium: true,
            trackedShelfItemCount: 200,
            currentStatus: .none,
            requestedStatus: .using
        )

        XCTAssertTrue(decision.isAllowed)
    }

    func testFreeRoutineAlternativesArePremiumOnly() {
        let policy = PremiumAccessPolicy()

        let decision = policy.routineAlternativesDecision(isPremium: false)

        XCTAssertFalse(decision.isAllowed)
        XCTAssertEqual(decision.title, "Premium alternatives")
    }

    func testPremiumRoutineAlternativesAreAllowed() {
        let policy = PremiumAccessPolicy()

        let decision = policy.routineAlternativesDecision(isPremium: true)

        XCTAssertTrue(decision.isAllowed)
    }

    func testFreeVisibleReportsAreLimitedToLatestReport() {
        let policy = PremiumAccessPolicy()
        let older = report(createdAt: Date(timeIntervalSince1970: 10), summary: "Older")
        let newer = report(createdAt: Date(timeIntervalSince1970: 20), summary: "Newer")

        let visible = policy.visibleReports(from: [older, newer], isPremium: false)

        XCTAssertEqual(visible.map(\.summary), ["Newer"])
        XCTAssertEqual(policy.hiddenReportCount(in: [older, newer], isPremium: false), 1)
    }

    func testPremiumVisibleReportsIncludeAllSortedReports() {
        let policy = PremiumAccessPolicy()
        let older = report(createdAt: Date(timeIntervalSince1970: 10), summary: "Older")
        let newer = report(createdAt: Date(timeIntervalSince1970: 20), summary: "Newer")

        let visible = policy.visibleReports(from: [older, newer], isPremium: true)

        XCTAssertEqual(visible.map(\.summary), ["Newer", "Older"])
        XCTAssertEqual(policy.hiddenReportCount(in: [older, newer], isPremium: true), 0)
    }

    func testFreeIngredientFindingsShowPreviewOnly() {
        let policy = PremiumAccessPolicy()
        let first = finding(title: "First", severity: .info)
        let second = finding(title: "Second", severity: .info)

        let visible = policy.visibleIngredientFindings(from: [first, second], isPremium: false)

        XCTAssertEqual(visible.map(\.title), ["First"])
        XCTAssertEqual(policy.hiddenIngredientFindingCount(in: [first, second], isPremium: false), 1)
    }

    func testFreeIngredientFindingsDoNotHideSafetyWarnings() {
        let policy = PremiumAccessPolicy()
        let warning = finding(title: "Warning", severity: .warning)
        let caution = finding(title: "Caution", severity: .caution)
        let info = finding(title: "Info", severity: .info)

        let visible = policy.visibleIngredientFindings(from: [warning, caution, info], isPremium: false)

        XCTAssertEqual(visible.map(\.title), ["Warning", "Caution"])
        XCTAssertEqual(policy.hiddenIngredientFindingCount(in: [warning, caution, info], isPremium: false), 1)
    }

    func testPremiumIngredientFindingsShowAllFindings() {
        let policy = PremiumAccessPolicy()
        let first = finding(title: "First")
        let second = finding(title: "Second")
        let third = finding(title: "Third")

        let visible = policy.visibleIngredientFindings(from: [first, second, third], isPremium: true)

        XCTAssertEqual(visible.map(\.title), ["First", "Second", "Third"])
        XCTAssertEqual(policy.hiddenIngredientFindingCount(in: [first, second, third], isPremium: true), 0)
    }

    private func report(createdAt: Date, summary: String) -> SkinReport {
        SkinReport(
            createdAt: createdAt,
            scanQuality: .preview,
            scores: [
                ConcernScore(
                    concern: .redness,
                    score: 70,
                    confidence: .high,
                    primaryRegion: .leftCheek,
                    explanation: "Fixture"
                )
            ],
            visibleStrengths: [],
            summary: summary
        )
    }

    private func finding(title: String, severity: IngredientFindingSeverity = .caution) -> IngredientCompatibilityFinding {
        IngredientCompatibilityFinding(
            severity: severity,
            title: title,
            detail: "Fixture",
            relatedProductIDs: []
        )
    }
}
