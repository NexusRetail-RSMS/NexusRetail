//
//  BOPISCardView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISCardView: View {
    @Environment(AppTheme.self) private var theme
    let order: BOPISOrder
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
            // Header: Order ID & Status
            HStack {
                Text(order.orderId)
                    .font(RSMSFonts.headline)
                    .foregroundColor(theme.primaryText)
                Spacer()
                PickupStatusBadge(status: order.status)
            }
            
            Divider()
                .background(theme.divider)
            
            // Customer Details & Order Summary
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                    Label(order.customerName, systemImage: "person.fill")
                        .font(RSMSFonts.body)
                        .foregroundColor(theme.primaryText)
                    
                    Label(order.phoneNumber, systemImage: "phone.fill")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(theme.secondaryText)
                    
                    Label(order.pickupTime, systemImage: "clock.fill")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: RSMSSpacing.sm) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Items")
                            .font(RSMSFonts.caption)
                            .foregroundColor(theme.secondaryText)
                        Text("\(order.itemCount)")
                            .font(RSMSFonts.headline)
                            .foregroundColor(theme.primaryText)
                    }
                    
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Total")
                            .font(RSMSFonts.caption)
                            .foregroundColor(theme.secondaryText)
                        Text(formatIndianCurrency(order.totalAmount))
                            .font(RSMSFonts.headline)
                            .foregroundColor(theme.primaryText)
                    }
                }
            }
            
            // The pickup code is emailed to the customer only — never shown here.
            if order.status == .waitingForCustomer {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 12))
                    Text("Pickup code sent to customer")
                        .font(RSMSFonts.subheadline)
                    Spacer()
                }
                .foregroundColor(theme.secondaryText)
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
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }
}
