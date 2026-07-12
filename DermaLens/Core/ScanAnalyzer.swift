import Foundation

protocol SkinAnalysisServicing {
    func analyze(capture: ScanCapture, profile: UserProfile) async -> SkinReport
}

struct SkinAnalysisProviderDescriptor: Hashable {
    var name: String
    var runsOnDevice: Bool
    var retainsImages: Bool

    static let simulatedLocal = SkinAnalysisProviderDescriptor(
        name: "Simulated local analyzer",
        runsOnDevice: true,
        retainsImages: false
    )
}

actor ScanAnalyzer: SkinAnalysisServicing {
    let descriptor = SkinAnalysisProviderDescriptor.simulatedLocal

    func analyze(capture: ScanCapture, profile: UserProfile) async -> SkinReport {
        try? await Task.sleep(nanoseconds: 900_000_000)

        let quality = capture.quality
        let evidence = capture.evidenceSummary
        let confidence = evidence.confidenceLevel(for: quality)
        let qualityPenalty = Int((1 - quality.average) * 16)
        let evidencePenalty = evidence.isComplete ? 0 : evidence.createdFromImageEvidence ? 4 : 10
        let goalBoost: (SkinConcern) -> Int = { concern in
            profile.currentGoals.contains(concern) ? 7 : 0
        }

        let scores = [
            makeScore(
                concern: .redness,
                base: 63 + goalBoost(.redness) - qualityPenalty - evidencePenalty,
                confidence: confidence,
                region: .leftCheek,
                explanation: "Visible redness is concentrated around the cheek zones. This is a cosmetic pattern, not a diagnosis."
            ),
            makeScore(
                concern: .texture,
                base: 58 + goalBoost(.texture) - qualityPenalty / 2 - evidencePenalty,
                confidence: confidence,
                region: .forehead,
                explanation: "The scan sees uneven light reflection around the forehead and chin, which can indicate texture."
            ),
            makeScore(
                concern: .blemishes,
                base: 56 + goalBoost(.blemishes) - qualityPenalty / 2 - evidencePenalty,
                confidence: confidence,
                region: .chin,
                explanation: "A few localized marks are visible on the lower face. Recommendations stay gentle to reduce over-treatment."
            ),
            makeScore(
                concern: .darkSpots,
                base: 42 + goalBoost(.darkSpots) - qualityPenalty - evidencePenalty,
                confidence: confidence,
                region: .rightCheek,
                explanation: "Uneven tone was visible in small cheek areas. Lighting can strongly affect this metric."
            ),
            makeScore(
                concern: .pores,
                base: 36 + goalBoost(.pores) - qualityPenalty / 2 - evidencePenalty,
                confidence: confidence,
                region: .nose,
                explanation: "Visible pore texture appears mild and mostly T-zone focused."
            ),
            makeScore(
                concern: .barrier,
                base: 32 + (profile.sensitivity * 4) - qualityPenalty / 2 - evidencePenalty,
                confidence: confidence,
                region: .leftCheek,
                explanation: "Sensitivity inputs and visible redness suggest keeping the barrier plan conservative."
            )
        ]

        let top = scores.sorted { $0.score > $1.score }.prefix(3).map(\.concern.title).joined(separator: ", ")

        return SkinReport(
            createdAt: Date(),
            scanQuality: quality,
            evidenceSummary: evidence,
            analysisMetadata: .simulatedLocal,
            scores: scores,
            visibleStrengths: visibleStrengths(for: evidence),
            summary: "Your main visible priorities are \(top). Start simple, protect the barrier, and rescan after two weeks before escalating actives."
        )
    }

    private func visibleStrengths(for evidence: ScanEvidenceSummary) -> [String] {
        var strengths = [
            evidence.isComplete
                ? "Captured \(evidence.coverageLabel) for a fuller baseline"
                : "Limited scan evidence captured; treat this as a softer baseline",
                "No severe dryness pattern visible in the guided regions",
                "Routine can start with low-irritation products"
        ]

        if evidence.createdFromImageEvidence {
            strengths.append("Raw frames were used transiently and are not saved to local history")
        }

        return strengths
    }

    private func makeScore(
        concern: SkinConcern,
        base: Int,
        confidence: ConfidenceLevel,
        region: FaceRegion,
        explanation: String
    ) -> ConcernScore {
        let score = min(max(base, 8), 92)
        return ConcernScore(
            concern: concern,
            score: score,
            confidence: confidence,
            primaryRegion: region,
            explanation: explanation
        )
    }
}
