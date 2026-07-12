import Foundation
import XCTest
@testable import DermaLens

final class RemoteSkinAnalysisClientTests: XCTestCase {
    override func tearDown() {
        CapturingURLProtocol.requestHandler = nil
        CapturingURLProtocol.capturedRequest = nil
        CapturingURLProtocol.capturedBody = nil
        super.tearDown()
    }

    func testRemoteAnalyzerSendsCaptureAndMapsResponse() async throws {
        let endpoint = URL(string: "https://example.com/skin-analysis")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let responseBody = """
        {
          "modelVersion": "vendor-model-2026-06",
          "requestID": "req_123",
          "validationStatus": "vendorProvided",
          "summary": "Remote summary",
          "visibleStrengths": ["Remote strength"],
          "scores": [
            {
              "concern": "redness",
              "score": 81,
              "confidence": "high",
              "primaryRegion": "leftCheek",
              "explanation": "Remote explanation"
            }
          ]
        }
        """.data(using: .utf8)!

        CapturingURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: endpoint,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                responseBody
            )
        }

        let client = RemoteSkinAnalysisClient(
            configuration: .init(endpoint: endpoint, apiKey: "test-key"),
            session: session
        )
        let capture = testCapture()

        let report = await client.analyze(capture: capture, profile: .default)

        XCTAssertEqual(report.summary, "Remote summary")
        XCTAssertEqual(report.scores.first?.concern, .redness)
        XCTAssertEqual(try XCTUnwrap(report.scores.first?.confidence), .medium)
        XCTAssertEqual(report.evidenceSummary.capturedFrameCount, 5)
        XCTAssertEqual(report.evidenceSummary.coveredRegions, GuidedScanStep.baselineSequence.map(\.region))
        XCTAssertEqual(report.analysisMetadata.kind, .remote)
        XCTAssertEqual(report.analysisMetadata.providerName, "example.com")
        XCTAssertTrue(report.analysisMetadata.remoteUploadAttempted)
        XCTAssertFalse(report.analysisMetadata.usedFallback)
        XCTAssertEqual(report.analysisMetadata.modelVersion, "vendor-model-2026-06")
        XCTAssertEqual(report.analysisMetadata.requestID, "req_123")
        XCTAssertEqual(report.analysisMetadata.validationStatus, .vendorProvided)
        XCTAssertEqual(CapturingURLProtocol.capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        XCTAssertEqual(
            try XCTUnwrap(CapturingURLProtocol.capturedRequest?.timeoutInterval),
            RemoteSkinAnalysisClient.Configuration.defaultTimeout,
            accuracy: 0.001
        )

        let body = try XCTUnwrap(CapturingURLProtocol.capturedBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertTrue((json["createdAt"] as? String)?.contains("T") == true)
        XCTAssertEqual(json["deviceModel"] as? String, "Unit Test iPhone")
        let profile = try XCTUnwrap(json["profile"] as? [String: Any])
        XCTAssertEqual(Set(profile.keys), [
            "skinType",
            "baselineSkinFeel",
            "sensitivity",
            "routineComplexity",
            "budget",
            "avoidsFragrance",
            "avoidsRetinoids",
            "knownIrritants",
            "retinoidSafetyContext",
            "currentGoals"
        ])
        XCTAssertEqual(profile["skinType"] as? String, UserProfile.default.skinType)
        XCTAssertEqual(profile["baselineSkinFeel"] as? String, UserProfile.default.baselineSkinFeel.rawValue)
        XCTAssertEqual(profile["sensitivity"] as? Int, UserProfile.default.sensitivity)
        XCTAssertEqual(profile["routineComplexity"] as? String, UserProfile.default.routineComplexity.rawValue)
        XCTAssertEqual(profile["budget"] as? String, UserProfile.default.budget.rawValue)
        XCTAssertEqual(profile["avoidsFragrance"] as? Bool, UserProfile.default.avoidsFragrance)
        XCTAssertEqual(profile["avoidsRetinoids"] as? Bool, UserProfile.default.avoidsRetinoids)
        XCTAssertEqual(profile["retinoidSafetyContext"] as? String, UserProfile.default.retinoidSafetyContext.rawValue)
        XCTAssertEqual((profile["knownIrritants"] as? [String])?.sorted(), UserProfile.default.knownIrritants.map(\.rawValue).sorted())
        XCTAssertEqual((profile["currentGoals"] as? [String])?.sorted(), UserProfile.default.currentGoals.map(\.rawValue).sorted())
        let evidence = try XCTUnwrap(json["evidenceSummary"] as? [String: Any])
        XCTAssertEqual(evidence["capturedFrameCount"] as? Int, 5)
        XCTAssertEqual(
            evidence["coveredRegions"] as? [String],
            GuidedScanStep.baselineSequence.map { $0.region.rawValue }
        )
        XCTAssertEqual(evidence["createdFromImageEvidence"] as? Bool, true)
        let frames = try XCTUnwrap(json["frames"] as? [[String: Any]])
        XCTAssertEqual(frames.count, 5)
        XCTAssertEqual(frames.first?["regionHint"] as? String, FaceRegion.forehead.rawValue)
        XCTAssertEqual(frames.first?["sourceFrameID"] as? Int, 1)
        XCTAssertEqual(frames.first?["verificationStatus"] as? String, ScanFrameVerificationStatus.freshGuidedCapture.rawValue)
        XCTAssertEqual(frames.first?["jpegBase64"] as? String, "AQ==")
        let frameQuality = try XCTUnwrap(frames.first?["qualitySnapshot"] as? [String: Any])
        XCTAssertEqual(frameQuality["depthGuidanceAvailable"] as? Bool, true)
        XCTAssertEqual(try XCTUnwrap(frameQuality["lighting"] as? Double), ScanQuality.preview.lighting, accuracy: 0.001)
    }

    func testRemoteAnalyzerWithoutValidationMetadataIsMarkedUnvalidated() async {
        let endpoint = URL(string: "https://example.com/skin-analysis")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let responseBody = """
        {
          "modelVersion": "vendor-model-2026-06",
          "summary": "Remote summary",
          "visibleStrengths": ["Remote strength"],
          "scores": [
            {
              "concern": "redness",
              "score": 81,
              "confidence": "medium",
              "primaryRegion": "leftCheek",
              "explanation": "Remote explanation"
            }
          ]
        }
        """.data(using: .utf8)!

        CapturingURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: endpoint,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                responseBody
            )
        }

        let client = RemoteSkinAnalysisClient(
            configuration: .init(endpoint: endpoint, apiKey: nil),
            session: session
        )
        let capture = testCapture()

        let report = await client.analyze(capture: capture, profile: .default)

        XCTAssertEqual(report.analysisMetadata.kind, .remote)
        XCTAssertEqual(report.analysisMetadata.validationStatus, .unvalidatedRemote)
    }

    func testRemoteAnalyzerRejectsIncompleteEvidenceBeforeUpload() async throws {
        let endpoint = URL(string: "https://example.com/skin-analysis")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)

        CapturingURLProtocol.requestHandler = { _ in
            XCTFail("Incomplete guided evidence should not be uploaded.")
            return (
                HTTPURLResponse(
                    url: endpoint,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data()
            )
        }

        let client = RemoteSkinAnalysisClient(
            configuration: .init(endpoint: endpoint, apiKey: nil),
            session: session
        )
        let capture = incompleteCapture()

        let report = await client.analyze(capture: capture, profile: .default)

        XCTAssertNil(CapturingURLProtocol.capturedRequest)
        XCTAssertEqual(report.analysisMetadata.kind, .remoteFallback)
        XCTAssertFalse(report.analysisMetadata.remoteUploadAttempted)
        XCTAssertTrue(report.analysisMetadata.usedFallback)
        XCTAssertEqual(report.analysisMetadata.fallbackReason, RemoteSkinAnalysisClient.AnalysisError.incompleteEvidence.localizedDescription)
        XCTAssertEqual(report.analysisMetadata.privacyLabel, "On-device, no image retention")
    }

    func testRemoteAnalyzerUnknownValidationMetadataIsMarkedUnvalidated() async {
        let endpoint = URL(string: "https://example.com/skin-analysis")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let responseBody = """
        {
          "modelVersion": "vendor-model-2026-06",
          "validationStatus": "vendorExperimentalPrivateBeta",
          "summary": "Remote summary",
          "visibleStrengths": ["Remote strength"],
          "scores": [
            {
              "concern": "redness",
              "score": 81,
              "confidence": "medium",
              "primaryRegion": "leftCheek",
              "explanation": "Remote explanation"
            }
          ]
        }
        """.data(using: .utf8)!

        CapturingURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: endpoint,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                responseBody
            )
        }

        let client = RemoteSkinAnalysisClient(
            configuration: .init(endpoint: endpoint, apiKey: nil),
            session: session
        )
        let report = await client.analyze(capture: testCapture(), profile: .default)

        XCTAssertEqual(report.analysisMetadata.kind, .remote)
        XCTAssertEqual(report.analysisMetadata.validationStatus, .unvalidatedRemote)
    }

    func testRemoteAnalyzerFallbackLabelsLocalReport() async throws {
        let endpoint = URL(string: "https://example.com/skin-analysis")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)

        CapturingURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: endpoint,
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data()
            )
        }

        let client = RemoteSkinAnalysisClient(
            configuration: .init(endpoint: endpoint, apiKey: nil),
            session: session
        )
        let capture = testCapture()

        let report = await client.analyze(capture: capture, profile: .default)

        XCTAssertEqual(report.analysisMetadata.kind, .remoteFallback)
        XCTAssertEqual(report.analysisMetadata.providerName, "example.com fallback")
        XCTAssertTrue(report.analysisMetadata.remoteUploadAttempted)
        XCTAssertTrue(report.analysisMetadata.usedFallback)
        XCTAssertEqual(report.analysisMetadata.fallbackReason, RemoteSkinAnalysisClient.AnalysisError.badResponse.localizedDescription)
        XCTAssertTrue(report.analysisMetadata.runsOnDevice)
        XCTAssertEqual(report.analysisMetadata.privacyLabel, "Remote upload attempted; local fallback used")
    }

    @MainActor
    func testRemoteConfiguredAppUsesLocalAnalysisUntilUploadConsentGranted() async throws {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let endpoint = URL(string: "https://analysis.example.com/skin-analysis")!
        let remoteAnalyzer = RecordingRemoteAnalyzer()
        let appState = AppState(
            configuration: AppConfiguration(
                analyzer: remoteAnalyzer,
                analyzerMode: .remote,
                remoteEndpoint: endpoint,
                remoteFallbacksToLocal: true
            ),
            consentGatedLocalAnalyzer: ImmediateLocalAnalyzer(),
            routineNotificationScheduler: ConsentNoopRoutineNotificationScheduler(),
            persistenceStore: PersistenceStore(defaults: defaults),
            seedPreviewData: false
        )
        let capture = testCapture()

        let firstScanCreatedReport = await appState.runScan(with: capture)

        XCTAssertTrue(firstScanCreatedReport)
        XCTAssertEqual(await remoteAnalyzer.callCount(), 0)
        XCTAssertFalse(appState.remoteAnalysisConsentGranted)
        XCTAssertEqual(appState.latestReport.analysisMetadata.kind, .remoteConsentNotGranted)
        XCTAssertEqual(appState.latestReport.analysisMetadata.providerName, "analysis.example.com upload off")
        XCTAssertFalse(appState.latestReport.analysisMetadata.remoteUploadAttempted)
        XCTAssertTrue(appState.latestReport.analysisMetadata.runsOnDevice)

        appState.setRemoteAnalysisConsent(true)
        let secondScanCreatedReport = await appState.runScan(with: capture)

        XCTAssertTrue(secondScanCreatedReport)
        XCTAssertEqual(await remoteAnalyzer.callCount(), 1)
        XCTAssertTrue(appState.remoteAnalysisConsentGranted)
        XCTAssertEqual(appState.latestReport.analysisMetadata.kind, .remote)
        XCTAssertTrue(appState.latestReport.analysisMetadata.remoteUploadAttempted)
    }

    @MainActor
    func testRemoteAnalysisConsentPersistsAndResets() async throws {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let endpoint = URL(string: "https://analysis.example.com/skin-analysis")!
        let store = PersistenceStore(defaults: defaults)
        let configuration = AppConfiguration(
            analyzer: RecordingRemoteAnalyzer(),
            analyzerMode: .remote,
            remoteEndpoint: endpoint,
            remoteFallbacksToLocal: true
        )
        let appState = AppState(
            configuration: configuration,
            consentGatedLocalAnalyzer: ImmediateLocalAnalyzer(),
            routineNotificationScheduler: ConsentNoopRoutineNotificationScheduler(),
            persistenceStore: store,
            seedPreviewData: false
        )

        appState.setRemoteAnalysisConsent(true)

        let restored = AppState(
            configuration: configuration,
            consentGatedLocalAnalyzer: ImmediateLocalAnalyzer(),
            routineNotificationScheduler: ConsentNoopRoutineNotificationScheduler(),
            persistenceStore: store,
            seedPreviewData: false
        )
        XCTAssertTrue(restored.remoteAnalysisConsentGranted)

        restored.deleteAllLocalData()

        let reset = AppState(
            configuration: configuration,
            consentGatedLocalAnalyzer: ImmediateLocalAnalyzer(),
            routineNotificationScheduler: ConsentNoopRoutineNotificationScheduler(),
            persistenceStore: store,
            seedPreviewData: false
        )
        XCTAssertFalse(reset.remoteAnalysisConsentGranted)
    }

    @MainActor
    func testRemoteAnalysisConsentDoesNotCarryAcrossHostChange() async throws {
        let suiteName = "DermaLensTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PersistenceStore(defaults: defaults)
        let originalConfiguration = AppConfiguration(
            analyzer: RecordingRemoteAnalyzer(),
            analyzerMode: .remote,
            remoteEndpoint: URL(string: "https://analysis.example.com/skin-analysis")!,
            remoteFallbacksToLocal: true
        )
        let appState = AppState(
            configuration: originalConfiguration,
            consentGatedLocalAnalyzer: ImmediateLocalAnalyzer(),
            routineNotificationScheduler: ConsentNoopRoutineNotificationScheduler(),
            persistenceStore: store,
            seedPreviewData: false
        )
        appState.setRemoteAnalysisConsent(true)

        let changedHostConfiguration = AppConfiguration(
            analyzer: RecordingRemoteAnalyzer(),
            analyzerMode: .remote,
            remoteEndpoint: URL(string: "https://new-vendor.example.com/skin-analysis")!,
            remoteFallbacksToLocal: true
        )
        let restored = AppState(
            configuration: changedHostConfiguration,
            consentGatedLocalAnalyzer: ImmediateLocalAnalyzer(),
            routineNotificationScheduler: ConsentNoopRoutineNotificationScheduler(),
            persistenceStore: store,
            seedPreviewData: false
        )

        XCTAssertFalse(restored.remoteAnalysisConsentGranted)
    }
}

