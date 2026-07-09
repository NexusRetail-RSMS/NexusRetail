//
//  StatusPill.swift
//  NexusRetail
//
//  Small colored status label (e.g. Pending / Approved).

import SwiftUI

enum StatusPillStyle {
    case success, warning, error, normal
}

/// A small status indicator with a colored dot and label text.
/// Used to show payment configuration status (Configured, Not Configured, Invalid).
struct StatusPill: View {
    @Environment(AppTheme.self) private var theme
    let label: String
    let style: StatusPillStyle
    
    var resolvedColor: Color {
        switch style {
        case .success: return theme.success
        case .warning: return theme.warning
        case .error: return theme.error
        case .normal: return theme.primaryText
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(resolvedColor)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(resolvedColor)
        }
    }
}

// MARK: - Convenience Initializers for Payment Status

extension StatusPill {
    /// Creates a status pill for a `PaymentConfigStatus` value.
    static func forPaymentStatus(_ status: PaymentConfigStatus) -> StatusPill {
        switch status {
        case .notConfigured:
            return StatusPill(label: "Not Configured", style: .warning)
        case .configured:
            return StatusPill(label: "Configured", style: .success)
        case .invalid:
            return StatusPill(label: "Invalid", style: .error)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusPill(label: "Configured", style: .success)
            .environment(AppTheme())
        StatusPill(label: "Not Configured", style: .warning)
            .environment(AppTheme())
        StatusPill(label: "Invalid", style: .error)
            .environment(AppTheme())
    }
    .padding()
}
