import SwiftUI

struct ShelfView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedCategory: ProductCategory? = nil
    @State private var selectedFilter: ShelfProductFilter = .all
    @State private var searchText = ""
    @State private var presentedSheet: ShelfSheet?
    private let premiumPolicy = PremiumAccessPolicy()

    private var products: [SkincareProduct] {
        let recommendedIDs = Set(appState.routinePlan.steps.map(\.product.id))
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = appState.productCatalog
            .filter { product in
                guard let selectedCategory else { return true }
                return product.category == selectedCategory
            }
            .filter { product in
                selectedFilter.includes(
                    product: product,
                    status: appState.productShelfStatus(for: product),
                    recommendedIDs: recommendedIDs
                )
            }
            .filter { product in
                guard !query.isEmpty else { return true }
                return product.matchesShelfSearch(query)
            }
            .sorted { lhs, rhs in
            if recommendedIDs.contains(lhs.id) != recommendedIDs.contains(rhs.id) {
                return recommendedIDs.contains(lhs.id)
            }
            let lhsRank = appState.productShelfStatus(for: lhs).sortRank
            let rhsRank = appState.productShelfStatus(for: rhs).sortRank
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            return lhs.price < rhs.price
        }
        return base
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    shelfSummary
                    filterScroller
                    categoryScroller
                    recommendedStack
                    comparisonPanel
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Shelf")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentedSheet = .addProduct
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add product")
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .addProduct:
                    AddProductSheet()
                        .environmentObject(appState)
                        .environmentObject(subscriptionManager)
                        .presentationDetents([.large])
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Search products")
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Product shelf")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Search, track, and compare products with source, ingredient, commercial, and trust disclosures visible.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                MetricPill(
                    title: "Budget",
                    value: appState.userProfile.budget.title,
                    symbolName: "dollarsign.circle",
                    tint: Theme.leaf
                )
                MetricPill(
                    title: "Owned",
                    value: "\(appState.productShelfSummary.ownedCount + appState.productShelfSummary.usingCount)",
                    symbolName: "shippingbox",
                    tint: Theme.moss
                )
            }

            if !subscriptionManager.isPremium {
                Label("Free shelf tracks \(premiumPolicy.freeShelfItemLimit) products. Premium unlocks unlimited shelf tracking.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(Theme.moss)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if appState.userProfile.avoidsRetinoids {
                Label("Retinoid products are deprioritized for your safety preference.", systemImage: "exclamationmark.shield")
                    .font(.caption)
                    .foregroundStyle(Theme.amber)
            }
        }
        .softCard(padding: 16)
    }

    private var shelfSummary: some View {
        HStack(spacing: 12) {
            MetricPill(
                title: "Wishlist",
                value: "\(appState.productShelfSummary.wishlistCount)",
                symbolName: "heart",
                tint: Theme.coral
            )
            Divider()
                .frame(height: 42)
            MetricPill(
                title: "Avoided",
                value: "\(appState.productShelfSummary.avoidedCount)",
                symbolName: "nosign",
                tint: Theme.amber
            )
        }
        .softCard(padding: 14)
    }

    private var filterScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShelfProductFilter.allCases) { filter in
                    CategoryChip(
                        title: filter.title,
                        symbolName: filter.symbolName,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var categoryScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    symbolName: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach(ProductCategory.allCases) { category in
                    CategoryChip(
                        title: category.title,
                        symbolName: category.symbolName,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var recommendedStack: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: selectedFilter.title,
                subtitle: selectedCategory.map { "\($0.title) products" } ?? "Routine picks appear first, then shelf items."
            )

            if products.isEmpty {
                EmptyShelfState(
                    title: "No products found",
                    detail: "Try another category, status, or search term."
                )
            } else {
                ForEach(products) { product in
                    ShelfProductCard(
                        product: product,
                        status: appState.productShelfStatus(for: product),
                        isRoutinePick: appState.routinePlan.steps.contains { $0.product.id == product.id },
                        isCustom: appState.isCustomProduct(product),
                        setStatus: { status in
                            let currentStatus = appState.productShelfStatus(for: product)
                            let nextStatus: ProductShelfStatus = currentStatus == status ? .none : status
                            let decision = premiumPolicy.shelfStatusDecision(
                                isPremium: subscriptionManager.isPremium,
                                trackedShelfItemCount: appState.productShelfState.items.count,
                                currentStatus: currentStatus,
                                requestedStatus: nextStatus
                            )
                            guard decision.isAllowed else {
                                appState.showingPaywall = true
                                return
                            }
                            appState.setProductShelfStatus(nextStatus, for: product)
                        },
                        deleteCustomProduct: appState.isCustomProduct(product) ? {
                            appState.deleteCustomProduct(product)
                        } : nil
                    )
                }
            }
        }
    }

    private enum ShelfSheet: Identifiable {
        case addProduct

        var id: String {
            switch self {
            case .addProduct: "addProduct"
            }
        }
    }

    private var comparisonPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Why these products", subtitle: "The app should earn trust with reasons, not mystery scores.")

            VStack(alignment: .leading, spacing: 10) {
                Label("Products that match top scan concerns get the largest lift.", systemImage: "chart.bar")
                Label("Sensitivity and fragrance-free preferences can outrank expensive actives.", systemImage: "leaf")
                Label("Every product shows source, evidence level, and commercial status before you track or swap it.", systemImage: "checkmark.shield")
                Label(subscriptionManager.isPremium ? "Premium alternatives are unlocked." : "Premium unlocks deeper ingredient comparisons and unlimited shelf tracking.", systemImage: subscriptionManager.isPremium ? "checkmark.seal" : "lock")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .softCard(padding: 14)

            if !subscriptionManager.isPremium {
                PrimaryButton(title: "Unlock comparisons", symbolName: "lock.open") {
                    appState.showingPaywall = true
                }
            }
        }
    }
}

