// Passkey login screen; on success populates SessionStore. (TEAM5-60/61/62/63)

//
//  LoginView.swift
//  NexusRetail
//

import SwiftUI

/// The login screen UI for NexusRetail. Renders the title, email and password
/// fields, the Log In button, an inline error label, and a loading spinner, and
/// forwards every user action to `LoginViewModel`. This view contains no
/// validation or authentication logic of its own.
struct LoginView: View {

    @State private var viewModel = LoginViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("NexusRetail")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 16) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .font(.body)
                    .accessibilityLabel("Email address")

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .font(.body)
                    .accessibilityLabel("Password")
            }

            errorLabel

            loginButton
        }
        .padding()
        .frame(maxWidth: 480)
    }

    /// The inline error message, shown only when the view model reports one.
    @ViewBuilder
    private var errorLabel: some View {
        if !viewModel.errorMessage.isEmpty {
            Text(viewModel.errorMessage)
                .font(.callout)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(viewModel.errorMessage)
                .transition(.opacity)
        }
    }

    /// The Log In button, which shows a spinner while authenticating and is
    /// disabled while loading or when either field is empty.
    private var loginButton: some View {
        Button {
            Task { await viewModel.login() }
        } label: {
            ZStack {
                // Reserve the label's space so the button height is stable
                // while the spinner is shown in its place.
                Text("Log In")
                    .font(.headline)
                    .opacity(viewModel.isLoading ? 0 : 1)

                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isLoginButtonEnabled)
        .accessibilityLabel("Log in")
        .accessibilityValue(viewModel.isLoading ? "Authenticating" : "")
    }
}

#Preview {
    LoginView()
}
