//
//  LoginView.swift
//  NexusRetail
//

import SwiftUI

/// The login screen UI for NexusRetail. Renders the title, email and password
/// fields, the Log In button, an inline error label, and a loading spinner.
/// Forwards user actions to `LoginViewModel`.
struct LoginView: View {

    @State private var viewModel = LoginViewModel()
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        VStack(spacing: 24) {
            
            // Header Image / Icon
            Image(systemName: "person.badge.key.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundStyle(Color.nexusGold)
                .padding(.top, 24)
            
            // Titles
            VStack(spacing: 8) {
                Text("NexusRetail")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .foregroundColor(Color.nexusRed)
                
                Text("Log in to your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            // Input Fields
            VStack(spacing: 16) {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .font(.body)
                    .accessibilityLabel("Email address")
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            .background(Color(uiColor: .systemBackground))
                    )

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .font(.body)
                    .accessibilityLabel("Password")
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            .background(Color(uiColor: .systemBackground))
                    )
            }

            errorLabel

            loginButton
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 480)
        .navigationBarBackButtonHidden(true)
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
                .accessibilityLabel("Error: \(viewModel.errorMessage)")
                .transition(.opacity)
        }
    }

    /// The Log In button, which shows a spinner while authenticating and is
    /// disabled while loading or when either field is empty.
    private var loginButton: some View {
        Button {
            Task { await viewModel.login(using: sessionStore) }
        } label: {
            ZStack {
                Text("Log In")
                    .font(.headline)
                    .opacity(viewModel.isLoading ? 0 : 1)

                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.nexusGold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.isLoginButtonEnabled ? Color.nexusDark : Color.gray.opacity(0.3))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .foregroundColor(viewModel.isLoginButtonEnabled ? Color.nexusGold : .gray)
        .disabled(!viewModel.isLoginButtonEnabled)
        .accessibilityLabel("Log in")
        .accessibilityValue(viewModel.isLoading ? "Authenticating" : "")
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(SessionStore())
    }
}
