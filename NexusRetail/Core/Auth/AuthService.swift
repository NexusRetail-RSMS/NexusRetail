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
    
    /// Calls Supabase auth.signIn for the initial step.
    /// Does NOT fetch AppUser automatically because MFA might be required before proceeding.
    func signInInitial(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }
    
    /// Fetches the user's profile row from the app_user table.
    func fetchCurrentUserProfile() async throws -> AppUser {
        let session = try await client.auth.session
        return try await fetchAppUser(for: session.user.id)
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
