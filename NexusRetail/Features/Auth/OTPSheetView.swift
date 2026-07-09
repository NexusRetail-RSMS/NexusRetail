import SwiftUI

enum OTPSendOutcome {
    case sent(debugCode: String?)
    case rateLimited
    case failed
}

struct OTPSheetView: View {
    let email: String
    var subtitle: String
    var cancelLabel: String = "Cancel"
    var onSend: () async -> OTPSendOutcome
    var onVerify: (String) async -> Bool
    var onCancel: () -> Void

    @State private var code = ""
    @State private var isSending = false
    @State private var isVerifying = false
    @State private var errorMessage = ""
    @State private var infoMessage = ""
    @State private var resendCountdown = 0
    @State private var debugCode: String? = nil
    @State private var countdownTask: Task<Void, Never>?
    @FocusState private var codeFocused: Bool

    private let codeLength = 6

    private var maskedEmail: String {
        guard let at = email.firstIndex(of: "@") else { return email }
        let name = String(email[email.startIndex..<at])
        let domain = String(email[at...])
        let shown = name.prefix(2)
        return "\(shown)\(String(repeating: "•", count: max(name.count - 2, 1)))\(domain)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            OTPCodeField(code: $code, isFocused: $codeFocused) {
                errorMessage = ""
            }

            GradientButton(
                title: "Verify",
                icon: "checkmark",
                isLoading: isVerifying,
                isEnabled: code.count == codeLength && !isVerifying
            ) {
                Task { await verify() }
            }
            .hSpacing(.trailing)

            resendRow

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(RSMSColors.error)
                    .accessibilityLabel("Error: \(errorMessage)")
            } else if !infoMessage.isEmpty {
                Text(infoMessage)
                    .font(.footnote)
                    .foregroundStyle(RSMSColors.secondaryText)
            }

            #if DEBUG
            if let debugCode {
                Text("DEBUG code: \(debugCode)")
                    .font(.caption2.bold())
                    .foregroundStyle(RSMSColors.warning)
            }
            #endif
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
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .task {
            await send()
            codeFocused = true
        }
        .onDisappear {
            countdownTask?.cancel()
        }
    }

    private var closeButton: some View {
        Button(action: onCancel) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RSMSColors.secondaryText)
                .padding(10)
                .background(RSMSColors.background, in: .circle)
        }
        .padding(.top, 20)
        .padding(.trailing, 20)
        .accessibilityLabel(cancelLabel)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle().fill(RSMSColors.burgundy.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(RSMSColors.burgundy)
            }
            .accessibilityHidden(true)

            Text("Verify It's You")
                .font(.title2.bold())
                .foregroundStyle(RSMSColors.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("\(subtitle)\nCode sent to \(maskedEmail).")
                .font(.callout)
                .foregroundStyle(RSMSColors.secondaryText)
        }
        .padding(.trailing, 36)
    }

    private var resendRow: some View {
        Group {
            if resendCountdown > 0 {
                Text("Resend code in \(resendCountdown)s")
                    .font(.footnote)
                    .foregroundStyle(RSMSColors.secondaryText)
            } else if isSending {
                Text("Sending…")
                    .font(.footnote)
                    .foregroundStyle(RSMSColors.secondaryText)
            } else {
                Button("Resend code") {
                    Task { await send() }
                }
                .font(.footnote.bold())
                .foregroundStyle(RSMSColors.burgundy)
            }
        }
        .accessibilityHint(resendCountdown > 0 ? "Available in \(resendCountdown) seconds" : "Double tap to resend the code")
    }

    private func send() async {
        guard !isSending else { return }
        isSending = true
        errorMessage = ""
        let outcome = await onSend()
        switch outcome {
        case .sent(let debug):
            infoMessage = "Code sent. Check your email."
            debugCode = debug
            startCountdown()
        case .rateLimited:
            infoMessage = "Please wait before requesting another code."
            startCountdown()
        case .failed:
            errorMessage = "Couldn't send the code. Try again."
        }
        isSending = false
    }

    private func verify() async {
        guard code.count == codeLength else { return }
        isVerifying = true
        errorMessage = ""
        let ok = await onVerify(code)
        if !ok {
            errorMessage = "Incorrect or expired code. Please try again."
            code = ""
            codeFocused = true
        }
        isVerifying = false
    }

    private func startCountdown() {
        countdownTask?.cancel()
        resendCountdown = 60
        countdownTask = Task {
            while resendCountdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                await MainActor.run { if resendCountdown > 0 { resendCountdown -= 1 } }
            }
        }
    }
}

#Preview("Login 2FA") {
    ZStack(alignment: .bottom) {
        RSMSColors.background.ignoresSafeArea()
        OTPSheetView(
            email: "manager@nexusretail.com",
            subtitle: "Enter the code to finish signing in.",
            cancelLabel: "Cancel and sign out",
            onSend: { .sent(debugCode: "482913") },
            onVerify: { _ in true },
            onCancel: {}
        )
    }
}

#Preview("Forgot Password verification") {
    ZStack(alignment: .bottom) {
        RSMSColors.background.ignoresSafeArea()
        OTPSheetView(
            email: "manager@nexusretail.com",
            subtitle: "Before changing your credentials, let's verify it's you.",
            cancelLabel: "Back",
            onSend: { .sent(debugCode: "119204") },
            onVerify: { _ in false },
            onCancel: {}
        )
    }
}

#Preview("Rate limited") {
    ZStack(alignment: .bottom) {
        RSMSColors.background.ignoresSafeArea()
        OTPSheetView(
            email: "sales@nexusretail.com",
            subtitle: "Enter the code to finish signing in.",
            cancelLabel: "Cancel and sign out",
            onSend: { .rateLimited },
            onVerify: { _ in true },
            onCancel: {}
        )
    }
}

#Preview("Send failed") {
    ZStack(alignment: .bottom) {
        RSMSColors.background.ignoresSafeArea()
        OTPSheetView(
            email: "sales@nexusretail.com",
            subtitle: "Enter the code to finish signing in.",
            cancelLabel: "Cancel and sign out",
            onSend: { .failed },
            onVerify: { _ in true },
            onCancel: {}
        )
    }
}
