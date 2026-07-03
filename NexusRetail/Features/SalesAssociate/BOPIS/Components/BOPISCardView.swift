//
//  BOPISCardView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISCardView: View {
    let order: BOPISOrder
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
            // Header: Order ID & Status
            HStack {
                Text(order.orderId)
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)
                Spacer()
                PickupStatusBadge(status: order.status)
            }
            
            Divider()
                .background(RSMSColors.divider)
            
            // Customer Details & Order Summary
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                    Label(order.customerName, systemImage: "person.fill")
                        .font(RSMSFonts.body)
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Label(order.phoneNumber, systemImage: "phone.fill")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Label(order.pickupTime, systemImage: "clock.fill")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: RSMSSpacing.sm) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Items")
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.secondaryText)
                        Text("\(order.itemCount)")
                            .font(RSMSFonts.headline)
                            .foregroundColor(RSMSColors.primaryText)
                    }
                    
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Total")
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.secondaryText)
                        Text(String(format: "$%.2f", order.totalAmount))
                            .font(RSMSFonts.headline)
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
            }
            
            // Verification Code (if applicable)
            if let code = order.verificationCode {
                HStack {
                    Text("Verification Code:")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                    Text(code)
                        .font(RSMSFonts.headline)
                        .foregroundColor(RSMSColors.burgundy)
                }
                .padding()
                .background(RSMSColors.cream)
                .cornerRadius(RSMSRadius.small)
            }
            
            // Action Button
            if order.status != .collected {
                PickupActionButton(status: order.status, action: action)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
}
