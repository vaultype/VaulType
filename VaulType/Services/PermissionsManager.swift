import AppKit
import AVFoundation
import Observation
import os

@Observable
final class PermissionsManager {
    // MARK: - State

    /// Whether text injection permission has been granted.
    /// App Store builds use PostEvent TCC; direct distribution uses full Accessibility.
    #if APPSTORE
    private(set) var accessibilityEnabled: Bool = CGPreflightPostEventAccess()
    #else
    private(set) var accessibilityEnabled: Bool = AXIsProcessTrusted()
    #endif

    // MARK: - Accessibility

    /// Check the current permission state.
    func refreshAccessibilityStatus() {
        #if APPSTORE
        accessibilityEnabled = CGPreflightPostEventAccess()
        #else
        accessibilityEnabled = AXIsProcessTrusted()
        #endif
    }

    #if APPSTORE
    /// Request PostEvent permission (shows system TCC dialog).
    func requestPostEventAccess() {
        CGRequestPostEventAccess()
    }
    #endif

    // MARK: - Microphone

    /// Request microphone access (shows system dialog).
    func requestMicrophoneAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            Logger.general.info("Microphone access \(granted ? "granted" : "denied")")
        }
    }

    // MARK: - Accessibility Settings

    /// Open System Settings to the Accessibility pane.
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
