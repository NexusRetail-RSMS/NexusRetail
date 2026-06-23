//
//  LoginViewModel.swift
//  NexusRetail
//

import Foundation
import Observation

/// Holds the login screen state (email, password, error message, loading, and
/// authentication status) and owns the `login()` flow that validates input and
/// simulates a network authentication call against a hardcoded test credential.
/// The paired `LoginView` contains no business logic and drives all behavior
/// through this view model.
@Observable
final class LoginViewModel {

    // MARK: - Constants

    /// Maximum number of characters accepted by the email field.
    static let maxEmailLength = 254
    /// Maximum number of characters accepted by the password field.
    static let maxPasswordLength = 128
    /// Simulated network delay, in nanoseconds (1 second).
    private static let authenticationDelayNanoseconds: UInt64 = 1_000_000_000

    /// The hardcoded credential pair that authenticates successfully.
    private static let testEmail = "admin@nexus.com"
    private static let testPassword = "password"

    // MARK: - State

    /// The current email field contents. Setting this enforces the max length.
    var email: String = "" {
        didSet {
            if email.count > Self.maxEmailLength {
                email = String(email.prefix(Self.maxEmailLength))
            }
        }
    }

    /// The current password field contents. Setting this enforces the max length.
    var password: String = "" {
        didSet {
            if password.count > Self.maxPasswordLength {
                password = String(password.prefix(Self.maxPasswordLength))
            }
        }
    }

    /// The inline error message. Empty string means no error is shown.
    var errorMessage: String = ""

    /// Whether an authentication attempt is currently in progress.
    var isLoading: Bool = false

    /// Whether the user has successfully authenticated.
    var isAuthenticated: Bool = false

    // MARK: - Derived state

    /// True when the email is non-empty and contains "@".
    private var isValidEmail: Bool {
        !email.isEmpty && email.contains("@")
    }

    /// True when the password contains at least 6 characters.
    private var isValidPassword: Bool {
        password.count >= 6
    }

    /// Whether the Log In button should be enabled, given the current state.
    /// The button is enabled only when not loading and both fields are non-empty.
    var isLoginButtonEnabled: Bool {
        !isLoading && !email.isEmpty && !password.isEmpty
    }

    // MARK: - Actions

    /// Validates the current input and, if valid, simulates a 1-second
    /// authentication call against the test credential.
    ///
    /// - Ignores the call entirely if an attempt is already in progress.
    /// - On validation failure, sets a clear error message, leaves the fields
    ///   untouched, and does not perform the simulated delay.
    /// - On success, marks the session authenticated and clears the error.
    /// - On credential mismatch, surfaces an "Invalid email or password." error.
    @MainActor
    func login() async {
        // Ignore re-entrant invocations while authenticating.
        guard !isLoading else { return }

        // Reset any prior error before validating a new attempt.
        errorMessage = ""

        // Input validation. On failure we stop before the simulated delay.
        guard isValidEmail else {
            errorMessage = "Please enter a valid email address."
            return
        }

        guard isValidPassword else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        // Begin the simulated authentication call.
        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(nanoseconds: Self.authenticationDelayNanoseconds)

        if email == Self.testEmail && password == Self.testPassword {
            errorMessage = ""
            isAuthenticated = true
        } else {
            errorMessage = "Invalid email or password."
        }
    }
}
