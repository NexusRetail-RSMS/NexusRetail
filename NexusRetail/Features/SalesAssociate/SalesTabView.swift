//
//  SalesTabView.swift
//  NexusRetail
//

import SwiftUI

/// Sales shell: Clients, Suggest, Sell, Settings.
struct SalesTabView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        VStack(spacing: 20) {
            Text("Sales Tab View")
                .font(.largeTitle)
            
            Button("Sign Out") {
                Task { try? await sessionStore.signOut() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}
