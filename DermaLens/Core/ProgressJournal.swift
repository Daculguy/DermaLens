import Foundation

enum JournalSkinFeel: String, CaseIterable, Codable, Identifiable, Hashable {
    case calm
    case dry
    case oily
    case tight
    case irritated
    case breakoutProne

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: "Calm"
        case .dry: "Dry"
        case .oily: "Oily"
        case .tight: "Tight"
        case .irritated: "Irritated"
        case .breakoutProne: "Breakout-prone"
        }
    }

    var symbolName: String {
        switch self {
        case .calm: "leaf"
        case .dry: "drop.triangle"
        case .oily: "drop.fill"
        case .tight: "arrow.left.and.right"
        case .irritated: "exclamationmark.triangle"
        case .breakoutProne: "circle.grid.cross"
        }
    }
}

enum JournalContextTag: String, CaseIterable, Codable, Identifiable, Hashable {
    case stress
    case poorSleep
    case cycle
    case weather
    case travel
    case newProduct
    case sunscreen
    case makeup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stress: "Stress"
        case .poorSleep: "Poor sleep"
        case .cycle: "Cycle"
        case .weather: "Weather"
        case .travel: "Travel"
        case .newProduct: "New product"
        case .sunscreen: "SPF"
        case .makeup: "Makeup"
        }
    }

    var symbolName: String {
        switch self {
        case .stress: "bolt"
        case .poorSleep: "moon.zzz"
        case .cycle: "calendar"
        case .weather: "cloud.sun"
        case .travel: "airplane"
        case .newProduct: "sparkles"
        case .sunscreen: "sun.max"
        case .makeup: "paintbrush"
        }
    }
}

struct ProgressJournalEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var createdAt: Date
    var dayID: String
    var reportID: UUID?
    var reportCreatedAt: Date?
    var reportTopConcerns: [SkinConcern]
    var routinePlanID: UUID?
    var comfortRating: Int?
    var skinFeel: JournalSkinFeel
    var tags: Set<JournalContextTag>
    var note: String
}

struct ProgressJournalSummary: Hashable {
    var totalEntries: Int
    var entriesInLast14Days: Int
    var latestEntry: ProgressJournalEntry?
    var mostCommonFeel: JournalSkinFeel?

    var recentLabel: String {
        "\(entriesInLast14Days) in 14 days"
    }
}

enum ProgressDeltaDirection: Hashable {
    case lessVisible
    case stable
    case moreVisible

    var title: String {
        switch self {
        case .lessVisible: "Less visible"
        case .stable: "Stable"
        case .moreVisible: "More visible"
        }
    }
}

struct ProgressConcernDelta: Identifiable, Hashable {
    var concern: SkinConcern
    var currentScore: Int
    var previousScore: Int

    var id: SkinConcern { concern }

    var delta: Int {
        currentScore - previousScore
    }

    var absoluteDelta: Int {
        abs(delta)
    }

    var direction: ProgressDeltaDirection {
        if absoluteDelta < 4 { return .stable }
        return delta < 0 ? .lessVisible : .moreVisible
    }

    var deltaLabel: String {
        switch direction {
        case .lessVisible:
            "Down \(absoluteDelta)"
        case .moreVisible:
            "Up \(absoluteDelta)"
        case .stable:
            "Stable"
        }
    }
}

struct ProgressComparison: Hashable {
    var currentReport: SkinReport
    var previousReport: SkinReport
    var daysBetweenReports: Int
    var deltas: [ProgressConcernDelta]
    var summary: String
}

struct ProgressComparisonEngine {
    func latestComparison(
        in reports: [SkinReport],
        calendar: Calendar = .current
    ) -> ProgressComparison? {
        let sortedReports = reports.sorted { lhs, rhs in
            lhs.createdAt > rhs.createdAt
        }
        guard sortedReports.count >= 2 else { return nil }

        return comparison(
            current: sortedReports[0],
            previous: sortedReports[1],
            calendar: calendar
        )
    }

    func comparison(
        current: SkinReport,
        previous: SkinReport,
        calendar: Calendar = .current
    ) -> ProgressComparison {
        let deltas = concernDeltas(current: current, previous: previous)
        return ProgressComparison(
            currentReport: current,
            previousReport: previous,
            daysBetweenReports: daysBetween(previous.createdAt, current.createdAt, calendar: calendar),
            deltas: deltas,
            summary: summary(for: deltas)
        )
    }

