import Foundation

struct RemoteSkinAnalysisClient: SkinAnalysisServicing {
    struct Configuration: Hashable {
        static let defaultTimeout: TimeInterval = 15

        var endpoint: URL
        var apiKey: String?
        var timeout: TimeInterval = Self.defaultTimeout
    }

    enum AnalysisError: LocalizedError {
        case noFrames
        case incompleteEvidence
        case badResponse

        var errorDescription: String? {
            switch self {
            case .noFrames:
                "The remote analyzer needs at least one captured frame."
            case .incompleteEvidence:
                "The remote analyzer needs a complete guided capture before upload."
            case .badResponse:
                "The skin-analysis service returned an invalid response."
            }
        }

        var remoteUploadAttempted: Bool {
            switch self {
            case .noFrames, .incompleteEvidence:
                false
            case .badResponse:
                true
            }
        }
    }

    private let configuration: Configuration
    private let session: URLSession

    init(configuration: Configuration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func analyze(capture: ScanCapture, profile: UserProfile) async -> SkinReport {
        do {
            var report = try await requestAnalysis(capture: capture, profile: profile)
            report.analysisMetadata = .remote(
                endpointHost: configuration.endpoint.host,
                modelVersion: report.analysisMetadata.modelVersion,
                requestID: report.analysisMetadata.requestID,
                validationStatus: report.analysisMetadata.validationStatus
            )
            return report
        } catch {
            let remoteUploadAttempted = (error as? AnalysisError)?.remoteUploadAttempted ?? true
            var report = await ScanAnalyzer().analyze(capture: capture, profile: profile)
            report.analysisMetadata = .remoteFallback(
                endpointHost: configuration.endpoint.host,
                reason: error.localizedDescription,
                remoteUploadAttempted: remoteUploadAttempted
            )
            return report
        }
    }

    private func requestAnalysis(capture: ScanCapture, profile: UserProfile) async throws -> SkinReport {
        guard capture.hasImageEvidence else {
            throw AnalysisError.noFrames
        }
        guard capture.evidenceSummary.isComplete else {
            throw AnalysisError.incompleteEvidence
        }

        var request = URLRequest(url: configuration.endpoint, timeoutInterval: configuration.timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(RemoteAnalysisRequest(capture: capture, profile: profile))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnalysisError.badResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let remote = try decoder.decode(RemoteAnalysisResponse.self, from: data)
        return remote.makeReport(scanQuality: capture.quality, evidenceSummary: capture.evidenceSummary)
    }
}

enum RemoteAnalysisDisclosure {
    static func consentDetail(host: String?) -> String {
        let destination = host.map { "\($0)" } ?? "the configured analyzer"
        return "Send short-lived scan frames, scan-quality metadata, device model, and profile context including skin type, baseline feel, routine complexity, budget, goals, sensitivity, ingredient flags, irritants, and retinoid context to \(destination) for analysis."
    }
}

private struct RemoteAnalysisRequest: Encodable {
    var createdAt: Date
    var deviceModel: String
    var quality: ScanQuality
    var evidenceSummary: ScanEvidenceSummary
    var profile: UserProfile
    var frames: [RemoteFrame]

    init(capture: ScanCapture, profile: UserProfile) {
        self.createdAt = capture.createdAt
        self.deviceModel = capture.deviceModel
        self.quality = capture.quality
        self.evidenceSummary = capture.evidenceSummary
        self.profile = profile
        self.frames = capture.frames.map(RemoteFrame.init(frame:))
    }
}

private struct RemoteFrame: Encodable {
    var capturedAt: Date
    var regionHint: FaceRegion?
    var qualitySnapshot: ScanQuality?
    var sourceFrameID: Int?
    var verificationStatus: ScanFrameVerificationStatus
    var jpegBase64: String

    init(frame: ScanFrame) {
        self.capturedAt = frame.capturedAt
        self.regionHint = frame.regionHint
        self.qualitySnapshot = frame.qualitySnapshot
        self.sourceFrameID = frame.sourceFrameID
        self.verificationStatus = frame.verificationStatus
        self.jpegBase64 = frame.jpegData.base64EncodedString()
    }
}

private struct RemoteAnalysisResponse: Decodable {
    var modelVersion: String?
    var requestID: String?
    var validationStatus: AnalysisValidationStatus?
    var scores: [RemoteConcernScore]
    var visibleStrengths: [String]
    var summary: String

    func makeReport(scanQuality: ScanQuality, evidenceSummary: ScanEvidenceSummary) -> SkinReport {
        let evidenceConfidence = evidenceSummary.confidenceLevel(for: scanQuality)
        SkinReport(
            createdAt: Date(),
            scanQuality: scanQuality,
            evidenceSummary: evidenceSummary,
            analysisMetadata: .remote(
                endpointHost: nil,
                modelVersion: modelVersion,
                requestID: requestID,
                validationStatus: validationStatus ?? .unvalidatedRemote
            ),
            scores: scores.map { $0.concernScore(limitedBy: evidenceConfidence) },
            visibleStrengths: visibleStrengths,
            summary: summary
        )
    }
}

private struct RemoteConcernScore: Decodable {
    var concern: SkinConcern
    var score: Int
    var confidence: ConfidenceLevel
    var primaryRegion: FaceRegion
    var explanation: String

    func concernScore(limitedBy evidenceConfidence: ConfidenceLevel) -> ConcernScore {
        ConcernScore(
            concern: concern,
            score: min(max(score, 0), 100),
            confidence: limitedConfidence(by: evidenceConfidence),
            primaryRegion: primaryRegion,
            explanation: explanation
        )
    }

    private func limitedConfidence(by evidenceConfidence: ConfidenceLevel) -> ConfidenceLevel {
        switch evidenceConfidence {
        case .low:
            .low
        case .medium:
            confidence == .high ? .medium : confidence
        case .high:
            confidence
        }
    }
}
