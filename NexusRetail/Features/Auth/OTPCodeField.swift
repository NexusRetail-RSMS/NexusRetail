// OTPCodeField.swift

import SwiftUI

struct OTPCodeField: View {
    @Binding var code: String
    var length: Int = 6
    var isFocused: FocusState<Bool>.Binding
    var onChange: (() -> Void)? = nil

    var body: some View {
        TextField(String(repeating: "0", count: length), text: $code)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .tracking(6)
            .foregroundStyle(RSMSColors.primaryText)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSColors.cardBorder, lineWidth: 1))
            .focused(isFocused)
            .accessibilityLabel("Verification code")
            .accessibilityHint("Enter the \(length)-digit code sent to your email")
            .onChange(of: code) { _, newValue in
                let filtered = String(newValue.filter(\.isNumber).prefix(length))
                if filtered != newValue { code = filtered }
                onChange?()
            }
    }
}

private struct OTPCodeFieldPreviewHost: View {
    @State private var code = ""
    @FocusState private var focused: Bool

    var body: some View {
        OTPCodeField(code: $code, isFocused: $focused)
            .padding()
            .background(RSMSColors.background)
    }
}

#Preview("OTP Code Field") {
    OTPCodeFieldPreviewHost()
}
