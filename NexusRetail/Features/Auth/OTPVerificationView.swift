//
//  OTPVerificationView.swift
//  NexusRetail
//
//  Second-factor screen shown after a successful password login. The user enters
//  the 6-digit code emailed to them; on success the app unlocks their dashboard.
//

import SwiftUI

struct OTPVerificationView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SessionStore.self) private var sessionStore

    @State private var code = ""
    @State private var isSending = false
    @State private var isVerifying = false
    @State private var errorMessage = ""
    @State private var infoMessage = ""
    @State private var resendCountdown = 0
    @State private var debugCode: String? = nil
    @FocusState private var codeFocused: Bool

    private let codeLength = 6

    private var maskedEmail: String {
        guard let email = sessionStore.currentUser?.email, let at = email.firstIndex(of: "@") else {
            return sessionStore.currentUser?.email ?? "your email"
        }
        let name = String(email[email.startIndex..<at])
        let domain = String(email[at...])
        let shown = name.prefix(2)
        return "\(shown)\(String(repeating: "•", count: max(name.count - 2, 1)))\(domain)"
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 14) {
                    ZStack {
                        Circle().fill(theme.burgundy.opacity(0.1)).frame(width: 84, height: 84)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 38))
                            .foregroundColor(theme.burgundy)
                    }
                    Text("Two-Factor Verification")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    Text("We sent a 6-digit code to\n\(maskedEmail)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                // Code field
                VStack(spacing: 8) {
                    TextField("000000", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .tracking(8)
                        .focused($codeFocused)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.cardBorder, lineWidth: 1))
                        .onChange(of: code) { _, newValue in
                            let filtered = String(newValue.filter(\.isNumber).prefix(codeLength))
                            if filtered != newValue { code = filtered }
                            errorMessage = ""
                        }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(theme.error)
                    } else if !infoMessage.isEmpty {
                        Text(infoMessage)
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryText)
                    }

                    if let debugCode {
                        Text("DEBUG code: \(debugCode)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)

                // Verify
                Button {
                    Task { await verify() }
                } label: {
                    HStack {
                        if isVerifying { ProgressView().tint(.white).padding(.trailing, 6) }
                        Text("Verify & Continue").font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(code.count == codeLength ? theme.burgundy : theme.secondaryText.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(code.count != codeLength || isVerifying)
                .padding(.horizontal, RSMSSpacing.lg)

                // Resend
                Button {
                    Task { await sendCode(initial: false) }
                } label: {
                    if resendCountdown > 0 {
                        Text("Resend code in \(resendCountdown)s")
                            .foregroundColor(theme.secondaryText)
                    } else if isSending {
                        Text("Sending…").foregroundColor(theme.secondaryText)
                    } else {
                        Text("Resend code").foregroundColor(theme.burgundy).fontWeight(.semibold)
                    }
                }
                .font(.system(size: 14))
                .disabled(resendCountdown > 0 || isSending)

                Spacer()

                Button {
                    Task { try? await sessionStore.signOut() }
                } label: {
                    Text("Cancel and sign out")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                }
                .padding(.bottom, 24)
            }
        }
        .task {
            await sendCode(initial: true)
            codeFocused = true
        }
    }

    // MARK: - Actions

    private func sendCode(initial: Bool) async {
        guard !isSending else { return }
        isSending = true
        errorMessage = ""
        do {
            let resp = try await sessionStore.requestOTP()
            if resp.success {
                infoMessage = "Code sent. Check your email."
                debugCode = resp.debugCode
                startCountdown()
            } else if resp.reason == "rate_limited" {
                infoMessage = "Please wait before requesting another code."
                startCountdown()
            } else {
                errorMessage = "Couldn't send the code. Try again."
            }
        } catch {
            errorMessage = "Couldn't send the code. Check your connection."
        }
        isSending = false
    }

    private func verify() async {
        guard code.count == codeLength else { return }
        isVerifying = true
        errorMessage = ""
        do {
            let ok = try await sessionStore.verifyOTP(code: code)
            if !ok {
                errorMessage = "Incorrect or expired code. Please try again."
                code = ""
            }
            // On success, RootView routes to the dashboard automatically.
        } catch {
            errorMessage = "Verification failed. Please try again."
        }
        isVerifying = false
    }

    private func startCountdown() {
        resendCountdown = 60
        Task {
            while resendCountdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { if resendCountdown > 0 { resendCountdown -= 1 } }
            }
        }
    }
}
