import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var profile = UserProfile.default

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    goals
                    baselineContext
                    sensitivity
                    budget
                    privacy
                    PrimaryButton(title: "Continue to guided scan", symbolName: "camera.viewfinder") {
                        appState.applyProfile(profile)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Start")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set your skin context")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("DermaLens works best when the scan is paired with your goals, skin feel, routine comfort, sensitivity, and budget. That context prevents overconfident product picks.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard(padding: 18)
    }

    private var goals: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Goals", subtitle: "Choose what you actually care about improving.")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(SkinConcern.allCases) { concern in
                    GoalToggle(
                        concern: concern,
                        isSelected: profile.currentGoals.contains(concern),
                        action: {
                            if profile.currentGoals.contains(concern) {
                                profile.currentGoals.remove(concern)
                            } else {
                                profile.currentGoals.insert(concern)
                            }
                        }
                    )
                }
            }
        }
    }

    private var baselineContext: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Skin context", subtitle: "The scan cannot see how your skin feels day to day.")

            VStack(alignment: .leading, spacing: 14) {
                Text("Baseline feel")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.muted)

                FlowLayout(spacing: 8) {
                    ForEach(BaselineSkinFeel.allCases) { feel in
                        ProfileChoiceChip(
                            title: feel.title,
                            symbolName: feel.symbolName,
                            isSelected: profile.baselineSkinFeel == feel,
                            action: { profile.baselineSkinFeel = feel }
                        )
                    }
                }

                Divider()

                Picker("Routine style", selection: $profile.routineComplexity) {
                    ForEach(RoutineComplexity.allCases) { complexity in
                        Text(complexity.title).tag(complexity)
                    }
                }
                .pickerStyle(.segmented)

                Text(profile.routineComplexity.detail)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .softCard(padding: 14)
        }
    }

    private var sensitivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Sensitivity", subtitle: "Higher sensitivity makes the routine more conservative.")

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Low")
                    Spacer()
                    Text("\(profile.sensitivity)")
                        .font(.headline.monospacedDigit().weight(.bold))
                        .foregroundStyle(Theme.moss)
                    Spacer()
                    Text("High")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)

                Slider(
                    value: Binding(
                        get: { Double(profile.sensitivity) },
                        set: { profile.sensitivity = Int($0.rounded()) }
                    ),
                    in: 1...5,
                    step: 1
                )
                .tint(Theme.moss)

                Toggle(
                    "Avoid fragrance and essential oils",
                    isOn: Binding(
                        get: { profile.avoidsFragrance },
                        set: { isEnabled in
                            profile.avoidsFragrance = isEnabled
                            if isEnabled {
                                profile.knownIrritants.insert(.fragrance)
                            } else {
                                profile.knownIrritants.remove(.fragrance)
                                profile.knownIrritants.remove(.essentialOils)
                            }
                        }
                    )
                )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.moss)

                Picker(
                    "Retinoids",
                    selection: Binding(
                        get: { profile.retinoidSafetyContext },
                        set: { context in
                            profile.retinoidSafetyContext = context
                            profile.avoidsRetinoids = context.shouldAvoidRetinoids
                        }
                    )
                ) {
                    ForEach(RetinoidSafetyContext.allCases) { context in
                        Text(context.title).tag(context)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.moss)

                Text("Choose avoid if pregnant, nursing, trying to conceive, or simply not ready for retinoid actives.")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ingredient flags")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.muted)

                    FlowLayout(spacing: 8) {
                        ForEach(KnownIrritant.allCases) { irritant in
                            ProfileChoiceChip(
                                title: irritant.title,
                                symbolName: profile.knownIrritants.contains(irritant) ? "checkmark" : "plus",
                                isSelected: profile.knownIrritants.contains(irritant),
                                action: { toggle(irritant) }
                            )
                        }
                    }
                }
            }
            .softCard(padding: 14)
        }
    }

    private var budget: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Budget", subtitle: "Recommendations should respect what you actually want to spend.")

            Picker("Budget", selection: $profile.budget) {
                ForEach(BudgetTier.allCases) { tier in
                    Text(tier.title).tag(tier)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Camera scans are for cosmetic visible-skin guidance, not diagnosis.", systemImage: "camera.viewfinder")
            Label("Face ID can lock your journal; it is not used to analyze skin.", systemImage: "faceid")
            Label("Ingredient flags and safety context make recommendations more conservative.", systemImage: "shield.checkered")
            Label("A production cloud analyzer should delete raw images by default unless you opt into history.", systemImage: "trash")
        }
        .font(.subheadline)
        .foregroundStyle(Theme.ink)
        .softCard(padding: 14)
    }

    private func toggle(_ irritant: KnownIrritant) {
        if profile.knownIrritants.contains(irritant) {
            profile.knownIrritants.remove(irritant)
            if irritant == .fragrance || irritant == .essentialOils {
                profile.avoidsFragrance = profile.knownIrritants.contains(.fragrance)
                    || profile.knownIrritants.contains(.essentialOils)
            }
        } else {
            profile.knownIrritants.insert(irritant)
            if irritant == .fragrance || irritant == .essentialOils {
                profile.avoidsFragrance = true
            }
        }
    }
}

private struct ProfileChoiceChip: View {
    var title: String
    var symbolName: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Theme.moss)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.moss : Theme.moss.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct GoalToggle: View {
    var concern: SkinConcern
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: concern.symbolName)
                    .foregroundStyle(isSelected ? .white : Theme.concernColor(concern))
                    .frame(width: 28)

                Text(concern.shortTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? .white : Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()
            }
            .padding(12)
            .frame(minHeight: 52)
            .background(isSelected ? Theme.concernColor(concern) : Theme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Theme.softShadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
