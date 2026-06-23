//
//  NexusRetailApp.swift
//  NexusRetail
//

import SwiftUI

/// App entry point (@main). Creates the shared SessionStore and launches RootView.
@main
struct NexusRetailApp: App {
    @State private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionStore)
                .task {
                    // Attempt to restore session on app launch
                    await sessionStore.restore()
                }
        }
    }
}
