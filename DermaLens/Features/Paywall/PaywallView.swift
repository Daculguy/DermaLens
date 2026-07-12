import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    included
                    purchaseOptions
                    legalSection
                    safetyCopy
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Premium")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
            .onChange(of: subscriptionManager.isPremium) { _, isPremium in
                if isPremium {
                    dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DermaLens Premium")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Pay for clarity: deeper ingredient reasoning, progress comparisons, and product alternatives without turning the scan into fake certainty.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                MetricPill(title: "History", value: "Saved", symbolName: "doc.text.magnifyingglass", tint: Theme.moss)
                MetricPill(title: "Reports", value: "Ingredient-level", symbolName: "text.magnifyingglass", tint: Theme.leaf)
            }
        }
        .softCard(padding: 18)
    }

    private var included: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Included", subtitle: nil)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(symbol: "chart.xyaxis.line", title: "Progress scans", detail: "Compare concern scores using repeatable capture quality gates.")
                FeatureRow(symbol: "cross.case", title: "Ingredient logic", detail: "See why an active was recommended and what to avoid combining.")
                FeatureRow(symbol: "shippingbox", title: "Budget alternatives", detail: "Swap products without breaking the routine strategy.")
                FeatureRow(symbol: "shield.checkered", title: "Trust controls", detail: "Confidence labels, scan-quality warnings, and conservative safety copy.")
            }
            .softCard(padding: 14)
        }
    }

    @ViewBuilder
    private var purchaseOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Choose plan", subtitle: "Purchases and restores are handled by the App Store.")

            if subscriptionManager.isLoadingProducts {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Theme.moss)
                    Text("Loading App Store products")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                }
                .softCard(padding: 12)
            }

            if subscriptionManager.storeProducts.isEmpty {
                VStack(spacing: 12) {
                    StaticPlanCard(title: "Monthly", price: "$4.99", detail: "$4.99 per month. Auto-renews monthly until canceled.", isFeatured: false)
                    StaticPlanCard(title: "Yearly", price: "$39.99", detail: "$39.99 per year. Auto-renews yearly until canceled.", isFeatured: true)

                    Label("Preview plans. Purchases activate after StoreKit products load.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Task { await subscriptionManager.loadProducts() }
                    } label: {
                        Label("Retry StoreKit products", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.moss)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .disabled(subscriptionManager.isLoadingProducts || subscriptionManager.isTransactionInProgress)

                    restoreButton
                }
            } else {
                ForEach(subscriptionManager.storeProducts, id: \.id) { product in
                    Button {
                        Task { await subscriptionManager.purchase(product) }
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.displayName)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Theme.ink)
                                Text(product.description)
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(renewalTerms(for: product))
                                    .font(.caption2)
                                    .foregroundStyle(Theme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            if subscriptionManager.activeProductID == product.id {
                                ProgressView()
                                    .tint(Theme.moss)
                            } else {
                                Text(product.displayPrice)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Theme.moss)
                            }
                        }
                        .softCard(padding: 14)
                    }
                    .buttonStyle(.plain)
                    .disabled(subscriptionManager.isTransactionInProgress)
                }

                restoreButton
            }

            if let status = subscriptionManager.statusMessage {
                Label(status, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let error = subscriptionManager.purchaseError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Theme.amber)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Legal", subtitle: "Review before purchase.")
            LegalDocumentLinks()
        }
    }

    private var restoreButton: some View {
        Button {
            Task { await subscriptionManager.restorePurchases() }
        } label: {
            HStack(spacing: 8) {
                if subscriptionManager.isRestoring {
                    ProgressView()
                        .tint(Theme.moss)
                }
                Text(subscriptionManager.isRestoring ? "Restoring purchases" : "Restore purchases")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.moss)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .disabled(subscriptionManager.isTransactionInProgress)
    }

    private var safetyCopy: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Subscriptions renew automatically unless canceled in your Apple account settings.", systemImage: "arrow.triangle.2.circlepath")
            Label("Your Apple account is charged after purchase confirmation and manages cancellation.", systemImage: "person.crop.circle.badge.checkmark")
            Label("DermaLens Premium does not diagnose, treat, or replace a dermatologist.", systemImage: "cross.case")
            Label("See a clinician for painful, changing, bleeding, or suspicious lesions.", systemImage: "exclamationmark.triangle")
            Label("Face ID can protect access, but the app cannot access Face ID biometric templates.", systemImage: "faceid")
        }
        .font(.footnote)
        .foregroundStyle(Theme.muted)
        .softCard(padding: 14)
    }

    private func renewalTerms(for product: SubscriptionProduct) -> String {
        guard let period = product.renewalPeriodDisplay else {
            return "Purchase handled by the App Store."
        }

        return "\(product.displayPrice) per \(period). Auto-renews until canceled in Apple account settings."
    }
}

private struct FeatureRow: View {
    var symbol: String
    var title: String
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Theme.moss)
                .frame(width: 34, height: 34)
                .background(Theme.moss.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct StaticPlanCard: View {
    var title: String
    var price: String
    var detail: String
    var isFeatured: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    if isFeatured {
                        Text("Best value")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.leaf)
                            .clipShape(Capsule())
                    }
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text(price)
                .font(.headline.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.moss)
        }
        .softCard(padding: 14)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager.preview())
}
