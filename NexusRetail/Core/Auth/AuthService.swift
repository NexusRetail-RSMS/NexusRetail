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

    // MARK: - Two-factor (email OTP)

    struct OTPSendResponse: Decodable {
        let success: Bool
        let emailSent: Bool?
        let emailError: String?
        let reason: String?
        let debugCode: String?
    }

    struct OTPVerifyResponse: Decodable {
        let success: Bool
        let reason: String?
    }

    /// Asks the edge function to generate + email a fresh login code to the signed-in user.
    @discardableResult
    func sendLoginOTP() async throws -> OTPSendResponse {
        try await client.functions.invoke("send-login-otp")
    }

    /// Verifies the code the user typed against the server.
    func verifyLoginOTP(code: String) async throws -> OTPVerifyResponse {
        struct Params: Encodable { let p_code: String }
        return try await client
            .rpc("verify_login_otp", params: Params(p_code: code))
            .execute()
            .value
    }

    // MARK: - Forgot password (email OTP → set new password)

    struct FunctionError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    struct ResetSendResponse: Decodable { let success: Bool?; let debugCode: String? }
    struct ResetVerifyResponse: Decodable { let success: Bool?; let reset_token: String? }
    struct ResetPasswordResponse: Decodable { let success: Bool? }

    /// Step 1: email a reset code (always "succeeds" to avoid revealing valid emails).
    @discardableResult
    func sendResetOTP(email: String) async throws -> ResetSendResponse {
        try await invokeReset("send-reset-otp", body: ["email": email])
    }

    /// Step 2: verify the code, returns a one-time reset token on success.
    func verifyResetOTP(email: String, otp: String) async throws -> ResetVerifyResponse {
        try await invokeReset("verify-reset-otp", body: ["email": email, "otp": otp])
    }

    /// Step 3: set the new password using the reset token.
    func resetPassword(email: String, newPassword: String, resetToken: String) async throws -> ResetPasswordResponse {
        try await invokeReset("reset-password", body: ["email": email, "new_password": newPassword, "reset_token": resetToken])
    }

    /// Invokes an unauthenticated reset function and surfaces server error messages.
    private func invokeReset<T: Decodable>(_ name: String, body: [String: String]) async throws -> T {
        do {
            return try await client.functions.invoke(name, options: FunctionInvokeOptions(body: body))
        } catch let FunctionsError.httpError(_, data) {
            if let obj = try? JSONDecoder().decode([String: String].self, from: data), let msg = obj["error"] {
                throw FunctionError(message: msg)
            }
            throw FunctionError(message: "Request failed. Please try again.")
        }
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
