import CoreGraphics
import Foundation

struct LuminanceSample: Hashable {
    var mean: Double
    var variance: Double
}

struct FaceObservationSample: Hashable {
    var center: CGPoint
    var height: Double
}

enum ScanQualityEstimator {
    static func luminanceMetrics(from sample: LuminanceSample) -> (lighting: Double, clarity: Double) {
        let lighting = clamp(1 - abs(sample.mean - 0.56) / 0.44)
        let clarity = clamp(sqrt(max(0, sample.variance)) / 0.24)
        return (lighting, clarity)
    }

    static func faceMetrics(
        current: FaceObservationSample?,
        previousCenter: CGPoint?
    ) -> (alignment: Double, stability: Double) {
        guard let current else {
            return (0.35, 0.5)
        }

        let centerOffset = Double(hypot(current.center.x - 0.5, current.center.y - 0.52))
        let sizeScore = clamp((current.height - 0.26) / 0.28)
        let alignment = clamp((1 - centerOffset / 0.34) * 0.72 + sizeScore * 0.28)

        let movement: Double
        if let previousCenter {
            movement = Double(hypot(current.center.x - previousCenter.x, current.center.y - previousCenter.y))
        } else {
            movement = 0.04
        }

        let stability = clamp(1 - movement / 0.14)
        return (alignment, stability)
    }

    static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
