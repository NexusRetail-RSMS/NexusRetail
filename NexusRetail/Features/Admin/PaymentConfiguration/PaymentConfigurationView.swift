//
//  PaymentConfigurationView.swift
//  NexusRetail
//
//  List screen for viewing and managing payment gateway configurations.
//  Renders provider cards with toggles, status pills, and navigation to detail screens.

import SwiftUI

/// The Payment Configuration list screen.
/// Displays all payment providers as premium cards with toggles, status indicators,
/// and navigation links to individual configuration detail screens.
struct PaymentConfigurationView: View {

    @State private var viewModel = PaymentConfigurationViewModel()
    @Environment(\.dismiss) private var dismiss

    let isAdmin: Bool
    let storeID: UUID

    var body: some View {
        ZStack {
            // Full-screen cream background
            RSMSColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: - Custom Header
                    customHeaderSection

                    // MARK: - Content Area
                    VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                        
                        // Page Intro
                        pageIntroSection

                        // MARK: - Provider Cards
                        providerCards

                        // MARK: - Status Banner
                        paymentReadinessBanner
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)

            // MARK: - Loading Overlay

            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadConfigurations(storeID: storeID)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage)
        }
    }

    // MARK: - Header Section

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
                Text(viewModel.storeName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Payment Configuration")
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
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }

    private var pageIntroSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text("Payment Gateways")
                .font(RSMSFonts.title)
                .foregroundColor(RSMSColors.burgundy)

            Text("Configure payment gateways for your store so you can start accepting payments.")
                .font(RSMSFonts.subheadline)
                .foregroundColor(RSMSColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Provider Cards

    private var providerCards: some View {
        VStack(spacing: RSMSSpacing.lg) {
            if let razorpay = viewModel.razorpayConfig {
                providerCard(for: razorpay)
            }
            if let card = viewModel.cardConfig {
                providerCard(for: card)
            }
        }
    }

    /// A single provider card with icon, name, toggle, status pill, timestamp, and navigation chevron.
    private func providerCard(for config: PaymentConfiguration) -> some View {
        NavigationLink {
            destinationView(for: config)
        } label: {
            VStack(spacing: 0) {
                // Top Row: Icon + Info + Toggle
                HStack(spacing: RSMSSpacing.md) {
                    // Provider icon in a burgundy circle
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy.opacity(0.12))
                            .frame(width: 48, height: 48)

                        Image(systemName: config.provider.iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(RSMSColors.burgundy)
                    }

                    // Name + subtitle
                    VStack(alignment: .leading, spacing: 3) {
                        Text(config.provider.displayName)
                            .font(RSMSFonts.headline)
                            .foregroundColor(RSMSColors.primaryText)

                        Text(config.provider.subtitle)
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Toggle
                    Toggle("", isOn: Binding(
                        get: { config.isEnabled },
                        set: { _ in
                            Task {
                                await viewModel.toggleEnabled(for: config)
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(RSMSColors.burgundy)
                    .disabled(!isAdmin)
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.md)

                // Divider
                Rectangle()
                    .fill(RSMSColors.divider)
                    .frame(height: 1)
                    .padding(.horizontal, RSMSSpacing.lg)

                // Bottom Row: Status pill + Last updated + Chevron
                HStack {
                    StatusPill.forPaymentStatus(config.status)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last Updated")
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.secondaryText)

                        Text(formattedDate(config.updatedAt))
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.primaryText)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(RSMSColors.secondaryText)
                        .padding(.leading, RSMSSpacing.sm)
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.vertical, RSMSSpacing.md)
            }
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.large)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation Destinations

    /// Routes to the correct detail screen based on the payment provider.
    @ViewBuilder
    private func destinationView(for config: PaymentConfiguration) -> some View {
        switch config.provider {
        case .razorpay:
            RazorpayConfigurationView(storeID: storeID, isAdmin: isAdmin)
        case .card:
            CardGatewayConfigurationView(storeID: storeID, isAdmin: isAdmin)
        }
    }

    // MARK: - Payment Readiness Banner

    @ViewBuilder
    private var paymentReadinessBanner: some View {
        if viewModel.canProcessPayments {
            // Success banner
            HStack(spacing: RSMSSpacing.md) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(RSMSColors.success)

                Text("At least one payment gateway is configured. You can now accept payments.")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.success)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(RSMSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RSMSColors.success.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.medium)
                    .stroke(RSMSColors.success.opacity(0.3), lineWidth: 1)
            )
        } else if !viewModel.configurations.isEmpty {
            // Warning banner — only show after configs have loaded
            HStack(spacing: RSMSSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(RSMSColors.warning)

                Text("Store cannot process payments until at least one payment gateway is configured.")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(RSMSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RSMSColors.warning.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.medium)
                    .stroke(RSMSColors.warning.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: RSMSSpacing.md) {
                ProgressView()
                    .controlSize(.large)
                    .tint(RSMSColors.burgundy)

                Text("Loading configurations…")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.primaryText)
            }
            .padding(RSMSSpacing.xxl)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        }
    }

    // MARK: - Date Formatting Helper

    /// Formats an ISO 8601 date string to a human-readable format, or returns "—" if nil.
    private func formattedDate(_ isoString: String?) -> String {
        guard let isoString, !isoString.isEmpty else { return "—" }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Try with fractional seconds first, then without
        if let date = isoFormatter.date(from: isoString) {
            return displayFormatter.string(from: date)
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: isoString) {
            return displayFormatter.string(from: date)
        }

        return "—"
    }

    /// Shared display date formatter: "dd MMM yyyy, hh:mm a"
    private var displayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PaymentConfigurationView(isAdmin: true, storeID: UUID())
    }
}
