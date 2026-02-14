//
//  VaulTypeApp.swift
//  VaulType
//
//  Created by Harun Güngörer on 13.02.2026.
//

import SwiftData
import SwiftUI

@main
struct VaulTypeApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            DictationEntry.self,
            PromptTemplate.self,
            AppProfile.self,
            VocabularyEntry.self,
            UserSettings.self,
            ModelInfo.self
        ])

        let configuration = ModelConfiguration(
            "VaulType",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: VaulTypeMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra("VaulType", systemImage: "mic.fill") {
            Text("VaulType Menu Bar App")
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)

        Settings {
            Text("Settings placeholder")
        }
        .modelContainer(modelContainer)
    }
}
