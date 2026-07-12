import Foundation

enum SkinConcern: String, CaseIterable, Codable, Identifiable, Hashable {
    case blemishes
    case redness
    case darkSpots
    case texture
    case pores
    case underEye
    case barrier

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blemishes: "Breakouts"
        case .redness: "Redness"
        case .darkSpots: "Dark spots"
        case .texture: "Texture"
        case .pores: "Visible pores"
        case .underEye: "Under-eye tone"
        case .barrier: "Barrier stress"
        }
    }

    var shortTitle: String {
        switch self {
        case .blemishes: "Acne"
        case .redness: "Redness"
        case .darkSpots: "Spots"
        case .texture: "Texture"
        case .pores: "Pores"
        case .underEye: "Eyes"
        case .barrier: "Barrier"
        }
    }

    var symbolName: String {
        switch self {
        case .blemishes: "circle.grid.cross"
        case .redness: "flame"
        case .darkSpots: "sparkle.magnifyingglass"
        case .texture: "waveform.path.ecg.rectangle"
        case .pores: "circle.hexagongrid"
        case .underEye: "eye"
        case .barrier: "shield.lefthalf.filled"
        }
    }
}

enum ConfidenceLevel: String, CaseIterable, Codable, Hashable {
    case high
    case medium
    case low

    static func fromQualityAverage(_ average: Double) -> ConfidenceLevel {
        if average >= 0.84 { return .high }
        if average >= 0.68 { return .medium }
        return .low
    }

    var label: String {
        switch self {
        case .high: "High confidence"
        case .medium: "Medium confidence"
        case .low: "Needs rescan"
        }
    }

    var value: Double {
        switch self {
        case .high: 0.92
        case .medium: 0.74
        case .low: 0.48
        }
    }

    var cappedAtMedium: ConfidenceLevel {
        self == .high ? .medium : self
    }
}

enum FaceRegion: String, CaseIterable, Codable, Identifiable, Hashable {
    case forehead
    case leftCheek
    case rightCheek
    case nose
    case chin
    case underEye

    var id: String { rawValue }

    var label: String {
        switch self {
        case .forehead: "Forehead"
        case .leftCheek: "Left cheek"
        case .rightCheek: "Right cheek"
        case .nose: "Nose"
        case .chin: "Chin"
        case .underEye: "Under-eye"
        }
    }
}

struct GuidedScanStep: Identifiable, Hashable {
    var region: FaceRegion
    var title: String
    var instruction: String
    var symbolName: String

    var id: FaceRegion { region }

    static let baselineSequence: [GuidedScanStep] = [
        GuidedScanStep(
            region: .forehead,
            title: "Forehead",
            instruction: "Hold steady with your forehead inside the top of the oval.",
            symbolName: "face.smiling"
        ),
        GuidedScanStep(
            region: .leftCheek,
            title: "Left cheek",
            instruction: "Turn a little right so your left cheek stays evenly lit.",
            symbolName: "arrow.left.circle"
        ),
        GuidedScanStep(
            region: .rightCheek,
            title: "Right cheek",
            instruction: "Turn a little left so your right cheek stays evenly lit.",
            symbolName: "arrow.right.circle"
        ),
        GuidedScanStep(
            region: .nose,
            title: "T-zone",
            instruction: "Face forward again so the nose and center face are sharp.",
            symbolName: "camera.metering.center.weighted"
        ),
        GuidedScanStep(
            region: .chin,
            title: "Chin",
            instruction: "Lower your chin slightly and keep the frame still.",
            symbolName: "arrow.down.circle"
        )
    ]
}

enum RoutineMoment: String, CaseIterable, Codable, Identifiable, Hashable {
    case morning
    case evening

    var id: String { rawValue }
    var title: String { self == .morning ? "Morning" : "Evening" }
    var symbolName: String { self == .morning ? "sun.max" : "moon.stars" }
}

enum ProductCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case cleanser
    case treatment
    case moisturizer
    case sunscreen
    case exfoliant
    case mask

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cleanser: "Cleanser"
        case .treatment: "Treatment"
        case .moisturizer: "Moisturizer"
        case .sunscreen: "SPF"
        case .exfoliant: "Exfoliant"
        case .mask: "Mask"
        }
    }

    var symbolName: String {
        switch self {
        case .cleanser: "drop"
        case .treatment: "cross.case"
        case .moisturizer: "humidity"
        case .sunscreen: "sun.max.trianglebadge.exclamationmark"
        case .exfoliant: "wand.and.stars"
        case .mask: "face.smiling"
        }
    }
}

enum BaselineSkinFeel: String, CaseIterable, Codable, Identifiable, Hashable {
    case balanced
    case dry
    case oily
    case tight
    case reactive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced: "Balanced"
        case .dry: "Dry"
        case .oily: "Oily"
        case .tight: "Tight"
        case .reactive: "Reactive"
        }
    }

    var symbolName: String {
        switch self {
        case .balanced: "circle.lefthalf.filled"
        case .dry: "drop.triangle"
        case .oily: "drop.fill"
        case .tight: "arrow.left.and.right"
        case .reactive: "exclamationmark.triangle"
        }
    }
}

enum RoutineComplexity: String, CaseIterable, Codable, Identifiable, Hashable {
    case minimal
    case steady
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minimal: "Minimal"
        case .steady: "Steady"
        case .advanced: "Advanced"
        }
    }

    var detail: String {
        switch self {
        case .minimal: "Keep actives low and skip optional extras."
        case .steady: "A balanced plan with cautious actives."
        case .advanced: "Comfortable with more detailed routines."
        }
    }
}

enum KnownIrritant: String, CaseIterable, Codable, Identifiable, Hashable {
    case fragrance
    case essentialOils
    case dryingAlcohol
    case exfoliatingAcids
    case benzoylPeroxide
    case strongVitaminC

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fragrance: "Fragrance"
        case .essentialOils: "Essential oils"
        case .dryingAlcohol: "Drying alcohol"
        case .exfoliatingAcids: "Acids"
        case .benzoylPeroxide: "Benzoyl peroxide"
        case .strongVitaminC: "Strong vitamin C"
        }
    }

    var tokens: [String] {
        switch self {
        case .fragrance: ["fragrance", "parfum"]
        case .essentialOils: ["essential oil", "lavender", "citrus"]
        case .dryingAlcohol: ["alcohol denat", "sd alcohol"]
        case .exfoliatingAcids: ["pha", "aha", "bha", "glycolic", "lactic", "salicylic"]
        case .benzoylPeroxide: ["benzoyl peroxide"]
        case .strongVitaminC: ["ascorbic", "vitamin c", "l-ascorbic"]
        }
    }
}

enum RetinoidSafetyContext: String, CaseIterable, Codable, Identifiable, Hashable {
    case comfortable
    case avoidPreference
    case pregnantNursingTrying
    case clinicianGuided

    var id: String { rawValue }

    var title: String {
        switch self {
        case .comfortable: "Comfortable"
        case .avoidPreference: "Avoid for now"
        case .pregnantNursingTrying: "Pregnant/nursing"
        case .clinicianGuided: "Clinician guided"
        }
    }

    var shouldAvoidRetinoids: Bool {
        switch self {
        case .avoidPreference, .pregnantNursingTrying:
            true
        case .comfortable, .clinicianGuided:
            false
        }
    }
}

