//
//  PickupStatusBadge.swift
//  NexusRetail
//

import SwiftUI

struct PickupStatusBadge: View {
    let status: BOPISOrderStatus
    
    private var badgeColor: Color {
        switch status {
        case .pending:
            return RSMSColors.warning
        case .readyForPickup:
            return RSMSColors.success
        case .waitingForCustomer:
            return Color.blue // Or another highlight color
        case .collected:
            return RSMSColors.secondaryText
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(RSMSFonts.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, RSMSSpacing.sm)
            .padding(.vertical, RSMSSpacing.xs)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .cornerRadius(RSMSRadius.small)
    }
}
