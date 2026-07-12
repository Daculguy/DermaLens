import SwiftUI

struct RoutineView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedMoment: RoutineMoment = .morning
    @State private var alternativeContext: RoutineAlternativeContext?
    private let premiumPolicy = PremiumAccessPolicy()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if appState.hasCompletedScan {
                        header
                        recommendationSourceNotice
                        reminderControls
                        adherenceOverview
                        momentPicker
                        steps
                        ingredientGuardrails
                        weeklyNotes
                        focusControls
                    } else {
                        NoScanRoutineState {
                            appState.selectedTab = .scan
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Routine")
            .sheet(item: $alternativeContext) { context in
                ProductAlternativesSheet(step: context.step)
                    .environmentObject(appState)
                    .presentationDetents([.large])
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal plan")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Built from your latest scan and tuned to avoid the common mistake: adding too many actives at once.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 8) {
                ForEach(appState.routinePlan.focus, id: \.self) { concern in
                    ConcernBadge(concern: concern, score: nil)
                }
            }
        }
        .softCard(padding: 16)
    }

    @ViewBuilder
    private var recommendationSourceNotice: some View {
        if appState.latestReport.analysisMetadata.isPrototypeOutput {
            VStack(alignment: .leading, spacing: 10) {
                Label("Prototype recommendation source", systemImage: "slider.horizontal.3")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("This routine is rule-generated from the latest scan priorities, profile choices, and a prototype catalog. Treat product picks as testable suggestions, not proof a product will fix a visible concern.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .softCard(padding: 14)
        }
    }

    private var momentPicker: some View {
        Picker("Routine moment", selection: $selectedMoment) {
            ForEach(RoutineMoment.allCases) { moment in
                Label(moment.title, systemImage: moment.symbolName)
                    .tag(moment)
            }
        }
        .pickerStyle(.segmented)
    }

    private var adherenceOverview: some View {
        let summary = appState.routineAdherenceSummary

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: summary.isComplete ? "checkmark.seal.fill" : "chart.bar.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(summary.isComplete ? Theme.leaf : Theme.moss)
                    .frame(width: 36, height: 36)
                    .background((summary.isComplete ? Theme.leaf : Theme.moss).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.isComplete ? "Routine complete today" : "Today's routine")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text("\(summary.progressLabel) steps done - \(summary.streakLabel)")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()
            }

            ProgressView(value: summary.completionRatio)
                .tint(summary.isComplete ? Theme.leaf : Theme.moss)
        }
        .softCard(padding: 14)
    }

    private var reminderControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { appState.routineRemindersEnabled },
                set: { isEnabled in
                    Task {
                        await appState.setRoutineRemindersEnabled(isEnabled)
                    }
                }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.routineReminderStatus.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.ink)
                        Text(appState.routineReminderStatus.detail)
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: appState.routineReminderStatus.symbolName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Theme.moss)
                }
            }
            .tint(Theme.moss)
            .disabled(appState.isUpdatingRoutineReminders)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                reminderTimePicker(for: .morning)
                reminderTimePicker(for: .evening)

                Label("Times are stored on this device and exported with local data.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if appState.isUpdatingRoutineReminders {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Updating reminders")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .softCard(padding: 14)
        .task {
            await appState.refreshRoutineReminderAuthorization()
        }
    }

    private func reminderTimePicker(for moment: RoutineMoment) -> some View {
        DatePicker(
            moment.title,
            selection: Binding(
                get: {
                    appState.routineReminderPreferences.time(for: moment).date()
                },
                set: { date in
                    appState.updateRoutineReminderTime(for: moment, to: date)
                }
            ),
            displayedComponents: .hourAndMinute
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Theme.ink)
        .tint(Theme.moss)
        .disabled(appState.isUpdatingRoutineReminders)
        .accessibilityValue(appState.routineReminderPreferences.time(for: moment).displayText)
    }

    private var steps: some View {
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "\(selectedMoment.title) steps",
                subtitle: "Tap the step circle when you finish it."
            )

            ForEach(appState.routinePlan.steps(for: selectedMoment)) { step in
                RoutineStepCard(
                    step: step,
                    isComplete: appState.isRoutineStepCompleted(step),
                    isPremium: subscriptionManager.isPremium,
                    toggle: { appState.toggleRoutineStepCompletion(step) },
                    showAlternatives: {
                        if subscriptionManager.isPremium {
                            alternativeContext = RoutineAlternativeContext(step: step)
                        } else {
                            appState.showingPaywall = true
                        }
                    }
                )
            }
        }
    }

    private var weeklyNotes: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Weekly guardrails", subtitle: "How to keep the routine from backfiring.")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(appState.routinePlan.weeklyNotes, id: \.self) { note in
                    Label(note, systemImage: "shield.checkered")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                }
            }
            .softCard(padding: 14)
        }
    }

    private var ingredientGuardrails: some View {
        let visibleFindings = premiumPolicy.visibleIngredientFindings(
            from: appState.ingredientFindings,
            isPremium: subscriptionManager.isPremium
        )
        let hiddenFindingCount = premiumPolicy.hiddenIngredientFindingCount(
            in: appState.ingredientFindings,
            isPremium: subscriptionManager.isPremium
        )

        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Ingredient guardrails",
                subtitle: subscriptionManager.isPremium ? "Compatibility checks across the whole routine." : "Safety findings stay visible. Premium unlocks the fuller ingredient list."
            )

            VStack(alignment: .leading, spacing: 10) {
                ForEach(visibleFindings.prefix(subscriptionManager.isPremium ? visibleFindings.count : 4)) { finding in
                    IngredientFindingRow(finding: finding)
                }

                if hiddenFindingCount > 0 {
                    RoutineLockedIngredientCard(hiddenFindingCount: hiddenFindingCount) {
                        appState.showingPaywall = true
                    }
                }
            }
        }
    }

    private var focusControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Tune goals", subtitle: "Use this when your personal goal differs from the scan priority.")

            VStack(spacing: 10) {
                ForEach(SkinConcern.allCases) { concern in
                    Toggle(isOn: Binding(
                        get: { appState.userProfile.currentGoals.contains(concern) },
                        set: { appState.updateProfile(goal: concern, isEnabled: $0) }
                    )) {
                        Label(concern.title, systemImage: concern.symbolName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    .tint(Theme.concernColor(concern))
                }
            }
            .softCard(padding: 14)
        }
    }
}

