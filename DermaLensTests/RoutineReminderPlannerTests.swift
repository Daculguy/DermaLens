import XCTest
@testable import DermaLens

final class RoutineReminderPlannerTests: XCTestCase {
    func testBuildsMorningAndEveningSlotsForRoutine() {
        let planner = RoutineReminderPlanner()

        let slots = planner.slots(for: SampleData.previewRoutine)

        XCTAssertEqual(slots.map(\.moment), [.morning, .evening])
        XCTAssertEqual(slots.first?.hour, 8)
        XCTAssertEqual(slots.first?.minute, 0)
        XCTAssertEqual(slots.last?.hour, 21)
        XCTAssertEqual(slots.last?.minute, 0)
        XCTAssertEqual(slots.first?.notificationIdentifier, "dermalens.routine.reminder.morning")
        XCTAssertEqual(slots.last?.notificationIdentifier, "dermalens.routine.reminder.evening")
    }

    func testUsesCustomReminderPreferences() {
        let planner = RoutineReminderPlanner(preferences: RoutineReminderPreferences(
            morning: RoutineReminderTime(hour: 7, minute: 15),
            evening: RoutineReminderTime(hour: 22, minute: 30)
        ))

        let slots = planner.slots(for: SampleData.previewRoutine)

        XCTAssertEqual(slots.first?.hour, 7)
        XCTAssertEqual(slots.first?.minute, 15)
        XCTAssertEqual(slots.last?.hour, 22)
        XCTAssertEqual(slots.last?.minute, 30)
    }

    func testReminderTimeClampsAndFormatsDisplayText() {
        let time = RoutineReminderTime(hour: 27, minute: -4)

        XCTAssertEqual(time.hour, 23)
        XCTAssertEqual(time.minute, 0)
        XCTAssertEqual(time.clockText, "23:00")
        XCTAssertEqual(time.displayText, "11:00 PM")
    }

    func testSkipsMomentsWithoutSteps() {
        let product = SampleData.products.first { $0.category == .cleanser }!
        let plan = RoutinePlan(
            generatedAt: Date(),
            focus: [.barrier],
            steps: [
                RoutineStep(
                    moment: .evening,
                    order: 1,
                    category: .cleanser,
                    product: product,
                    instruction: "Cleanse gently.",
                    caution: nil
                )
            ],
            weeklyNotes: []
        )

        let slots = RoutineReminderPlanner().slots(for: plan)

        XCTAssertEqual(slots.map(\.moment), [.evening])
    }

    func testNotificationBodiesAvoidDiagnosticLanguage() {
        let slots = RoutineReminderPlanner().slots(for: SampleData.previewRoutine)
        let combinedBody = slots.map(\.body).joined(separator: " ").lowercased()

        XCTAssertFalse(combinedBody.contains("acne"))
        XCTAssertFalse(combinedBody.contains("redness"))
        XCTAssertFalse(combinedBody.contains("problem"))
        XCTAssertFalse(combinedBody.contains("score"))
        XCTAssertFalse(combinedBody.contains("treat"))
    }

    func testAllIdentifiersAreStable() {
        let identifiers = RoutineReminderPlanner().allIdentifiers()

        XCTAssertEqual(identifiers, [
            "dermalens.routine.reminder.morning",
            "dermalens.routine.reminder.evening"
        ])
    }
}
