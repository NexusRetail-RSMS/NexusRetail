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
    var role: UserRole = .admin
    @State private var viewModel = LoginViewModel()
    @Environment(SessionStore.self) private var sessionStore
    @State private var showPassword = false
    @Environment(\.dismiss) private var dismiss
    @State private var isPresented = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Screen Background Color
            RSMSColors.background
                .ignoresSafeArea()

            // Main Content
            VStack(spacing: 0) {
                Spacer()
                
                logoHeader
                    .padding(.bottom, 20)
                
                Spacer()
                
                // MARK: - Bottom Sheet Card
                VStack(spacing: 0) {
                    // Top drag/indicator handle pill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(RSMSColors.burgundy.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    VStack(spacing: RSMSSpacing.lg) {
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
                                    .foregroundColor(RSMSColors.burgundy)
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
                            .background(RSMSColors.background)
                            .cornerRadius(RSMSRadius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: RSMSRadius.small)
                                    .stroke(RSMSColors.inputBorder, lineWidth: 1)
                            )

                            // Password Input
                            HStack(spacing: RSMSSpacing.sm) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(RSMSColors.burgundy)
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
                            .background(RSMSColors.background)
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

                        // MARK: - Sign In Button (styled in burgundy background to match mockup!)
                        signInButton
                        
                        // MARK: - Apple Sign-in Section
                        appleSignInSection
                        
                        // MARK: - Bottom Security Badge
                        securityBadge
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: 480)
                .background(RSMSColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            
            // MARK: - Background Watermark Image Overlay (renders on top of the sheet)
            GeometryReader { geometry in
                Image("ChatGPT Image Jun 25, 2026, 11_07_16 AM")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width + 240, height: geometry.size.height)
                    .offset(x: -180)
                    .opacity(0.25)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // MARK: - Custom Back Button (overlaid at top-left, respecting safe area)
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                    Text("Back")
                        .font(RSMSFonts.headline)
                }
                .foregroundColor(RSMSColors.burgundy)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .padding(.leading, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.md)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                isPresented = true
            }
        }
    }

    // MARK: - Logo Header View
    private var logoHeader: some View {
        HStack(spacing: RSMSSpacing.md) {
            ZStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 48))
                    .foregroundColor(RSMSColors.burgundy)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(RSMSColors.background)
                    .offset(y: 3)
            }
            
            Text("NexusRetail")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(RSMSColors.primaryText)
                .tracking(0.5)
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
            .background(viewModel.isLoginButtonEnabled ? RSMSColors.burgundy : RSMSColors.disabled)
            .foregroundColor(.white)
            .cornerRadius(RSMSRadius.medium)
            .shadow(color: viewModel.isLoginButtonEnabled ? RSMSColors.burgundy.opacity(0.15) : Color.clear, radius: 6, x: 0, y: 3)
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
        VStack(spacing: 6) {
            Image(systemName: "shield")
                .foregroundColor(Color(hex: "C5A880"))
                .font(.system(size: 18))
            
            Text("Secure  •  Reliable  •  Efficient")
                .font(RSMSFonts.caption)
                .foregroundColor(RSMSColors.secondaryText)
        }
        .padding(.top, RSMSSpacing.md)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(SessionStore())
    }
}
