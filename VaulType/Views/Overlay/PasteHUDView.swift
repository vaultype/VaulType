import AppKit
import SwiftUI
import os

/// Compact transient HUD for short status messages — the "Copied — press ⌘V
/// to paste" reminder (App Store clipboard-only delivery) and errors that need
/// a visible surface (e.g. microphone permission denied).
struct StatusHUDView: View {
    var appState: AppState

    var body: some View {
        // Render nothing when there is no content — the panel hides
        // asynchronously, and an empty capsule must not flash meanwhile.
        if let content = appState.statusHUD {
            Label(content.text, systemImage: content.systemImage)
                .font(.callout)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: 560)
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
                .contentShape(Capsule())
                .onTapGesture {
                    guard let url = content.openURLOnClick else { return }
                    NSWorkspace.shared.open(url)
                    appState.statusHUD = nil
                }
                .accessibilityLabel(content.text)
                .accessibilityAddTraits(content.openURLOnClick != nil ? .isButton : [])
        }
    }
}

/// Floating non-activating panel hosting StatusHUDView. Owned by AppDelegate.
final class StatusHUDWindow: NSPanel {
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

        Logger.ui.info("StatusHUDWindow initialized")
    }

    /// Set the SwiftUI content view with app state binding.
    func setContent(appState: AppState) {
        let hosting = NSHostingView(rootView: StatusHUDView(appState: appState))
        hosting.frame = contentRect(forFrameRect: frame)
        contentView = hosting
    }

    /// Show the HUD centered near the bottom of the main screen.
    /// - Parameter interactive: When true the panel accepts clicks (actionable
    ///   HUDs like permission errors); otherwise it stays click-through so it
    ///   never blocks the app underneath (paste reminder).
    func showHUD(interactive: Bool = false) {
        ignoresMouseEvents = !interactive
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
