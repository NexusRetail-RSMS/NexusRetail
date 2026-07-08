//
//  SessionStore.swift
//  NexusRetail
//

import Foundation
import SwiftUI

/// Observable holder of the current Session. Exposes currentRole and sign-in/sign-out.
/// The whole app observes this to react to login/logout.
@Observable
class SessionStore {
    var currentUser: AppUser?
    
    var currentRole: UserRole? {
        currentUser?.role
    }
    
    let authService = AuthService()
    
    func signInInitial(email: String, password: String) async throws {
        try await authService.signInInitial(email: email, password: password)
        // Note: We do NOT set `currentUser` yet. The LoginViewModel will handle MFA.
    }
    
    /// Called after MFA is verified (or if MFA is somehow bypassed safely).
    func completeLogin() async throws {
        let user = try await authService.fetchCurrentUserProfile()
        await MainActor.run {
            self.currentUser = user
        }
    }
    
    func signOut() async throws {
        try await authService.signOut()
        await MainActor.run {
            self.currentUser = nil
        }
    }
    
    func restore() async {
        if let user = await authService.restoreSession() {
            await MainActor.run {
                self.currentUser = user
            }
        }
    }
}
