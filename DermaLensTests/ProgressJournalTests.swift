import XCTest
@testable import DermaLens

final class ProgressJournalTests: XCTestCase {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testSanitizesAndTrimsLongNotes() {
        let journal = ProgressJournal()
        let longNote = "  " + String(repeating: "a", count: 400) + "  "

        let entry = journal.makeEntry(
            report: nil,
            routinePlanID: nil,
            skinFeel: .dry,
            tags: [],
            note: longNote,
            comfortRating: nil,
            calendar: utcCalendar,
            date: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(entry.note.count, journal.maxNoteLength)
        XCTAssertFalse(entry.note.hasPrefix(" "))
        XCTAssertFalse(entry.note.hasSuffix(" "))
    }

    func testDayIDUsesInjectedCalendar() throws {
        let date = try XCTUnwrap(DateComponents(
            calendar: utcCalendar,
            timeZone: utcCalendar.timeZone,
            year: 2026,
            month: 6,
            day: 12,
            hour: 23,
            minute: 30
        ).date)
        var plusTwoCalendar = utcCalendar
        plusTwoCalendar.timeZone = TimeZone(secondsFromGMT: 7200)!

        let journal = ProgressJournal()

        XCTAssertEqual(journal.dayID(for: date, calendar: utcCalendar), "2026-06-12")
        XCTAssertEqual(journal.dayID(for: date, calendar: plusTwoCalendar), "2026-06-13")
    }

    func testEntryKeepsReportSnapshotContext() throws {
        let report = try fixtureReport(createdAt: Date(timeIntervalSince1970: 200))
        let routinePlanID = UUID()

        let entry = ProgressJournal().makeEntry(
            report: report,
            routinePlanID: routinePlanID,
            skinFeel: .calm,
            tags: [.newProduct, .poorSleep],
            note: "Changed moisturizer",
            comfortRating: 8,
            calendar: utcCalendar,
            date: Date(timeIntervalSince1970: 300)
        )

        XCTAssertEqual(entry.reportID, report.id)
        XCTAssertEqual(entry.reportCreatedAt, report.createdAt)
        XCTAssertEqual(entry.reportTopConcerns, report.topConcerns.map(\.concern))
        XCTAssertEqual(entry.routinePlanID, routinePlanID)
        XCTAssertEqual(entry.comfortRating, 5)
        XCTAssertEqual(entry.tags, [.newProduct, .poorSleep])
    }

    func testSortingAndReportFilteringUseNewestFirst() throws {
        let report = try fixtureReport(createdAt: Date(timeIntervalSince1970: 10))
        let older = ProgressJournalEntry(
            createdAt: Date(timeIntervalSince1970: 100),
            dayID: "1970-01-01",
            reportID: report.id,
            reportCreatedAt: report.createdAt,
            reportTopConcerns: [.redness],
            routinePlanID: nil,
            comfortRating: nil,
            skinFeel: .calm,
            tags: [],
            note: "Older"
        )
        let newest = ProgressJournalEntry(
            createdAt: Date(timeIntervalSince1970: 300),
            dayID: "1970-01-01",
            reportID: report.id,
            reportCreatedAt: report.createdAt,
            reportTopConcerns: [.texture],
            routinePlanID: nil,
            comfortRating: nil,
            skinFeel: .tight,
            tags: [],
            note: "Newest"
        )
        let unrelated = ProgressJournalEntry(
            createdAt: Date(timeIntervalSince1970: 400),
            dayID: "1970-01-01",
            reportID: UUID(),
            reportCreatedAt: nil,
            reportTopConcerns: [],
            routinePlanID: nil,
            comfortRating: nil,
            skinFeel: .oily,
            tags: [],
            note: "Other"
        )

        let linked = ProgressJournal().entries(for: report.id, in: [older, unrelated, newest])

        XCTAssertEqual(linked.map(\.note), ["Newest", "Older"])
    }

    func testSortPreservesInputOrderWhenTimestampsTie() {
        let timestamp = Date(timeIntervalSince1970: 200)
        let first = journalEntry(note: "First", createdAt: timestamp, dayID: "1970-01-01")
        let second = journalEntry(note: "Second", createdAt: timestamp, dayID: "1970-01-01")
        let newer = journalEntry(note: "Newer", createdAt: Date(timeIntervalSince1970: 300), dayID: "1970-01-01")

        let sorted = ProgressJournal().sorted([first, second, newer])

        XCTAssertEqual(sorted.map(\.note), ["Newer", "First", "Second"])
    }

