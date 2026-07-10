//
//  MenuBarView.swift
//  VaulType
//
//  Created by Claude on 14.02.2026.
//

import SwiftUI
import os.log

struct MenuBarView: View {
    var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    /// Dismisses the MenuBarExtra popup — window-style popups do not
    /// auto-close when a button inside them is clicked.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Status Section
            VStack(alignment: .leading, spacing: 6) {
                if appState.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text("Recording...")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Status: Recording")
                } else if appState.isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text("Processing...")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Status: Processing transcription")
                } else {
                    Text("Ready")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Status: Ready")
                }

                // Active mode indicator
                HStack(spacing: 6) {
                    Image(systemName: appState.activeMode.iconName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(appState.activeMode.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Language indicator
                    if let lang = appState.detectedLanguage {
                        Text(lang.uppercased())
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    appState.detectedLanguage.map { lang in
                        "Mode: \(appState.activeMode.displayName), Language: \(lang.uppercased())"
                    } ?? "Mode: \(appState.activeMode.displayName)"
                )
            }

            Divider()

            // MARK: - Last Transcription Preview
            if let preview = appState.lastTranscriptionPreview, !preview.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Transcription")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(truncatePreview(preview))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last transcription: \(truncatePreview(preview))")

                Divider()
            }

            // MARK: - Error Display
            if let error = appState.currentError {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        Text("Error")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error: \(error)")

                Divider()
            }

            // MARK: - Action Buttons
            VStack(spacing: 8) {
                Button {
                    dismiss()
                    openWindow(id: "history")
                    Self.raiseWindow { $0.title == "Dictation History" }
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("h", modifiers: .command)
                .accessibilityLabel("History")
                .accessibilityHint("Opens the dictation history window")

                Button {
                    dismiss()
                    openSettings()
                    Self.raiseWindow { window in
                        window.identifier?.rawValue.contains("Settings") == true
                    }
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Settings")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)
                .foregroundStyle(.primary)
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens the VaulType settings window")

                Button {
                    quitApp()
                } label: {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit VaulType")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q", modifiers: .command)
                .foregroundStyle(.red)
                .accessibilityLabel("Quit VaulType")
                .accessibilityHint("Exits the application")
            }
        }
        .padding(12)
        .frame(width: 280)
    }

    // MARK: - Helper Methods

    /// Bring a just-opened window above other apps' windows.
    ///
    /// Menu bar apps run with the `.accessory` activation policy, so opening a
    /// window does not activate the app and the window can appear behind the
    /// frontmost app. SwiftUI also creates the window asynchronously, so retry
    /// briefly until it exists.
    private static func raiseWindow(matching predicate: @escaping (NSWindow) -> Bool) {
        for delay: TimeInterval in [0.05, 0.2, 0.5] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: predicate) {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
            }
        }
    }

    private func truncatePreview(_ text: String) -> String {
        let maxLength = 120
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "..."
    }

    private func quitApp() {
        Logger.general.info("User requested quit from menu bar")
        NSApp.terminate(nil)
    }
}

#Preview {
    MenuBarView(appState: AppState())
}
