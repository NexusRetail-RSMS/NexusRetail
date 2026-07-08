//
//  PickupStatusBadge.swift
//  NexusRetail
//

import SwiftUI

struct PickupStatusBadge: View {
    @Environment(AppTheme.self) private var theme
    let status: BOPISOrderStatus
    
    private var badgeColor: Color {
        switch status {
        case .pending:
            return theme.warning
        case .waitingForCustomer:
            return Color.blue // Or another highlight color
        case .collected:
            return theme.secondaryText
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
