import Combine
import Foundation
import LocalAuthentication

protocol DeviceAuthenticationServicing {
    var biometryLabel: String { get }
    var biometrySymbolName: String { get }

    func authenticate(reason: String) async throws -> Bool
}

struct DeviceAuthenticator: DeviceAuthenticationServicing {
    var biometryLabel: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "device passcode"
        }

        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "biometrics"
        }
    }

    var biometrySymbolName: String {
        switch biometryLabel {
        case "Face ID": return "faceid"
        case "Touch ID": return "touchid"
        default: return "lock.shield"
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }
}

@MainActor
final class PrivacyLockManager: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var isJournalLockEnabled = false
    @Published private(set) var lastError: String?

    private let defaults: UserDefaults
    private let authenticator: any DeviceAuthenticationServicing
    private let journalLockEnabledKey = "dermalens.privacyLock.journalLockEnabled.v1"

    init(
        defaults: UserDefaults = .standard,
        authenticator: any DeviceAuthenticationServicing = DeviceAuthenticator()
    ) {
        self.defaults = defaults
        self.authenticator = authenticator
        isJournalLockEnabled = defaults.bool(forKey: journalLockEnabledKey)
        isLocked = isJournalLockEnabled
    }

    var biometryLabel: String {
        authenticator.biometryLabel
    }

    var biometrySymbolName: String {
        authenticator.biometrySymbolName
    }

    func setJournalLockEnabled(_ isEnabled: Bool) {
        isJournalLockEnabled = isEnabled
        defaults.set(isEnabled, forKey: journalLockEnabledKey)
        lastError = nil

        if !isEnabled {
            isLocked = false
        }
    }

    func lock() {
        lastError = nil
        isLocked = true
    }

    func lockIfEnabled() {
        guard isJournalLockEnabled else { return }
        lock()
    }

    func unlock() async {
        let reason = "Unlock your private DermaLens skin journal."
        do {
            let success = try await authenticator.authenticate(reason: reason)
            isLocked = !success
            lastError = success ? nil : "Authentication failed."
        } catch {
            lastError = error.localizedDescription
        }
    }
}