private struct RoutineLockedIngredientCard: View {
    var hiddenFindingCount: Int
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                "\(hiddenFindingCount) deeper ingredient finding\(hiddenFindingCount == 1 ? "" : "s") locked",
                systemImage: "lock"
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Theme.ink)

            Text("Premium keeps safety warnings visible and unlocks the full compatibility report for context, alternatives, and progress comparisons.")
                .font(.caption)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Label("View premium", systemImage: "lock.open")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.amber)
            }
            .buttonStyle(.plain)
        }
        .softCard(padding: 14)
    }
}

private struct RoutineAlternativeContext: Identifiable {
    var step: RoutineStep
    var id: UUID { step.id }
}

private struct NoScanRoutineState: View {
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Routine starts after your scan", systemImage: "checklist")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("DermaLens waits for a real report before choosing products, checking ingredient conflicts, or tracking step completion.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Label("No demo products are marked as your routine.", systemImage: "shippingbox")
                Label("Your profile choices will still shape the plan once a scan exists.", systemImage: "slider.horizontal.3")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)

            PrimaryButton(title: "Start guided scan", symbolName: "camera.viewfinder", action: action)
        }
        .softCard(padding: 16)
    }
}

private struct IngredientFindingRow: View {
    var finding: IngredientCompatibilityFinding

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: finding.severity.symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(finding.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(finding.detail)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Label(finding.recommendation, systemImage: "arrow.turn.down.right")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .softCard(padding: 14)
    }

    private var tint: Color {
        switch finding.severity {
        case .info: Theme.leaf
        case .caution: Theme.amber
        case .warning: Theme.coral
        }
    }
}

private struct RoutineStepCard: View {
    var step: RoutineStep
    var isComplete: Bool
    var isPremium: Bool
    var toggle: () -> Void
    var showAlternatives: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Button(action: toggle) {
                    Image(systemName: isComplete ? "checkmark.circle.fill" : "\(step.order).circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isComplete ? Theme.leaf : Theme.moss)
                        .frame(width: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isComplete ? "Mark step incomplete" : "Mark step complete")

                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text(step.category.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.muted)
                        Spacer()
                        Text(step.product.brand)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                    }

                    Text(step.product.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)

                    ProductTrustChips(product: step.product, compact: true)
                    ProductTrustSummaryView(summary: step.product.trustSummary, compact: true)
                    ProductSourceDisclosureView(metadata: step.product.sourceMetadata, compact: true)
                    ProductReadinessDisclosureView(readiness: step.product.recommendationReadiness, compact: true)

                    RoutineSelectionRationale(step: step)

                    Text(step.instruction)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let caution = step.caution {
                        Label(caution, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(Theme.amber)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: showAlternatives) {
                        Label(isPremium ? "View alternatives" : "Premium alternatives", systemImage: isPremium ? "arrow.triangle.2.circlepath" : "lock")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isPremium ? Theme.moss : Theme.amber)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .softCard(padding: 14)
        .accessibilityLabel("\(step.category.title), \(step.product.name)")
        .accessibilityValue(isComplete ? "Complete" : "Not complete")
    }
}

private struct RoutineSelectionRationale: View {
    var step: RoutineStep

