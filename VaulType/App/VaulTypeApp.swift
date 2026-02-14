//
//  VaulTypeApp.swift
//  VaulType
//
//  Created by Harun Güngörer on 13.02.2026.
//

import SwiftUI

@main
struct VaulTypeApp: App {
    var body: some Scene {
        MenuBarExtra("VaulType", systemImage: "mic.fill") {
            Text("VaulType Menu Bar App")
        }
        .menuBarExtraStyle(.window)
    }
}