private enum ShelfProductFilter: String, CaseIterable, Identifiable {
    case all
    case recommended
    case using
    case owned
    case wishlist
    case avoided

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .recommended: "Recommended"
        case .using: "Using"
        case .owned: "Owned"
        case .wishlist: "Wishlist"
        case .avoided: "Avoided"
        }
    }

    var symbolName: String {
        switch self {
        case .all: "square.grid.2x2"
        case .recommended: "sparkles"
        case .using: "checkmark.seal"
        case .owned: "shippingbox"
        case .wishlist: "heart"
        case .avoided: "nosign"
        }
    }

    func includes(
        product: SkincareProduct,
        status: ProductShelfStatus,
        recommendedIDs: Set<String>
    ) -> Bool {
        switch self {
        case .all:
            return true
        case .recommended:
            return recommendedIDs.contains(product.id)
        case .using:
            return status == .using
        case .owned:
            return status == .owned
        case .wishlist:
            return status == .wishlist
        case .avoided:
            return status == .avoided
        }
    }
}

private struct CategoryChip: View {
    var title: String
    var symbolName: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Theme.moss)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(isSelected ? Theme.moss : Theme.moss.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ShelfProductCard: View {
    var product: SkincareProduct
    var status: ProductShelfStatus
    var isRoutinePick: Bool
    var isCustom: Bool
    var setStatus: (ProductShelfStatus) -> Void
    var deleteCustomProduct: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: product.category.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(width: 42, height: 42)
                    .background(Theme.moss.opacity(0.11))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(product.brand)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                        if isRoutinePick {
                            Image(systemName: "sparkles")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.amber)
                                .accessibilityLabel("Recommended in routine")
                        }
                        if isCustom {
                            Text("Custom")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.moss)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Theme.moss.opacity(0.10))
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(priceAndCategoryLabel)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()

                if status != .none {
                    Label(status.title, systemImage: status.symbolName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(status.tint)
                        .labelStyle(.iconOnly)
                        .accessibilityLabel(status.title)
                }
            }

            Text(product.whyItMatches)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ProductTrustChips(product: product)
            ProductTrustSummaryView(summary: product.trustSummary)
            ProductSourceDisclosureView(metadata: product.sourceMetadata)
            ProductReadinessDisclosureView(readiness: product.recommendationReadiness)

            VStack(alignment: .leading, spacing: 7) {
                Text("Key ingredients")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.muted)

                FlowLayout(spacing: 8) {
                    ForEach(product.heroIngredients, id: \.self) { ingredient in
                        Text(ingredient)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.moss)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Theme.moss.opacity(0.09))
                            .clipShape(Capsule())
                    }
                }
            }

            HStack(spacing: 8) {
                ShelfStatusButton(
                    status: .using,
                    isSelected: status == .using,
                    action: { setStatus(.using) }
                )
                ShelfStatusButton(
                    status: .owned,
                    isSelected: status == .owned,
                    action: { setStatus(.owned) }
                )
                ShelfStatusButton(
                    status: .wishlist,
                    isSelected: status == .wishlist,
                    action: { setStatus(.wishlist) }
                )
                ShelfStatusButton(
                    status: .avoided,
                    isSelected: status == .avoided,
                    action: { setStatus(.avoided) }
                )
            }

            if let deleteCustomProduct {
                Button(role: .destructive, action: deleteCustomProduct) {
                    Label("Remove custom product", systemImage: "trash")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)
            }
        }
        .softCard(padding: 14)
    }

    private var priceAndCategoryLabel: String {
        let priceLabel = product.recommendationReadiness == .purchaseReady
            ? "$\(product.price)"
            : "$\(product.price) reference"
        return "\(priceLabel) - \(product.category.title)"
    }
}

