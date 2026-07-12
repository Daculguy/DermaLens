import CoreGraphics
import Foundation
import XCTest
@testable import DermaLens

final class ScanQualityEstimatorTests: XCTestCase {
    func testBalancedLuminanceScoresWell() {
        let metrics = ScanQualityEstimator.luminanceMetrics(
            from: LuminanceSample(mean: 0.56, variance: 0.04)
        )

        XCTAssertEqual(metrics.lighting, 1, accuracy: 0.001)
        XCTAssertGreaterThan(metrics.clarity, 0.8)
    }

    func testBacklitOrDarkLuminanceScoresPoorly() {
        let dark = ScanQualityEstimator.luminanceMetrics(
            from: LuminanceSample(mean: 0.1, variance: 0.01)
        )
        let blownOut = ScanQualityEstimator.luminanceMetrics(
            from: LuminanceSample(mean: 0.98, variance: 0.01)
        )

        XCTAssertLessThan(dark.lighting, 0.1)
        XCTAssertLessThan(blownOut.lighting, 0.1)
    }

    func testCenteredFaceScoresHigherThanOffCenterFace() {
        let centered = ScanQualityEstimator.faceMetrics(
            current: FaceObservationSample(center: CGPoint(x: 0.5, y: 0.52), height: 0.48),
            previousCenter: CGPoint(x: 0.5, y: 0.52)
        )
        let offCenter = ScanQualityEstimator.faceMetrics(
            current: FaceObservationSample(center: CGPoint(x: 0.18, y: 0.18), height: 0.24),
            previousCenter: CGPoint(x: 0.5, y: 0.52)
        )

        XCTAssertGreaterThan(centered.alignment, offCenter.alignment)
        XCTAssertGreaterThan(centered.stability, offCenter.stability)
    }

    func testMissingFaceUsesWeakFallback() {
        let metrics = ScanQualityEstimator.faceMetrics(current: nil, previousCenter: nil)

        XCTAssertLessThan(metrics.alignment, 0.5)
        XCTAssertEqual(metrics.stability, 0.5, accuracy: 0.001)
    }

    func testScanCaptureBuildsRegionEvidenceSummary() {
        let capture = ScanCapture(
            createdAt: Date(timeIntervalSince1970: 10),
            quality: .preview,
            frames: [
                freshGuidedFrame(region: .forehead, sourceFrameID: 1, byte: 0x01),
                freshGuidedFrame(region: .leftCheek, sourceFrameID: 2, byte: 0x02),
                freshGuidedFrame(region: .rightCheek, sourceFrameID: 3, byte: 0x03),
                freshGuidedFrame(region: .nose, sourceFrameID: 4, byte: 0x04),
                freshGuidedFrame(region: .chin, sourceFrameID: 5, byte: 0x05)
            ],
            deviceModel: "Unit Test"
        )

        XCTAssertEqual(capture.evidenceSummary.capturedFrameCount, 5)
        XCTAssertEqual(capture.evidenceSummary.coveredRegions, GuidedScanStep.baselineSequence.map { $0.region })
        XCTAssertEqual(capture.evidenceSummary.coverageScore, 1, accuracy: 0.001)
        XCTAssertEqual(capture.evidenceSummary.coverageLabel, "5/5 guided captures")
        XCTAssertTrue(capture.evidenceSummary.isComplete)
        XCTAssertEqual(capture.evidenceSummary.confidenceLevel(for: .preview), .medium)
        XCTAssertEqual(capture.evidenceSummary.regionEvidence.count, GuidedScanStep.baselineSequence.count)
        XCTAssertTrue(capture.evidenceSummary.regionEvidence.allSatisfy(\.isCaptured))
        XCTAssertTrue(capture.evidenceSummary.regionEvidence.allSatisfy(\.isFreshGuidedCapture))
        XCTAssertTrue(capture.evidenceSummary.regionEvidence.allSatisfy { !$0.isVerified })
        XCTAssertTrue(capture.evidenceSummary.regionEvidence.allSatisfy { $0.freshGuidedFrameCount == 1 })
        XCTAssertTrue(capture.evidenceSummary.regionEvidence.allSatisfy { $0.verifiedFrameCount == 0 })
    }

