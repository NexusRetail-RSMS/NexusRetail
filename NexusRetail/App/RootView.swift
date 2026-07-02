//
//  RootView.swift
//  NexusRetail
//

import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var sessionStore
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var isRestoring = true

    var body: some View {
        Group {
            if isRestoring {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RSMSColors.background.ignoresSafeArea())
            } else if let role = sessionStore.currentRole {
                switch role {
                case .admin:
                    AdminTabView()
                case .manager:
                    ManagerTabView()
                case .salesAssociate:
                    SalesTabView()
                case .afterSales:
                    AfterSalesTabView()
                }
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
        .animation(.easeInOut, value: sessionStore.currentRole)
        .task {
            await sessionStore.restore()
            isRestoring = false
        }
    }
}
