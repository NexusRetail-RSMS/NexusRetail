// CustomTF.swift

import SwiftUI

struct CustomTF: View {
    var sfIcon: String
    var iconTint: Color = RSMSColors.secondaryText
    var hint: String
    var isPassword: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var errorMessage: String? = nil
    @Binding var value: String
    var isFocused: FocusState<Bool>.Binding? = nil
    @State private var showPassword: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: sfIcon)
                .foregroundStyle(iconTint)
                .frame(width: 30)
                .offset(y: 3)

            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if isPassword {
                        Group {
                            if showPassword {
                                TextField(hint, text: $value)
                            } else {
                                SecureField(hint, text: $value)
                            }
                        }
                        .textContentType(textContentType ?? .password)
                    } else {
                        TextField(hint, text: $value)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(textContentType)
                    }
                }
                .foregroundStyle(RSMSColors.primaryText)
                .applyFocus(isFocused)
                .accessibilityLabel(hint)

                Divider()
                    .overlay(errorMessage != nil ? RSMSColors.error : RSMSColors.inputBorder)

                if let errorMessage {
                    Text(localized: errorMessage)
                        .font(.caption2)
                        .foregroundStyle(RSMSColors.error)
                }
            }
            .overlay(alignment: .trailing) {
                if isPassword {
                    Button {
                        withAnimation {
                            showPassword.toggle()
                        }
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(RSMSColors.secondaryText)
                            .padding(30)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func applyFocus(_ binding: FocusState<Bool>.Binding?) -> some View {
        if let binding {
            self.focused(binding)
        } else {
            self
        }
    }
}

private struct CustomTFPreviewHost: View {
    @State private var email = ""
    @State private var password = ""
    @FocusState private var emailFocused: Bool
    @FocusState private var passwordFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            CustomTF(sfIcon: "at", hint: "Email ID", keyboardType: .emailAddress, value: $email, isFocused: $emailFocused)
            CustomTF(sfIcon: "lock", hint: "Password", isPassword: true, value: $password, isFocused: $passwordFocused)
            CustomTF(sfIcon: "lock", hint: "Password", isPassword: true, errorMessage: "Incorrect password", value: $password, isFocused: $passwordFocused)
        }
        .padding()
        .background(RSMSColors.background)
    }
}

#Preview("Text Fields") {
    CustomTFPreviewHost()
}
