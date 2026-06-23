//
//  AdminTabView.swift
//  NexusRetail
//

import SwiftUI

/// Admin shell: tabs for Stores, Products, Transfers, Analytics, Profiles.
struct AdminTabView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        VStack(spacing: 20) {
            Text("Admin Tab View")
                .font(.largeTitle)
            
            Button("Sign Out") {
                Task { try? await sessionStore.signOut() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}
