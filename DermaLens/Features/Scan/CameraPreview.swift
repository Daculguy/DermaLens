import AVFoundation
import Combine
import CoreImage
import CoreGraphics
import SwiftUI
import UIKit
import Vision

final class CameraSessionController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    enum AuthorizationState: Equatable {
        case unknown
        case authorized
        case denied
        case unavailable
    }

    let session = AVCaptureSession()

    @Published private(set) var authorizationState: AuthorizationState = .unknown
    @Published private(set) var depthGuidanceAvailable = false
    @Published private(set) var observedQuality = ScanQuality.preview
    @Published private(set) var hasBufferedFrame = false
    @Published private(set) var latestFrameID = 0

    private let ciContext = CIContext()
    private let sessionQueue = DispatchQueue(label: "DermaLens.camera.session")
    private let frameQueue = DispatchQueue(label: "DermaLens.camera.frames")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false
    private var frameCounter = 0
    private var lastFaceCenter: CGPoint?
    private var latestFrameData: Data?
    private var latestBufferedFrameID = 0

    func requestAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorizationState = .authorized
            configureSessionIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationState = granted ? .authorized : .denied
                }
                if granted {
                    self?.configureSessionIfNeeded()
                }
            }
        case .denied, .restricted:
            authorizationState = .denied
        @unknown default:
            authorizationState = .unavailable
        }
    }

    func startSession() {
        sessionQueue.async { [session] in
            guard !session.isRunning else { return }
            session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    private func configureSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isConfigured else {
                self.startSession()
                return
            }

            let trueDepth = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
            let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            guard let camera = trueDepth ?? wide else {
                DispatchQueue.main.async { self.authorizationState = .unavailable }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async { self.authorizationState = .unavailable }
                    return
                }

                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                ]
                self.videoOutput.setSampleBufferDelegate(self, queue: self.frameQueue)
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                }

                self.session.commitConfiguration()
                self.isConfigured = true

                DispatchQueue.main.async {
                    self.depthGuidanceAvailable = trueDepth != nil
                    self.observedQuality = ScanQuality(
                        lighting: self.observedQuality.lighting,
                        alignment: self.observedQuality.alignment,
                        stability: self.observedQuality.stability,
                        clarity: self.observedQuality.clarity,
                        depthGuidanceAvailable: trueDepth != nil
                    )
                }
                self.startSession()
            } catch {
                DispatchQueue.main.async { self.authorizationState = .unavailable }
            }
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        frameCounter += 1
        guard frameCounter % 8 == 0 else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let luminance = luminanceMetrics(from: pixelBuffer)
        let face = faceMetrics(from: sampleBuffer)
        latestFrameData = jpegData(from: pixelBuffer)
        latestBufferedFrameID = frameCounter
        let hasFrame = latestFrameData != nil
        let frameID = latestBufferedFrameID
        let quality = ScanQuality(
            lighting: luminance.lighting,
            alignment: face.alignment,
            stability: face.stability,
            clarity: luminance.clarity,
            depthGuidanceAvailable: depthGuidanceAvailable
        )

        DispatchQueue.main.async {
            self.observedQuality = quality
            self.hasBufferedFrame = hasFrame
            self.latestFrameID = frameID
        }
    }

    private func luminanceMetrics(from pixelBuffer: CVPixelBuffer) -> (lighting: Double, clarity: Double) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return (0.7, 0.7)
        }

        let buffer = base.assumingMemoryBound(to: UInt8.self)
        let xStep = max(1, width / 48)
        let yStep = max(1, height / 48)
        var count = 0.0
        var sum = 0.0
        var squaredSum = 0.0

        for y in stride(from: 0, to: height, by: yStep) {
            let row = buffer + y * bytesPerRow
            for x in stride(from: 0, to: width, by: xStep) {
                let value = Double(row[x]) / 255.0
                sum += value
                squaredSum += value * value
                count += 1
            }
        }

        guard count > 0 else { return (0.7, 0.7) }
        let mean = sum / count
        let variance = max(0, squaredSum / count - mean * mean)
        return ScanQualityEstimator.luminanceMetrics(from: LuminanceSample(mean: mean, variance: variance))
    }

    private func faceMetrics(from sampleBuffer: CMSampleBuffer) -> (alignment: Double, stability: Double) {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .leftMirrored,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            return (0.45, 0.55)
        }

        guard let face = request.results?.first else {
            lastFaceCenter = nil
            return ScanQualityEstimator.faceMetrics(current: nil, previousCenter: nil)
        }

        let center = CGPoint(x: face.boundingBox.midX, y: face.boundingBox.midY)
        let metrics = ScanQualityEstimator.faceMetrics(
            current: FaceObservationSample(center: center, height: Double(face.boundingBox.height)),
            previousCenter: lastFaceCenter
        )
        lastFaceCenter = center
        return metrics
    }

    func makeScanFrame(regionHint: FaceRegion?, minimumFreshFrameID: Int? = nil) -> ScanFrame? {
        var frameData: Data?
        var sourceFrameID = 0
        frameQueue.sync {
            frameData = latestFrameData
            sourceFrameID = latestBufferedFrameID
        }

        guard let frameData else { return nil }
        let verificationStatus = verificationStatus(
            for: regionHint,
            sourceFrameID: sourceFrameID,
            minimumFreshFrameID: minimumFreshFrameID
        )
        return ScanFrame(
            capturedAt: Date(),
            jpegData: frameData,
            regionHint: regionHint,
            qualitySnapshot: observedQuality,
            sourceFrameID: sourceFrameID,
            verificationStatus: verificationStatus
        )
    }

    func makeScanCapture(frames capturedFrames: [ScanFrame] = []) -> ScanCapture {
        let frames = capturedFrames.isEmpty
            ? makeScanFrame(regionHint: nil).map { [$0] } ?? []
            : capturedFrames
        clearBufferedFrame()

        return ScanCapture(
            createdAt: Date(),
            quality: observedQuality,
            frames: frames,
            deviceModel: UIDevice.current.model
        )
    }

    func clearBufferedFrame() {
        frameQueue.async { [weak self] in
            self?.latestFrameData = nil
            self?.latestBufferedFrameID = 0
            DispatchQueue.main.async {
                self?.hasBufferedFrame = false
                self?.latestFrameID = 0
            }
        }
    }

    private func verificationStatus(
        for regionHint: FaceRegion?,
        sourceFrameID: Int,
        minimumFreshFrameID: Int?
    ) -> ScanFrameVerificationStatus {
        guard regionHint != nil else { return .unverified }
        guard minimumFreshFrameID == nil || sourceFrameID > (minimumFreshFrameID ?? 0) else {
            return .staleGuidedCapture
        }
        guard observedQuality.isUsableForAnalysis else {
            return .lowQualityGuidedCapture
        }
        return .freshGuidedCapture
    }

    private func jpegData(from pixelBuffer: CVPixelBuffer) -> Data? {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let oriented = image.oriented(.leftMirrored)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        return ciContext.jpegRepresentation(
            of: oriented,
            colorSpace: colorSpace,
            options: [:]
        )
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraSessionController

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = camera.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = camera.session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
