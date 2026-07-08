//
//  CardGatewayConfigurationView.swift
//  NexusRetail
//
//  Card Gateway (Stripe) credential configuration screen.
//  Premium retail design using RSMS design tokens.
//

import SwiftUI

struct CardGatewayConfigurationView: View {
    @Environment(AppTheme.self) private var theme

    // MARK: - Parameters

    let storeID: UUID
    let isAdmin: Bool

    // MARK: - State

    @State private var viewModel = CardGatewayConfigurationViewModel()
    @State private var showSecret = false
    @State private var showInfoHelper = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full-screen cream background
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // MARK: - Custom Header
                    customHeaderSection

                    // MARK: - Content
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .tint(theme.burgundy)
                                .scaleEffect(1.2)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                            Spacer()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                            subtitleSection

                            credentialSection
                            securityBadge

                            if isAdmin {
                                actionButtons
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.xl)
                        .padding(.bottom, RSMSSpacing.xxl)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadExisting(storeID: storeID)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage)
        }
    }

    // MARK: - Custom Header

    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Back")
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Card Payments (Stripe)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Credential Configuration")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [theme.burgundy, theme.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }

    // MARK: - Subtitle

    private var subtitleSection: some View {
        Text("Enter your Stripe credentials. You can find these in your Stripe dashboard.")
            .font(RSMSFonts.subheadline)
            .foregroundColor(theme.secondaryText)
            .padding(.bottom, RSMSSpacing.xs)
    }



    // MARK: - Credential Fields

    private var credentialSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
            Text("Credentials")
                .font(RSMSFonts.headline)
                .foregroundColor(theme.darkBrown)

            // Publishable Key Field
            VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                Text("Publishable Key")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(theme.darkBrown)

                HStack(spacing: RSMSSpacing.sm) {
                    TextField("Enter Publishable Key", text: $viewModel.publicKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(!isAdmin)

                    Button {
                        withAnimation {
                            showInfoHelper.toggle()
                        }
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(theme.secondaryText)
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                }
                .padding(RSMSSpacing.md)
                .background(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSRadius.small)
                        .stroke(
                            viewModel.publicKeyError.isEmpty
                                ? theme.inputBorder
                                : theme.error,
                            lineWidth: 1
                        )
                )
                .cornerRadius(RSMSRadius.small)

                if showInfoHelper {
                    HStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(theme.burgundy)
                        
                        Text(viewModel.environment == .test 
                             ? "Test Mode: Use your Stripe Test Publishable Key (starts with 'pk_test_'). Find this in Dashboard > Developers > API Keys." 
                             : "Live Mode: Use your Stripe Live Publishable Key (starts with 'pk_live_').")
                            .font(RSMSFonts.caption)
                            .foregroundColor(theme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(RSMSSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.burgundy.opacity(0.06))
                    .cornerRadius(RSMSRadius.small)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if !viewModel.publicKeyError.isEmpty {
                    Text(viewModel.publicKeyError)
                        .font(RSMSFonts.caption)
                        .foregroundColor(theme.error)
                }
            }

            // Secret Key Field
            VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                Text("Secret Key")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(theme.darkBrown)

                HStack(spacing: RSMSSpacing.sm) {
                    Group {
                        if showSecret {
                            TextField("Enter Secret Key", text: $viewModel.secretKey)
                        } else {
                            SecureField("Enter Secret Key", text: $viewModel.secretKey)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(!isAdmin)

                    Button {
                        showSecret.toggle()
                    } label: {
                        Image(systemName: showSecret ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(theme.secondaryText)
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isAdmin)
                }
                .padding(RSMSSpacing.md)
                .background(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSRadius.small)
                        .stroke(
                            viewModel.secretKeyError.isEmpty
                                ? theme.inputBorder
                                : theme.error,
                            lineWidth: 1
                        )
                )
                .cornerRadius(RSMSRadius.small)

                if !viewModel.secretKeyError.isEmpty {
                    Text(viewModel.secretKeyError)
                        .font(RSMSFonts.caption)
                        .foregroundColor(theme.error)
                }
            }
        }
        .padding(RSMSSpacing.lg)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Security Badge

    private var securityBadge: some View {
        HStack(spacing: RSMSSpacing.sm) {
            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                .foregroundColor(theme.success)
                .imageScale(.medium)

            Text("Your credentials are encrypted and stored securely.")
                .font(RSMSFonts.caption)
                .foregroundColor(theme.success)
        }
        .padding(RSMSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.success.opacity(0.08))
        .cornerRadius(RSMSRadius.small)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: RSMSSpacing.lg) {
            RSMSPrimaryButton(
                title: viewModel.isEditing ? "Save Changes" : "Save Configuration",
                isLoading: viewModel.isSaving,
                isDisabled: !isAdmin
            ) {
                Task {
                    await viewModel.save(storeID: storeID)
                }
            }

            if viewModel.isEditing {
                RSMSSecondaryButton(
                    title: "Disable Card Gateway",
                    isDestructive: true
                ) {
                    Task {
                        await disableCardGateway()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, RSMSSpacing.sm)
    }

    // MARK: - Disable Action

    /// Disables the Card configuration by toggling `isEnabled` to false.
    private func disableCardGateway() async {
        guard let id = viewModel.configID else { return }

        viewModel.isSaving = true
        defer { viewModel.isSaving = false }

        do {
            try await viewModel.service.toggleEnabled(id: id, isEnabled: false)
            viewModel.successMessage = "Card Gateway has been disabled."
            viewModel.showSuccess = true
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }
}

// MARK: - Preview

#Preview("Admin — New Config") {
    NavigationStack {
        CardGatewayConfigurationView(
            storeID: UUID(),
            isAdmin: true
        )
    }
}

#Preview("Read-Only") {
    NavigationStack {
        CardGatewayConfigurationView(
            storeID: UUID(),
            isAdmin: false
        )
    }
}
