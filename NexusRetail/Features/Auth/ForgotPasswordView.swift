//
//  ForgotPasswordView.swift
//  NexusRetail
//
//  Email-OTP password reset: enter email → verify 6-digit code → set new password.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    private enum Step { case email, code, newPassword, done }

    private let authService = AuthService()

    @State private var step: Step = .email
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var resetToken = ""

    @State private var isBusy = false
    @State private var errorMessage = ""
    @State private var infoMessage = ""
    @State private var debugCode: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header

                        switch step {
                        case .email:       emailStep
                        case .code:        codeStep
                        case .newPassword: passwordStep
                        case .done:        doneStep
                        }

                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.system(size: 13)).foregroundColor(RSMSColors.error)
                                .multilineTextAlignment(.center)
                        } else if !infoMessage.isEmpty {
                            Text(infoMessage).font(.system(size: 13)).foregroundColor(RSMSColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        if let debugCode {
                            Text("DEBUG code: \(debugCode)").font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                        }
                    }
                    .padding(RSMSSpacing.lg)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(RSMSColors.burgundy)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(RSMSColors.burgundy.opacity(0.1)).frame(width: 72, height: 72)
                Image(systemName: step == .done ? "checkmark.circle.fill" : "key.horizontal.fill")
                    .font(.system(size: 30))
                    .foregroundColor(step == .done ? RSMSColors.success : RSMSColors.burgundy)
            }
            Text(headerText)
                .font(.system(size: 14))
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var headerText: String {
        switch step {
        case .email: return "Enter your account email and we'll send you a reset code."
        case .code: return "Enter the 6-digit code sent to \(email)."
        case .newPassword: return "Choose a new password for your account."
        case .done: return "Your password has been reset. You can now sign in."
        }
    }

    // MARK: - Steps

    private var emailStep: some View {
        VStack(spacing: 16) {
            field("Email", text: $email, keyboard: .emailAddress)
            primaryButton("Send Code", enabled: email.contains("@")) {
                Task { await sendCode() }
            }
        }
    }

    private var codeStep: some View {
        VStack(spacing: 16) {
            TextField("000000", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(6)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(RSMSColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSColors.cardBorder, lineWidth: 1))
                .onChange(of: code) { _, v in
                    let f = String(v.filter(\.isNumber).prefix(6)); if f != v { code = f }; errorMessage = ""
                }
            primaryButton("Verify Code", enabled: code.count == 6) {
                Task { await verifyCode() }
            }
            Button("Resend code") { Task { await sendCode() } }
                .font(.system(size: 14)).foregroundColor(RSMSColors.burgundy)
        }
    }

    private var passwordStep: some View {
        VStack(spacing: 16) {
            secureField("New password (min 8 chars)", text: $newPassword)
            secureField("Confirm new password", text: $confirmPassword)
            primaryButton("Update Password", enabled: newPassword.count >= 8 && newPassword == confirmPassword) {
                Task { await updatePassword() }
            }
            if !newPassword.isEmpty && newPassword != confirmPassword {
                Text("Passwords don't match.").font(.system(size: 12)).foregroundColor(RSMSColors.error)
            }
        }
    }

    private var doneStep: some View {
        primaryButton("Back to Sign In", enabled: true) { dismiss() }
    }

    // MARK: - Reusable controls

    private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(14)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }

    private func secureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding(14)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }

    private func primaryButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if isBusy { ProgressView().tint(.white).padding(.trailing, 6) }
                Text(title).font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(enabled && !isBusy ? RSMSColors.burgundy : RSMSColors.secondaryText.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!enabled || isBusy)
    }

    // MARK: - Actions

    private func sendCode() async {
        isBusy = true; errorMessage = ""; infoMessage = ""
        do {
            let resp = try await authService.sendResetOTP(email: email.trimmingCharacters(in: .whitespaces).lowercased())
            debugCode = resp.debugCode
            infoMessage = "If an account exists, a code has been sent."
            withAnimation { step = .code }
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    private func verifyCode() async {
        isBusy = true; errorMessage = ""; infoMessage = ""
        do {
            let resp = try await authService.verifyResetOTP(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(), otp: code)
            if let token = resp.reset_token, resp.success == true {
                resetToken = token
                withAnimation { step = .newPassword }
            } else {
                errorMessage = "Incorrect or expired code."
            }
        } catch {
            errorMessage = error.localizedDescription
            code = ""
        }
        isBusy = false
    }

    private func updatePassword() async {
        isBusy = true; errorMessage = ""; infoMessage = ""
        do {
            let resp = try await authService.resetPassword(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                newPassword: newPassword,
                resetToken: resetToken)
            if resp.success == true {
                withAnimation { step = .done }
            } else {
                errorMessage = "Couldn't update the password. Please start over."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }
}
