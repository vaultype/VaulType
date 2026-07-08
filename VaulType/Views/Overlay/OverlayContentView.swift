import SwiftUI
import os

/// SwiftUI content view displayed inside the OverlayWindow.
/// Shows transcription result with optional edit-before-inject capability.
struct OverlayContentView: View {
    var appState: AppState

    @State private var editableText: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerBar

            Divider()

            // MARK: - Content
            if let text = appState.overlayText, !text.isEmpty {
                if isEditing {
                    editView
                } else {
                    displayView(text: text)
                }
            } else if appState.isProcessing {
                processingView
            } else {
                emptyView
            }

            Divider()

            // MARK: - Footer Controls
            footerBar
        }
        .frame(width: 420)
        .frame(minHeight: 120)
        .background {
            if appState.prefersReducedTransparency {
                Color(NSColor.windowBackgroundColor)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    appState.prefersHighContrast
                        ? Color.primary.opacity(0.5)
                        : Color.primary.opacity(0.1),
                    lineWidth: appState.prefersHighContrast ? 2 : 1
                )
        )
        .onChange(of: appState.overlayText ?? "") { oldValue, newValue in
            if !newValue.isEmpty {
                editableText = newValue
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 8) {
            // Mode indicator
            HStack(spacing: 4) {
                Image(systemName: appState.activeMode.iconName)
                    .font(.caption2)
                Text(appState.activeMode.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)

            // Language indicator
            if let lang = appState.detectedLanguage {
                Text(lang.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            // Status
            if appState.isProcessing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                    Text("Processing...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Display View (read-only)

    private func displayView(text: String) -> some View {
        ScrollView {
            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Edit View

    private var editView: some View {
        TextEditor(text: $editableText)
            .font(.body)
            .focused($textFieldFocused)
            .frame(maxHeight: 200)
            .padding(6)
            .scrollContentBackground(.hidden)
            .accessibilityLabel("Edit transcription text")
            .accessibilityHint("Modify the transcription before injecting")
            .onAppear {
                textFieldFocused = true
            }
    }

    // MARK: - Processing View

    private var processingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Transcribing...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(14)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        Text("Waiting for transcription...")
            .font(.body)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(14)
    }

    // MARK: - Footer

    // App Store builds deliver text via the clipboard (no synthetic keystrokes),
    // so the confirm action is a copy rather than an injection.
    #if APPSTORE
    private static let confirmTitle = "Copy"
    private static let confirmEditedLabel = "Copy edited text"
    private static let confirmEditedHint = "Copies your edited text to the clipboard so you can paste it with Command V"
    private static let confirmLabel = "Copy transcription"
    private static let confirmHint = "Copies the transcribed text to the clipboard so you can paste it with Command V"
    private static let editHint = "Opens the text editor to modify the transcription before copying"
    private static let dismissHint = "Closes this panel without copying text"
    #else
    private static let confirmTitle = "Inject"
    private static let confirmEditedLabel = "Inject edited text"
    private static let confirmEditedHint = "Types your edited text at the cursor position"
    private static let confirmLabel = "Inject transcription"
    private static let confirmHint = "Types the transcribed text at the cursor position"
    private static let editHint = "Opens the text editor to modify the transcription before injecting"
    private static let dismissHint = "Closes this panel without injecting text"
    #endif

    private var footerBar: some View {
        HStack(spacing: 10) {
            if isEditing {
                Button("Cancel") {
                    appState.overlayEditCancelled = true
                    isEditing = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                .accessibilityLabel("Cancel edit")
                .accessibilityHint("Discards your edits and cancels injection")

                Spacer()

                Button(Self.confirmTitle) {
                    appState.overlayEditedText = editableText
                    appState.overlayEditConfirmed = true
                    isEditing = false
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel(Self.confirmEditedLabel)
                .accessibilityHint(Self.confirmEditedHint)
            } else {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .controlSize(.small)
                .keyboardShortcut("e", modifiers: .command)
                .disabled(appState.overlayText == nil)
                .accessibilityLabel("Edit transcription")
                .accessibilityHint(Self.editHint)

                Spacer()

                Button("Dismiss") {
                    appState.showOverlay = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                .controlSize(.small)
                .accessibilityLabel("Dismiss overlay")
                .accessibilityHint(Self.dismissHint)

                Button(Self.confirmTitle) {
                    appState.overlayEditConfirmed = true
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(appState.overlayText == nil)
                .accessibilityLabel(Self.confirmLabel)
                .accessibilityHint(Self.confirmHint)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
