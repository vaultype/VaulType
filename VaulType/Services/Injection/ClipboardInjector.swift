import AppKit
import CoreGraphics
import Foundation
import os

/// Injects text by copying to clipboard and simulating Cmd+V paste.
/// Preserves and restores the original clipboard contents when possible.
final class ClipboardInjector: @unchecked Sendable {
    // MARK: - Text Injection

    /// Inject text via clipboard paste operation.
    /// - Parameter text: The text to inject.
    /// - Throws: TextInjectionError if clipboard or paste operation fails.
    func inject(_ text: String) async throws {
        #if APPSTORE
        // App Store builds never post synthetic events (Guideline 2.4.5).
        // Plain copy — the user pastes with Cmd+V; no snapshot/restore because
        // restoring at an unknown time would overwrite the dictated text.
        Logger.injection.info("Clipboard injection started for \(text.count) characters")

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            Logger.injection.error("Failed to write text to clipboard")
            throw TextInjectionError.clipboardOperationFailed
        }

        Logger.injection.info("Clipboard injection completed (text on clipboard — Cmd+V to paste)")
        #else
        Logger.injection.info("Clipboard injection started for \(text.count) characters")

        // Step 1: Save current clipboard state by deep-copying data.
        // NSPasteboardItem references are invalidated after clearContents(),
        // so we must snapshot the raw data for each type before clearing.
        let pasteboard = NSPasteboard.general
        let originalChangeCount = pasteboard.changeCount
        let savedData: [[(NSPasteboard.PasteboardType, Data)]] = (pasteboard.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in
                guard let data = item.data(forType: type) else { return nil }
                return (type, data)
            }
        }

        Logger.injection.debug("Saved clipboard state (changeCount: \(originalChangeCount), items: \(savedData.count))")

        do {
            // Step 2: Clear and write new text to clipboard
            pasteboard.clearContents()
            let success = pasteboard.setString(text, forType: .string)

            guard success else {
                Logger.injection.error("Failed to write text to clipboard")
                throw TextInjectionError.clipboardOperationFailed
            }

            Logger.injection.debug("Text written to clipboard")

            // Step 3: Simulate Cmd+V paste (requires accessibility permission)
            let canSimulatePaste = AXIsProcessTrusted()
            if canSimulatePaste {
                try await simulatePaste()

                // Step 4: Wait for paste to complete
                try await Task.sleep(for: .milliseconds(100))

                // Step 5: Restore original clipboard if it hasn't changed
                if pasteboard.changeCount == originalChangeCount + 1 {
                    restoreClipboard(pasteboard: pasteboard, savedData: savedData)
                } else {
                    Logger.injection.debug("Clipboard changed during paste — skipping restore")
                }

                Logger.injection.info("Clipboard injection completed (pasted)")
            } else {
                // No accessibility — text is on clipboard, user can Cmd+V manually
                Logger.injection.info("Clipboard injection completed (text on clipboard — Cmd+V to paste)")
            }

        } catch {
            // Attempt to restore clipboard even on failure
            if pasteboard.changeCount == originalChangeCount + 1 {
                restoreClipboard(pasteboard: pasteboard, savedData: savedData)
            }
            throw error
        }
        #endif
    }

    #if !APPSTORE
    // MARK: - Clipboard Restore

    /// Restore clipboard from deep-copied data snapshot.
    private func restoreClipboard(pasteboard: NSPasteboard, savedData: [[(NSPasteboard.PasteboardType, Data)]]) {
        guard !savedData.isEmpty else { return }
        pasteboard.clearContents()
        for itemData in savedData {
            let newItem = NSPasteboardItem()
            for (type, data) in itemData {
                newItem.setData(data, forType: type)
            }
            pasteboard.writeObjects([newItem])
        }
        Logger.injection.debug("Original clipboard restored")
    }

    // MARK: - Paste Simulation

    /// Simulate Cmd+V keyboard shortcut using CGEvent.
    private func simulatePaste() async throws {
        Logger.injection.debug("Simulating Cmd+V paste")

        // Create event source
        guard let eventSource = CGEventSource(stateID: .combinedSessionState) else {
            Logger.injection.error("Failed to create CGEventSource for paste")
            throw TextInjectionError.eventCreationFailed
        }

        // Key code for 'V' key (9)
        let vKeyCode: CGKeyCode = 9

        // Create key down event with Command modifier
        guard let keyDownEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: vKeyCode, keyDown: true) else {
            Logger.injection.error("Failed to create Cmd+V key down event")
            throw TextInjectionError.eventCreationFailed
        }

        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: vKeyCode, keyDown: false) else {
            Logger.injection.error("Failed to create Cmd+V key up event")
            throw TextInjectionError.eventCreationFailed
        }

        // Set Command modifier flag
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand

        // Post events
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)

        Logger.injection.debug("Cmd+V paste simulated")
    }
    #endif
}