    func testLatestEntryForTodayUsesDayID() {
        let journal = ProgressJournal()
        let yesterday = ProgressJournalEntry(
            createdAt: Date(timeIntervalSince1970: 300),
            dayID: "2026-06-11",
            reportID: nil,
            reportCreatedAt: nil,
            reportTopConcerns: [],
            routinePlanID: nil,
            comfortRating: nil,
            skinFeel: .calm,
            tags: [],
            note: "Yesterday"
        )
        let today = ProgressJournalEntry(
            createdAt: Date(timeIntervalSince1970: 100),
            dayID: "2026-06-12",
            reportID: nil,
            reportCreatedAt: nil,
            reportTopConcerns: [],
            routinePlanID: nil,
            comfortRating: nil,
            skinFeel: .dry,
            tags: [],
            note: "Today"
        )

        let result = journal.latestEntryForToday(
            in: [yesterday, today],
            now: date(year: 2026, month: 6, day: 12),
            calendar: utcCalendar
        )

        XCTAssertEqual(result?.note, "Today")
    }

    func testLatestEntryForTodayIgnoresFutureDatedEntries() {
        let journal = ProgressJournal()
        let now = date(year: 2026, month: 6, day: 12)
        let dayID = journal.dayID(for: now, calendar: utcCalendar)
        let current = journalEntry(
            note: "Current",
            createdAt: now.addingTimeInterval(-60),
            dayID: dayID
        )
        let future = journalEntry(
            note: "Future",
            createdAt: now.addingTimeInterval(60),
            dayID: dayID
        )

        let result = journal.latestEntryForToday(
            in: [future, current],
            now: now,
            calendar: utcCalendar
        )

        XCTAssertEqual(result?.note, "Current")
    }

    func testDanglingReportLinkKeepsSnapshotContext() throws {
        let report = try fixtureReport(createdAt: Date(timeIntervalSince1970: 1000))
        let entry = ProgressJournal().makeEntry(
            report: report,
            routinePlanID: nil,
            skinFeel: .irritated,
            tags: [],
            note: "Scan deleted later",
            comfortRating: 2,
            calendar: utcCalendar,
            date: Date(timeIntervalSince1970: 1100)
        )

        XCTAssertEqual(entry.reportID, report.id)
        XCTAssertEqual(entry.reportCreatedAt, report.createdAt)
        XCTAssertFalse(entry.reportTopConcerns.isEmpty)
    }

    func testSummaryIgnoresFutureDatedEntriesForRecentAndLatest() {
        let journal = ProgressJournal()
        let now = date(year: 2026, month: 6, day: 12)
        let current = journalEntry(
            note: "Current",
            createdAt: now,
            dayID: journal.dayID(for: now, calendar: utcCalendar)
        )
        let futureDate = date(year: 2026, month: 6, day: 14)
        let future = journalEntry(
            note: "Future",
            createdAt: futureDate,
            dayID: journal.dayID(for: futureDate, calendar: utcCalendar)
        )

        let summary = journal.summary(for: [future, current], now: now, calendar: utcCalendar)

        XCTAssertEqual(summary.totalEntries, 2)
        XCTAssertEqual(summary.entriesInLast14Days, 1)
        XCTAssertEqual(summary.latestEntry?.note, "Current")
    }

    func testProgressComparisonUsesNewestAndPreviousReports() {
        let older = comparisonReport(
            createdAt: date(year: 2026, month: 5, day: 1),
            scores: [(.redness, 88), (.texture, 67)]
        )
        let previous = comparisonReport(
            createdAt: date(year: 2026, month: 6, day: 1),
            scores: [(.redness, 80), (.texture, 52)]
        )
        let current = comparisonReport(
            createdAt: date(year: 2026, month: 6, day: 15),
            scores: [(.redness, 62), (.texture, 55)]
        )

        let comparison = ProgressComparisonEngine().latestComparison(
            in: [previous, older, current],
            calendar: utcCalendar
        )

        XCTAssertEqual(comparison?.currentReport.id, current.id)
        XCTAssertEqual(comparison?.previousReport.id, previous.id)
        XCTAssertEqual(comparison?.daysBetweenReports, 14)
        XCTAssertEqual(comparison?.deltas.first?.concern, .redness)
        XCTAssertEqual(comparison?.deltas.first?.delta, -18)
        XCTAssertEqual(comparison?.deltas.first?.direction, .lessVisible)
        XCTAssertTrue(comparison?.summary.localizedCaseInsensitiveContains("less visible") == true)
    }

