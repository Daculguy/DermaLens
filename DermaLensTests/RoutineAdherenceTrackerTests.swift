import XCTest
@testable import DermaLens

final class RoutineAdherenceTrackerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testDayKeyUsesInjectedCalendar() throws {
        let date = try XCTUnwrap(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 6,
            day: 12,
            hour: 23,
            minute: 30
        ).date)

        XCTAssertEqual(RoutineAdherenceTracker().dayKey(for: date, calendar: calendar), "2026-06-12")
    }

    func testToggleSameStepAddsThenRemovesOneCompletion() throws {
        let plan = singleStepPlan()
        let step = try XCTUnwrap(plan.steps.first)
        let date = try date(year: 2026, month: 6, day: 12)
        let tracker = RoutineAdherenceTracker()

        let completed = tracker.records(
            afterToggling: step,
            in: plan,
            records: [],
            on: date,
            calendar: calendar
        )
        XCTAssertEqual(completed.count, 1)
        XCTAssertTrue(tracker.isStepCompleted(step, in: plan, records: completed, on: date, calendar: calendar))

        let removed = tracker.records(
            afterToggling: step,
            in: plan,
            records: completed,
            on: date,
            calendar: calendar
        )
        XCTAssertTrue(removed.isEmpty)
    }

    func testTodayCompletionDoesNotCountTomorrow() throws {
        let plan = singleStepPlan()
        let step = try XCTUnwrap(plan.steps.first)
        let today = try date(year: 2026, month: 6, day: 12)
        let tomorrow = try date(year: 2026, month: 6, day: 13)
        let tracker = RoutineAdherenceTracker()
        let records = tracker.records(
            afterToggling: step,
            in: plan,
            records: [],
            on: today,
            calendar: calendar
        )

        let todaySummary = tracker.summary(for: plan, records: records, on: today, calendar: calendar)
        let tomorrowSummary = tracker.summary(for: plan, records: records, on: tomorrow, calendar: calendar)

        XCTAssertEqual(todaySummary.completedSteps, 1)
        XCTAssertEqual(tomorrowSummary.completedSteps, 0)
    }

    func testCompletionSurvivesRoutineRegenerationWhenStepKeyMatches() throws {
        let plan = singleStepPlan()
        let step = try XCTUnwrap(plan.steps.first)
        let date = try date(year: 2026, month: 6, day: 12)
        let tracker = RoutineAdherenceTracker()
        let records = tracker.records(
            afterToggling: step,
            in: plan,
            records: [],
            on: date,
            calendar: calendar
        )

        var regeneratedPlan = plan
        regeneratedPlan.id = UUID()
        regeneratedPlan.generatedAt = try date(year: 2026, month: 6, day: 13)
        regeneratedPlan.steps = regeneratedPlan.steps.map { original in
            var regenerated = original
            regenerated.id = UUID()
            return regenerated
        }

        let summary = tracker.summary(for: regeneratedPlan, records: records, on: date, calendar: calendar)

        XCTAssertEqual(summary.completedSteps, 1)
        XCTAssertTrue(tracker.isStepCompleted(regeneratedPlan.steps[0], in: regeneratedPlan, records: records, on: date, calendar: calendar))
    }

    func testCompletionSurvivesRationaleOnlyChanges() throws {
        let plan = singleStepPlan()
        let step = try XCTUnwrap(plan.steps.first)
        let date = try date(year: 2026, month: 6, day: 12)
        let tracker = RoutineAdherenceTracker()
        let records = tracker.records(
            afterToggling: step,
            in: plan,
            records: [],
            on: date,
            calendar: calendar
        )

        var changedPlan = plan
        changedPlan.steps[0].fitScore = 999
        changedPlan.steps[0].selectionReasons = ["Different explanation"]

        XCTAssertTrue(tracker.isStepCompleted(changedPlan.steps[0], in: changedPlan, records: records, on: date, calendar: calendar))
    }

    func testChangedProductDoesNotInheritOldCompletion() throws {
        let plan = singleStepPlan(product: SampleData.products[0])
        let date = try date(year: 2026, month: 6, day: 12)
        let tracker = RoutineAdherenceTracker()
        let records = tracker.records(
            afterToggling: try XCTUnwrap(plan.steps.first),
            in: plan,
            records: [],
            on: date,
            calendar: calendar
        )

        let changedPlan = singleStepPlan(product: SampleData.products[1])
        let summary = tracker.summary(for: changedPlan, records: records, on: date, calendar: calendar)

        XCTAssertEqual(summary.completedSteps, 0)
    }

    func testMorningAndEveningStepsAreIndependent() throws {
        let product = SampleData.products[0]
        let plan = RoutinePlan(
            generatedAt: try date(year: 2026, month: 6, day: 12),
            focus: [.barrier],
            steps: [
                RoutineStep(moment: .morning, order: 1, category: product.category, product: product, instruction: "Use", caution: nil),
                RoutineStep(moment: .evening, order: 1, category: product.category, product: product, instruction: "Use", caution: nil)
            ],
            weeklyNotes: []
        )
        let date = try date(year: 2026, month: 6, day: 12)
        let tracker = RoutineAdherenceTracker()
        let records = tracker.records(
            afterToggling: plan.steps[0],
            in: plan,
            records: [],
            on: date,
            calendar: calendar
        )

        XCTAssertTrue(tracker.isStepCompleted(plan.steps[0], in: plan, records: records, on: date, calendar: calendar))
        XCTAssertFalse(tracker.isStepCompleted(plan.steps[1], in: plan, records: records, on: date, calendar: calendar))
    }

    func testStreakCountsContiguousCompleteDays() throws {
        let plan = singleStepPlan()
        let step = try XCTUnwrap(plan.steps.first)
        let tracker = RoutineAdherenceTracker()
        let today = try date(year: 2026, month: 6, day: 12)
        let yesterday = try date(year: 2026, month: 6, day: 11)
        let twoDaysAgo = try date(year: 2026, month: 6, day: 10)

        var records: [RoutineCompletionRecord] = []
        records = tracker.records(afterToggling: step, in: plan, records: records, on: today, calendar: calendar)
        records = tracker.records(afterToggling: step, in: plan, records: records, on: yesterday, calendar: calendar)
        records = tracker.records(afterToggling: step, in: plan, records: records, on: twoDaysAgo, calendar: calendar)

        let summary = tracker.summary(for: plan, records: records, on: today, calendar: calendar)

        XCTAssertEqual(summary.streakDays, 3)
    }

    func testPrunesOldCompletionRecords() throws {
        let plan = singleStepPlan()
        let step = try XCTUnwrap(plan.steps.first)
        let tracker = RoutineAdherenceTracker()
        let today = try date(year: 2026, month: 6, day: 12)
        let oldDay = try date(year: 2026, month: 6, day: 1)

        var records: [RoutineCompletionRecord] = []
        records = tracker.records(afterToggling: step, in: plan, records: records, on: today, calendar: calendar)
        records = tracker.records(afterToggling: step, in: plan, records: records, on: oldDay, calendar: calendar)

        let pruned = tracker.pruned(records: records, keepingDays: 7, from: today, calendar: calendar)

        XCTAssertEqual(pruned.count, 1)
        XCTAssertEqual(pruned.first?.dayKey, "2026-06-12")
    }

    private func singleStepPlan(product: SkincareProduct = SampleData.products[0]) -> RoutinePlan {
        RoutinePlan(
            generatedAt: Date(timeIntervalSince1970: 0),
            focus: [.barrier],
            steps: [
                RoutineStep(
                    moment: .morning,
                    order: 1,
                    category: product.category,
                    product: product,
                    instruction: "Use",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try XCTUnwrap(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: 12
        ).date)
    }
}
