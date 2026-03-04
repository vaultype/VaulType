import AVFoundation
import os
import SwiftData
import SwiftUI

/// First-launch onboarding wizard guiding users through setup.
struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var permissionsManager = PermissionsManager()
    @State private var microphoneGranted: Bool = false
    @State private var pollingTimer: Timer?
    @State private var whisperDownloader = ModelDownloader()
    @State private var llmDownloader = ModelDownloader()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var allModels: [ModelInfo]

    /// The default whisper model, looked up from the full model list.
    private var defaultWhisperModel: ModelInfo? {
        allModels.first { $0.isDefault && $0.type == .whisper }
    }

    /// The default LLM model, looked up from the full model list.
    private var defaultLLMModel: ModelInfo? {
        allModels.first { $0.isDefault && $0.type == .llm }
    }

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .accessibilityLabel(step < currentStep ? "Step \(step + 1) completed" : step == currentStep ? "Step \(step + 1), current" : "Step \(step + 1)")
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Setup progress: step \(currentStep + 1) of \(totalSteps)")

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: microphoneStep
                case 2: accessibilityStep
                case 3: modelDownloadStep
                default: completionStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation buttons
            HStack {
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    Button("Back") {
                        if reduceMotion { currentStep -= 1 } else { withAnimation { currentStep -= 1 } }
                    }
                    .accessibilityLabel("Back")
                    .accessibilityHint("Goes to the previous setup step")
                }

                Spacer()

                if currentStep == 3 && !bothModelsReady && !isDownloading {
                    Button("Download Later") {
                        if reduceMotion { currentStep += 1 } else { withAnimation { currentStep += 1 } }
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Download later")
                    .accessibilityHint("Skips model download. You can download models later in Settings.")
                } else if currentStep < totalSteps - 1 {
                    Button("Continue") {
                        if reduceMotion { currentStep += 1 } else { withAnimation { currentStep += 1 } }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 3 && !bothModelsReady)
                    .accessibilityLabel("Continue")
                    .accessibilityHint("Proceeds to the next setup step")
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Get started")
                    .accessibilityHint("Completes the setup and opens VaulType")
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 480)
        .onAppear {
            refreshMicrophoneStatus()
            permissionsManager.refreshAccessibilityStatus()
        }
        .onChange(of: currentStep) { _, newStep in
            stopPolling()
            if newStep == 1 || newStep == 2 {
                startPolling()
            }
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        OnboardingStepView(
            iconName: "waveform.circle.fill",
            title: "Welcome to VaulType",
            description: "Privacy-first speech-to-text that runs entirely on your device. No cloud, no telemetry — just your voice and your machine."
        )
    }

    private var microphoneStep: some View {
        VStack(spacing: 20) {
            Spacer()

            if microphoneGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.green)
            } else {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
            }

            Text("Microphone Access")
                .font(.title)
                .fontWeight(.bold)

            Text("VaulType needs microphone access to capture your voice. All audio is processed locally and never leaves your device.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            if microphoneGranted {
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                    .font(.callout)
                    .accessibilityLabel("Microphone access granted")
            } else {
                Button("Grant Microphone Access") {
                    permissionsManager.requestMicrophoneAccess()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Grant microphone access")
                .accessibilityHint("Opens the system permission dialog to allow VaulType to use the microphone")

                Text("Microphone access is required for dictation. You can grant it later in System Settings.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var accessibilityStep: some View {
        VStack(spacing: 20) {
            Spacer()

            if permissionsManager.accessibilityEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.green)
            } else {
                Image(systemName: "accessibility.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
            }

            #if APPSTORE
            Text("Text Input Permission")
                .font(.title)
                .fontWeight(.bold)

            Text("VaulType needs permission to simulate keystrokes so it can type transcribed text into any app.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            if permissionsManager.accessibilityEnabled {
                Label("Text input permission granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                    .font(.callout)
                    .accessibilityLabel("Text input permission granted")
            } else {
                Button("Grant Text Input Permission") {
                    permissionsManager.requestPostEventAccess()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Grant text input permission")
                .accessibilityHint("Shows a system dialog to allow VaulType to type text into applications")

                Text("Without this permission, text will be copied to clipboard instead of typed directly. You can grant it later in System Settings.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }
            #else
            Text("Accessibility Permission")
                .font(.title)
                .fontWeight(.bold)

            Text("Accessibility permission enables VaulType to type text into any app and manage windows via voice commands.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            if permissionsManager.accessibilityEnabled {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                    .font(.callout)
                    .accessibilityLabel("Accessibility access granted")
            } else {
                Button("Open Accessibility Settings") {
                    permissionsManager.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Open Accessibility Settings")
                .accessibilityHint("Opens System Settings so you can grant VaulType accessibility permission for text injection and window management")

                Text("Without accessibility permission, text injection may be limited. You can grant it later in System Settings.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }
            #endif

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var modelDownloadStep: some View {
        VStack(spacing: 20) {
            Spacer()

            if bothModelsReady {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.green)
            } else if isDownloading {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
            }

            Text("Download Models")
                .font(.title)
                .fontWeight(.bold)

            if bothModelsReady {
                Text("Models are ready. You're good to go!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            } else if isDownloading {
                Text("Downloading required models. This may take a minute depending on your connection.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            } else {
                Text("VaulType needs two small AI models to work — one for speech recognition (~150 MB) and one for text processing (~460 MB). Everything runs locally on your device.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            if bothModelsReady || isDownloading {
                VStack(spacing: 12) {
                    modelProgressRow(model: defaultWhisperModel, label: "Speech Model")
                    modelProgressRow(model: defaultLLMModel, label: "Text Processing Model")
                }
                .frame(maxWidth: 340)
            } else if hasDownloadError {
                VStack(spacing: 12) {
                    modelProgressRow(model: defaultWhisperModel, label: "Speech Model")
                    modelProgressRow(model: defaultLLMModel, label: "Text Processing Model")

                    Button("Retry Download") {
                        startModelDownloads()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: 340)
            } else {
                Button("Download Now") {
                    startModelDownloads()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Download models now")
                .accessibilityHint("Downloads the required speech and text processing models")
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var bothModelsReady: Bool {
        let whisperReady = defaultWhisperModel?.fileExistsOnDisk ?? false
        let llmReady = defaultLLMModel?.fileExistsOnDisk ?? false
        return whisperReady && llmReady
    }

    private var isDownloading: Bool {
        let whisperDownloading = defaultWhisperModel?.downloadProgress != nil
        let llmDownloading = defaultLLMModel?.downloadProgress != nil
        return whisperDownloading || llmDownloading
    }

    private var hasDownloadError: Bool {
        let whisperError = defaultWhisperModel?.lastDownloadError != nil
        let llmError = defaultLLMModel?.lastDownloadError != nil
        return (whisperError || llmError) && !isDownloading
    }

    @ViewBuilder
    private func modelProgressRow(model: ModelInfo?, label: String) -> some View {
        if let model {
            if model.fileExistsOnDisk {
                Label("\(model.name) is ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                    .font(.callout)
            } else if let progress = model.downloadProgress {
                VStack(spacing: 4) {
                    ProgressView(value: progress)
                    Text("Downloading \(model.name)… \(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let errorMsg = model.lastDownloadError {
                Label("\(label): \(errorMsg)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            } else {
                Label(model.name, systemImage: "circle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }

    private var completionStep: some View {
        OnboardingStepView(
            iconName: "checkmark.circle.fill",
            title: "You're All Set!",
            description: "Press and hold the fn key to start dictating. Release to stop and inject text at your cursor. You can customize everything in Settings."
        )
    }

    // MARK: - Permission Polling

    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshMicrophoneStatus()
            permissionsManager.refreshAccessibilityStatus()
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func refreshMicrophoneStatus() {
        microphoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    // MARK: - Model Downloads

    private func startModelDownloads() {
        if let model = defaultWhisperModel, !model.fileExistsOnDisk, model.downloadProgress == nil {
            whisperDownloader.download(model)
        }
        if let model = defaultLLMModel, !model.fileExistsOnDisk, model.downloadProgress == nil {
            llmDownloader.download(model)
        }
    }

    // MARK: - Completion

    private func completeOnboarding() {
        stopPolling()
        UserDefaults.standard.set(true, forKey: "com.vaultype.onboardingCompleted")
        Logger.ui.info("Onboarding completed")
        dismiss()
    }
}

#Preview {
    OnboardingView()
}
