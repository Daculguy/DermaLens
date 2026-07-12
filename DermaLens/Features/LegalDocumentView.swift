import SwiftUI

enum LegalDocument: String, CaseIterable, Identifiable {
    case privacyPolicy
    case termsOfUse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy: "Privacy Policy"
        case .termsOfUse: "Terms of Use"
        }
    }

    var subtitle: String {
        switch self {
        case .privacyPolicy: "How DermaLens handles scan, routine, purchase, and account data."
        case .termsOfUse: "Subscription, cosmetic guidance, and acceptable-use terms."
        }
    }

    var updatedLabel: String {
        "Draft updated June 12, 2026"
    }

    var sections: [LegalSection] {
        switch self {
        case .privacyPolicy:
            return [
                LegalSection(
                    title: "What this build stores",
                    body: "DermaLens stores profile choices, generated scan reports, routine state, shelf statuses, reminder preferences, progress journal entries, and optional remote-analysis consent on this device. Raw camera frames, saved face photos, Face ID templates, and payment details are not stored by this prototype."
                ),
                LegalSection(
                    title: "Camera and Face ID boundaries",
                    body: "Guided scan frames are used to create cosmetic skin reports. Face ID or device passcode can protect private reports and journal notes, but DermaLens does not receive or store enrolled biometric templates."
                ),
                LegalSection(
                    title: "Remote analysis",
                    body: "If a production remote analyzer is configured, scan-frame upload requires explicit opt-in before frames leave the device. The consent screen identifies the destination host and asks that production uploads use short retention."
                ),
                LegalSection(
                    title: "Purchases",
                    body: "Subscription purchases are processed by the App Store. DermaLens reads entitlement status from StoreKit and does not receive full payment card details."
                ),
                LegalSection(
                    title: "Your controls",
                    body: "You can export a structured copy of local app data from Privacy Center. You can also delete local DermaLens data on this device, including reports, journal notes, routine history, reminder settings, and lock preferences."
                ),
                LegalSection(
                    title: "Before release",
                    body: "This in-app policy text must be reviewed by counsel and hosted at the App Store Connect privacy policy URL before public submission."
                )
            ]
        case .termsOfUse:
            return [
                LegalSection(
                    title: "Cosmetic guidance only",
                    body: "DermaLens provides cosmetic skincare guidance and routine organization. It does not diagnose, treat, cure, prevent disease, or replace advice from a licensed clinician."
                ),
                LegalSection(
                    title: "When to seek care",
                    body: "See a clinician promptly for painful, changing, bleeding, suspicious, infected, rapidly worsening, or urgent skin concerns. Do not delay care because of an app result."
                ),
                LegalSection(
                    title: "Subscriptions",
                    body: "Premium subscriptions unlock deeper ingredient reasoning, saved report history, progress comparisons, and product alternatives. Subscriptions renew automatically unless canceled in your Apple account settings before renewal."
                ),
                LegalSection(
                    title: "Product recommendations",
                    body: "Recommendations depend on scan quality, user-entered preferences, product catalog data, ingredient-list coverage, and disclosed commercial relationships. Verify labels and patch test when appropriate."
                ),
                LegalSection(
                    title: "User responsibility",
                    body: "Use the app only for personal skincare planning. Do not use it for emergency care, diagnosis, prescriptions, or decisions about suspicious lesions."
                ),
                LegalSection(
                    title: "Before release",
                    body: "These draft terms should be replaced or approved by counsel before App Store submission. If no custom EULA is configured in App Store Connect, Apple's standard EULA may also apply."
                )
            ]
        }
    }
}

struct LegalSection: Identifiable, Hashable {
    var title: String
    var body: String
    var id: String { title }
}

struct LegalDocumentLinks: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(LegalDocument.allCases) { document in
                NavigationLink {
                    LegalDocumentView(document: document)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: document == .privacyPolicy ? "hand.raised" : "doc.text")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Theme.moss)
                            .frame(width: 30, height: 30)
                            .background(Theme.moss.opacity(0.11))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(document.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.ink)
                            Text(document.subtitle)
                                .font(.caption)
                                .foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("LegalLink.\(document.rawValue)")
            }
        }
        .softCard(padding: 14)
    }
}

struct LegalDocumentView: View {
    var document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text(document.updatedLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                    Text(document.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .softCard(padding: 16)

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(section.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Theme.ink)
                        Text(section.body)
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .softCard(padding: 14)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .appBackground()
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(document: .privacyPolicy)
    }
}
