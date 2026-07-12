import Combine
import Foundation
import StoreKit

struct SubscriptionProduct: Identifiable, Equatable {
    var id: String
    var displayName: String
    var displayPrice: String
    var description: String
    var renewalPeriodDisplay: String?
    var priceSortValue: Double
    fileprivate var storeKitProduct: StoreKit.Product?

    init(
        id: String,
        displayName: String,
        displayPrice: String,
        description: String,
        renewalPeriodDisplay: String?,
        priceSortValue: Double
    ) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.description = description
        self.renewalPeriodDisplay = renewalPeriodDisplay
        self.priceSortValue = priceSortValue
        self.storeKitProduct = nil
    }

    fileprivate init(
        id: String,
        displayName: String,
        displayPrice: String,
        description: String,
        renewalPeriodDisplay: String?,
        priceSortValue: Double,
        storeKitProduct: StoreKit.Product
    ) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.description = description
        self.renewalPeriodDisplay = renewalPeriodDisplay
        self.priceSortValue = priceSortValue
        self.storeKitProduct = storeKitProduct
    }

    static func == (lhs: SubscriptionProduct, rhs: SubscriptionProduct) -> Bool {
        lhs.id == rhs.id
            && lhs.displayName == rhs.displayName
            && lhs.displayPrice == rhs.displayPrice
            && lhs.description == rhs.description
            && lhs.renewalPeriodDisplay == rhs.renewalPeriodDisplay
            && lhs.priceSortValue == rhs.priceSortValue
    }
}

enum SubscriptionPurchaseOutcome: Equatable {
    case success
    case userCancelled
    case pending
    case unknown
}

@MainActor
protocol SubscriptionStoreClient {
    func products(for productIDs: Set<String>) async throws -> [SubscriptionProduct]
    func purchase(_ product: SubscriptionProduct) async throws -> SubscriptionPurchaseOutcome
    func restorePurchases() async throws
    func currentEntitlementProductIDs() async -> Set<String>
    func verifiedTransactionUpdates() -> AsyncStream<String>
}

@MainActor
final class SubscriptionManager: ObservableObject {
    static let premiumProductIDs: Set<String> = [
        "dermalens.premium.monthly",
        "dermalens.premium.yearly"
    ]

    @Published private(set) var storeProducts: [SubscriptionProduct] = []
    @Published private(set) var isPremium = false
    @Published private(set) var purchaseError: String?
    @Published private(set) var statusMessage: String?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published private(set) var activeProductID: String?

    var isTransactionInProgress: Bool {
        isPurchasing || isRestoring
    }

    private var updatesTask: Task<Void, Never>?
    private let storeClient: SubscriptionStoreClient

    init(
        storeClient: SubscriptionStoreClient = AppStoreSubscriptionClient(),
        automaticallyLoadsProducts: Bool = true,
        listensForTransactions: Bool = true
    ) {
        self.storeClient = storeClient
        if listensForTransactions {
            updatesTask = listenForTransactions()
        }
        if automaticallyLoadsProducts {
            Task {
                await loadProducts()
                await refreshEntitlements()
            }
        }
    }

    static func preview() -> SubscriptionManager {
        SubscriptionManager(
            storeClient: PreviewSubscriptionStoreClient(),
            automaticallyLoadsProducts: false,
            listensForTransactions: false
        )
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoadingProducts = true
        purchaseError = nil
        statusMessage = nil
        defer { isLoadingProducts = false }

        do {
            storeProducts = try await storeClient.products(for: Self.premiumProductIDs)
                .sorted { $0.priceSortValue < $1.priceSortValue }
            if storeProducts.isEmpty {
                statusMessage = "StoreKit products are not loaded yet. The plans below are previews for simulator QA."
            }
        } catch {
            purchaseError = "Subscriptions are not configured in this build yet."
        }
    }

