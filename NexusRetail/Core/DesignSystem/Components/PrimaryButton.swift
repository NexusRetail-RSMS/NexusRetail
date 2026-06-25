//
//  PrimaryButton.swift
//  NexusRetail
//
//  Reusable styled primary button.

import SwiftUI

/// A full-width primary action button styled with the RSMS brand.
/// Supports a loading state that replaces the label with a spinner.
struct RSMSPrimaryButton: View {
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
            .background(isDisabled ? RSMSColors.disabled : RSMSColors.burgundy)
            .foregroundColor(.white)
            .cornerRadius(RSMSRadius.medium)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}

/// A secondary / destructive link-style button (e.g., "Disable Razorpay").
struct RSMSSecondaryButton: View {
    let title: String
    var color: Color = RSMSColors.burgundy
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        RSMSPrimaryButton(title: "Save Configuration", action: {})
        RSMSPrimaryButton(title: "Saving...", isLoading: true, action: {})
        RSMSPrimaryButton(title: "Disabled", isDisabled: true, action: {})
        RSMSSecondaryButton(title: "Disable Razorpay", color: .red, action: {})
    }
    .padding()
}
