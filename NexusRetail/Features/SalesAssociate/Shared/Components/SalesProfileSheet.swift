//
//  SalesProfileSheet.swift
//  NexusRetail
//
//  Profile sheet for the Sales Associate, shown from the Dashboard header avatar.
//

import SwiftUI

struct SalesProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 86, height: 86)
                    .overlay {
                        Text(salesInitials(for: sessionStore.currentUser?.name))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSColors.burgundy)
                    }

                Text(sessionStore.currentUser?.name ?? "Sales Associate")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)

                Text("Sales Associate")
                    .font(RSMSFonts.subheadline)
                    .foregroundStyle(RSMSColors.secondaryText)

                Spacer()
            }
            .padding(24)
            .background(RSMSColors.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