private actor RecordingRemoteAnalyzer: SkinAnalysisServicing {
    private var count = 0

    func analyze(capture: ScanCapture, profile: UserProfile) async -> SkinReport {
        count += 1
        return SkinReport(
            createdAt: Date(timeIntervalSince1970: 1_780_000_010),
            scanQuality: capture.quality,
            evidenceSummary: capture.evidenceSummary,
            analysisMetadata: .remote(endpointHost: "analysis.example.com"),
            scores: [
                ConcernScore(
                    concern: .redness,
                    score: 70,
                    confidence: .medium,
                    primaryRegion: .leftCheek,
                    explanation: "Remote fixture"
                )
            ],
            visibleStrengths: ["Remote fixture"],
            summary: "Remote report"
        )
    }

    func callCount() -> Int {
        count
    }
}

private struct ImmediateLocalAnalyzer: SkinAnalysisServicing {
    func analyze(capture: ScanCapture, profile: UserProfile) async -> SkinReport {
        SkinReport(
            createdAt: Date(timeIntervalSince1970: 1_780_000_020),
            scanQuality: capture.quality,
            evidenceSummary: capture.evidenceSummary,
            analysisMetadata: .simulatedLocal,
            scores: [
                ConcernScore(
                    concern: .texture,
                    score: 58,
                    confidence: .medium,
                    primaryRegion: .forehead,
                    explanation: "Local fixture"
                )
            ],
            visibleStrengths: ["Local fixture"],
            summary: "Local report"
        )
    }
}

