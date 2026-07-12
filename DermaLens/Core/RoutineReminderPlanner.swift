import Foundation

struct RoutineReminderTime: Codable, Hashable {
    var hour: Int
    var minute: Int

    init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    var clockText: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var displayText: String {
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    func date(on referenceDate: Date = Date(), calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? referenceDate
    }
}

struct RoutineReminderPreferences: Codable, Hashable {
    var morning: RoutineReminderTime
    var evening: RoutineReminderTime

    static let `default` = RoutineReminderPreferences(
        morning: RoutineReminderTime(hour: 8, minute: 0),
        evening: RoutineReminderTime(hour: 21, minute: 0)
    )

    func time(for moment: RoutineMoment) -> RoutineReminderTime {
        switch moment {
        case .morning: morning
        case .evening: evening
        }
    }

    mutating func setTime(_ time: RoutineReminderTime, for moment: RoutineMoment) {
        switch moment {
        case .morning:
            morning = time
        case .evening:
            evening = time
        }
    }
}

struct RoutineReminderSlot: Identifiable, Hashable {
    var id: String { notificationIdentifier }
    var moment: RoutineMoment
    var hour: Int
    var minute: Int
    var title: String
    var body: String
    var stepCount: Int

    var notificationIdentifier: String {
        RoutineReminderPlanner.notificationIdentifier(for: moment)
    }

    var dateComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }
}

struct RoutineReminderPlanner {
    static let identifierPrefix = "dermalens.routine.reminder."

    var preferences: RoutineReminderPreferences = .default

    func slots(for plan: RoutinePlan) -> [RoutineReminderSlot] {
        RoutineMoment.allCases.compactMap { moment in
            let steps = plan.steps(for: moment)
            guard !steps.isEmpty else { return nil }

            let time = preferences.time(for: moment)
            return RoutineReminderSlot(
                moment: moment,
                hour: time.hour,
                minute: time.minute,
                title: title(for: moment),
                body: body(for: moment),
                stepCount: steps.count
            )
        }
    }

    func allIdentifiers() -> [String] {
        RoutineMoment.allCases.map(Self.notificationIdentifier(for:))
    }

    static func notificationIdentifier(for moment: RoutineMoment) -> String {
        "\(identifierPrefix)\(moment.rawValue)"
    }

    private func title(for moment: RoutineMoment) -> String {
        switch moment {
        case .morning:
            "Morning routine"
        case .evening:
            "Evening routine"
        }
    }

    private func body(for moment: RoutineMoment) -> String {
        switch moment {
        case .morning:
            "Your DermaLens steps are ready. Open the app to keep the plan consistent."
        case .evening:
            "Your DermaLens wind-down steps are ready. Keep changes slow and steady."
        }
    }
}
