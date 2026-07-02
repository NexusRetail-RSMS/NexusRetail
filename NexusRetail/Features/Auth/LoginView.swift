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
    @State private var isPresented = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Screen Background Color
            RSMSColors.background
                .ignoresSafeArea()

            // Background Watermark Image (placed in the back, behind the card)
            GeometryReader { geometry in
                Image("ChatGPT Image Jun 25, 2026, 11_07_16 AM")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width + 240, height: geometry.size.height)
                    .offset(x: -180)
                    .opacity(0.35)
            }
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
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(RSMSColors.burgundy.opacity(0.3))
//                        .frame(width: 40, height: 4)
//                        .padding(.top, 16)
//                        .padding(.bottom, 8)
                    
                    VStack(spacing: RSMSSpacing.lg) {
                        // MARK: - Titles & Subtitles
                        VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                            Text("Welcome!")
                                .blendMode(.darken)
                                .font(.system(size: 35, weight: .heavy))
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
                            .padding(.horizontal, RSMSSpacing.md)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.45))
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
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
                                .frame(height: 24)
                                
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(RSMSColors.secondaryText)
                                        .imageScale(.medium)
                                        .frame(width: 24, height: 24)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, RSMSSpacing.md)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.45))
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
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

                        // MARK: - Sign In Button
                        signInButton
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: 480)
                .frame(maxHeight: 420)
                .background(
                    ZStack {
                        // iOS Material Frosted Glass
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.88)
                        
                        // Liquid Glass Luminous Sheen
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.65),
                                Color.white.opacity(0.30),
                                Color.white.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 36, bottomLeadingRadius: 54, bottomTrailingRadius: 54, topTrailingRadius: 36))
                .overlay(
                    // Liquid Glass Specular Highlight / Rim Light
                    UnevenRoundedRectangle(topLeadingRadius: 36, bottomLeadingRadius: 54, bottomTrailingRadius: 54, topTrailingRadius: 36)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.65)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)
                .padding(.horizontal, 7)
                .padding(.bottom, 7)
            }
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
        VStack(spacing: RSMSSpacing.xs) {
            ZStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 58))
                    .foregroundColor(RSMSColors.burgundy)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(RSMSColors.background)
                    .offset(y: 3)
            }
            
            Text("NexusRetail")
                .font(.system(size: 42, weight: .black))
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
            .cornerRadius(24)
            .shadow(color: viewModel.isLoginButtonEnabled ? RSMSColors.burgundy.opacity(0.15) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isLoginButtonEnabled)
        .accessibilityLabel("Sign in")
        .accessibilityValue(viewModel.isLoading ? "Authenticating" : "")
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(SessionStore())
    }
}