private struct ConsentNoopRoutineNotificationScheduler: RoutineNotificationScheduling {
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

private func testCapture() -> ScanCapture {
    ScanCapture(
        createdAt: Date(timeIntervalSince1970: 1_780_000_000),
        quality: .preview,
        frames: [
            testFrame(region: .forehead, sourceFrameID: 1, byte: 0x01),
            testFrame(region: .leftCheek, sourceFrameID: 2, byte: 0x02),
            testFrame(region: .rightCheek, sourceFrameID: 3, byte: 0x03),
            testFrame(region: .nose, sourceFrameID: 4, byte: 0x04),
            testFrame(region: .chin, sourceFrameID: 5, byte: 0x05)
        ],
        deviceModel: "Unit Test iPhone"
    )
}

private func incompleteCapture() -> ScanCapture {
    ScanCapture(
        createdAt: Date(timeIntervalSince1970: 1_780_000_000),
        quality: .preview,
        frames: [
            testFrame(region: .forehead, sourceFrameID: 1, byte: 0x01)
        ],
        deviceModel: "Unit Test iPhone"
    )
}

private func testFrame(region: FaceRegion, sourceFrameID: Int, byte: UInt8) -> ScanFrame {
    ScanFrame(
        capturedAt: Date(timeIntervalSince1970: TimeInterval(1_780_000_000 + sourceFrameID)),
        jpegData: Data([byte]),
        regionHint: region,
        qualitySnapshot: .preview,
        sourceFrameID: sourceFrameID,
        verificationStatus: .freshGuidedCapture
    )
}

private final class CapturingURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var capturedRequest: URLRequest?
    static var capturedBody: Data?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.capturedRequest = request
        if let httpBody = request.httpBody {
            Self.capturedBody = httpBody
        } else if let httpBodyStream = request.httpBodyStream {
            Self.capturedBody = Self.readBodyStream(httpBodyStream)
        }

        do {
            let handler = try XCTUnwrap(Self.requestHandler)
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func readBodyStream(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count > 0 {
                data.append(contentsOf: buffer.prefix(count))
            } else {
                break
            }
        }
        return data
    }
}
