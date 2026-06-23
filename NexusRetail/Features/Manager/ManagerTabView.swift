//
//  ManagerTabView.swift
//  NexusRetail
//

import SwiftUI

/// Manager shell: Inventory, Requests, Pricing, Events, Staff.
struct ManagerTabView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        VStack(spacing: 20) {
            Text("Manager Tab View")
                .font(.largeTitle)
            
            Button("Sign Out") {
                Task { try? await sessionStore.signOut() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}
