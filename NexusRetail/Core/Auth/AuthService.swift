//
//  AuthService.swift
//  NexusRetail
//

import Foundation
import Supabase

/// Protocol/Implementation for authentication.
/// Handles signing in, signing out, and session restoration via Supabase Auth.
struct AuthService {
    
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    /// Calls Supabase auth.signIn, then queries app_user for the logged-in user's row and returns it.
    func signIn(email: String, password: String) async throws -> AppUser {
        let authResponse = try await client.auth.signIn(email: email, password: password)
        return try await fetchAppUser(for: authResponse.user.id)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    /// On app launch, if a Supabase session exists, return the app_user row (so users stay logged in).
    func restoreSession() async -> AppUser? {
        do {
            let session = try await client.auth.session
            return try await fetchAppUser(for: session.user.id)
        } catch {
            // No valid session exists, return nil
            return nil
        }
    }
    
    private func fetchAppUser(for userId: UUID) async throws -> AppUser {
        let user: AppUser = try await client
            .from("app_user")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return user
    }
}