struct UserProfile: Codable, Hashable {
    var skinType: String
    var baselineSkinFeel: BaselineSkinFeel
    var sensitivity: Int
    var routineComplexity: RoutineComplexity
    var budget: BudgetTier
    var avoidsFragrance: Bool
    var avoidsRetinoids: Bool
    var knownIrritants: Set<KnownIrritant>
    var retinoidSafetyContext: RetinoidSafetyContext
    var currentGoals: Set<SkinConcern>

    var shouldAvoidRetinoids: Bool {
        avoidsRetinoids || retinoidSafetyContext.shouldAvoidRetinoids
    }

    var prefersFragranceFree: Bool {
        avoidsFragrance
        || knownIrritants.contains(.fragrance)
        || knownIrritants.contains(.essentialOils)
    }

    static let `default` = UserProfile(
        skinType: "Combination",
        baselineSkinFeel: .balanced,
        sensitivity: 3,
        routineComplexity: .steady,
        budget: .balanced,
        avoidsFragrance: true,
        avoidsRetinoids: false,
        knownIrritants: [.fragrance],
        retinoidSafetyContext: .comfortable,
        currentGoals: [.blemishes, .redness, .texture]
    )

    init(
        skinType: String,
        baselineSkinFeel: BaselineSkinFeel = .balanced,
        sensitivity: Int,
        routineComplexity: RoutineComplexity = .steady,
        budget: BudgetTier,
        avoidsFragrance: Bool,
        avoidsRetinoids: Bool,
        knownIrritants: Set<KnownIrritant> = [],
        retinoidSafetyContext: RetinoidSafetyContext = .comfortable,
        currentGoals: Set<SkinConcern>
    ) {
        self.skinType = skinType
        self.baselineSkinFeel = baselineSkinFeel
        self.sensitivity = sensitivity
        self.routineComplexity = routineComplexity
        self.budget = budget
        self.avoidsFragrance = avoidsFragrance
        self.avoidsRetinoids = avoidsRetinoids
        self.knownIrritants = knownIrritants
        self.retinoidSafetyContext = retinoidSafetyContext
        self.currentGoals = currentGoals
    }

    private enum CodingKeys: String, CodingKey {
        case skinType
        case baselineSkinFeel
        case sensitivity
        case routineComplexity
        case budget
        case avoidsFragrance
        case avoidsRetinoids
        case knownIrritants
        case retinoidSafetyContext
        case currentGoals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        skinType = try container.decode(String.self, forKey: .skinType)
        baselineSkinFeel = try container.decodeIfPresent(BaselineSkinFeel.self, forKey: .baselineSkinFeel) ?? .balanced
        sensitivity = try container.decode(Int.self, forKey: .sensitivity)
        routineComplexity = try container.decodeIfPresent(RoutineComplexity.self, forKey: .routineComplexity) ?? .steady
        budget = try container.decode(BudgetTier.self, forKey: .budget)
        avoidsFragrance = try container.decode(Bool.self, forKey: .avoidsFragrance)
        avoidsRetinoids = try container.decode(Bool.self, forKey: .avoidsRetinoids)
        knownIrritants = try container.decodeIfPresent(Set<KnownIrritant>.self, forKey: .knownIrritants)
            ?? (avoidsFragrance ? [.fragrance] : [])
        retinoidSafetyContext = try container.decodeIfPresent(RetinoidSafetyContext.self, forKey: .retinoidSafetyContext)
            ?? (avoidsRetinoids ? .avoidPreference : .comfortable)
        currentGoals = try container.decode(Set<SkinConcern>.self, forKey: .currentGoals)
    }
}

enum BudgetTier: String, CaseIterable, Codable, Identifiable, Hashable {
    case value
    case balanced
    case premium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .value: "Value"
        case .balanced: "Balanced"
        case .premium: "Premium"
        }
    }
}

struct ScanQuality: Codable, Hashable {
    var lighting: Double
    var alignment: Double
    var stability: Double
    var clarity: Double
    var depthGuidanceAvailable: Bool

    var average: Double {
        (lighting + alignment + stability + clarity) / 4
    }

    var blockingIssues: [ScanQualityIssue] {
        var issues: [ScanQualityIssue] = []
        if lighting < 0.62 {
            issues.append(.lighting)
        }
        if alignment < 0.58 {
            issues.append(.alignment)
        }
        if stability < 0.58 {
            issues.append(.stability)
        }
        if clarity < 0.54 {
            issues.append(.clarity)
        }
        return issues
    }

    var isUsableForAnalysis: Bool {
        blockingIssues.isEmpty && average >= 0.64
    }

    var confidenceLevel: ConfidenceLevel {
        ConfidenceLevel.fromQualityAverage(average)
    }

    static let preview = ScanQuality(
        lighting: 0.88,
        alignment: 0.92,
        stability: 0.86,
        clarity: 0.9,
        depthGuidanceAvailable: true
    )
}

enum ScanQualityIssue: String, CaseIterable, Identifiable, Hashable {
    case lighting
    case alignment
    case stability
    case clarity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lighting: "Improve lighting"
        case .alignment: "Center your face"
        case .stability: "Hold still"
        case .clarity: "Clean the frame"
        }
    }

    var guidance: String {
        switch self {
        case .lighting: "Move toward soft front light and avoid strong backlight."
        case .alignment: "Keep your full face inside the oval."
        case .stability: "Rest your elbows or hold the phone closer to eye level."
        case .clarity: "Wipe the lens and remove glasses or heavy glare."
        }
    }

    var symbolName: String {
        switch self {
        case .lighting: "sun.max"
        case .alignment: "face.smiling"
        case .stability: "gyroscope"
        case .clarity: "camera.aperture"
        }
    }
}

enum ScanFrameVerificationStatus: String, Codable, Hashable {
    case unverified
    case freshGuidedCapture
    case staleGuidedCapture
    case lowQualityGuidedCapture
    case regionVerified

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "guidedRegionFresh":
            self = .freshGuidedCapture
        case "staleGuidedRegion":
            self = .staleGuidedCapture
        case "lowQualityGuidedRegion":
            self = .lowQualityGuidedCapture
        default:
            self = ScanFrameVerificationStatus(rawValue: rawValue) ?? .unverified
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var isFreshGuidedCapture: Bool {
        switch self {
        case .freshGuidedCapture, .regionVerified:
            true
        case .unverified, .staleGuidedCapture, .lowQualityGuidedCapture:
            false
        }
    }

    var isRegionVerified: Bool {
        self == .regionVerified
    }
}

struct ScanFrame: Identifiable, Hashable {
    var id = UUID()
    var capturedAt: Date
    var jpegData: Data
    var regionHint: FaceRegion?
    var qualitySnapshot: ScanQuality? = nil
    var sourceFrameID: Int? = nil
    var verificationStatus: ScanFrameVerificationStatus = .unverified

    var freshGuidedRegion: FaceRegion? {
        verificationStatus.isFreshGuidedCapture ? regionHint : nil
    }

    var verifiedRegion: FaceRegion? {
        verificationStatus.isRegionVerified ? regionHint : nil
    }
}

struct ScanCapture: Identifiable, Hashable {
    var id = UUID()
    var createdAt: Date
    var quality: ScanQuality
    var frames: [ScanFrame]
    var deviceModel: String

    var hasImageEvidence: Bool {
        !frames.isEmpty
    }

    var coveredRegions: [FaceRegion] {
        evidenceSummary.coveredRegions
    }

    var baselineCoverageScore: Double {
        evidenceSummary.coverageScore
    }

    var evidenceSummary: ScanEvidenceSummary {
        ScanEvidenceSummary(capture: self)
    }
}

