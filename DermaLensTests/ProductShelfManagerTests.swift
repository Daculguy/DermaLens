import XCTest
@testable import DermaLens

final class ProductShelfManagerTests: XCTestCase {
    func testSettingStatusReplacesPreviousStatusForSameProduct() {
        let manager = ProductShelfManager()
        let productID = "cleanser-oat-gel"

        var state = manager.state(
            afterSetting: .wishlist,
            for: productID,
            in: .empty,
            date: Date(timeIntervalSince1970: 10)
        )
        state = manager.state(
            afterSetting: .using,
            for: productID,
            in: state,
            date: Date(timeIntervalSince1970: 20)
        )

        XCTAssertEqual(state.items.count, 1)
        XCTAssertEqual(manager.status(for: productID, in: state), .using)
        XCTAssertEqual(state.items.first?.updatedAt, Date(timeIntervalSince1970: 20))
    }

    func testRemovingShelfItemDeletesOnlyThatProduct() {
        let manager = ProductShelfManager()
        var state = ProductShelfState.empty
        state = manager.state(afterSetting: .owned, for: "a", in: state)
        state = manager.state(afterSetting: .wishlist, for: "b", in: state)

        let removed = manager.state(afterRemoving: "a", from: state)

        XCTAssertEqual(manager.status(for: "a", in: removed), .none)
        XCTAssertEqual(manager.status(for: "b", in: removed), .wishlist)
    }

    func testSummaryCountsStatuses() {
        let manager = ProductShelfManager()
        var state = ProductShelfState.empty
        state = manager.state(afterSetting: .owned, for: "owned", in: state)
        state = manager.state(afterSetting: .using, for: "using", in: state)
        state = manager.state(afterSetting: .wishlist, for: "wishlist", in: state)
        state = manager.state(afterSetting: .avoided, for: "avoided", in: state)

        let summary = manager.summary(for: state)

        XCTAssertEqual(summary.ownedCount, 1)
        XCTAssertEqual(summary.usingCount, 1)
        XCTAssertEqual(summary.wishlistCount, 1)
        XCTAssertEqual(summary.avoidedCount, 1)
    }

    func testDuplicatePersistedItemsCollapseToLatestStatusMapValue() {
        let state = ProductShelfState(items: [
            ProductShelfItem(productID: "a", status: .owned, updatedAt: Date(timeIntervalSince1970: 10), note: nil),
            ProductShelfItem(productID: "a", status: .avoided, updatedAt: Date(timeIntervalSince1970: 20), note: nil)
        ])

        XCTAssertEqual(state.statuses["a"], .avoided)
        XCTAssertEqual(ProductShelfManager().status(for: "a", in: state), .avoided)
    }

    func testShelfSearchIncludesFullIngredientList() {
        let product = customProduct(
            id: "custom-search",
            heroIngredients: ["peptides"],
            fullIngredients: ["water", "glycerin", "azelaic acid"],
            ingredientListCoverage: .completeINCI
        )

        XCTAssertTrue(product.matchesShelfSearch("azelaic"))
        XCTAssertTrue(product.matchesShelfSearch("peptides"))
        XCTAssertFalse(product.matchesShelfSearch("retinol"))
    }

    @MainActor
    func testDeleteAllLocalDataClearsShelfItems() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        appState.setProductShelfStatus(.owned, for: SampleData.products[0])
        appState.addCustomProduct(customProduct(id: "custom-reset"), initialStatus: .owned)

        appState.deleteAllLocalData()

