//
//  PickupActionButton.swift
//  NexusRetail
//

import SwiftUI

struct PickupActionButton: View {
    let status: BOPISOrderStatus
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(buttonTitle)
                .font(RSMSFonts.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, RSMSSpacing.md)
                .background(RSMSColors.burgundy)
                .cornerRadius(RSMSRadius.medium)
        }
    }
    
    private var buttonTitle: String {
        switch status {
        case .pending:
            return "Pack Order"
        case .waitingForCustomer:
            return "Mark as Collected"
        case .collected:
            return "Collected"
        }
    }
}
