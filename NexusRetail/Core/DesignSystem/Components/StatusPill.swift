//
//  StatusPill.swift
//  NexusRetail
//
//  Small colored status label (e.g. Pending / Approved).

import SwiftUI

/// A small status indicator with a colored dot and label text.
/// Used to show payment configuration status (Configured, Not Configured, Invalid).
struct StatusPill: View {
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
}

// MARK: - Convenience Initializers for Payment Status

extension StatusPill {
    /// Creates a status pill for a `PaymentConfigStatus` value.
    static func forPaymentStatus(_ status: PaymentConfigStatus) -> StatusPill {
        switch status {
        case .notConfigured:
            return StatusPill(label: "Not Configured", color: RSMSColors.warning)
        case .configured:
            return StatusPill(label: "Configured", color: RSMSColors.success)
        case .invalid:
            return StatusPill(label: "Invalid", color: RSMSColors.error)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusPill(label: "Configured", color: RSMSColors.success)
        StatusPill(label: "Not Configured", color: RSMSColors.warning)
        StatusPill(label: "Invalid", color: RSMSColors.error)
    }
    .padding()
}
