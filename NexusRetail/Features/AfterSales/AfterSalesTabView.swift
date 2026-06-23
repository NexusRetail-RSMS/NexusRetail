//
//  AfterSalesTabView.swift
//  NexusRetail
//

import SwiftUI

/// After-Sales shell: Intake, Estimate, Repair, Return, Workload.
struct AfterSalesTabView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        VStack(spacing: 20) {
            Text("After Sales Tab View")
                .font(.largeTitle)
            
            Button("Sign Out") {
                Task { try? await sessionStore.signOut() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}