    func testEvidenceSummaryLowersConfidenceWithoutFrames() {
        let capture = ScanCapture(
            createdAt: Date(timeIntervalSince1970: 10),
            quality: .preview,
            frames: [],
            deviceModel: "Unit Test"
        )

        XCTAssertFalse(capture.evidenceSummary.createdFromImageEvidence)
        XCTAssertFalse(capture.evidenceSummary.isComplete)
        XCTAssertEqual(capture.evidenceSummary.confidenceLevel(for: .preview), .low)
    }

    func testEvidenceSummaryTracksPerRegionQualitySnapshots() {
        let lowQuality = ScanQuality(
            lighting: 0.7,
            alignment: 0.68,
            stability: 0.66,
            clarity: 0.64,
            depthGuidanceAvailable: true
        )
        let capture = ScanCapture(
            createdAt: Date(timeIntervalSince1970: 10),
            quality: .preview,
            frames: [
                ScanFrame(
                    capturedAt: Date(timeIntervalSince1970: 11),
                    jpegData: Data([0x01]),
                    regionHint: .forehead,
                    qualitySnapshot: .preview,
                    sourceFrameID: 1,
                    verificationStatus: .freshGuidedCapture
                ),
                ScanFrame(
                    capturedAt: Date(timeIntervalSince1970: 12),
                    jpegData: Data([0x02]),
                    regionHint: .leftCheek,
                    qualitySnapshot: lowQuality,
                    sourceFrameID: 2,
                    verificationStatus: .freshGuidedCapture
                )
            ],
            deviceModel: "Unit Test"
        )

        let evidence = capture.evidenceSummary.regionEvidence
        XCTAssertEqual(evidence.first { $0.region == .forehead }?.confidence, .high)
        XCTAssertEqual(evidence.first { $0.region == .leftCheek }?.confidence, .low)
        XCTAssertEqual(evidence.first { $0.region == .nose }?.isCaptured, false)
    }

    func testRegionHintsDoNotCountAsGuidedCaptureCoverage() {
        let capture = ScanCapture(
            createdAt: Date(timeIntervalSince1970: 10),
            quality: .preview,
            frames: [
                ScanFrame(
                    capturedAt: Date(timeIntervalSince1970: 11),
                    jpegData: Data([0x01]),
                    regionHint: .forehead,
                    qualitySnapshot: .preview,
                    sourceFrameID: 1,
                    verificationStatus: .staleGuidedCapture
                )
            ],
            deviceModel: "Unit Test"
        )

        let forehead = capture.evidenceSummary.regionEvidence.first { $0.region == .forehead }
        XCTAssertEqual(capture.evidenceSummary.coveredRegions, [])
        XCTAssertEqual(capture.evidenceSummary.coverageScore, 0, accuracy: 0.001)
        XCTAssertFalse(capture.evidenceSummary.isComplete)
        XCTAssertTrue(forehead?.isCaptured == true)
        XCTAssertFalse(forehead?.isFreshGuidedCapture == true)
        XCTAssertFalse(forehead?.isVerified == true)
        XCTAssertEqual(forehead?.statusLabel, "Hint only")
    }

    func testDuplicateSourceFrameDoesNotCountForMultipleGuidedRegions() {
        let capture = ScanCapture(
            createdAt: Date(timeIntervalSince1970: 10),
            quality: .preview,
            frames: [
                freshGuidedFrame(region: .forehead, sourceFrameID: 1, byte: 0x01),
                freshGuidedFrame(region: .leftCheek, sourceFrameID: 1, byte: 0x02),
                freshGuidedFrame(region: .rightCheek, sourceFrameID: 2, byte: 0x03),
                freshGuidedFrame(region: .nose, sourceFrameID: 3, byte: 0x04),
                freshGuidedFrame(region: .chin, sourceFrameID: 4, byte: 0x05)
            ],
            deviceModel: "Unit Test"
        )

        XCTAssertEqual(capture.evidenceSummary.coveredRegions, [.forehead, .rightCheek, .nose, .chin])
        XCTAssertEqual(capture.evidenceSummary.coverageScore, 0.8, accuracy: 0.001)
        XCTAssertFalse(capture.evidenceSummary.isComplete)
        XCTAssertEqual(capture.evidenceSummary.confidenceLevel(for: .preview), .medium)
        XCTAssertFalse(capture.evidenceSummary.regionEvidence.first { $0.region == .leftCheek }?.isFreshGuidedCapture == true)
        XCTAssertFalse(capture.evidenceSummary.regionEvidence.first { $0.region == .leftCheek }?.isVerified == true)
    }