private struct AddProductSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var name = ""
    @State private var brand = ""
    @State private var category: ProductCategory = .treatment
    @State private var price = ""
    @State private var budgetTier: BudgetTier = .balanced
    @State private var ingredients = ""
    @State private var fullIngredientList = ""
    @State private var hasCompleteIngredientList = false
    @State private var concernFit: Set<SkinConcern> = [.barrier]
    @State private var fragranceFree = true
    @State private var sensitivityScore = 3
    @State private var initialStatus: ProductShelfStatus = .owned
    @State private var validationMessage: String?

    private let premiumPolicy = PremiumAccessPolicy()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    identitySection
                    fitSection
                    statusSection
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Add product")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add something you actually use")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Manual entries stay on this device and can influence recommendations once they are marked owned, using, or avoided.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard(padding: 16)
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Product details", subtitle: "Full INCI lists make ingredient guardrails more reliable than key ingredients alone.")

            TextField("Product name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Brand", text: $brand)
                .textFieldStyle(.roundedBorder)

            Picker("Category", selection: $category) {
                ForEach(ProductCategory.allCases) { category in
                    Label(category.title, systemImage: category.symbolName).tag(category)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 12) {
                TextField("Price", text: $price)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Picker("Budget", selection: $budgetTier) {
                    ForEach(BudgetTier.allCases) { tier in
                        Text(tier.title).tag(tier)
                    }
                }
                .pickerStyle(.menu)
            }

            TextField("Key ingredients, comma separated", text: $ingredients, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            TextField("Full INCI list, comma separated (optional)", text: $fullIngredientList, axis: .vertical)
                .lineLimit(3...7)
                .textFieldStyle(.roundedBorder)

            Toggle("This is the complete ingredient list", isOn: $hasCompleteIngredientList)
                .tint(Theme.moss)
        }
        .softCard(padding: 14)
    }

    private var fitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Routine fit", subtitle: "Choose only what you reasonably know from the label.")

            Toggle("Fragrance-free", isOn: $fragranceFree)
                .tint(Theme.moss)

            Stepper("Sensitivity fit \(sensitivityScore)/5", value: $sensitivityScore, in: 1...5)

            VStack(alignment: .leading, spacing: 10) {
                Text("Concerns it may support")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.muted)

                FlowLayout(spacing: 8) {
                    ForEach(SkinConcern.allCases) { concern in
                        ProductConcernChip(
                            concern: concern,
                            isSelected: concernFit.contains(concern),
                            action: { toggle(concern) }
                        )
                    }
                }
            }

            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.amber)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .softCard(padding: 14)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Shelf status", subtitle: "Tracked products count toward the free shelf limit.")

            Picker("Initial status", selection: $initialStatus) {
                ForEach(ProductShelfStatus.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.menu)

            Label("You can change this status later from the Shelf.", systemImage: "shippingbox")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
        .softCard(padding: 14)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && parsedPrice != nil
        && (!parsedIngredients.isEmpty || !parsedFullIngredients.isEmpty)
        && !concernFit.isEmpty
    }

    private var parsedPrice: Int? {
        guard let value = Int(price.trimmingCharacters(in: .whitespacesAndNewlines)), value >= 0 else {
            return nil
        }
        return min(value, 999)
    }

    private var parsedIngredients: [String] {
        parsedIngredientList(from: ingredients, limit: 8)
    }

    private var parsedFullIngredients: [String] {
        parsedIngredientList(from: fullIngredientList, limit: 90)
    }

    private var savedHeroIngredients: [String] {
        if !parsedIngredients.isEmpty {
            return parsedIngredients
        }
        return Array(parsedFullIngredients.prefix(8))
    }

    private var savedIngredientListCoverage: IngredientListCoverage {
        if parsedFullIngredients.isEmpty {
            return .userEnteredPartial
        }
        return hasCompleteIngredientList ? .completeINCI : .userEnteredPartial
    }

    private func parsedIngredientList(from text: String, limit: Int) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(limit)
            .map(String.init)
    }

    private func toggle(_ concern: SkinConcern) {
        if concernFit.contains(concern) {
            concernFit.remove(concern)
        } else {
            concernFit.insert(concern)
        }
    }

    private func save() {
        guard canSave, let parsedPrice else {
            validationMessage = "Add a name, brand, price, at least one ingredient signal, and at least one concern."
            return
        }

        let decision = premiumPolicy.shelfStatusDecision(
            isPremium: subscriptionManager.isPremium,
            trackedShelfItemCount: appState.productShelfState.items.count,
            currentStatus: .none,
            requestedStatus: initialStatus
        )
        guard decision.isAllowed else {
            appState.showingPaywall = true
            dismiss()
            return
        }

        let product = SkincareProduct(
            id: "custom-\(UUID().uuidString.lowercased())",
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            price: parsedPrice,
            budgetTier: budgetTier,
            heroIngredients: savedHeroIngredients,
            fullIngredients: parsedFullIngredients,
            ingredientListCoverage: savedIngredientListCoverage,
            concernFit: concernFit,
            fragranceFree: fragranceFree,
            sensitivityScore: sensitivityScore,
            usageNote: defaultUsageNote,
            whyItMatches: "Custom shelf product added from your routine. DermaLens uses your label details conservatively when matching it to scan priorities.",
            catalogSource: .userEntered,
            evidenceLevel: .userProvided,
            commercialStatus: .independent,
            sourceMetadata: .userEntered
        )

        appState.addCustomProduct(product, initialStatus: initialStatus)
        dismiss()
    }

    private var defaultUsageNote: String {
        switch category {
        case .cleanser:
            "Use as your cleanser step if it feels comfortable."
        case .treatment:
            "Introduce slowly and stop if irritation appears."
        case .moisturizer:
            "Apply after treatment steps to support comfort."
        case .sunscreen:
            "Apply as the final morning step."
        case .exfoliant:
            "Use sparingly and avoid pairing with strong actives on the same night."
        case .mask:
            "Use occasionally and skip when skin feels reactive."
        }
    }
}

