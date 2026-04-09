#if !APPSTORE
import Sparkle
#endif
import SwiftUI
import SwiftData
import os

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Int = 0
    #if !APPSTORE
    let updater: SPUUpdater
    #endif

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear.circle")
                }
                .tag(0)

            AudioSettingsTab()
                .tabItem {
                    Label("Audio", systemImage: "waveform.circle")
                }
                .tag(1)

            ProcessingSettingsTab()
                .tabItem {
                    Label("Processing", systemImage: "sparkles")
                }
                .tag(2)

            ModelManagementView()
                .tabItem {
                    Label("Models", systemImage: "arrow.down.circle")
                }
                .tag(3)

            AppProfilesSettingsTab()
                .tabItem {
                    Label("App Profiles", systemImage: "apps.iphone")
                }
                .tag(4)

            VocabularySettingsTab()
                .tabItem {
                    Label("Vocabulary", systemImage: "textformat.abc")
                }
                .tag(5)

            LanguageSettingsTab()
                .tabItem {
                    Label("Language", systemImage: "globe")
                }
                .tag(6)

            HistorySettingsTab()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(7)

            CommandSettingsTab()
                .tabItem {
                    Label("Commands", systemImage: "command")
                }
                .tag(8)

            #if !APPSTORE
            PluginManagerView(pluginManager: appState.pluginManager)
                .tabItem {
                    Label("Plugins", systemImage: "puzzlepiece.extension")
                }
                .tag(9)
            #endif

            #if !APPSTORE
            AboutSettingsTab(updater: updater)
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(10)
            #else
            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(10)
            #endif
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            selectedTab = 0
            Logger.ui.info("Settings window opened")
        }
    }
}

#if APPSTORE
#Preview {
    SettingsView()
        .environment(AppState())
        .modelContainer(for: [
            UserSettings.self, ModelInfo.self, PromptTemplate.self,
            AppProfile.self, VocabularyEntry.self, DictationEntry.self,
            CustomCommand.self
        ], inMemory: true)
}
#else
#Preview {
    SettingsView(updater: SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil).updater)
        .environment(AppState())
        .modelContainer(for: [
            UserSettings.self, ModelInfo.self, PromptTemplate.self,
            AppProfile.self, VocabularyEntry.self, DictationEntry.self,
            CustomCommand.self
        ], inMemory: true)
}
#endif
