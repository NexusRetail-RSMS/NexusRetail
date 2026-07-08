//
//  LoginViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI
import Supabase
import Auth

enum LoginState {
    case credentials
    case mfaSetup(factorId: String, uri: String, secret: String)
    case mfaVerify(factorId: String)
}

/// @Observable view model encapsulating the login screen's state and validation logic.
@Observable
class LoginViewModel {
    var email = ""
    var password = ""
    var errorMessage = ""
    var isLoading = false
    var mfaCode = ""
    
    var loginState: LoginState = .credentials
    private let mfaService = MFAService()
    
    var isLoginButtonEnabled: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
    }
    
    var isVerifyButtonEnabled: Bool {
        mfaCode.trimmingCharacters(in: .whitespaces).count == 6 && !isLoading
    }
    
    func login(using sessionStore: SessionStore) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedEmail.contains("@") else {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        guard trimmedPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        errorMessage = ""
        isLoading = true
        
        do {
            try await sessionStore.signInInitial(email: trimmedEmail, password: trimmedPassword)
            
            // Check MFA status
            let status = try await mfaService.checkMFAStatus()
            
            if let factor = status.factors.first {
                // User has an enrolled factor, proceed to verify
                await MainActor.run {
                    self.loginState = .mfaVerify(factorId: factor.id)
                }
            } else {
                // User has no factors, proceed to setup
                let enrollResponse = try await mfaService.enroll()
                await MainActor.run {
                    self.loginState = .mfaSetup(
                        factorId: enrollResponse.id,
                        uri: enrollResponse.totp?.uri ?? "",
                        secret: enrollResponse.totp?.secret ?? ""
                    )
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func verifyMFA(using sessionStore: SessionStore) async {
        errorMessage = ""
        isLoading = true
        
        do {
            let factorId: String
            switch loginState {
            case .mfaSetup(let id, _, _), .mfaVerify(let id):
                factorId = id
            default:
                throw NSError(domain: "MFAService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MFA state"])
            }
            
            let challenge = try await mfaService.challenge(factorId: factorId)
            _ = try await mfaService.verify(factorId: factorId, challengeId: challenge.id, code: mfaCode)
            
            // Success! Complete the login
            try await sessionStore.completeLogin()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func cancelMFA(using sessionStore: SessionStore) {
        Task {
            try? await sessionStore.signOut()
            await MainActor.run {
                self.loginState = .credentials
                self.mfaCode = ""
                self.errorMessage = ""
            }
        }
    }
}