struct ScanRegionEvidence: Codable, Identifiable, Hashable {
    var region: FaceRegion
    var frameCount: Int
    var freshGuidedFrameCount: Int
    var verifiedFrameCount: Int
    var averageQuality: Double
    var confidence: ConfidenceLevel

    var id: FaceRegion { region }

    var isCaptured: Bool {
        frameCount > 0
    }

    var isFreshGuidedCapture: Bool {
        freshGuidedFrameCount > 0
    }

    var isVerified: Bool {
        verifiedFrameCount > 0
    }

    var qualityPercent: Int {
        Int(averageQuality * 100)
    }

    var statusLabel: String {
        if isVerified { return "\(qualityPercent)% region verified" }
        if isFreshGuidedCapture { return "\(qualityPercent)% guided capture" }
        return isCaptured ? "Hint only" : "Missing"
    }

    var verificationStatus: String {
        if isVerified { return "regionVerified" }
        if isFreshGuidedCapture { return "freshGuidedCapture" }
        return isCaptured ? "regionHintOnly" : "missing"
    }

    init(
        region: FaceRegion,
        frameCount: Int,
        freshGuidedFrameCount: Int = 0,
        verifiedFrameCount: Int = 0,
        averageQuality: Double,
        confidence: ConfidenceLevel
    ) {
        self.region = region
        let safeFrameCount = max(frameCount, 0)
        let safeFreshGuidedFrameCount = min(max(freshGuidedFrameCount, 0), safeFrameCount)
        self.frameCount = safeFrameCount
        self.freshGuidedFrameCount = safeFreshGuidedFrameCount
        self.verifiedFrameCount = min(max(verifiedFrameCount, 0), safeFreshGuidedFrameCount)
        self.averageQuality = min(max(averageQuality, 0), 1)
        self.confidence = confidence
    }

    private enum CodingKeys: String, CodingKey {
        case region
        case frameCount
        case freshGuidedFrameCount
        case verifiedFrameCount
        case averageQuality
        case confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedRegion = try container.decode(FaceRegion.self, forKey: .region)
        let decodedFrameCount = try container.decode(Int.self, forKey: .frameCount)
        let legacyVerifiedFrameCount = try container.decodeIfPresent(Int.self, forKey: .verifiedFrameCount)
        let decodedFreshGuidedFrameCount = try container.decodeIfPresent(Int.self, forKey: .freshGuidedFrameCount)
        let decodedAverageQuality = try container.decode(Double.self, forKey: .averageQuality)
        let decodedConfidence = try container.decode(ConfidenceLevel.self, forKey: .confidence)

        self.init(
            region: decodedRegion,
            frameCount: decodedFrameCount,
            freshGuidedFrameCount: decodedFreshGuidedFrameCount ?? legacyVerifiedFrameCount ?? decodedFrameCount,
            verifiedFrameCount: decodedFreshGuidedFrameCount == nil ? 0 : (legacyVerifiedFrameCount ?? 0),
            averageQuality: decodedAverageQuality,
            confidence: decodedConfidence
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(region, forKey: .region)
        try container.encode(frameCount, forKey: .frameCount)
        try container.encode(freshGuidedFrameCount, forKey: .freshGuidedFrameCount)
        try container.encode(verifiedFrameCount, forKey: .verifiedFrameCount)
        try container.encode(averageQuality, forKey: .averageQuality)
        try container.encode(confidence, forKey: .confidence)
    }
}

struct ScanEvidenceSummary: Codable, Hashable {
    var capturedFrameCount: Int
    var coveredRegions: [FaceRegion]
    var requiredRegions: [FaceRegion]
    var coverageScore: Double
    var createdFromImageEvidence: Bool
    var regionEvidence: [ScanRegionEvidence]

    var isComplete: Bool {
        createdFromImageEvidence && coverageScore >= 1
    }

    var coverageLabel: String {
        "\(coveredRegions.count)/\(requiredRegions.count) guided captures"
    }

    static let empty = ScanEvidenceSummary(
        capturedFrameCount: 0,
        coveredRegions: [],
        requiredRegions: GuidedScanStep.baselineSequence.map(\.region),
        coverageScore: 0,
        createdFromImageEvidence: false,
        regionEvidence: makeRegionEvidence(
            coveredRegions: [],
            requiredRegions: GuidedScanStep.baselineSequence.map(\.region),
            defaultQuality: 0,
            createdFromImageEvidence: false
        )
    )

    static let previewComplete = ScanEvidenceSummary(
        capturedFrameCount: GuidedScanStep.baselineSequence.count,
        coveredRegions: GuidedScanStep.baselineSequence.map(\.region),
        requiredRegions: GuidedScanStep.baselineSequence.map(\.region),
        coverageScore: 1,
        createdFromImageEvidence: true,
        regionEvidence: makeRegionEvidence(
            coveredRegions: GuidedScanStep.baselineSequence.map(\.region),
            requiredRegions: GuidedScanStep.baselineSequence.map(\.region),
            defaultQuality: ScanQuality.preview.average,
            createdFromImageEvidence: true
        )
    )

    init(
        capturedFrameCount: Int,
        coveredRegions: [FaceRegion],
        requiredRegions: [FaceRegion],
        coverageScore: Double,
        createdFromImageEvidence: Bool,
        regionEvidence: [ScanRegionEvidence]? = nil
    ) {
        self.capturedFrameCount = capturedFrameCount
        self.coveredRegions = coveredRegions
        self.requiredRegions = requiredRegions
        self.coverageScore = min(max(coverageScore, 0), 1)
        self.createdFromImageEvidence = createdFromImageEvidence
        self.regionEvidence = regionEvidence ?? Self.makeRegionEvidence(
            coveredRegions: coveredRegions,
            requiredRegions: requiredRegions,
            defaultQuality: createdFromImageEvidence ? 0.7 : 0,
            createdFromImageEvidence: createdFromImageEvidence
        )
    }

    init(capture: ScanCapture) {
        let requiredRegions = GuidedScanStep.baselineSequence.map(\.region)
        let acceptedGuidedCaptureFrameIDs = Self.acceptedGuidedCaptureFrameIDs(
            from: capture.frames,
            requiredRegions: requiredRegions
        )
        let captured = Set(capture.frames.compactMap { frame in
            acceptedGuidedCaptureFrameIDs.contains(frame.id) ? frame.regionHint : nil
        })
        let coveredRegions = requiredRegions.filter { captured.contains($0) }
        let coverageScore = requiredRegions.isEmpty
            ? 0
            : Double(coveredRegions.count) / Double(requiredRegions.count)

        self.init(
            capturedFrameCount: capture.frames.count,
            coveredRegions: coveredRegions,
            requiredRegions: requiredRegions,
            coverageScore: coverageScore,
            createdFromImageEvidence: capture.hasImageEvidence,
            regionEvidence: Self.regionEvidence(
                from: capture.frames,
                requiredRegions: requiredRegions,
                fallbackQuality: capture.quality,
                acceptedGuidedCaptureFrameIDs: acceptedGuidedCaptureFrameIDs
            )
        )
    }

