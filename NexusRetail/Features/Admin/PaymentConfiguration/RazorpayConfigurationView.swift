//
//  RazorpayConfigurationView.swift
//  NexusRetail
//
//  Razorpay credential configuration screen.
//  Premium retail design using RSMS design tokens.

import SwiftUI

struct RazorpayConfigurationView: View {

    // MARK: - Parameters

    let storeID: UUID
    let isAdmin: Bool

    // MARK: - State

    @State private var viewModel = RazorpayConfigurationViewModel()
    @State private var showSecret = false
    @State private var showInfoHelper = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full-screen cream background
            RSMSColors.background
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(RSMSColors.burgundy)
                    .scaleEffect(1.2)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                        subtitleSection
                        environmentSection
                        credentialSection
                        securityBadge

                        if isAdmin {
                            actionButtons
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.vertical, RSMSSpacing.xl)
                }
            }
        }
        .navigationTitle("Razorpay Configuration")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(RSMSColors.burgundy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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

    // MARK: - Subtitle

    private var subtitleSection: some View {
        Text("Enter your Razorpay credentials. You can find these in your Razorpay dashboard.")
            .font(RSMSFonts.subheadline)
            .foregroundColor(RSMSColors.secondaryText)
            .padding(.bottom, RSMSSpacing.xs)
    }

    // MARK: - Environment Picker

    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text("Environment")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.darkBrown)

            Picker("Environment", selection: $viewModel.environment) {
                ForEach(PaymentEnvironment.allCases, id: \.self) { env in
                    Text(env.displayName).tag(env)
                }
            }
            .pickerStyle(.segmented)
            .tint(RSMSColors.burgundy)
            .disabled(!isAdmin)
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Credential Fields

    private var credentialSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
            Text("Credentials")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.darkBrown)

            // Key ID Field
            VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                Text("Key ID")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.darkBrown)

                HStack(spacing: RSMSSpacing.sm) {
                    TextField("Enter Razorpay Key ID", text: $viewModel.keyID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(!isAdmin)

                    Button {
                        withAnimation {
                            showInfoHelper.toggle()
                        }
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(RSMSColors.secondaryText)
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                }
                .padding(RSMSSpacing.md)
                .background(RSMSColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSRadius.small)
                        .stroke(
                            viewModel.keyIDError.isEmpty
                                ? RSMSColors.inputBorder
                                : RSMSColors.error,
                            lineWidth: 1
                        )
                )
                .cornerRadius(RSMSRadius.small)

                if showInfoHelper {
                    HStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(RSMSColors.burgundy)
                        
                        Text(viewModel.environment == .test 
                             ? "Test Mode: Use your Razorpay Test Key ID (starts with 'rzp_test_'). Generate this in Dashboard > Settings > API Keys." 
                             : "Live Mode: Use your Razorpay Live Key ID (starts with 'rzp_live_').")
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(RSMSSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RSMSColors.burgundy.opacity(0.06))
                    .cornerRadius(RSMSRadius.small)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if !viewModel.keyIDError.isEmpty {
                    Text(viewModel.keyIDError)
                        .font(RSMSFonts.caption)
                        .foregroundColor(RSMSColors.error)
                }
            }

            // Key Secret Field
            VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                Text("Key Secret")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.darkBrown)

                HStack(spacing: RSMSSpacing.sm) {
                    Group {
                        if showSecret {
                            TextField("Enter Razorpay Key Secret", text: $viewModel.keySecret)
                        } else {
                            SecureField("Enter Razorpay Key Secret", text: $viewModel.keySecret)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(!isAdmin)

                    Button {
                        showSecret.toggle()
                    } label: {
                        Image(systemName: showSecret ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(RSMSColors.secondaryText)
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isAdmin)
                }
                .padding(RSMSSpacing.md)
                .background(RSMSColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSRadius.small)
                        .stroke(
                            viewModel.keySecretError.isEmpty
                                ? RSMSColors.inputBorder
                                : RSMSColors.error,
                            lineWidth: 1
                        )
                )
                .cornerRadius(RSMSRadius.small)

                if !viewModel.keySecretError.isEmpty {
                    Text(viewModel.keySecretError)
                        .font(RSMSFonts.caption)
                        .foregroundColor(RSMSColors.error)
                }
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Security Badge

    private var securityBadge: some View {
        HStack(spacing: RSMSSpacing.sm) {
            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                .foregroundColor(RSMSColors.success)
                .imageScale(.medium)

            Text("Your credentials are encrypted and stored securely.")
                .font(RSMSFonts.caption)
                .foregroundColor(RSMSColors.success)
        }
        .padding(RSMSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSColors.success.opacity(0.08))
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
                    title: "Disable Razorpay",
                    color: RSMSColors.error
                ) {
                    Task {
                        await disableRazorpay()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, RSMSSpacing.sm)
    }

    // MARK: - Disable Action

    /// Disables the Razorpay configuration by toggling `isEnabled` to false.
    private func disableRazorpay() async {
        guard let id = viewModel.configID else { return }

        viewModel.isSaving = true
        defer { viewModel.isSaving = false }

        do {
            try await viewModel.service.toggleEnabled(id: id, isEnabled: false)
            viewModel.successMessage = "Razorpay has been disabled."
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
        RazorpayConfigurationView(
            storeID: UUID(),
            isAdmin: true
        )
    }
}

#Preview("Read-Only") {
    NavigationStack {
        RazorpayConfigurationView(
            storeID: UUID(),
            isAdmin: false
        )
    }
}
