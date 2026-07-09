import SwiftUI

struct ForgotPasswordSheet: View {
    @Binding var isPresented: Bool

    enum Step {
        case email, code, newPassword, done
    }

    private let authService = AuthService()

    @State private var step: Step = .email
    @State private var email = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var resetToken = ""

    @State private var isBusy = false
    @State private var errorMessage = ""
    @State private var infoMessage = ""

    @FocusState private var emailFocused: Bool
    @FocusState private var passwordFocused: Bool
    @FocusState private var confirmFocused: Bool

    init(isPresented: Binding<Bool>, initialStep: Step = .email, initialEmail: String = "") {
        _isPresented = isPresented
        _step = State(initialValue: initialStep)
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        Group {
            if step == .code {
                codeStep
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    switch step {
                    case .email: emailStep
                    case .newPassword: passwordStep
                    case .done: doneStep
                    case .code: EmptyView()
                    }

                    if !errorMessage.isEmpty {
                        Text(localized: errorMessage)
                            .font(.footnote)
                            .foregroundStyle(RSMSColors.error)
                            .accessibilityLabel("Error: \(errorMessage)")
                    } else if !infoMessage.isEmpty {
                        Text(localized: infoMessage)
                            .font(.footnote)
                            .foregroundStyle(RSMSColors.secondaryText)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 24)
                .padding(.bottom, 34)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 28
                    )
                    .fill(RSMSColors.cardBackground)
                    .ignoresSafeArea(.container, edges: .bottom)
                }
                .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: -8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: step)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            if step != .done {
                Button(action: handleBack) {
                    Image(systemName: step == .newPassword ? "xmark" : "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RSMSColors.primaryText)
                }
                .accessibilityLabel(step == .newPassword ? "Close" : "Back")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(localized: title)
                    .font(.title2.bold())
                    .foregroundStyle(RSMSColors.primaryText)
                    .accessibilityAddTraits(.isHeader)

                Text(localized: subtitle)
                    .font(.callout)
                    .foregroundStyle(RSMSColors.secondaryText)
            }
        }
    }

    private var title: String {
        switch step {
        case .email: return "Forgot Password?"
        case .code: return "Verify Code"
        case .newPassword: return "Reset Password"
        case .done: return "All Set"
        }
    }

    private var subtitle: String {
        switch step {
        case .email: return "Please enter your Email ID so that we can send the reset link."
        case .code: return ""
        case .newPassword: return "Choose a new password for your account."
        case .done: return "Your password has been reset. You can now sign in."
        }
    }

    private var emailStep: some View {
        VStack(spacing: 20) {
            CustomTF(
                sfIcon: "at",
                hint: "Email ID",
                keyboardType: .emailAddress,
                textContentType: .username,
                value: $email,
                isFocused: $emailFocused
            )

            GradientButton(
                title: "Send Link",
                icon: "arrow.right",
                isLoading: isBusy,
                isEnabled: email.contains("@") && !isBusy
            ) {
                Task { await sendCode() }
            }
            .hSpacing(.trailing)
        }
    }

    private var codeStep: some View {
        OTPSheetView(
            email: email,
            subtitle: "Before changing your credentials, let's verify it's you.",
            cancelLabel: "Back",
            onSend: { await sendOTPOutcome() },
            onVerify: { code in await verifyOTP(code) },
            onCancel: { withAnimation { step = .email } }
        )
    }

    private var passwordStep: some View {
        VStack(spacing: 20) {
            CustomTF(
                sfIcon: "lock",
                hint: "Password",
                isPassword: true,
                textContentType: .newPassword,
                value: $newPassword,
                isFocused: $passwordFocused
            )

            CustomTF(
                sfIcon: "lock",
                hint: "Confirm Password",
                isPassword: true,
                textContentType: .newPassword,
                value: $confirmPassword,
                isFocused: $confirmFocused
            )

            GradientButton(
                title: "Reset Password",
                icon: "arrow.right",
                isLoading: isBusy,
                isEnabled: newPassword.count >= 8 && newPassword == confirmPassword && !isBusy
            ) {
                Task { await updatePassword() }
            }
            .hSpacing(.trailing)
        }
    }

    private var doneStep: some View {
        GradientButton(title: "Back to Login", icon: "arrow.right", isEnabled: true) {
            isPresented = false
        }
        .hSpacing(.trailing)
    }

    private func handleBack() {
        errorMessage = ""
        infoMessage = ""
        switch step {
        case .email:
            isPresented = false
        case .code:
            withAnimation { step = .email }
        case .newPassword:
            isPresented = false
        case .done:
            isPresented = false
        }
    }

    private func sendCode() async {
        isBusy = true
        errorMessage = ""
        infoMessage = ""
        _ = await sendOTPOutcome()
        withAnimation { step = .code }
        isBusy = false
    }

    private func sendOTPOutcome() async -> OTPSendOutcome {
        do {
            let resp = try await authService.sendResetOTP(
                email: email.trimmingCharacters(in: .whitespaces).lowercased()
            )
            return .sent(debugCode: resp.debugCode)
        } catch {
            return .failed
        }
    }

    private func verifyOTP(_ code: String) async -> Bool {
        do {
            let resp = try await authService.verifyResetOTP(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                otp: code
            )
            if let token = resp.reset_token, resp.success == true {
                resetToken = token
                withAnimation { step = .newPassword }
                return true
            }
            return false
        } catch {
            return false
        }
    }

    private func updatePassword() async {
        isBusy = true
        errorMessage = ""
        infoMessage = ""
        do {
            let resp = try await authService.resetPassword(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                newPassword: newPassword,
                resetToken: resetToken
            )
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

#Preview("Email step") {
    ZStack(alignment: .bottom) {
        RSMSColors.background.ignoresSafeArea()
        ForgotPasswordSheet(isPresented: .constant(true))
    }
}

#Preview("Code step") {
    ZStack(alignment: .bottom) {
        RSMSColors.background.ignoresSafeArea()
        ForgotPasswordSheet(isPresented: .constant(true), initialStep: .code, initialEmail: "manager@nexusretail.com")
    }
}

#Preview("Reset password step") {
    ZStack(alignment: .bottom) {
        RSMSColors.background.ignoresSafeArea()
        ForgotPasswordSheet(isPresented: .constant(true), initialStep: .newPassword, initialEmail: "manager@nexusretail.com")
    }
}

#Preview("Done step") {
    ZStack(alignment: .bottom) {
        RSMSColors.background.ignoresSafeArea()
        ForgotPasswordSheet(isPresented: .constant(true), initialStep: .done)
    }
}