    private enum CodingKeys: String, CodingKey {
        case capturedFrameCount
        case coveredRegions
        case requiredRegions
        case coverageScore
        case createdFromImageEvidence
        case regionEvidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        capturedFrameCount = try container.decode(Int.self, forKey: .capturedFrameCount)
        coveredRegions = try container.decode([FaceRegion].self, forKey: .coveredRegions)
        requiredRegions = try container.decode([FaceRegion].self, forKey: .requiredRegions)
        coverageScore = min(max(try container.decode(Double.self, forKey: .coverageScore), 0), 1)
        createdFromImageEvidence = try container.decode(Bool.self, forKey: .createdFromImageEvidence)
        regionEvidence = try container.decodeIfPresent([ScanRegionEvidence].self, forKey: .regionEvidence)
            ?? Self.makeRegionEvidence(
                coveredRegions: coveredRegions,
                requiredRegions: requiredRegions,
                defaultQuality: createdFromImageEvidence ? 0.7 : 0,
                createdFromImageEvidence: createdFromImageEvidence
            )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(capturedFrameCount, forKey: .capturedFrameCount)
        try container.encode(coveredRegions, forKey: .coveredRegions)
        try container.encode(requiredRegions, forKey: .requiredRegions)
        try container.encode(coverageScore, forKey: .coverageScore)
        try container.encode(createdFromImageEvidence, forKey: .createdFromImageEvidence)
        try container.encode(regionEvidence, forKey: .regionEvidence)
    }

    func confidenceLevel(for quality: ScanQuality) -> ConfidenceLevel {
        guard createdFromImageEvidence else { return .low }
        if coverageScore >= 1 {
            return hasCompleteRegionVerification ? quality.confidenceLevel : quality.confidenceLevel.cappedAtMedium
        }
        if coverageScore >= 0.45, quality.confidenceLevel == .high { return .medium }
        return .low
    }

    private var hasCompleteRegionVerification: Bool {
        !requiredRegions.isEmpty && requiredRegions.allSatisfy { requiredRegion in
            regionEvidence.first { $0.region == requiredRegion }?.isVerified == true
        }
    }

    private static func acceptedGuidedCaptureFrameIDs(
        from frames: [ScanFrame],
        requiredRegions: [FaceRegion]
    ) -> Set<UUID> {
        var usedSourceFrameIDs = Set<Int>()
        var acceptedFrameIDs = Set<UUID>()

        for region in requiredRegions {
            for frame in frames where frame.regionHint == region && frame.verificationStatus.isFreshGuidedCapture {
                if let sourceFrameID = frame.sourceFrameID {
                    guard usedSourceFrameIDs.insert(sourceFrameID).inserted else { continue }
                }
                acceptedFrameIDs.insert(frame.id)
            }
        }

        return acceptedFrameIDs
    }

    private static func regionEvidence(
        from frames: [ScanFrame],
        requiredRegions: [FaceRegion],
        fallbackQuality: ScanQuality,
        acceptedGuidedCaptureFrameIDs: Set<UUID>
    ) -> [ScanRegionEvidence] {
        requiredRegions.map { region in
            let matchingFrames = frames.filter { $0.regionHint == region }
            let guidedCaptureFrames = matchingFrames.filter { acceptedGuidedCaptureFrameIDs.contains($0.id) }
            let verifiedFrames = guidedCaptureFrames.filter { $0.verificationStatus.isRegionVerified }
            guard !matchingFrames.isEmpty else {
                return ScanRegionEvidence(
                    region: region,
                    frameCount: 0,
                    verifiedFrameCount: 0,
                    averageQuality: 0,
                    confidence: .low
                )
            }

            let qualityFrames = guidedCaptureFrames.isEmpty ? matchingFrames : guidedCaptureFrames
            let averageQuality = qualityFrames
                .map { $0.qualitySnapshot?.average ?? fallbackQuality.average }
                .reduce(0, +) / Double(qualityFrames.count)

            return ScanRegionEvidence(
                region: region,
                frameCount: matchingFrames.count,
                freshGuidedFrameCount: guidedCaptureFrames.count,
                verifiedFrameCount: verifiedFrames.count,
                averageQuality: min(max(averageQuality, 0), 1),
                confidence: ConfidenceLevel.fromQualityAverage(averageQuality)
            )
        }
    }

    private static func makeRegionEvidence(
        coveredRegions: [FaceRegion],
        requiredRegions: [FaceRegion],
        defaultQuality: Double,
        createdFromImageEvidence: Bool
    ) -> [ScanRegionEvidence] {
        let covered = Set(coveredRegions)
        let clampedQuality = min(max(defaultQuality, 0), 1)
        return requiredRegions.map { region in
            let isCaptured = createdFromImageEvidence && covered.contains(region)
            return ScanRegionEvidence(
                region: region,
                frameCount: isCaptured ? 1 : 0,
                freshGuidedFrameCount: isCaptured ? 1 : 0,
                verifiedFrameCount: 0,
                averageQuality: isCaptured ? clampedQuality : 0,
                confidence: isCaptured ? ConfidenceLevel.fromQualityAverage(clampedQuality) : .low
            )
        }
    }
}

struct ConcernScore: Codable, Identifiable, Hashable {
    var id: SkinConcern { concern }
    var concern: SkinConcern
    var score: Int
    var confidence: ConfidenceLevel
    var primaryRegion: FaceRegion
    var explanation: String

    var severityLabel: String {
        switch score {
        case 0..<35: "Low"
        case 35..<68: "Moderate"
        default: "High"
        }
    }
}

enum AnalysisValidationStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case prototype
    case vendorProvided
    case unvalidatedRemote
    case internallyValidated
    case legacyUnknown

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = AnalysisValidationStatus(rawValue: rawValue) ?? .unvalidatedRemote
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var title: String {
        switch self {
        case .prototype: "Prototype"
        case .vendorProvided: "Vendor provided"
        case .unvalidatedRemote: "Unvalidated remote"
        case .internallyValidated: "Internally validated"
        case .legacyUnknown: "Unknown legacy"
        }
    }
}

struct AnalysisMetadata: Codable, Hashable {
    enum Kind: String, Codable, Hashable {
        case simulatedLocal
        case remote
        case remoteFallback
        case remoteConsentNotGranted
        case legacy
    }

    var providerName: String
    var kind: Kind
    var runsOnDevice: Bool
    var retainsImages: Bool
    var remoteUploadAttempted: Bool
    var usedFallback: Bool
    var fallbackReason: String?
    var modelVersion: String
    var requestID: String?
    var validationStatus: AnalysisValidationStatus

    var title: String {
        switch kind {
        case .simulatedLocal: "Simulated local analysis"
        case .remote: "Remote analysis"
        case .remoteFallback: "Local fallback analysis"
        case .remoteConsentNotGranted: "Local analysis - upload off"
        case .legacy: "Legacy local analysis"
        }
    }

    var isPrototypeOutput: Bool {
        switch kind {
        case .remote:
            validationStatus != .internallyValidated
        case .simulatedLocal, .remoteFallback, .remoteConsentNotGranted, .legacy:
            true
        }
    }

    var scoreSourceLabel: String {
        switch kind {
        case .simulatedLocal:
            "Rule-generated prototype scores"
        case .remote:
            validationStatus == .internallyValidated ? "Validated remote analyzer scores" : "Unvalidated remote analyzer scores"
        case .remoteFallback:
            "Rule-generated local fallback scores"
        case .remoteConsentNotGranted:
            "Rule-generated local scores; upload off"
        case .legacy:
            "Legacy rule-generated scores"
        }
    }

    var privacyLabel: String {
        if retainsImages {
            return "Provider may retain images"
        }
        if remoteUploadAttempted, usedFallback {
            return "Remote upload attempted; local fallback used"
        }
        if remoteUploadAttempted {
            return "Images sent for analysis, not retained"
        }
        return runsOnDevice ? "On-device, no image retention" : "Images sent for analysis, not retained"
    }