private struct ProductConcernChip: View {
    var concern: SkinConcern
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(concern.shortTitle, systemImage: concern.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Theme.concernColor(concern))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.concernColor(concern) : Theme.concernColor(concern).opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct ShelfStatusButton: View {
    var status: ProductShelfStatus
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(status.title, systemImage: status.symbolName)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : status.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? status.tint : status.tint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct EmptyShelfState: View {
    var title: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "magnifyingglass")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard(padding: 14)
    }
}

private extension ProductShelfStatus {
    var sortRank: Int {
        switch self {
        case .using: 0
        case .owned: 1
        case .wishlist: 2
        case .none: 3
        case .avoided: 4
        }
    }

    var tint: Color {
        switch self {
        case .none: Theme.muted
        case .owned: Theme.moss
        case .using: Theme.leaf
        case .wishlist: Theme.coral
        case .avoided: Theme.amber
        }
    }
}

extension SkincareProduct {
    func matchesShelfSearch(_ query: String) -> Bool {
        let normalizedQuery = query.lowercased()
        let haystack = [
            name,
            brand,
            category.title,
            ingredientSignalsForSearch.joined(separator: " "),
            concernFit.map(\.title).joined(separator: " ")
        ].joined(separator: " ").lowercased()

        return haystack.contains(normalizedQuery)
    }
}

#Preview {
    ShelfView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.preview())
}
