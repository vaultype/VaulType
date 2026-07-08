#if !APPSTORE
import Sparkle
#endif
import SwiftUI

struct AboutSettingsTab: View {
    #if !APPSTORE
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
    }
    #endif

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("VaulType")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Privacy-first speech-to-text for macOS")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            #if !APPSTORE
            Button("Check for Updates…") {
                updater.checkForUpdates()
            }
            .accessibilityHint("Checks if a newer version of VaulType is available")
            #endif

            VStack(spacing: 12) {
                #if !APPSTORE
                // The landing page's primary CTA is the direct download —
                // keep it out of the App Store build (Guideline 2.3.10).
                Link(destination: URL(string: "https://vaultype.app")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Website")
                    }
                }
                .accessibilityLabel("Visit VaulType website")
                #endif

                Link(destination: URL(string: "https://github.com/vaultype/VaulType")!) {
                    HStack {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("Source Code")
                    }
                }
                .accessibilityLabel("View source code on GitHub")

                Link(destination: URL(string: "https://vaultype.app/security/legal/#4-privacy-policy")!) {
                    HStack {
                        Image(systemName: "hand.raised")
                        Text("Privacy Policy")
                    }
                }
                .accessibilityLabel("Read privacy policy")
            }
            .buttonStyle(.link)

            Spacer()

            VStack(spacing: 4) {
                Text("Open Source (AGPL-3.0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\u{00A9} 2026 VaulType. All rights reserved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
