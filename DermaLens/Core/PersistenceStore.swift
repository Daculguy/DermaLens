import Foundation

struct RoutineSwapOverride: Codable, Identifiable, Hashable {
    var moment: RoutineMoment
    var order: Int
    var category: ProductCategory
    var productID: String
    var replacedProductID: String
    var updatedAt: Date

    var id: String { slotID }

    var slotID: String {
        "\(moment.rawValue).\(order).\(category.rawValue)"
    }

    init(
        moment: RoutineMoment,
        order: Int,
        category: ProductCategory,
        productID: String,
        replacedProductID: String,
        updatedAt: Date = Date()
    ) {
        self.moment = moment
        self.order = order
        self.category = category
        self.productID = productID
        self.replacedProductID = replacedProductID
        self.updatedAt = updatedAt
    }

    init(step: RoutineStep, product: SkincareProduct, updatedAt: Date = Date()) {
        self.init(
            moment: step.moment,
            order: step.order,
            category: step.category,
            productID: product.id,
            replacedProductID: step.product.id,
            updatedAt: updatedAt
        )
    }
}

struct RemoteAnalysisConsentRecord: Codable, Hashable {
    static let currentCopyVersion = "remote-analysis-consent-v1"

    var host: String
    var copyVersion: String
    var grantedAt: Date

    init(
        host: String,
        copyVersion: String = Self.currentCopyVersion,
        grantedAt: Date = Date()
    ) {
        self.host = host
        self.copyVersion = copyVersion
        self.grantedAt = grantedAt
    }
}

struct PersistedAppSnapshot: Codable {
    var userProfile: UserProfile
    var reports: [SkinReport]
    var hasCompletedOnboarding: Bool
    var routinePlan: RoutinePlan?
    var routineRemindersEnabled: Bool
    var routineReminderPreferences: RoutineReminderPreferences
    var routineCompletionRecords: [RoutineCompletionRecord]
    var routineSwapOverrides: [RoutineSwapOverride]
    var productShelfState: ProductShelfState
    var customProducts: [SkincareProduct]
    var progressJournalEntries: [ProgressJournalEntry]
    var remoteAnalysisConsent: RemoteAnalysisConsentRecord?

    static let empty = PersistedAppSnapshot(
        userProfile: .default,
        reports: [],
        hasCompletedOnboarding: false,
        routinePlan: nil,
        routineRemindersEnabled: false,
        routineReminderPreferences: .default,
        routineCompletionRecords: [],
        routineSwapOverrides: [],
        productShelfState: .empty,
        customProducts: [],
        progressJournalEntries: [],
        remoteAnalysisConsent: nil
    )

    init(
        userProfile: UserProfile,
        reports: [SkinReport],
        hasCompletedOnboarding: Bool,
        routinePlan: RoutinePlan?,
        routineRemindersEnabled: Bool = false,
        routineReminderPreferences: RoutineReminderPreferences = .default,
        routineCompletionRecords: [RoutineCompletionRecord] = [],
        routineSwapOverrides: [RoutineSwapOverride] = [],
        productShelfState: ProductShelfState = .empty,
        customProducts: [SkincareProduct] = [],
        progressJournalEntries: [ProgressJournalEntry] = [],
        remoteAnalysisConsent: RemoteAnalysisConsentRecord? = nil
    ) {
        self.userProfile = userProfile
        self.reports = reports
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.routinePlan = routinePlan
        self.routineRemindersEnabled = routineRemindersEnabled
        self.routineReminderPreferences = routineReminderPreferences
        self.routineCompletionRecords = routineCompletionRecords
        self.routineSwapOverrides = routineSwapOverrides
        self.productShelfState = productShelfState
        self.customProducts = customProducts
        self.progressJournalEntries = progressJournalEntries
        self.remoteAnalysisConsent = remoteAnalysisConsent
    }

    private enum CodingKeys: String, CodingKey {
        case userProfile
        case reports
        case hasCompletedOnboarding
        case routinePlan
        case routineRemindersEnabled
        case routineReminderPreferences
        case routineCompletionRecords
        case routineSwapOverrides
        case productShelfState
        case customProducts
        case progressJournalEntries
        case remoteAnalysisConsent
        case remoteAnalysisConsentGranted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userProfile = try container.decode(UserProfile.self, forKey: .userProfile)
        reports = try container.decode([SkinReport].self, forKey: .reports)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        routinePlan = try container.decodeIfPresent(RoutinePlan.self, forKey: .routinePlan)
        routineRemindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .routineRemindersEnabled) ?? false
        routineReminderPreferences = try container.decodeIfPresent(RoutineReminderPreferences.self, forKey: .routineReminderPreferences) ?? .default
        routineCompletionRecords = try container.decodeIfPresent([RoutineCompletionRecord].self, forKey: .routineCompletionRecords) ?? []
        routineSwapOverrides = try container.decodeIfPresent([RoutineSwapOverride].self, forKey: .routineSwapOverrides) ?? []
        productShelfState = try container.decodeIfPresent(ProductShelfState.self, forKey: .productShelfState) ?? .empty
        customProducts = try container.decodeIfPresent([SkincareProduct].self, forKey: .customProducts) ?? []
        progressJournalEntries = try container.decodeIfPresent([ProgressJournalEntry].self, forKey: .progressJournalEntries) ?? []
        remoteAnalysisConsent = try container.decodeIfPresent(RemoteAnalysisConsentRecord.self, forKey: .remoteAnalysisConsent)
    }
}

final class PersistenceStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let key = "dermalens.persisted.snapshot.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> PersistedAppSnapshot {
        guard let data = defaults.data(forKey: key) else {
            return .empty
        }

        do {
            return try decoder.decode(PersistedAppSnapshot.self, from: data)
        } catch {
            return .empty
        }
    }

    func save(_ snapshot: PersistedAppSnapshot) {
        do {
            let data = try encoder.encode(snapshot)
            defaults.set(data, forKey: key)
        } catch {
            assertionFailure("Failed to persist DermaLens snapshot: \(error.localizedDescription)")
        }
    }

    func deleteAll() {
        defaults.removeObject(forKey: key)
    }
}
