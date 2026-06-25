//
//  LoginView.swift
//  NexusRetail
//
//  The login screen UI for NexusRetail. Renders the title, email and password
//  fields, the Log In button, an inline error label, and a loading spinner.
//  Refactored to match the premium RSMS layout and branding.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(SessionStore.self) private var sessionStore
    @State private var showPassword = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Full-screen cream background
                RSMSColors.background
                    .ignoresSafeArea()

                // Immersive background store image (full-screen, shifted left)
                Image("ChatGPT Image Jun 25, 2026, 11_07_16 AM")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width + 240, height: geometry.size.height)
                    .offset(x: -180)
                    .opacity(0.25)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSSpacing.xl) {
                        
                        // MARK: - Logo Header
                        logoHeader
                            .padding(.top, geometry.safeAreaInsets.top + 64)

                        // MARK: - Titles & Subtitles
                        VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                            Text("Welcome back!")
                                .font(RSMSFonts.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(RSMSColors.primaryText)
                            
                            Text("Sign in to continue to your account")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, RSMSSpacing.sm)

                        // MARK: - Credential Inputs
                        VStack(spacing: RSMSSpacing.md) {
                            // Email/Username Input
                            HStack(spacing: RSMSSpacing.sm) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .frame(width: 20)
                                
                                TextField("Email or Username", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .textContentType(.username)
                                    .font(RSMSFonts.body)
                                    .accessibilityLabel("Email address or username")
                            }
                            .padding(RSMSSpacing.md)
                            .background(RSMSColors.cardBackground)
                            .cornerRadius(RSMSRadius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: RSMSRadius.small)
                                    .stroke(RSMSColors.inputBorder, lineWidth: 1)
                            )

                            // Password Input
                            HStack(spacing: RSMSSpacing.sm) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .frame(width: 20)
                                
                                Group {
                                    if showPassword {
                                        TextField("Password", text: $viewModel.password)
                                            .textContentType(.password)
                                            .font(RSMSFonts.body)
                                    } else {
                                        SecureField("Password", text: $viewModel.password)
                                            .textContentType(.password)
                                            .font(RSMSFonts.body)
                                    }
                                }
                                .accessibilityLabel("Password")
                                
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(RSMSColors.secondaryText)
                                        .imageScale(.medium)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(RSMSSpacing.md)
                            .background(RSMSColors.cardBackground)
                            .cornerRadius(RSMSRadius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: RSMSRadius.small)
                                    .stroke(RSMSColors.inputBorder, lineWidth: 1)
                            )
                            
                            // Forgot Password Link
                            HStack {
                                Spacer()
                                Button(action: {}) {
                                    Text("Forgot password?")
                                        .font(RSMSFonts.subheadline)
                                        .foregroundColor(RSMSColors.burgundy)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Error Message (if any)
                        errorLabel

                        // MARK: - Sign In Button (styled in dark brown)
                        signInButton
                        
                        // MARK: - Apple Sign-in Section
                        appleSignInSection
                        
                        Spacer()
                        
                        // MARK: - Bottom Security Badge
                        securityBadge
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .frame(maxWidth: 480)
                }
                .frame(width: geometry.size.width)

                // MARK: - Custom Back Button
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text("Back")
                            .font(RSMSFonts.headline)
                        Spacer()
                    }
                    .foregroundColor(RSMSColors.burgundy)
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.vertical, RSMSSpacing.md)
                }
                .padding(.top, geometry.safeAreaInsets.top)
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Logo Header View
    private var logoHeader: some View {
        VStack(spacing: RSMSSpacing.sm) {
            ZStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 64))
                    .foregroundColor(RSMSColors.burgundy)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 22))
                    .foregroundColor(RSMSColors.background)
                    .offset(y: 4)
            }
            
            VStack(spacing: 2) {
                Text("RSMS")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(RSMSColors.primaryText)
                    .tracking(2)
                
                Text("RETAIL STORE MANAGEMENT SYSTEM")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(RSMSColors.secondaryText)
                    .tracking(1.5)
            }
        }
    }

    // MARK: - Error Message View
    @ViewBuilder
    private var errorLabel: some View {
        if !viewModel.errorMessage.isEmpty {
            Text(viewModel.errorMessage)
                .font(RSMSFonts.subheadline)
                .foregroundStyle(RSMSColors.error)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Error: \(viewModel.errorMessage)")
                .transition(.opacity)
                .padding(.vertical, RSMSSpacing.xs)
        }
    }

    // MARK: - Sign In Button
    private var signInButton: some View {
        Button {
            Task { await viewModel.login(using: sessionStore) }
        } label: {
            ZStack {
                Text("Sign In")
                    .font(RSMSFonts.headline)
                    .opacity(viewModel.isLoading ? 0 : 1)

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.isLoginButtonEnabled ? RSMSColors.darkBrown : RSMSColors.disabled)
            .foregroundColor(.white)
            .cornerRadius(RSMSRadius.medium)
            .shadow(color: viewModel.isLoginButtonEnabled ? RSMSColors.darkBrown.opacity(0.15) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isLoginButtonEnabled)
        .accessibilityLabel("Sign in")
        .accessibilityValue(viewModel.isLoading ? "Authenticating" : "")
    }

    // MARK: - Apple Sign-in View
    private var appleSignInSection: some View {
        VStack(spacing: RSMSSpacing.md) {
            HStack(spacing: RSMSSpacing.md) {
                Rectangle()
                    .fill(RSMSColors.divider)
                    .frame(height: 1)
                
                Text("or continue with")
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
                
                Rectangle()
                    .fill(RSMSColors.divider)
                    .frame(height: 1)
            }
            .padding(.vertical, RSMSSpacing.xs)
            
            Button(action: {}) {
                HStack(spacing: RSMSSpacing.sm) {
                    Image(systemName: "apple.logo")
                        .font(.headline)
                    Text("Continue with Apple")
                        .font(RSMSFonts.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(RSMSRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSRadius.medium)
                        .stroke(Color.black, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bottom Security Badge
    private var securityBadge: some View {
        HStack(spacing: RSMSSpacing.xs) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.orange)
                .imageScale(.small)
            
            Text("Secure  •  Reliable  •  Efficient")
                .font(RSMSFonts.caption)
                .foregroundColor(RSMSColors.secondaryText)
        }
        .padding(.top, RSMSSpacing.xl)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(SessionStore())
    }
}
