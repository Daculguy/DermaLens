import Foundation
import UserNotifications

enum RoutineReminderAuthorizationState: Hashable {
    case notDetermined
    case granted
    case denied
}

enum RoutineNotificationSchedulerError: Error, Equatable {
    case authorizationDenied
    case noRoutineSteps
}

protocol RoutineNotificationScheduling {
    func authorizationState() async -> RoutineReminderAuthorizationState
    func scheduleReminders(
        for plan: RoutinePlan,
        preferences: RoutineReminderPreferences
    ) async throws -> [RoutineReminderSlot]
    func cancelReminders() async
}

final class RoutineNotificationScheduler: RoutineNotificationScheduling {
    private let center: UNUserNotificationCenter
    private let planner: RoutineReminderPlanner

    init(
        center: UNUserNotificationCenter = .current(),
        planner: RoutineReminderPlanner = RoutineReminderPlanner()
    ) {
        self.center = center
        self.planner = planner
    }

    func authorizationState() async -> RoutineReminderAuthorizationState {
        let settings = await notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func scheduleReminders(
        for plan: RoutinePlan,
        preferences: RoutineReminderPreferences
    ) async throws -> [RoutineReminderSlot] {
        let slots = RoutineReminderPlanner(preferences: preferences).slots(for: plan)
        guard !slots.isEmpty else { throw RoutineNotificationSchedulerError.noRoutineSteps }

        let state = await authorizationState()
        if state == .denied {
            throw RoutineNotificationSchedulerError.authorizationDenied
        }

        if state == .notDetermined {
            let granted = try await requestAuthorization()
            guard granted else { throw RoutineNotificationSchedulerError.authorizationDenied }
        }

        await cancelReminders()
        for slot in slots {
            try await addRequest(for: slot)
        }
        return slots
    }

    func cancelReminders() async {
        center.removePendingNotificationRequests(withIdentifiers: planner.allIdentifiers())
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNNotificationSettings, Never>) in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func addRequest(for slot: RoutineReminderSlot) async throws {
        let content = UNMutableNotificationContent()
        content.title = slot.title
        content.body = slot.body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: slot.dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: slot.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
