import SwiftUI

struct MetricPill: View {
    var title: String
    var value: String
    var symbolName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

struct ConcernBadge: View {
    var concern: SkinConcern
    var score: Int?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: concern.symbolName)
                .font(.caption.weight(.bold))
            Text(score.map { "\(concern.shortTitle) \($0)" } ?? concern.shortTitle)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Theme.concernColor(concern))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.concernColor(concern).opacity(0.12))
        .clipShape(Capsule())
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.moss)
            }
        }
    }
}

struct ScoreRing: View {
    var score: Int
    var tint: Color
    var label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.16), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(10)
        }
        .frame(width: 88, height: 88)
        .accessibilityLabel("\(label), score \(score)")
    }
}

struct PrimaryButton: View {
    var title: String
    var symbolName: String
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: symbolName)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.body.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.moss)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
    }
}

struct ProductCard: View {
    var product: SkincareProduct
    var compact = false

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
                    Text(product.brand)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                    Text(product.name)
                        .font(compact ? .subheadline.weight(.bold) : .headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("$\(product.price) - \(product.category.title)")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()
            }

            ProductTrustChips(product: product, compact: compact)
            ProductTrustSummaryView(summary: product.trustSummary, compact: compact)
            ProductSourceDisclosureView(metadata: product.sourceMetadata, compact: compact)

            if !compact {
                Text(product.whyItMatches)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

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
            }
        }
        .softCard(padding: 14)
    }
}

struct ProductSourceDisclosureView: View {
    var metadata: ProductSourceMetadata
    var compact = false

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(metadata.sourceDisplay)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)

                Text(compactDetail)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if !compact {
                    Text(metadata.ingredientVerificationDisplay)
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } icon: {
            Image(systemName: "doc.text.magnifyingglass")
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, compact ? 6 : 8)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel(Text(metadata.accessibilitySummary))
    }

    private var compactDetail: String {
        "\(metadata.sourceReviewDisplay) - \(metadata.reviewerDisplay)"
    }

    private var tint: Color {
        metadata.hasRecordedSource && metadata.hasDatedSourceReview ? Theme.moss : Theme.amber
    }
}

struct ProductTrustSummaryView: View {
    var summary: ProductTrustSummary
    var compact = false

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.headline)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                if shouldShowDetail {
                    Text(summary.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } icon: {
            Image(systemName: summary.grade.symbolName)
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, compact ? 6 : 8)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var tint: Color {
        switch summary.grade {
        case .strong: Theme.leaf
        case .clear: Theme.moss
        case .provisional: Theme.amber
        case .review: Theme.coral
        }
    }

    private var shouldShowDetail: Bool {
        !compact || summary.grade == .provisional || summary.grade == .review
    }

    private var accessibilityLabel: String {
        var parts = ["Product trust: \(summary.headline)", "score \(summary.score)"]
        parts.append(contentsOf: summary.strengths)
        parts.append(contentsOf: summary.limitations)
        return parts.joined(separator: ", ")
    }
}

struct ProductTrustChips: View {
    var product: SkincareProduct
    var compact = false

    private var chips: [(title: String, symbolName: String, tint: Color)] {
        let values: [(title: String, symbolName: String, tint: Color)] = [
            (title: product.catalogSource.title, symbolName: product.catalogSource.symbolName, tint: Theme.moss),
            (title: product.evidenceLevel.title, symbolName: product.evidenceLevel.symbolName, tint: Theme.leaf),
            (title: product.ingredientListCoverage.title, symbolName: product.ingredientListCoverage.symbolName, tint: product.ingredientListCoverage.supportsAbsenceClaims ? Theme.lavender : Theme.amber),
            (title: product.commercialStatus.title, symbolName: product.commercialStatus.symbolName, tint: product.commercialStatus == .independent ? Theme.lavender : Theme.amber),
            (title: product.recommendationReadiness.title, symbolName: product.recommendationReadiness.symbolName, tint: readinessTint)
        ]
        return values
    }

    var body: some View {
        FlowLayout(spacing: 7) {
            ForEach(Array(chips.enumerated()), id: \.offset) { item in
                let chip = item.element
                Label(chip.title, systemImage: chip.symbolName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(chip.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(chip.tint.opacity(0.10))
                    .clipShape(Capsule())
            }
        }
        .accessibilityLabel(Text(product.disclosureSummary))
    }

    private var readinessTint: Color {
        switch product.recommendationReadiness {
        case .purchaseReady: Theme.leaf
        case .metadataReviewNeeded: Theme.amber
        case .prototypeOnly, .userReviewNeeded: Theme.coral
        }
    }
}

struct ProductReadinessDisclosureView: View {
    var readiness: ProductRecommendationReadiness
    var compact = false

    var body: some View {
        if readiness != .purchaseReady {
            Label {
                Text(readiness.detail)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: readiness.symbolName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
            }
            .padding(.horizontal, compact ? 9 : 10)
            .padding(.vertical, compact ? 6 : 8)
            .background(tint.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(Text("\(readiness.title): \(readiness.detail)"))
        }
    }

    private var tint: Color {
        switch readiness {
        case .purchaseReady: Theme.leaf
        case .metadataReviewNeeded: Theme.amber
        case .prototypeOnly, .userReviewNeeded: Theme.coral
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var size = CGSize(width: maxWidth, height: 0)
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if x + subviewSize.width > maxWidth, x > 0 {
                size.height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }

        size.height += rowHeight
        return size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if x + subviewSize.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
            )
            x += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
    }
}
