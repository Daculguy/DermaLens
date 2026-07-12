import SwiftUI

struct PrivacyLockView: View {
    @EnvironmentObject private var privacyLock: PrivacyLockManager

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(Theme.moss)
                    .frame(width: 104, height: 104)
                    .background(Theme.moss.opacity(0.12))
                    .clipShape(Circle())

                VStack(spacing: 8) {
                    Text("Private skin journal locked")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)

                    Text("Use \(privacyLock.biometryLabel) or your device passcode to reopen reports and routines.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PrimaryButton(title: "Unlock DermaLens", symbolName: privacyLock.biometrySymbolName) {
                    Task { await privacyLock.unlock() }
                }

                if let error = privacyLock.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.amber)
                        .multilineTextAlignment(.center)
                }

                Text("\(privacyLock.biometryLabel) unlock only returns whether authentication succeeds. DermaLens never receives your enrolled biometric data.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: 420)
        }
    }
}

#Preview {
    PrivacyLockView()
        .environmentObject(PrivacyLockManager())
}
