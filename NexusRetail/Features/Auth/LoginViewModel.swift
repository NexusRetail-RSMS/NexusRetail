//
//  LoginViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI

/// @Observable view model encapsulating the login screen's state and validation logic.
@Observable
class LoginViewModel {
    var email = ""
    var password = ""
    var errorMessage = ""
    var isLoading = false
    
    var isLoginButtonEnabled: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
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
            try await sessionStore.signIn(email: trimmedEmail, password: trimmedPassword)
            // On complete success, the SessionStore updates and RootView routes automatically.
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