    func testLegacyRegionEvidenceDecodesCapturedFramesAsFreshGuidedCapture() throws {
        let json = """
        {
          "region": "forehead",
          "frameCount": 1,
          "averageQuality": 0.89,
          "confidence": "high"
        }
        """.data(using: .utf8)!

        let evidence = try JSONDecoder().decode(ScanRegionEvidence.self, from: json)

        XCTAssertTrue(evidence.isCaptured)
        XCTAssertTrue(evidence.isFreshGuidedCapture)
        XCTAssertFalse(evidence.isVerified)
        XCTAssertEqual(evidence.freshGuidedFrameCount, 1)
        XCTAssertEqual(evidence.verifiedFrameCount, 0)
        XCTAssertEqual(evidence.verificationStatus, "freshGuidedCapture")
    }

    func testLegacyFrameStatusDecodesAsFreshGuidedCapture() throws {
        let data = #""guidedRegionFresh""#.data(using: .utf8)!

        let status = try JSONDecoder().decode(ScanFrameVerificationStatus.self, from: data)

        XCTAssertEqual(status, .freshGuidedCapture)
        XCTAssertTrue(status.isFreshGuidedCapture)
        XCTAssertFalse(status.isRegionVerified)
    }

    func testFutureRegionVerifiedFramesCanEarnHighConfidence() {
        let capture = ScanCapture(
            createdAt: Date(timeIntervalSince1970: 10),
            quality: .preview,
            frames: [
                regionVerifiedFrame(region: .forehead, sourceFrameID: 1, byte: 0x01),
                regionVerifiedFrame(region: .leftCheek, sourceFrameID: 2, byte: 0x02),
                regionVerifiedFrame(region: .rightCheek, sourceFrameID: 3, byte: 0x03),
                regionVerifiedFrame(region: .nose, sourceFrameID: 4, byte: 0x04),
                regionVerifiedFrame(region: .chin, sourceFrameID: 5, byte: 0x05)
            ],
            deviceModel: "Unit Test"
        )

        XCTAssertEqual(capture.evidenceSummary.coverageLabel, "5/5 guided captures")
        XCTAssertEqual(capture.evidenceSummary.confidenceLevel(for: .preview), .high)
        XCTAssertTrue(capture.evidenceSummary.regionEvidence.allSatisfy(\.isVerified))
    }

    func testSimulatedAnalyzerReflectsMissingImageEvidence() async {
        let capture = ScanCapture(
            createdAt: Date(timeIntervalSince1970: 10),
            quality: .preview,
            frames: [],
            deviceModel: "Unit Test"
        )

        let report = await ScanAnalyzer().analyze(capture: capture, profile: .default)

        XCTAssertEqual(report.evidenceSummary, .empty)
        XCTAssertEqual(report.analysisMetadata.kind, .simulatedLocal)
        XCTAssertFalse(report.analysisMetadata.retainsImages)
        XCTAssertTrue(report.scores.allSatisfy { $0.confidence == .low })
        XCTAssertTrue(report.visibleStrengths.contains { $0.localizedCaseInsensitiveContains("limited scan evidence") })
    }
}

private func freshGuidedFrame(region: FaceRegion, sourceFrameID: Int, byte: UInt8) -> ScanFrame {
    ScanFrame(
        capturedAt: Date(timeIntervalSince1970: TimeInterval(10 + sourceFrameID)),
        jpegData: Data([byte]),
        regionHint: region,
        qualitySnapshot: .preview,
        sourceFrameID: sourceFrameID,
        verificationStatus: .freshGuidedCapture
    )
}

private func regionVerifiedFrame(region: FaceRegion, sourceFrameID: Int, byte: UInt8) -> ScanFrame {
    ScanFrame(
        capturedAt: Date(timeIntervalSince1970: TimeInterval(10 + sourceFrameID)),
        jpegData: Data([byte]),
        regionHint: region,
        qualitySnapshot: .preview,
        sourceFrameID: sourceFrameID,
        verificationStatus: .regionVerified
    )
}
