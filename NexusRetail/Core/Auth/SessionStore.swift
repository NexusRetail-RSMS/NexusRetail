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
    
    func signIn(email: String, password: String) async throws {
        let user = try await authService.signIn(email: email, password: password)
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
