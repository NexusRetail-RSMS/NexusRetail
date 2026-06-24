//
//  RootView.swift
//  NexusRetail
//

import SwiftUI

/// Role-based router (RBAC). Reads the signed-in user's role from SessionStore and
/// mounts only that role's tab view, or the Auth flow (RoleSelectionView) when there is no active session.
struct RootView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        Group {
            if let role = sessionStore.currentRole {
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
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
        .animation(.easeInOut, value: sessionStore.currentRole)
    }
}
