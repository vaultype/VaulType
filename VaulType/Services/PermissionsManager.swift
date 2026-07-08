import AppKit
import AVFoundation
import Observation
import os

@Observable
final class PermissionsManager {
    // MARK: - State

    /// Whether text injection permission has been granted.
    /// App Store builds are clipboard-only and never use post-event APIs
    /// (Guideline 2.4.5), so this is always false there.
    #if APPSTORE
    private(set) var accessibilityEnabled: Bool = false
    #else
    private(set) var accessibilityEnabled: Bool = AXIsProcessTrusted()
    #endif

    // MARK: - Accessibility

    /// Check the current permission state.
    func refreshAccessibilityStatus() {
        #if !APPSTORE
        accessibilityEnabled = AXIsProcessTrusted()
        #endif
    }

    // MARK: - Microphone

    /// Request microphone access (shows system dialog).
    func requestMicrophoneAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            Logger.general.info("Microphone access \(granted ? "granted" : "denied")")
        }
    }

    #if !APPSTORE
    // MARK: - Accessibility Settings

    /// Open System Settings to the Accessibility pane.
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    #endif
}
