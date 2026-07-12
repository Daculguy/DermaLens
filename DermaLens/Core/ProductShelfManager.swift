import Foundation

enum ProductShelfStatus: String, CaseIterable, Codable, Identifiable, Hashable {
    case none
    case owned
    case using
    case wishlist
    case avoided

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "None"
        case .owned:
            "Owned"
        case .using:
            "Using"
        case .wishlist:
            "Wishlist"
        case .avoided:
            "Avoid"
        }
    }

    var symbolName: String {
        switch self {
        case .none:
            "circle"
        case .owned:
            "shippingbox"
        case .using:
            "checkmark.seal"
        case .wishlist:
            "heart"
        case .avoided:
            "nosign"
        }
    }

    var influencesRoutine: Bool {
        switch self {
        case .owned, .using, .avoided:
            true
        case .none, .wishlist:
            false
        }
    }
}

struct ProductShelfItem: Codable, Identifiable, Hashable {
    var id: String { productID }
    var productID: String
    var status: ProductShelfStatus
    var updatedAt: Date
    var note: String?
}

struct ProductShelfState: Codable, Hashable {
    var items: [ProductShelfItem]

    static let empty = ProductShelfState(items: [])

    var statuses: [String: ProductShelfStatus] {
        var result: [String: ProductShelfStatus] = [:]
        for item in items {
            result[item.productID] = item.status
        }
        return result
    }
}

struct ProductShelfSummary: Hashable {
    var ownedCount: Int
    var usingCount: Int
    var wishlistCount: Int
    var avoidedCount: Int
}

struct ProductShelfManager {
    func status(for productID: String, in state: ProductShelfState) -> ProductShelfStatus {
        state.items.last { $0.productID == productID }?.status ?? .none
    }

    func state(
        afterSetting status: ProductShelfStatus,
        for productID: String,
        in state: ProductShelfState,
        date: Date = Date()
    ) -> ProductShelfState {
        var nextState = state
        remove(productID, from: &nextState.items)

        switch status {
        case .none:
            break
        case .owned, .using, .wishlist, .avoided:
            nextState.items.append(ProductShelfItem(
                productID: productID,
                status: status,
                updatedAt: date,
                note: nil
            ))
        }

        return nextState
    }

    func state(afterRemoving productID: String, from state: ProductShelfState) -> ProductShelfState {
        var nextState = state
        remove(productID, from: &nextState.items)
        return nextState
    }

    func summary(for state: ProductShelfState) -> ProductShelfSummary {
        ProductShelfSummary(
            ownedCount: state.items.filter { $0.status == .owned }.count,
            usingCount: state.items.filter { $0.status == .using }.count,
            wishlistCount: state.items.filter { $0.status == .wishlist }.count,
            avoidedCount: state.items.filter { $0.status == .avoided }.count
        )
    }

    private func remove(_ productID: String, from items: inout [ProductShelfItem]) {
        items.removeAll { $0.productID == productID }
    }
}