    static let simulatedLocal = AnalysisMetadata(
        providerName: "Simulated local analyzer",
        kind: .simulatedLocal,
        runsOnDevice: true,
        retainsImages: false,
        remoteUploadAttempted: false,
        usedFallback: false,
        fallbackReason: nil,
        modelVersion: "simulated-rules-v1",
        requestID: nil,
        validationStatus: .prototype
    )

    static let legacyLocal = AnalysisMetadata(
        providerName: "Legacy local analyzer",
        kind: .legacy,
        runsOnDevice: true,
        retainsImages: false,
        remoteUploadAttempted: false,
        usedFallback: false,
        fallbackReason: nil,
        modelVersion: "legacy-local",
        requestID: nil,
        validationStatus: .legacyUnknown
    )

    init(
        providerName: String,
        kind: Kind,
        runsOnDevice: Bool,
        retainsImages: Bool,
        remoteUploadAttempted: Bool = false,
        usedFallback: Bool,
        fallbackReason: String?,
        modelVersion: String = "unknown",
        requestID: String? = nil,
        validationStatus: AnalysisValidationStatus = .prototype
    ) {
        self.providerName = providerName
        self.kind = kind
        self.runsOnDevice = runsOnDevice
        self.retainsImages = retainsImages
        self.remoteUploadAttempted = remoteUploadAttempted
        self.usedFallback = usedFallback
        self.fallbackReason = fallbackReason
        self.modelVersion = modelVersion
        self.requestID = requestID
        self.validationStatus = validationStatus
    }

    private enum CodingKeys: String, CodingKey {
        case providerName
        case kind
        case runsOnDevice
        case retainsImages
        case remoteUploadAttempted
        case usedFallback
        case fallbackReason
        case modelVersion
        case requestID
        case validationStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        providerName = try container.decode(String.self, forKey: .providerName)
        kind = try container.decode(Kind.self, forKey: .kind)
        runsOnDevice = try container.decode(Bool.self, forKey: .runsOnDevice)
        retainsImages = try container.decode(Bool.self, forKey: .retainsImages)
        remoteUploadAttempted = try container.decodeIfPresent(Bool.self, forKey: .remoteUploadAttempted)
            ?? Self.defaultRemoteUploadAttempted(for: kind)
        usedFallback = try container.decode(Bool.self, forKey: .usedFallback)
        fallbackReason = try container.decodeIfPresent(String.self, forKey: .fallbackReason)
        modelVersion = try container.decodeIfPresent(String.self, forKey: .modelVersion)
            ?? Self.defaultModelVersion(for: kind)
        requestID = try container.decodeIfPresent(String.self, forKey: .requestID)
        validationStatus = try container.decodeIfPresent(AnalysisValidationStatus.self, forKey: .validationStatus)
            ?? Self.defaultValidationStatus(for: kind)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(providerName, forKey: .providerName)
        try container.encode(kind, forKey: .kind)
        try container.encode(runsOnDevice, forKey: .runsOnDevice)
        try container.encode(retainsImages, forKey: .retainsImages)
        try container.encode(remoteUploadAttempted, forKey: .remoteUploadAttempted)
        try container.encode(usedFallback, forKey: .usedFallback)
        try container.encodeIfPresent(fallbackReason, forKey: .fallbackReason)
        try container.encode(modelVersion, forKey: .modelVersion)
        try container.encodeIfPresent(requestID, forKey: .requestID)
        try container.encode(validationStatus, forKey: .validationStatus)
    }

    static func remote(
        endpointHost: String?,
        modelVersion: String? = nil,
        requestID: String? = nil,
        validationStatus: AnalysisValidationStatus = .unvalidatedRemote
    ) -> AnalysisMetadata {
        AnalysisMetadata(
            providerName: endpointHost ?? "Remote analyzer",
            kind: .remote,
            runsOnDevice: false,
            retainsImages: false,
            remoteUploadAttempted: true,
            usedFallback: false,
            fallbackReason: nil,
            modelVersion: modelVersion ?? "remote-unversioned",
            requestID: requestID,
            validationStatus: validationStatus
        )
    }

    static func remoteFallback(
        endpointHost: String?,
        reason: String,
        remoteUploadAttempted: Bool = true
    ) -> AnalysisMetadata {
        AnalysisMetadata(
            providerName: endpointHost.map { "\($0) fallback" } ?? "Remote analyzer fallback",
            kind: .remoteFallback,
            runsOnDevice: true,
            retainsImages: false,
            remoteUploadAttempted: remoteUploadAttempted,
            usedFallback: true,
            fallbackReason: reason,
            modelVersion: "local-fallback-rules-v1",
            requestID: nil,
            validationStatus: .prototype
        )
    }

    static func remoteConsentNotGranted(endpointHost: String?) -> AnalysisMetadata {
        AnalysisMetadata(
            providerName: endpointHost.map { "\($0) upload off" } ?? "Remote analyzer upload off",
            kind: .remoteConsentNotGranted,
            runsOnDevice: true,
            retainsImages: false,
            remoteUploadAttempted: false,
            usedFallback: true,
            fallbackReason: "Remote analysis is configured, but scan-frame upload consent is off.",
            modelVersion: "local-consent-gated-rules-v1",
            requestID: nil,
            validationStatus: .prototype
        )
    }

    private static func defaultModelVersion(for kind: Kind) -> String {
        switch kind {
        case .simulatedLocal: "simulated-rules-v1"
        case .remote: "remote-unversioned"
        case .remoteFallback: "local-fallback-rules-v1"
        case .remoteConsentNotGranted: "local-consent-gated-rules-v1"
        case .legacy: "legacy-local"
        }
    }

    private static func defaultValidationStatus(for kind: Kind) -> AnalysisValidationStatus {
        switch kind {
        case .simulatedLocal, .remoteFallback, .remoteConsentNotGranted: .prototype
        case .remote: .unvalidatedRemote
        case .legacy: .legacyUnknown
        }
    }

    private static func defaultRemoteUploadAttempted(for kind: Kind) -> Bool {
        switch kind {
        case .remote, .remoteFallback:
            true
        case .simulatedLocal, .remoteConsentNotGranted, .legacy:
            false
        }
    }
}

struct SkinReport: Codable, Identifiable, Hashable {
    var id = UUID()
    var createdAt: Date
    var scanQuality: ScanQuality
    var evidenceSummary: ScanEvidenceSummary
    var analysisMetadata: AnalysisMetadata
    var scores: [ConcernScore]
    var visibleStrengths: [String]
    var summary: String

    init(
        id: UUID = UUID(),
        createdAt: Date,
        scanQuality: ScanQuality,
        evidenceSummary: ScanEvidenceSummary = .empty,
        analysisMetadata: AnalysisMetadata = .simulatedLocal,
        scores: [ConcernScore],
        visibleStrengths: [String],
        summary: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.scanQuality = scanQuality
        self.evidenceSummary = evidenceSummary
        self.analysisMetadata = analysisMetadata
        self.scores = scores
        self.visibleStrengths = visibleStrengths
        self.summary = summary
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case scanQuality
        case evidenceSummary
        case analysisMetadata
        case scores
        case visibleStrengths
        case summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        scanQuality = try container.decode(ScanQuality.self, forKey: .scanQuality)
        evidenceSummary = try container.decodeIfPresent(ScanEvidenceSummary.self, forKey: .evidenceSummary) ?? .empty
        analysisMetadata = try container.decodeIfPresent(AnalysisMetadata.self, forKey: .analysisMetadata) ?? .legacyLocal
        scores = try container.decode([ConcernScore].self, forKey: .scores)
        visibleStrengths = try container.decode([String].self, forKey: .visibleStrengths)
        summary = try container.decode(String.self, forKey: .summary)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(scanQuality, forKey: .scanQuality)
        try container.encode(evidenceSummary, forKey: .evidenceSummary)
        try container.encode(analysisMetadata, forKey: .analysisMetadata)
        try container.encode(scores, forKey: .scores)
        try container.encode(visibleStrengths, forKey: .visibleStrengths)
        try container.encode(summary, forKey: .summary)
    }

