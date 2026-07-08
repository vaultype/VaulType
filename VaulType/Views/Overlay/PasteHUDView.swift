import AppKit
import SwiftUI
import os

/// Compact HUD shown after a dictation lands on the clipboard, prompting the
/// user to paste manually. Used by App Store builds, where text delivery is
/// clipboard-only (Guideline 2.4.5 — no synthetic keystrokes).
struct PasteHUDView: View {
    var appState: AppState

    var body: some View {
        Label("Copied — press ⌘V to paste", systemImage: "doc.on.clipboard.fill")
            .font(.callout)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if appState.prefersReducedTransparency {
                    Capsule().fill(Color(NSColor.windowBackgroundColor))
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
            .overlay(
                Capsule()
                    .stroke(
                        appState.prefersHighContrast
                            ? Color.primary.opacity(0.5)
                            : Color.primary.opacity(0.1),
                        lineWidth: appState.prefersHighContrast ? 2 : 1
                    )
            )
            .accessibilityLabel("Transcription copied to clipboard. Press Command V to paste.")
    }
}

/// Floating non-activating panel hosting PasteHUDView. Owned by AppDelegate.
final class PasteHUDWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 44),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        animationBehavior = .utilityWindow
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        Logger.ui.info("PasteHUDWindow initialized")
    }

    /// Set the SwiftUI content view with app state binding.
    func setContent(appState: AppState) {
        let hosting = NSHostingView(rootView: PasteHUDView(appState: appState))
        hosting.frame = contentRect(forFrameRect: frame)
        contentView = hosting
    }

    /// Show the HUD centered near the bottom of the main screen.
    func showHUD() {
        guard let screen = NSScreen.main else { return }
        // Size to fit the hosted capsule before positioning
        if let contentView {
            let fitting = contentView.fittingSize
            setContentSize(fitting)
        }
        let screenFrame = screen.visibleFrame
        let windowSize = frame.size
        setFrameOrigin(NSPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.minY + 40
        ))
        orderFrontRegardless()
    }

    /// Hide the HUD.
    func hideHUD() {
        orderOut(nil)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