    private func concernDeltas(current: SkinReport, previous: SkinReport) -> [ProgressConcernDelta] {
        let currentScores = Dictionary(uniqueKeysWithValues: current.scores.map { ($0.concern, $0.score) })
        let previousScores = Dictionary(uniqueKeysWithValues: previous.scores.map { ($0.concern, $0.score) })
        let concerns = Set(currentScores.keys).union(previousScores.keys)

        return concerns
            .map { concern in
                ProgressConcernDelta(
                    concern: concern,
                    currentScore: currentScores[concern] ?? 0,
                    previousScore: previousScores[concern] ?? 0
                )
            }
            .sorted { lhs, rhs in
                if lhs.absoluteDelta == rhs.absoluteDelta {
                    return lhs.concern.title < rhs.concern.title
                }
                return lhs.absoluteDelta > rhs.absoluteDelta
            }
    }

    private func daysBetween(_ previous: Date, _ current: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: previous)
        let end = calendar.startOfDay(for: current)
        return max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
    }

    private func summary(for deltas: [ProgressConcernDelta]) -> String {
        if let improvement = deltas.first(where: { $0.direction == .lessVisible }) {
            return "\(improvement.concern.shortTitle) looks less visible by \(improvement.absoluteDelta) points versus the prior scan."
        }

        if let increase = deltas.first(where: { $0.direction == .moreVisible }) {
            return "\(increase.concern.shortTitle) looks more visible by \(increase.absoluteDelta) points; compare lighting, routine changes, and journal context."
        }

        return "Scores are broadly stable across the last two comparable scans."
    }
}

struct ProgressJournal {
    let maxNoteLength = 280
    let maxStoredEntries = 80

    func dayID(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    func makeEntry(
        report: SkinReport?,
        routinePlanID: UUID?,
        skinFeel: JournalSkinFeel,
        tags: Set<JournalContextTag>,
        note: String,
        comfortRating: Int?,
        calendar: Calendar = .current,
        date: Date = Date()
    ) -> ProgressJournalEntry {
        ProgressJournalEntry(
            createdAt: date,
            dayID: dayID(for: date, calendar: calendar),
            reportID: report?.id,
            reportCreatedAt: report?.createdAt,
            reportTopConcerns: report?.topConcerns.map(\.concern) ?? [],
            routinePlanID: routinePlanID,
            comfortRating: comfortRating.map { min(max($0, 1), 5) },
            skinFeel: skinFeel,
            tags: tags,
            note: sanitized(note)
        )
    }

    func sanitized(_ note: String) -> String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxNoteLength else { return trimmed }
        return String(trimmed.prefix(maxNoteLength))
    }

    func sorted(_ entries: [ProgressJournalEntry]) -> [ProgressJournalEntry] {
        entries.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.createdAt == rhs.element.createdAt {
                    return lhs.offset < rhs.offset
                }
                return lhs.element.createdAt > rhs.element.createdAt
            }
            .map(\.element)
    }

    func capped(_ entries: [ProgressJournalEntry]) -> [ProgressJournalEntry] {
        Array(sorted(entries).prefix(maxStoredEntries))
    }

    func entries(for reportID: UUID, in entries: [ProgressJournalEntry]) -> [ProgressJournalEntry] {
        sorted(entries.filter { $0.reportID == reportID })
    }

    func latestEntryForToday(
        in entries: [ProgressJournalEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ProgressJournalEntry? {
        let today = dayID(for: now, calendar: calendar)
        return sorted(entries.filter { $0.createdAt <= now }).first { $0.dayID == today }
    }

    func entries(afterDeleting id: UUID, from entries: [ProgressJournalEntry]) -> [ProgressJournalEntry] {
        entries.filter { $0.id != id }
    }

    func summary(
        for entries: [ProgressJournalEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ProgressJournalSummary {
        let cutoff = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: now)) ?? now
        let summaryEntries = sorted(entries.filter { $0.createdAt <= now })
        let recentEntries = summaryEntries.filter { $0.createdAt >= cutoff }
        let feelCounts = Dictionary(grouping: recentEntries, by: \.skinFeel)
            .mapValues(\.count)
        let mostCommonFeel = feelCounts.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.title > rhs.key.title
            }
            return lhs.value < rhs.value
        }?.key

        return ProgressJournalSummary(
            totalEntries: entries.count,
            entriesInLast14Days: recentEntries.count,
            latestEntry: summaryEntries.first,
            mostCommonFeel: mostCommonFeel
        )
    }
}