    var priorityScores: [ConcernScore] {
        scores.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.concern.title < rhs.concern.title
            }
            return lhs.score > rhs.score
        }
    }

    var topConcerns: [ConcernScore] {
        Array(priorityScores.prefix(3))
    }
}

enum ProductCatalogSource: String, Codable, CaseIterable, Identifiable, Hashable {
    case curatedPrototype
    case userEntered
    case verifiedRetailer
    case clinicianCurated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .curatedPrototype: "Curated sample"
        case .userEntered: "User entered"
        case .verifiedRetailer: "Retailer verified"
        case .clinicianCurated: "Clinician curated"
        }
    }

    var symbolName: String {
        switch self {
        case .curatedPrototype: "list.bullet.clipboard"
        case .userEntered: "person.crop.square"
        case .verifiedRetailer: "checkmark.seal"
        case .clinicianCurated: "cross.case"
        }
    }
}

enum ProductEvidenceLevel: String, Codable, CaseIterable, Identifiable, Hashable {
    case labelBased
    case userProvided
    case thirdPartyVerified
    case clinicalReviewed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .labelBased: "Label-based"
        case .userProvided: "User-provided"
        case .thirdPartyVerified: "Verified data"
        case .clinicalReviewed: "Clinician reviewed"
        }
    }

    var symbolName: String {
        switch self {
        case .labelBased: "tag"
        case .userProvided: "square.and.pencil"
        case .thirdPartyVerified: "checkmark.seal"
        case .clinicalReviewed: "stethoscope"
        }
    }
}

enum ProductCommercialStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case undisclosed
    case independent
    case affiliate
    case brandPartner
    case ownedBrand

    var id: String { rawValue }

    var title: String {
        switch self {
        case .undisclosed: "Commercial status undisclosed"
        case .independent: "Independent"
        case .affiliate: "Affiliate"
        case .brandPartner: "Brand partner"
        case .ownedBrand: "Owned brand"
        }
    }

    var symbolName: String {
        switch self {
        case .undisclosed: "questionmark.shield"
        case .independent: "checkmark.shield"
        case .affiliate: "link"
        case .brandPartner: "building.2"
        case .ownedBrand: "shippingbox"
        }
    }
}

enum IngredientListCoverage: String, Codable, CaseIterable, Identifiable, Hashable {
    case heroOnly
    case userEnteredPartial
    case completeINCI
    case verifiedINCI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .heroOnly: "Key ingredients only"
        case .userEnteredPartial: "Partial ingredient list"
        case .completeINCI: "Complete INCI list"
        case .verifiedINCI: "Verified INCI list"
        }
    }

    var symbolName: String {
        switch self {
        case .heroOnly: "text.badge.checkmark"
        case .userEnteredPartial: "list.bullet.rectangle"
        case .completeINCI: "doc.text.magnifyingglass"
        case .verifiedINCI: "checkmark.seal"
        }
    }

    var supportsAbsenceClaims: Bool {
        switch self {
        case .completeINCI, .verifiedINCI:
            true
        case .heroOnly, .userEnteredPartial:
            false
        }
    }
}

enum ProductTrustGrade: String, Codable, CaseIterable, Identifiable, Hashable {
    case strong
    case clear
    case provisional
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strong: "Strong data"
        case .clear: "Clear disclosure"
        case .provisional: "Provisional data"
        case .review: "Review bias"
        }
    }

    var symbolName: String {
        switch self {
        case .strong: "checkmark.seal"
        case .clear: "checkmark.shield"
        case .provisional: "exclamationmark.triangle"
        case .review: "eye"
        }
    }
}

enum ProductRecommendationReadiness: String, Codable, CaseIterable, Identifiable, Hashable {
    case prototypeOnly
    case userReviewNeeded
    case metadataReviewNeeded
    case purchaseReady

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prototypeOnly: "Prototype only"
        case .userReviewNeeded: "User data"
        case .metadataReviewNeeded: "Needs review"
        case .purchaseReady: "Launch-ready data"
        }
    }

    var shortReason: String {
        switch self {
        case .prototypeOnly:
            "Prototype-only product data"
        case .userReviewNeeded:
            "User-entered data needs review"
        case .metadataReviewNeeded:
            "Product metadata needs launch review"
        case .purchaseReady:
            "Launch-ready product metadata"
        }
    }

    var detail: String {
        switch self {
        case .prototypeOnly:
            "This product is from the DermaLens sample catalog and should be verified before purchase guidance."
        case .userReviewNeeded:
            "This product depends on user-entered label data and should be checked before being treated as a recommendation."
        case .metadataReviewNeeded:
            "This product is missing at least one launch-readiness signal such as a source URL, reviewer, dated INCI check, complete ingredients, or commercial disclosure."
        case .purchaseReady:
            "This product has independent commercial status, verified evidence, complete or verified ingredients, and dated source and INCI checks."
        }
    }

    var symbolName: String {
        switch self {
        case .prototypeOnly: "list.bullet.clipboard"
        case .userReviewNeeded: "person.crop.square"
        case .metadataReviewNeeded: "exclamationmark.triangle"
        case .purchaseReady: "checkmark.seal"
        }
    }
}

struct ProductTrustSummary: Codable, Hashable {
    var grade: ProductTrustGrade
    var score: Int
    var strengths: [String]
    var limitations: [String]

    var headline: String {
        grade.title
    }

    var detail: String {
        if let limitation = limitations.first {
            return limitation
        }
        return strengths.first ?? "Product data is disclosed before ranking."
    }
}

struct ProductSourceMetadata: Codable, Hashable {
    var sourceLabel: String
    var sourceURL: URL?
    var sourceLastCheckedAt: Date?
    var inciVerifiedAt: Date?
    var reviewer: String?

    init(
        sourceLabel: String,
        sourceURL: URL? = nil,
        sourceLastCheckedAt: Date? = nil,
        inciVerifiedAt: Date? = nil,
        reviewer: String? = nil
    ) {
        self.sourceLabel = sourceLabel
        self.sourceURL = sourceURL
        self.sourceLastCheckedAt = sourceLastCheckedAt
        self.inciVerifiedAt = inciVerifiedAt
        self.reviewer = reviewer
    }

    static let missing = ProductSourceMetadata(sourceLabel: "Source not recorded")
    static let userEntered = ProductSourceMetadata(
        sourceLabel: "User-entered label",
        reviewer: "User"
    )
    static let prototypeCatalog = ProductSourceMetadata(
        sourceLabel: "DermaLens prototype catalog",
        sourceLastCheckedAt: Date(timeIntervalSince1970: 1_780_272_000),
        reviewer: "DermaLens product rules v0.1"
    )

    var hasRecordedSource: Bool {
        sourceLabel != Self.missing.sourceLabel
    }

    var hasDatedSourceReview: Bool {
        sourceLastCheckedAt != nil
    }

    var hasDatedIngredientVerification: Bool {
        inciVerifiedAt != nil
    }

