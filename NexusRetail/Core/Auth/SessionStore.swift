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

    /// True once a password login succeeds but the email OTP second factor has not
    /// yet been verified. RootView shows the OTP screen while this is true.
    var needsOTPVerification: Bool = false

    var currentRole: UserRole? {
        currentUser?.role
    }
    
    let authService = AuthService()

    // Remembers which user id has completed 2FA, so a valid restored session doesn't
    // re-prompt on every launch — but a session interrupted mid-OTP still will.
    private let verifiedUserKey = "otpVerifiedUserId"

    func signIn(email: String, password: String) async throws {
        // Step 1: Authenticate with Supabase (password only — MFA comes next)
        try await authService.signInInitial(email: email, password: password)
        // Step 2: Fetch the app_user profile row
        let user = try await authService.fetchCurrentUserProfile()
        // Fresh password login always requires a new OTP. Clear any prior marker.
        UserDefaults.standard.removeObject(forKey: verifiedUserKey)
        await MainActor.run {
            self.currentUser = user
            self.needsOTPVerification = true
        }
    }

    /// Requests a fresh OTP email for the signed-in user.
    @discardableResult
    func requestOTP() async throws -> AuthService.OTPSendResponse {
        try await authService.sendLoginOTP()
    }

    /// Verifies the code; on success clears the 2FA gate and remembers this session.
    func verifyOTP(code: String) async throws -> Bool {
        let result = try await authService.verifyLoginOTP(code: code)
        if result.success {
            if let id = currentUser?.id.uuidString {
                UserDefaults.standard.set(id, forKey: verifiedUserKey)
            }
            await MainActor.run { self.needsOTPVerification = false }
        }
        return result.success
    }

    func signOut() async throws {
        try await authService.signOut()
        UserDefaults.standard.removeObject(forKey: verifiedUserKey)
        await MainActor.run {
            self.currentUser = nil
            self.needsOTPVerification = false
        }
    }
    
    func restore() async {
        if let user = await authService.restoreSession() {
            // Only skip OTP if this exact user completed 2FA previously on this device.
            let verifiedId = UserDefaults.standard.string(forKey: verifiedUserKey)
            let stillVerified = (verifiedId == user.id.uuidString)
            await MainActor.run {
                self.currentUser = user
                self.needsOTPVerification = !stillVerified
            }
        }
    }
}
