import XCTest
@testable import DermaLens

@MainActor
final class SubscriptionManagerTests: XCTestCase {
    func testLoadProductsSortsByPrice() async {
        let client = MockSubscriptionStoreClient(products: [
            .yearly,
            .monthly
        ])
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.loadProducts()

        XCTAssertEqual(manager.storeProducts.map(\.id), [
            "dermalens.premium.monthly",
            "dermalens.premium.yearly"
        ])
        XCTAssertNil(manager.purchaseError)
        XCTAssertNil(manager.statusMessage)
    }

    func testLoadProductsFailureShowsConfigurationError() async {
        let client = MockSubscriptionStoreClient(productsError: TestSubscriptionError.productLoadFailed)
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.loadProducts()

        XCTAssertTrue(manager.storeProducts.isEmpty)
        XCTAssertEqual(manager.purchaseError, "Subscriptions are not configured in this build yet.")
        XCTAssertFalse(manager.isLoadingProducts)
    }

    func testSuccessfulPurchaseRefreshesPremiumEntitlement() async {
        let client = MockSubscriptionStoreClient(products: [.monthly])
        client.purchaseOutcome = .success
        client.entitlementProductIDsAfterPurchase = ["dermalens.premium.monthly"]
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.purchase(.monthly)

        XCTAssertTrue(manager.isPremium)
        XCTAssertEqual(manager.statusMessage, "Premium is active.")
        XCTAssertNil(manager.purchaseError)
        XCTAssertFalse(manager.isPurchasing)
        XCTAssertNil(manager.activeProductID)
    }

    func testCancelledPurchaseDoesNotUnlockPremium() async {
        let client = MockSubscriptionStoreClient(products: [.monthly])
        client.purchaseOutcome = .userCancelled
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.purchase(.monthly)

        XCTAssertFalse(manager.isPremium)
        XCTAssertEqual(manager.statusMessage, "Purchase canceled.")
        XCTAssertNil(manager.purchaseError)
    }

    func testPendingPurchaseDoesNotUnlockUntilStoreConfirms() async {
        let client = MockSubscriptionStoreClient(products: [.monthly])
        client.purchaseOutcome = .pending
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.purchase(.monthly)

        XCTAssertFalse(manager.isPremium)
        XCTAssertEqual(manager.statusMessage, "Purchase is pending approval. Premium unlocks after the App Store confirms it.")
        XCTAssertNil(manager.purchaseError)
    }

    func testPurchaseFailureShowsStoreError() async {
        let client = MockSubscriptionStoreClient(products: [.monthly])
        client.purchaseError = TestSubscriptionError.purchaseFailed
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.purchase(.monthly)

        XCTAssertFalse(manager.isPremium)
        XCTAssertEqual(manager.purchaseError, TestSubscriptionError.purchaseFailed.localizedDescription)
        XCTAssertNil(manager.statusMessage)
    }

    func testRestoreSuccessRefreshesPremiumEntitlement() async {
        let client = MockSubscriptionStoreClient(products: [.yearly])
        client.entitlementProductIDsAfterRestore = ["dermalens.premium.yearly"]
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.restorePurchases()

        XCTAssertTrue(manager.isPremium)
        XCTAssertEqual(manager.statusMessage, "Premium restored.")
        XCTAssertNil(manager.purchaseError)
        XCTAssertFalse(manager.isRestoring)
    }

    func testRestoreWithoutEntitlementShowsNoSubscriptionStatus() async {
        let client = MockSubscriptionStoreClient(products: [.monthly])
        client.entitlementProductIDsAfterRestore = []
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.restorePurchases()

        XCTAssertFalse(manager.isPremium)
        XCTAssertEqual(manager.statusMessage, "No active Premium subscription was found for this Apple ID.")
        XCTAssertNil(manager.purchaseError)
    }

    func testRestoreFailureShowsStoreError() async {
        let client = MockSubscriptionStoreClient(products: [.monthly])
        client.restoreError = TestSubscriptionError.restoreFailed
        let manager = SubscriptionManager(
            storeClient: client,
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )

        await manager.restorePurchases()

        XCTAssertFalse(manager.isPremium)
        XCTAssertEqual(manager.purchaseError, TestSubscriptionError.restoreFailed.localizedDescription)
        XCTAssertNil(manager.statusMessage)
    }
}

@MainActor
private final class MockSubscriptionStoreClient: SubscriptionStoreClient {
    var products: [SubscriptionProduct]
    var productsError: Error?
    var purchaseOutcome: SubscriptionPurchaseOutcome = .success
    var purchaseError: Error?
    var restoreError: Error?
    var entitlementProductIDs = Set<String>()
    var entitlementProductIDsAfterPurchase: Set<String>?
    var entitlementProductIDsAfterRestore: Set<String>?

    init(
        products: [SubscriptionProduct] = [],
        productsError: Error? = nil
    ) {
        self.products = products
        self.productsError = productsError
    }

    func products(for productIDs: Set<String>) async throws -> [SubscriptionProduct] {
        if let productsError {
            throw productsError
        }
        return products.filter { productIDs.contains($0.id) }
    }

    func purchase(_ product: SubscriptionProduct) async throws -> SubscriptionPurchaseOutcome {
        if let purchaseError {
            throw purchaseError
        }
        if let entitlementProductIDsAfterPurchase {
            entitlementProductIDs = entitlementProductIDsAfterPurchase
        }
        return purchaseOutcome
    }

    func restorePurchases() async throws {
        if let restoreError {
            throw restoreError
        }
        if let entitlementProductIDsAfterRestore {
            entitlementProductIDs = entitlementProductIDsAfterRestore
        }
    }

    func currentEntitlementProductIDs() async -> Set<String> {
        entitlementProductIDs
    }

    func verifiedTransactionUpdates() -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private enum TestSubscriptionError: LocalizedError {
    case productLoadFailed
    case purchaseFailed
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .productLoadFailed:
            "Products failed to load."
        case .purchaseFailed:
            "Purchase failed."
        case .restoreFailed:
            "Restore failed."
        }
    }
}

private extension SubscriptionProduct {
    static let monthly = SubscriptionProduct(
        id: "dermalens.premium.monthly",
        displayName: "DermaLens Monthly",
        displayPrice: "$4.99",
        description: "Monthly premium access",
        renewalPeriodDisplay: "month",
        priceSortValue: 4.99
    )

    static let yearly = SubscriptionProduct(
        id: "dermalens.premium.yearly",
        displayName: "DermaLens Yearly",
        displayPrice: "$39.99",
        description: "Yearly premium access",
        renewalPeriodDisplay: "year",
        priceSortValue: 39.99
    )
}