    var sourceDisplay: String {
        hasRecordedSource ? sourceLabel : "Source not recorded"
    }

    var sourceReviewDisplay: String {
        guard let sourceLastCheckedAt else {
            return "Source check date not recorded"
        }
        return "Checked \(shortDate(sourceLastCheckedAt))"
    }

    var ingredientVerificationDisplay: String {
        guard let inciVerifiedAt else {
            return "INCI verification date not recorded"
        }
        return "INCI verified \(shortDate(inciVerifiedAt))"
    }

    var reviewerDisplay: String {
        reviewer ?? "Reviewer not recorded"
    }

    var sourceURLForExport: URL? {
        guard let sourceURL,
              var components = URLComponents(url: sourceURL, resolvingAgainstBaseURL: false) else {
            return sourceURL
        }

        components.query = nil
        components.fragment = nil
        return components.url
    }

    var accessibilitySummary: String {
        [
            sourceDisplay,
            sourceReviewDisplay,
            ingredientVerificationDisplay,
            reviewerDisplay
        ].joined(separator: ", ")
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct SkincareProduct: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var brand: String
    var category: ProductCategory
    var price: Int
    var budgetTier: BudgetTier
    var heroIngredients: [String]
    var fullIngredients: [String]
    var ingredientListCoverage: IngredientListCoverage
    var concernFit: Set<SkinConcern>
    var fragranceFree: Bool
    var sensitivityScore: Int
    var usageNote: String
    var whyItMatches: String
    var catalogSource: ProductCatalogSource
    var evidenceLevel: ProductEvidenceLevel
    var commercialStatus: ProductCommercialStatus
    var sourceMetadata: ProductSourceMetadata

    var disclosureSummary: String {
        "\(catalogSource.title) - \(evidenceLevel.title) - \(ingredientListCoverage.title) - \(commercialStatus.title) - \(recommendationReadiness.title) - \(sourceMetadata.accessibilitySummary)"
    }

    var trustSummary: ProductTrustSummary {
        var score = 0
        var strengths: [String] = []
        var limitations: [String] = []

        switch catalogSource {
        case .curatedPrototype:
            score += 1
            limitations.append("Prototype catalog entry; verify against current retailer data before launch.")
        case .userEntered:
            limitations.append("User-entered product data may be incomplete.")
        case .verifiedRetailer:
            score += 3
            strengths.append("Retailer data is verified.")
        case .clinicianCurated:
            score += 4
            strengths.append("Clinician-curated product entry.")
        }

        switch evidenceLevel {
        case .labelBased:
            score += 1
            limitations.append("Recommendation evidence is label-based.")
        case .userProvided:
            limitations.append("Evidence comes from user-provided label data.")
        case .thirdPartyVerified:
            score += 3
            strengths.append("Ingredient data is third-party verified.")
        case .clinicalReviewed:
            score += 4
            strengths.append("Reviewed by a clinical source.")
        }

        switch ingredientListCoverage {
        case .heroOnly:
            limitations.append("Only key ingredients are known; absence claims are limited.")
        case .userEnteredPartial:
            score += 1
            limitations.append("Ingredient list is partial; safety checks stay conservative.")
        case .completeINCI:
            score += 3
            strengths.append("Complete INCI list supports stronger ingredient checks.")
        case .verifiedINCI:
            score += 4
            strengths.append("Verified INCI list supports stronger ingredient checks.")
        }

        switch commercialStatus {
        case .undisclosed:
            limitations.insert("Commercial relationship is not disclosed; treat ranking as provisional.", at: 0)
        case .independent:
            score += 3
            strengths.append("No affiliate or brand relationship disclosed.")
        case .affiliate:
            limitations.insert("Affiliate relationship is disclosed and penalized in ranking.", at: 0)
        case .brandPartner:
            score -= 1
            limitations.insert("Brand partnership is disclosed and penalized in ranking.", at: 0)
        case .ownedBrand:
            score -= 2
            limitations.insert("Owned-brand relationship is disclosed and penalized in ranking.", at: 0)
        }

        if sourceMetadata.hasRecordedSource {
            score += 1
            strengths.append("Product source is recorded.")
        } else {
            limitations.append("Product source is not recorded.")
        }

        if sourceMetadata.hasDatedSourceReview {
            score += 1
            strengths.append("Source review date is recorded.")
        } else {
            limitations.append("Source review date is not recorded.")
        }

        if sourceMetadata.hasDatedIngredientVerification {
            score += 1
            strengths.append("INCI verification date is recorded.")
        } else if ingredientListCoverage == .completeINCI || ingredientListCoverage == .verifiedINCI {
            limitations.append("Ingredient verification date is not recorded.")
        }

        return ProductTrustSummary(
            grade: trustGrade(score: score, commercialStatus: commercialStatus),
            score: min(max(score, 0), 17),
            strengths: Array(strengths.prefix(5)),
            limitations: Array(limitations.prefix(5))
        )
    }

    var recommendationReadiness: ProductRecommendationReadiness {
        if catalogSource == .curatedPrototype {
            return .prototypeOnly
        }
        if catalogSource == .userEntered {
            return .userReviewNeeded
        }

        let hasVerifiedSource = (catalogSource == .verifiedRetailer || catalogSource == .clinicianCurated)
            && sourceMetadata.hasRecordedSource
            && sourceMetadata.hasDatedSourceReview
            && sourceMetadata.hasDatedIngredientVerification
            && sourceMetadata.sourceURL != nil
            && sourceMetadata.reviewer != nil
        let hasVerifiedEvidence = evidenceLevel == .thirdPartyVerified || evidenceLevel == .clinicalReviewed
        let hasUsableIngredientCoverage = ingredientListCoverage == .completeINCI || ingredientListCoverage == .verifiedINCI
        let hasIndependentCommercialDisclosure = commercialStatus == .independent

        if hasVerifiedSource && hasVerifiedEvidence && hasUsableIngredientCoverage && hasIndependentCommercialDisclosure {
            return .purchaseReady
        }

        return .metadataReviewNeeded
    }

    var ingredientSignalsForSafety: [String] {
        Array(Set(heroIngredients + fullIngredients)).sorted()
    }

    var ingredientSignalsForSearch: [String] {
        Array(Set(heroIngredients + fullIngredients)).sorted()
    }

    func hasIngredientSignal(matching tokens: [String]) -> Bool {
        ingredientSignalsForSafety.contains { ingredient in
            tokens.contains { token in
                ingredient.localizedCaseInsensitiveContains(token)
            }
        }
    }

    private func trustGrade(score: Int, commercialStatus: ProductCommercialStatus) -> ProductTrustGrade {
        if commercialStatus == .undisclosed
            || commercialStatus == .affiliate
            || commercialStatus == .brandPartner
            || commercialStatus == .ownedBrand {
            return .review
        }
        if score >= 11 { return .strong }
        if score >= 7 { return .clear }
        return .provisional
    }

    init(
        id: String,
        name: String,
        brand: String,
        category: ProductCategory,
        price: Int,
        budgetTier: BudgetTier,
        heroIngredients: [String],
        fullIngredients: [String] = [],
        ingredientListCoverage: IngredientListCoverage = .heroOnly,
        concernFit: Set<SkinConcern>,
        fragranceFree: Bool,
        sensitivityScore: Int,
        usageNote: String,
        whyItMatches: String,
        catalogSource: ProductCatalogSource = .curatedPrototype,
        evidenceLevel: ProductEvidenceLevel = .labelBased,
        commercialStatus: ProductCommercialStatus = .independent,
        sourceMetadata: ProductSourceMetadata = .missing
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.price = price
        self.budgetTier = budgetTier
        self.heroIngredients = heroIngredients
        self.fullIngredients = fullIngredients
        self.ingredientListCoverage = ingredientListCoverage
        self.concernFit = concernFit
        self.fragranceFree = fragranceFree
        self.sensitivityScore = sensitivityScore
        self.usageNote = usageNote
        self.whyItMatches = whyItMatches
        self.catalogSource = catalogSource
        self.evidenceLevel = evidenceLevel
        self.commercialStatus = commercialStatus
        self.sourceMetadata = sourceMetadata
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case category
        case price
        case budgetTier
        case heroIngredients
        case fullIngredients
        case ingredientListCoverage
        case concernFit
        case fragranceFree
        case sensitivityScore
        case usageNote
        case whyItMatches
        case catalogSource
        case evidenceLevel
        case commercialStatus
        case sourceMetadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        brand = try container.decode(String.self, forKey: .brand)
        category = try container.decode(ProductCategory.self, forKey: .category)
        price = try container.decode(Int.self, forKey: .price)
        budgetTier = try container.decode(BudgetTier.self, forKey: .budgetTier)
        heroIngredients = try container.decode([String].self, forKey: .heroIngredients)
        fullIngredients = try container.decodeIfPresent([String].self, forKey: .fullIngredients) ?? []
        ingredientListCoverage = try container.decodeIfPresent(IngredientListCoverage.self, forKey: .ingredientListCoverage) ?? .heroOnly
        concernFit = try container.decode(Set<SkinConcern>.self, forKey: .concernFit)
        fragranceFree = try container.decode(Bool.self, forKey: .fragranceFree)
        sensitivityScore = try container.decode(Int.self, forKey: .sensitivityScore)
        usageNote = try container.decode(String.self, forKey: .usageNote)
        whyItMatches = try container.decode(String.self, forKey: .whyItMatches)
        catalogSource = try container.decodeIfPresent(ProductCatalogSource.self, forKey: .catalogSource) ?? .curatedPrototype
        evidenceLevel = try container.decodeIfPresent(ProductEvidenceLevel.self, forKey: .evidenceLevel) ?? .labelBased
        commercialStatus = try container.decodeIfPresent(ProductCommercialStatus.self, forKey: .commercialStatus) ?? .undisclosed
        sourceMetadata = try container.decodeIfPresent(ProductSourceMetadata.self, forKey: .sourceMetadata) ?? .missing
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(brand, forKey: .brand)
        try container.encode(category, forKey: .category)
        try container.encode(price, forKey: .price)
        try container.encode(budgetTier, forKey: .budgetTier)
        try container.encode(heroIngredients, forKey: .heroIngredients)
        try container.encode(fullIngredients, forKey: .fullIngredients)
        try container.encode(ingredientListCoverage, forKey: .ingredientListCoverage)
        try container.encode(concernFit, forKey: .concernFit)
        try container.encode(fragranceFree, forKey: .fragranceFree)
        try container.encode(sensitivityScore, forKey: .sensitivityScore)
        try container.encode(usageNote, forKey: .usageNote)
        try container.encode(whyItMatches, forKey: .whyItMatches)
        try container.encode(catalogSource, forKey: .catalogSource)
        try container.encode(evidenceLevel, forKey: .evidenceLevel)
        try container.encode(commercialStatus, forKey: .commercialStatus)
        try container.encode(sourceMetadata, forKey: .sourceMetadata)
    }
}

struct RoutineStep: Codable, Identifiable, Hashable {
    var id = UUID()
    var moment: RoutineMoment
    var order: Int
    var category: ProductCategory
    var product: SkincareProduct
    var instruction: String
    var caution: String?
    var fitScore: Int?
    var selectionReasons: [String]