        XCTAssertTrue(appState.productShelfState.items.isEmpty)
        XCTAssertTrue(appState.customProducts.isEmpty)
    }

    @MainActor
    func testCustomProductPersistsAndFeedsRoutineWhenTracked() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PersistenceStore(defaults: defaults)
        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: store
        )
        let product = customProduct(id: "custom-cleanser", category: .cleanser)

        appState.addCustomProduct(product, initialStatus: .using)

        XCTAssertEqual(appState.productShelfStatus(for: product), .using)
        XCTAssertTrue(appState.productCatalog.contains { $0.id == product.id })
        XCTAssertTrue(appState.routinePlan.steps.contains { $0.product.id == product.id })

        let restored = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: store
        )

        XCTAssertTrue(restored.customProducts.contains { $0.id == product.id })
        XCTAssertEqual(restored.productShelfStatus(for: product), .using)
        XCTAssertTrue(restored.routinePlan.steps.contains { $0.product.id == product.id })
    }

    @MainActor
    func testCustomProductWithNoStatusStaysOutOfRoutine() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        let product = customProduct(id: "custom-untracked", category: .mask)

        appState.addCustomProduct(product, initialStatus: .none)

        XCTAssertTrue(appState.productCatalog.contains { $0.id == product.id })
        XCTAssertEqual(appState.productShelfStatus(for: product), .none)
        XCTAssertFalse(appState.routinePlan.steps.contains { $0.product.id == product.id })
    }

    @MainActor
    func testDeletingCustomProductRemovesShelfStateAndRoutineUse() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        let product = customProduct(id: "custom-delete", category: .cleanser)
        appState.addCustomProduct(product, initialStatus: .using)
        if let step = appState.routinePlan.steps.first(where: { $0.product.id == product.id }) {
            appState.toggleRoutineStepCompletion(step)
        }

        appState.deleteCustomProduct(product)

        XCTAssertFalse(appState.customProducts.contains { $0.id == product.id })
        XCTAssertEqual(appState.productShelfStatus(for: product), .none)
        XCTAssertFalse(appState.routinePlan.steps.contains { $0.product.id == product.id })
        XCTAssertFalse(appState.routineCompletionRecords.contains { $0.stepKey.productID == product.id })
    }

    @MainActor
    func testRoutineSwapUsesCustomProductAndMarksItUsing() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PersistenceStore(defaults: defaults)
        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: store
        )
        let step = appState.routinePlan.steps.first { $0.category == .cleanser }!
        let custom = customProduct(id: "custom-swap", category: .cleanser)
        appState.addCustomProduct(custom, initialStatus: .none)
        appState.toggleRoutineStepCompletion(step)

        appState.swapRoutineStep(step, with: custom)

        XCTAssertEqual(appState.productShelfStatus(for: custom), .using)
        XCTAssertTrue(appState.routinePlan.steps.contains { $0.product.id == custom.id })
        XCTAssertTrue(appState.routineSwapOverrides.contains { $0.productID == custom.id })
        XCTAssertFalse(appState.routineCompletionRecords.contains { $0.stepKey.productID == step.product.id })
        XCTAssertTrue(appState.routinePlan.steps.contains { routineStep in
            routineStep.product.id == custom.id
            && routineStep.selectionReasons.contains { $0.localizedCaseInsensitiveContains("user-selected") }
        })

        let restored = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: store
        )

        XCTAssertEqual(restored.productShelfStatus(for: custom), .using)
        XCTAssertTrue(restored.routinePlan.steps.contains { $0.product.id == custom.id })
        XCTAssertTrue(restored.routineSwapOverrides.contains { $0.productID == custom.id })
    }

    @MainActor
    func testRoutineSwapPromotesWishlistCustomProductToUsing() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        let step = appState.routinePlan.steps.first { $0.category == .cleanser }!
        let custom = customProduct(id: "custom-wishlist-swap", category: .cleanser)
        appState.addCustomProduct(custom, initialStatus: .wishlist)

        appState.swapRoutineStep(step, with: custom)

        XCTAssertEqual(appState.productShelfStatus(for: custom), .using)
        XCTAssertTrue(appState.routinePlan.steps.contains { $0.product.id == custom.id })
    }

    @MainActor
    func testFreeRoutineSwapIsBlockedAndShowsPaywall() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        let step = appState.routinePlan.steps.first { $0.category == .cleanser }!
        let alternative = SampleData.products.first { $0.id == "cleanser-balanced-milk" }!

        let decision = appState.swapRoutineStep(step, with: alternative, isPremium: false)

        XCTAssertFalse(decision.isAllowed)
        XCTAssertTrue(appState.showingPaywall)
        XCTAssertFalse(appState.routinePlan.steps.contains { $0.product.id == alternative.id })
        XCTAssertTrue(appState.routineSwapOverrides.isEmpty)
    }

    @MainActor
    func testRetinoidSwapRemovesExfoliantCompletionRecords() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        let treatmentStep = appState.routinePlan.steps.first { $0.category == .treatment }!
        let exfoliantStep = appState.routinePlan.steps.first { $0.category == .exfoliant }!
        let retinoid = SampleData.products.first { $0.id == "treatment-retinal" }!
        appState.toggleRoutineStepCompletion(exfoliantStep)

        appState.swapRoutineStep(treatmentStep, with: retinoid)

        XCTAssertFalse(appState.routinePlan.steps.contains { $0.category == .exfoliant })
        XCTAssertFalse(appState.routineCompletionRecords.contains { $0.stepKey == RoutineStepKey(step: exfoliantStep) })
    }

    @MainActor
    func testFullIngredientRetinoidSwapRemovesExfoliantCompletionRecords() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        let treatmentStep = appState.routinePlan.steps.first { $0.category == .treatment }!
        let exfoliantStep = appState.routinePlan.steps.first { $0.category == .exfoliant }!
        let retinoid = customProduct(
            id: "custom-hidden-retinoid",
            category: .treatment,
            heroIngredients: ["peptides"],
            fullIngredients: ["water", "glycerin", "adapalene"],
            ingredientListCoverage: .completeINCI
        )
        appState.addCustomProduct(retinoid, initialStatus: .none)
        appState.toggleRoutineStepCompletion(exfoliantStep)

        appState.swapRoutineStep(treatmentStep, with: retinoid)

        XCTAssertFalse(appState.routinePlan.steps.contains { $0.category == .exfoliant })
        XCTAssertFalse(appState.routineCompletionRecords.contains { $0.stepKey == RoutineStepKey(step: exfoliantStep) })
    }

    @MainActor
    func testFullIngredientRetinoidSwapIsRejectedWhenProfileAvoidsRetinoids() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        appState.userProfile.retinoidSafetyContext = .pregnantNursingTrying
        let treatmentStep = appState.routinePlan.steps.first { $0.category == .treatment }!
        let retinoid = customProduct(
            id: "custom-blocked-retinoid",
            category: .treatment,
            heroIngredients: ["peptides"],
            fullIngredients: ["water", "glycerin", "adapalene"],
            ingredientListCoverage: .completeINCI
        )
        appState.addCustomProduct(retinoid, initialStatus: .none)

        let decision = appState.swapRoutineStep(treatmentStep, with: retinoid)

        XCTAssertFalse(decision.isAllowed)
        XCTAssertFalse(appState.routinePlan.steps.contains { $0.product.id == retinoid.id })
    }

    @MainActor
    func testProductAlternativesIncludeUntrackedCustomProducts() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: NoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        let step = appState.routinePlan.steps.first { $0.category == .cleanser }!
        let custom = customProduct(id: "custom-alternative", category: .cleanser)
        appState.addCustomProduct(custom, initialStatus: .none)

        let alternatives = appState.productAlternatives(for: step)

        XCTAssertTrue(alternatives.contains { $0.product.id == custom.id })
        XCTAssertFalse(appState.routinePlan.steps.contains { $0.product.id == custom.id })
    }

    private func customProduct(
        id: String,
        category: ProductCategory = .treatment,
        heroIngredients: [String] = ["glycerin", "centella", "niacinamide"],
        fullIngredients: [String] = [],
        ingredientListCoverage: IngredientListCoverage = .heroOnly
    ) -> SkincareProduct {
        SkincareProduct(
            id: id,
            name: "Custom \(category.title)",
            brand: "User Shelf",
            category: category,
            price: 8,
            budgetTier: .balanced,
            heroIngredients: heroIngredients,
            fullIngredients: fullIngredients,
            ingredientListCoverage: ingredientListCoverage,
            concernFit: [.redness, .texture, .blemishes, .barrier],
            fragranceFree: true,
            sensitivityScore: 3,
            usageNote: "Use",
            whyItMatches: "Fixture custom product"
        )
    }
}

private struct NoopRoutineNotificationScheduler: RoutineNotificationScheduling {
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