    func purchase(_ product: SubscriptionProduct) async {
        guard !isTransactionInProgress else { return }
        isPurchasing = true
        activeProductID = product.id
        purchaseError = nil
        statusMessage = nil
        defer {
            isPurchasing = false
            activeProductID = nil
        }

        do {
            let result = try await storeClient.purchase(product)
            switch result {
            case .success:
                await refreshEntitlements()
                statusMessage = isPremium ? "Premium is active." : nil
            case .userCancelled:
                statusMessage = "Purchase canceled."
            case .pending:
                statusMessage = "Purchase is pending approval. Premium unlocks after the App Store confirms it."
            case .unknown:
                statusMessage = "The App Store returned an unknown purchase state."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        guard !isTransactionInProgress else { return }
        isRestoring = true
        purchaseError = nil
        statusMessage = nil
        defer { isRestoring = false }

        do {
            try await storeClient.restorePurchases()
            await refreshEntitlements()
            statusMessage = isPremium
                ? "Premium restored."
                : "No active Premium subscription was found for this Apple ID."
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        let productIDs = await storeClient.currentEntitlementProductIDs()
        isPremium = !productIDs.intersection(Self.premiumProductIDs).isEmpty
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            for await _ in storeClient.verifiedTransactionUpdates() {
                guard !Task.isCancelled else { return }
                await self.refreshEntitlements()
            }
        }
    }
}

private struct AppStoreSubscriptionClient: SubscriptionStoreClient {
    func products(for productIDs: Set<String>) async throws -> [SubscriptionProduct] {
        try await StoreKit.Product.products(for: Array(productIDs)).map(SubscriptionProduct.init(storeKitProduct:))
    }

    func purchase(_ product: SubscriptionProduct) async throws -> SubscriptionPurchaseOutcome {
        guard let storeKitProduct = product.storeKitProduct else {
            throw SubscriptionStoreError.missingStoreKitProduct
        }

        let result = try await storeKitProduct.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return .success
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .unknown
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    func currentEntitlementProductIDs() async -> Set<String> {
        var productIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            productIDs.insert(transaction.productID)
        }
        return productIDs
    }

    func verifiedTransactionUpdates() -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { return }
                    guard case .verified(let transaction) = result else { continue }
                    let productID = transaction.productID
                    await transaction.finish()
                    continuation.yield(productID)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseVerificationError.failed
        case .verified(let safe):
            return safe
        }
    }
}

private struct PreviewSubscriptionStoreClient: SubscriptionStoreClient {
    func products(for productIDs: Set<String>) async throws -> [SubscriptionProduct] {
        [SubscriptionProduct.previewMonthlyPlan, .previewYearlyPlan]
            .filter { productIDs.contains($0.id) }
    }

    func purchase(_ product: SubscriptionProduct) async throws -> SubscriptionPurchaseOutcome {
        .userCancelled
    }

    func restorePurchases() async throws {}

    func currentEntitlementProductIDs() async -> Set<String> {
        []
    }

    func verifiedTransactionUpdates() -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private extension SubscriptionProduct {
    init(storeKitProduct product: StoreKit.Product) {
        self.init(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            description: product.description,
            renewalPeriodDisplay: product.subscription?.subscriptionPeriod.displayName,
            priceSortValue: NSDecimalNumber(decimal: product.price).doubleValue,
            storeKitProduct: product
        )
    }

    static let previewMonthlyPlan = SubscriptionProduct(
        id: "dermalens.premium.monthly",
        displayName: "DermaLens Monthly",
        displayPrice: "$4.99",
        description: "Monthly premium access",
        renewalPeriodDisplay: "month",
        priceSortValue: 4.99
    )

    static let previewYearlyPlan = SubscriptionProduct(
        id: "dermalens.premium.yearly",
        displayName: "DermaLens Yearly",
        displayPrice: "$39.99",
        description: "Yearly premium access",
        renewalPeriodDisplay: "year",
        priceSortValue: 39.99
    )
}

private enum PurchaseVerificationError: LocalizedError {
    case failed

    var errorDescription: String? {
        "The App Store could not verify this purchase."
    }
}

private enum SubscriptionStoreError: LocalizedError {
    case missingStoreKitProduct

    var errorDescription: String? {
        "This subscription product is not available for purchase yet."
    }
}

private extension Product.SubscriptionPeriod {
    var displayName: String {
        let unitName: String
        switch unit {
        case .day:
            unitName = value == 1 ? "day" : "days"
        case .week:
            unitName = value == 1 ? "week" : "weeks"
        case .month:
            unitName = value == 1 ? "month" : "months"
        case .year:
            unitName = value == 1 ? "year" : "years"
        @unknown default:
            unitName = "periods"
        }

        return value == 1 ? unitName : "\(value) \(unitName)"
    }
}