    init(
        id: UUID = UUID(),
        moment: RoutineMoment,
        order: Int,
        category: ProductCategory,
        product: SkincareProduct,
        instruction: String,
        caution: String?,
        fitScore: Int? = nil,
        selectionReasons: [String] = []
    ) {
        self.id = id
        self.moment = moment
        self.order = order
        self.category = category
        self.product = product
        self.instruction = instruction
        self.caution = caution
        self.fitScore = fitScore
        self.selectionReasons = selectionReasons
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case moment
        case order
        case category
        case product
        case instruction
        case caution
        case fitScore
        case selectionReasons
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        moment = try container.decode(RoutineMoment.self, forKey: .moment)
        order = try container.decode(Int.self, forKey: .order)
        category = try container.decode(ProductCategory.self, forKey: .category)
        product = try container.decode(SkincareProduct.self, forKey: .product)
        instruction = try container.decode(String.self, forKey: .instruction)
        caution = try container.decodeIfPresent(String.self, forKey: .caution)
        fitScore = try container.decodeIfPresent(Int.self, forKey: .fitScore)
        selectionReasons = try container.decodeIfPresent([String].self, forKey: .selectionReasons) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(moment, forKey: .moment)
        try container.encode(order, forKey: .order)
        try container.encode(category, forKey: .category)
        try container.encode(product, forKey: .product)
        try container.encode(instruction, forKey: .instruction)
        try container.encodeIfPresent(caution, forKey: .caution)
        try container.encodeIfPresent(fitScore, forKey: .fitScore)
        try container.encode(selectionReasons, forKey: .selectionReasons)
    }
}

struct RoutinePlan: Codable, Identifiable, Hashable {
    var id = UUID()
    var generatedAt: Date
    var focus: [SkinConcern]
    var steps: [RoutineStep]
    var weeklyNotes: [String]

    func steps(for moment: RoutineMoment) -> [RoutineStep] {
        steps
            .filter { $0.moment == moment }
            .sorted { $0.order < $1.order }
    }
}

enum IngredientFindingSeverity: String, Codable, CaseIterable, Identifiable, Hashable {
    case info
    case caution
    case warning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .info: "Good fit"
        case .caution: "Use carefully"
        case .warning: "Adjust routine"
        }
    }

    var symbolName: String {
        switch self {
        case .info: "checkmark.seal"
        case .caution: "exclamationmark.triangle"
        case .warning: "xmark.octagon"
        }
    }
}

struct IngredientCompatibilityFinding: Codable, Identifiable, Hashable {
    static let defaultRecommendation = "Use this as routine context, not a medical instruction."

    var id = UUID()
    var severity: IngredientFindingSeverity
    var title: String
    var detail: String
    var recommendation: String
    var relatedProductIDs: [String]

    init(
        id: UUID = UUID(),
        severity: IngredientFindingSeverity,
        title: String,
        detail: String,
        recommendation: String = IngredientCompatibilityFinding.defaultRecommendation,
        relatedProductIDs: [String]
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.detail = detail
        self.recommendation = recommendation
        self.relatedProductIDs = relatedProductIDs
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case severity
        case title
        case detail
        case recommendation
        case relatedProductIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        severity = try container.decode(IngredientFindingSeverity.self, forKey: .severity)
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decode(String.self, forKey: .detail)
        recommendation = try container.decodeIfPresent(String.self, forKey: .recommendation)
            ?? IngredientCompatibilityFinding.defaultRecommendation
        relatedProductIDs = try container.decode([String].self, forKey: .relatedProductIDs)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(severity, forKey: .severity)
        try container.encode(title, forKey: .title)
        try container.encode(detail, forKey: .detail)
        try container.encode(recommendation, forKey: .recommendation)
        try container.encode(relatedProductIDs, forKey: .relatedProductIDs)
    }
}
