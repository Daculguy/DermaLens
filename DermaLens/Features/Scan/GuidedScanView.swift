import SwiftUI

struct GuidedScanView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var camera = CameraSessionController()

    @State private var scanProgress = 0.0
    @State private var isAnimatingScan = false
    @State private var showingQualityWarning = false
    @State private var qualityWarningMessage = "Adjust lighting, alignment, stability, and clarity before scanning."
    @State private var activeScanStep = GuidedScanStep.baselineSequence.first
    @State private var completedRegions: Set<FaceRegion> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    scanner
                    scanPathPanel
                    qualityPanel
                    qualityWarnings
                    consentPanel
                    actionPanel
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .appBackground()
            .navigationTitle("Guided Scan")
            .task {
                camera.requestAndConfigure()
            }
            .onAppear {
                camera.startSession()
            }
            .onDisappear {
                camera.stopSession()
            }
            .alert("Improve scan quality", isPresented: $showingQualityWarning) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(qualityWarningMessage)
            }
        }
    }

    private var scanner: some View {
        ZStack {
            cameraLayer

            RoundedRectangle(cornerRadius: 150, style: .continuous)
                .stroke(.white.opacity(0.82), lineWidth: 2)
                .frame(width: 230, height: 310)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)

            VStack {
                HStack {
                    scannerBadge("Light", value: currentQuality.lighting, symbol: "sun.max")
                    Spacer()
                    scannerBadge("Frame", value: camera.depthGuidanceAvailable ? 0.94 : 0.72, symbol: "camera.viewfinder")
                }
                Spacer()
                progressStrip
            }
            .padding(16)
        }
        .frame(height: 430)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .bottom) {
            Text("Keep your face centered, remove glasses, and use soft front light.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.38))
                .clipShape(Capsule())
                .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private var cameraLayer: some View {
        switch camera.authorizationState {
        case .authorized:
            CameraPreview(camera: camera)
        case .denied:
            fallbackLayer(
                title: "Camera permission needed",
                subtitle: "Enable camera access to run a real guided scan.",
                symbol: "camera.badge.ellipsis"
            )
        case .unavailable:
            fallbackLayer(
                title: "Camera unavailable",
                subtitle: "The simulator can still preview the scan flow.",
                symbol: "video.slash"
            )
        case .unknown:
            fallbackLayer(
                title: "Preparing camera",
                subtitle: "Checking the front camera and framing assist.",
                symbol: "viewfinder"
            )
        }
    }

    private func fallbackLayer(title: String, subtitle: String, symbol: String) -> some View {
        ZStack {
            LinearGradient(
                colors: [Theme.moss, Theme.leaf, Theme.panel],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func scannerBadge(_ title: String, value: Double, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            Text("\(title) \(Int(value * 100))")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.32))
        .clipShape(Capsule())
    }

    private var progressStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(progressTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(scanProgress * 100))%")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.24))
                    Capsule()
                        .fill(.white)
                        .frame(width: max(12, proxy.size.width * scanProgress))
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(.black.opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var progressTitle: String {
        if appState.isScanning {
            return "Building cosmetic skin report"
        }
        if isAnimatingScan, let activeScanStep {
            return "Capturing \(activeScanStep.title)"
        }
        return "Ready for baseline"
    }

    private var scanPathPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Complete scan pass",
                subtitle: activeScanStep?.instruction ?? "Capture each guided region before analysis."
            )

            FlowLayout(spacing: 8) {
                ForEach(GuidedScanStep.baselineSequence) { step in
                    ScanStepChip(
                        step: step,
                        isActive: activeScanStep?.region == step.region && isAnimatingScan,
                        isComplete: completedRegions.contains(step.region)
                    )
                }
            }

            Label(
                camera.hasBufferedFrame ? "Camera evidence is ready for the next guided region." : "Hold still until the camera has a sharp frame.",
                systemImage: camera.hasBufferedFrame ? "checkmark.seal" : "camera.aperture"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(camera.hasBufferedFrame || camera.authorizationState != .authorized ? Theme.moss : Theme.amber)
        }
        .softCard(padding: 14)
    }

    private var qualityPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Capture quality", subtitle: "These gates make the skin report more repeatable.")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QualityTile(title: "Lighting", value: currentQuality.lighting, symbol: "sun.max", tint: Theme.amber)
                QualityTile(title: "Alignment", value: currentQuality.alignment, symbol: "face.smiling", tint: Theme.moss)
                QualityTile(title: "Stability", value: currentQuality.stability, symbol: "gyroscope", tint: Theme.leaf)
                QualityTile(title: "Clarity", value: currentQuality.clarity, symbol: "camera.aperture", tint: Theme.lavender)
            }
        }
    }

    @ViewBuilder
    private var qualityWarnings: some View {
        let issues = currentQuality.blockingIssues
        if !issues.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Fix before scanning", subtitle: "A weak capture makes product advice less trustworthy.")

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(issues) { issue in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(issue.title)
                                    .font(.subheadline.weight(.bold))
                                Text(issue.guidance)
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                            }
                        } icon: {
                            Image(systemName: issue.symbolName)
                                .foregroundStyle(Theme.amber)
                        }
                    }
                }
                .foregroundStyle(Theme.ink)
                .softCard(padding: 14)
            }
        }
    }

    private var consentPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your scan is analyzed as a cosmetic skin report, not a medical diagnosis.", systemImage: "checkmark.shield")
            Label("Face ID biometric data is not used. Front-camera guidance only improves framing consistency.", systemImage: "camera.viewfinder")
            if appState.isRemoteAnalysisConfigured {
                Toggle(isOn: remoteAnalysisConsentBinding) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Allow remote analysis upload")
                            .font(.subheadline.weight(.semibold))
                        Text(remoteConsentDetail)
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.moss)

                Label("When off, DermaLens keeps the scan local and uses the prototype analyzer.", systemImage: "hand.raised")
            } else {
                Label("This build analyzes scans locally; raw images are not persisted.", systemImage: "trash")
            }
        }
        .font(.subheadline)
        .foregroundStyle(Theme.ink)
        .softCard(padding: 14)
    }

    private var remoteAnalysisConsentBinding: Binding<Bool> {
        Binding(
            get: { appState.remoteAnalysisConsentGranted },
            set: { appState.setRemoteAnalysisConsent($0) }
        )
    }

    private var remoteConsentDetail: String {
        RemoteAnalysisDisclosure.consentDetail(host: appState.remoteAnalyzerHost)
    }

    private var actionPanel: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: appState.isScanning ? "Building report" : "Run complete scan",
                symbolName: "sparkle.magnifyingglass",
                isLoading: appState.isScanning || isAnimatingScan,
                action: startScan
            )

            Button {
                appState.showingPaywall = true
            } label: {
                Label("Unlock ingredient-level report", systemImage: "lock")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.moss)
            }
        }
    }

    private var currentQuality: ScanQuality {
        camera.observedQuality
    }

    private func startScan() {
        guard !appState.isScanning, !isAnimatingScan else { return }
        guard camera.authorizationState == .authorized else {
            qualityWarningMessage = "Camera access is required before DermaLens can create a real scan report."
            showingQualityWarning = true
            return
        }
        guard currentQuality.isUsableForAnalysis else {
            qualityWarningMessage = currentQuality.blockingIssues.first?.guidance
                ?? "Adjust lighting, alignment, stability, and clarity before scanning."
            showingQualityWarning = true
            return
        }
        guard camera.hasBufferedFrame else {
            qualityWarningMessage = "Hold still for a moment so DermaLens can capture a sharp camera frame before analysis."
            showingQualityWarning = true
            return
        }

        Task { @MainActor in
            let scanSteps = GuidedScanStep.baselineSequence
            var capturedFrames: [ScanFrame] = []

            isAnimatingScan = true
            scanProgress = 0
            completedRegions = []

            for (index, step) in scanSteps.enumerated() {
                activeScanStep = step
                let startingFrameID = camera.latestFrameID
                for tick in 1...4 {
                    try? await Task.sleep(nanoseconds: 110_000_000)
                    withAnimation(.easeOut(duration: 0.12)) {
                        scanProgress = (Double(index) + Double(tick) / 4) / Double(scanSteps.count)
                    }
                }

                if let frame = camera.makeScanFrame(regionHint: step.region, minimumFreshFrameID: startingFrameID) {
                    capturedFrames.append(frame)
                    if frame.verificationStatus.isFreshGuidedCapture {
                        completedRegions.insert(step.region)
                    }
                }
            }

            let capture = camera.makeScanCapture(frames: capturedFrames)
            guard capture.evidenceSummary.isComplete else {
                let missingRegions = capture.evidenceSummary.requiredRegions
                    .filter { !capture.evidenceSummary.coveredRegions.contains($0) }
                    .map(\.label)
                    .joined(separator: ", ")
                qualityWarningMessage = missingRegions.isEmpty
                    ? "The guided scan needs a fresh usable frame for each region before DermaLens can build a routine."
                    : "Retake the guided scan. Missing fresh captures: \(missingRegions)."
                showingQualityWarning = true
                isAnimatingScan = false
                activeScanStep = scanSteps.first
                completedRegions = []
                scanProgress = 0
                return
            }

            let didCreateReport = await appState.runScan(with: capture)
            if !didCreateReport {
                qualityWarningMessage = "Retake the guided scan. DermaLens needs fresh captures for each guided region before it can build a report."
                showingQualityWarning = true
            }
            isAnimatingScan = false
            activeScanStep = scanSteps.first
            completedRegions = []
            scanProgress = 0
        }
    }
}

private struct ScanStepChip: View {
    var step: GuidedScanStep
    var isActive: Bool
    var isComplete: Bool

    var body: some View {
        Label(step.title, systemImage: symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(background)
            .clipShape(Capsule())
            .accessibilityValue(accessibilityValue)
    }

    private var symbolName: String {
        if isComplete { return "checkmark" }
        return step.symbolName
    }

    private var foreground: Color {
        if isComplete || isActive { return .white }
        return Theme.moss
    }

    private var background: Color {
        if isComplete { return Theme.leaf }
        if isActive { return Theme.moss }
        return Theme.moss.opacity(0.10)
    }

    private var accessibilityValue: String {
        if isComplete { return "Captured" }
        if isActive { return "Current" }
        return "Pending"
    }
}

private struct QualityTile: View {
    var title: String
    var value: Double
    var symbol: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                Spacer()
                Text("\(Int(value * 100))")
                    .font(.headline.monospacedDigit().weight(.bold))
                    .foregroundStyle(Theme.ink)
            }

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.ink)

            ProgressView(value: value)
                .tint(tint)
        }
        .softCard(padding: 14)
    }
}

#Preview {
    GuidedScanView()
        .environmentObject(AppState())
}
