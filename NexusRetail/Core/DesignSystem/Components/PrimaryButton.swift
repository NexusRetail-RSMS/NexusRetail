//
//  PrimaryButton.swift
//  NexusRetail
//
//  Reusable styled primary button.

import SwiftUI

/// A full-width primary action button styled with the RSMS brand.
/// Supports a loading state that replaces the label with a spinner.
struct RSMSPrimaryButton: View {
    @Environment(AppTheme.self) private var theme
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .opacity(isLoading ? 0 : 1)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isDisabled ? theme.disabled : theme.primaryAction)
            .foregroundColor(.white)
            .cornerRadius(RSMSRadius.medium)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}

/// A secondary / destructive link-style button (e.g., "Disable Razorpay").
struct RSMSSecondaryButton: View {
    @Environment(AppTheme.self) private var theme
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isDestructive ? theme.error : theme.primaryAction)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        RSMSPrimaryButton(title: "Save Configuration", action: {})
            .environment(AppTheme())
        RSMSPrimaryButton(title: "Saving...", isLoading: true, action: {})
            .environment(AppTheme())
        RSMSPrimaryButton(title: "Disabled", isDisabled: true, action: {})
            .environment(AppTheme())
        RSMSSecondaryButton(title: "Disable Razorpay", isDestructive: true, action: {})
            .environment(AppTheme())
    }
    .padding()
}