    func testProgressComparisonMarksSmallChangesStable() {
        let previous = comparisonReport(
            createdAt: date(year: 2026, month: 6, day: 1),
            scores: [(.barrier, 50)]
        )
        let current = comparisonReport(
            createdAt: date(year: 2026, month: 6, day: 2),
            scores: [(.barrier, 53)]
        )

        let comparison = ProgressComparisonEngine().comparison(
            current: current,
            previous: previous,
            calendar: utcCalendar
        )

        XCTAssertEqual(comparison.deltas.first?.direction, .stable)
        XCTAssertEqual(comparison.deltas.first?.deltaLabel, "Stable")
        XCTAssertTrue(comparison.summary.localizedCaseInsensitiveContains("stable") == true)
    }

    @MainActor
    func testDeleteAllLocalDataClearsJournalEntries() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let appState = AppState(
            routineNotificationScheduler: JournalNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )
        appState.addProgressJournalEntry(
            skinFeel: .calm,
            tags: [.stress],
            note: "Private note",
            linkedReport: SampleData.previewReport,
            comfortRating: 4
        )

        appState.deleteAllLocalData()

        XCTAssertTrue(appState.progressJournalEntries.isEmpty)
    }

    @MainActor
    func testRestoredJournalEntriesAreCapped() {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let journal = ProgressJournal()
        let entries = (0..<90).map { offset in
            journalEntry(
                note: "Entry \(offset)",
                createdAt: Date(timeIntervalSince1970: TimeInterval(offset)),
                dayID: "1970-01-01"
            )
        }
        PersistenceStore(defaults: defaults).save(PersistedAppSnapshot(
            userProfile: .default,
            reports: [SampleData.previewReport],
            hasCompletedOnboarding: true,
            routinePlan: SampleData.previewRoutine,
            progressJournalEntries: entries
        ))

        let appState = AppState(
            routineNotificationScheduler: JournalNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults)
        )

        XCTAssertEqual(appState.progressJournalEntries.count, journal.maxStoredEntries)
        XCTAssertEqual(appState.progressJournalEntries.first?.note, "Entry 89")
    }

    private func fixtureReport(createdAt: Date) throws -> SkinReport {
        SkinReport(
            createdAt: createdAt,
            scanQuality: .preview,
            scores: [
                ConcernScore(
                    concern: .texture,
                    score: 88,
                    confidence: .high,
                    primaryRegion: .forehead,
                    explanation: "Fixture"
                ),
                ConcernScore(
                    concern: .redness,
                    score: 73,
                    confidence: .medium,
                    primaryRegion: .leftCheek,
                    explanation: "Fixture"
                ),
                ConcernScore(
                    concern: .barrier,
                    score: 64,
                    confidence: .medium,
                    primaryRegion: .rightCheek,
                    explanation: "Fixture"
                )
            ],
            visibleStrengths: [],
            summary: "Fixture"
        )
    }

    private func comparisonReport(createdAt: Date, scores: [(SkinConcern, Int)]) -> SkinReport {
        SkinReport(
            createdAt: createdAt,
            scanQuality: .preview,
            scores: scores.enumerated().map { offset, score in
                ConcernScore(
                    concern: score.0,
                    score: score.1,
                    confidence: .high,
                    primaryRegion: FaceRegion.allCases[offset % FaceRegion.allCases.count],
                    explanation: "Fixture"
                )
            },
            visibleStrengths: [],
            summary: "Fixture"
        )
    }

    private func journalEntry(note: String, createdAt: Date, dayID: String) -> ProgressJournalEntry {
        ProgressJournalEntry(
            createdAt: createdAt,
            dayID: dayID,
            reportID: nil,
            reportCreatedAt: nil,
            reportTopConcerns: [],
            routinePlanID: nil,
            comfortRating: nil,
            skinFeel: .calm,
            tags: [],
            note: note
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(
            calendar: utcCalendar,
            timeZone: utcCalendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: 12
        ).date!
    }
}

private struct JournalNoopRoutineNotificationScheduler: RoutineNotificationScheduling {
    func authorizationState() async -> RoutineReminderAuthorizationState {
        .granted
    }

    func scheduleReminders(
        for plan: RoutinePlan,
        preferences: RoutineReminderPreferences
    ) async throws -> [RoutineReminderSlot] {
        []
    }

    func cancelReminders() async {}
}