    var body: some View {
        FlowLayout(spacing: 7) {
            if let fitScore = step.fitScore {
                Text("Fit \(fitScore)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.moss)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Theme.moss.opacity(0.10))
                    .clipShape(Capsule())
            }

            ForEach(step.selectionReasons, id: \.self) { reason in
                Text(reason)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Theme.muted.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .accessibilityLabel(Text(rationaleLabel))
    }

    private var rationaleLabel: String {
        var parts: [String] = []
        if let fitScore = step.fitScore {
            parts.append("Fit score \(fitScore)")
        }
        parts.append(contentsOf: step.selectionReasons)
        return parts.joined(separator: ", ")
    }
}

private struct ProductAlternativesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    var step: RoutineStep

    private var alternatives: [ProductAlternative] {
        appState.productAlternatives(for: step)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    currentPick
                    alternativeList
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Alternatives")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Swap without breaking the plan")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Alternatives keep the same routine role and reuse the app's safety, budget, shelf, and ingredient guardrails.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard(padding: 16)
    }

    private var currentPick: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Current \(step.category.title.lowercased())")
            ProductCard(product: step.product, compact: true)
        }
    }

    @ViewBuilder
    private var alternativeList: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Ranked alternatives", subtitle: "Higher fit scores appear first.")

            if alternatives.isEmpty {
                EmptyAlternativeState()
            } else {
                ForEach(alternatives) { alternative in
                    AlternativeProductCard(
                        alternative: alternative,
                        isCustom: appState.isCustomProduct(alternative.product),
                        action: {
                            let decision = appState.swapRoutineStep(
                                step,
                                with: alternative.product,
                                isPremium: subscriptionManager.isPremium
                            )
                            if decision.isAllowed {
                                dismiss()
                            }
                        }
                    )
                }
            }
        }
    }
}

private struct AlternativeProductCard: View {
    var alternative: ProductAlternative
    var isCustom: Bool
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: alternative.product.category.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(width: 42, height: 42)
                    .background(Theme.moss.opacity(0.11))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(alternative.product.brand)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.muted)
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
                    Text(alternative.product.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(priceAndFitLabel)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()
            }

            FlowLayout(spacing: 8) {
                ForEach(alternative.reasons, id: \.self) { reason in
                    Text(reason)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.moss)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Theme.moss.opacity(0.09))
                        .clipShape(Capsule())
                }
            }

            ProductTrustChips(product: alternative.product)
            ProductTrustSummaryView(summary: alternative.product.trustSummary)
            ProductSourceDisclosureView(metadata: alternative.product.sourceMetadata)
            ProductReadinessDisclosureView(readiness: alternative.product.recommendationReadiness)

            PrimaryButton(title: actionTitle, symbolName: "arrow.triangle.2.circlepath", action: action)
        }
        .softCard(padding: 14)
    }

    private var priceAndFitLabel: String {
        let priceLabel = alternative.product.recommendationReadiness == .purchaseReady
            ? "$\(alternative.product.price)"
            : "$\(alternative.product.price) reference"
        return "\(priceLabel) - Fit \(alternative.score)"
    }

    private var actionTitle: String {
        switch alternative.product.recommendationReadiness {
        case .purchaseReady:
            "Swap into routine"
        case .prototypeOnly:
            "Use as prototype swap"
        case .userReviewNeeded, .metadataReviewNeeded:
            "Use with review label"
        }
    }
}

private struct EmptyAlternativeState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No compatible alternatives yet", systemImage: "shippingbox")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Add products to your Shelf or loosen filters like retinoid avoidance, fragrance preference, or budget before swapping.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard(padding: 14)
    }
}

#Preview {
    RoutineView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.preview())
}
