import Foundation

struct RoutineStepKey: Codable, Hashable {
    var moment: RoutineMoment
    var order: Int
    var category: ProductCategory
    var productID: String

    init(step: RoutineStep) {
        self.moment = step.moment
        self.order = step.order
        self.category = step.category
        self.productID = step.product.id
    }

    var storageID: String {
        "\(moment.rawValue).\(order).\(category.rawValue).\(productID)"
    }
}

struct RoutineCompletionRecord: Codable, Identifiable, Hashable {
    var id: String { "\(dayKey).\(stepKey.storageID)" }
    var dayKey: String
    var routinePlanID: UUID
    var routineGeneratedAt: Date
    var stepKey: RoutineStepKey
    var moment: RoutineMoment
    var completedAt: Date
}

struct RoutineAdherenceSummary: Hashable {
    var completedSteps: Int
    var totalSteps: Int
    var streakDays: Int

    var completionRatio: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(completedSteps) / Double(totalSteps)
    }

    var isComplete: Bool {
        totalSteps > 0 && completedSteps >= totalSteps
    }

    var progressLabel: String {
        "\(completedSteps)/\(totalSteps)"
    }

    var streakLabel: String {
        switch streakDays {
        case 0:
            "No full-day streak yet"
        case 1:
            "1 full day"
        default:
            "\(streakDays) full days"
        }
    }
}

struct RoutineAdherenceTracker {
    func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    func isStepCompleted(
        _ step: RoutineStep,
        in plan: RoutinePlan,
        records: [RoutineCompletionRecord],
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        let key = dayKey(for: date, calendar: calendar)
        let stepKey = RoutineStepKey(step: step)
        guard plan.steps.contains(where: { RoutineStepKey(step: $0) == stepKey }) else {
            return false
        }

        return records.contains {
            $0.dayKey == key && $0.stepKey == stepKey
        }
    }

    func records(
        afterToggling step: RoutineStep,
        in plan: RoutinePlan,
        records: [RoutineCompletionRecord],
        on date: Date,
        calendar: Calendar = .current
    ) -> [RoutineCompletionRecord] {
        let key = dayKey(for: date, calendar: calendar)
        let stepKey = RoutineStepKey(step: step)
        guard plan.steps.contains(where: { RoutineStepKey(step: $0) == stepKey }) else {
            return records
        }

        if isStepCompleted(step, in: plan, records: records, on: date, calendar: calendar) {
            return records.filter {
                !($0.dayKey == key && $0.stepKey == stepKey)
            }
        }

        var nextRecords = records
        nextRecords.append(RoutineCompletionRecord(
            dayKey: key,
            routinePlanID: plan.id,
            routineGeneratedAt: plan.generatedAt,
            stepKey: stepKey,
            moment: step.moment,
            completedAt: date
        ))
        return nextRecords
    }

    func summary(
        for plan: RoutinePlan,
        records: [RoutineCompletionRecord],
        on date: Date,
        calendar: Calendar = .current
    ) -> RoutineAdherenceSummary {
        let totalSteps = plan.steps.count
        let completedToday = completedStepIDs(
            for: plan,
            records: records,
            dayKey: dayKey(for: date, calendar: calendar)
        ).count

        return RoutineAdherenceSummary(
            completedSteps: completedToday,
            totalSteps: totalSteps,
            streakDays: streakDays(for: plan, records: records, endingOn: date, calendar: calendar)
        )
    }

    func pruned(
        records: [RoutineCompletionRecord],
        keepingDays maxDays: Int,
        from date: Date,
        calendar: Calendar = .current
    ) -> [RoutineCompletionRecord] {
        guard maxDays > 0,
              let cutoff = calendar.date(byAdding: .day, value: -(maxDays - 1), to: calendar.startOfDay(for: date)) else {
            return []
        }

        return records.filter { record in
            guard let recordDate = date(from: record.dayKey, calendar: calendar) else {
                return false
            }
            return recordDate >= cutoff
        }
    }

    private func streakDays(
        for plan: RoutinePlan,
        records: [RoutineCompletionRecord],
        endingOn date: Date,
        calendar: Calendar
    ) -> Int {
        guard !plan.steps.isEmpty else { return 0 }

        let totalSteps = plan.steps.count
        var streak = 0
        var cursor = calendar.startOfDay(for: date)

        while true {
            let key = dayKey(for: cursor, calendar: calendar)
            let completedCount = completedStepIDs(for: plan, records: records, dayKey: key).count
            guard completedCount >= totalSteps else { break }

            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }

    private func completedStepIDs(
        for plan: RoutinePlan,
        records: [RoutineCompletionRecord],
        dayKey: String
    ) -> Set<UUID> {
        var stepKeyPairs: [RoutineStepKey: UUID] = [:]
        for step in plan.steps {
            stepKeyPairs[RoutineStepKey(step: step)] = step.id
        }

        return Set(records.compactMap { record in
            guard record.dayKey == dayKey else { return nil }
            return stepKeyPairs[record.stepKey]
        })
    }

    private func date(from dayKey: String, calendar: Calendar) -> Date? {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }

        return calendar.date(from: DateComponents(
            year: parts[0],
            month: parts[1],
            day: parts[2]
        ))
    }
}
