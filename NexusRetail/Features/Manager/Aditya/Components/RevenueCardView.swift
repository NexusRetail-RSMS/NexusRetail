//
//  RevenueCardView.swift
//  NexusRetail
//

import SwiftUI

struct RevenueCardView: View {
    @Environment(AppTheme.self) private var theme
    let revenue: String
    let trend: String
    let transactions: String
    let averageTicket: String
    let returns: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
            
            // Top Section
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                    Text("TODAY'S REVENUE")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(theme.secondaryText)
                    
                    Text(revenue)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: trend.hasPrefix("-") ? "arrow.down.right" : "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                        Text(trend)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(trend.hasPrefix("-") ? theme.error : theme.success)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(trend.hasPrefix("-") ? theme.error.opacity(0.12) : theme.success.opacity(0.12))
                    .cornerRadius(RSMSRadius.medium)
                    
                    Text("vs yesterday")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Divider()
                .background(theme.divider)
            
            // Bottom Metrics
            HStack(spacing: 0) {
                metricView(title: "Transactions", value: transactions)
                
                Divider()
                    .frame(height: 30)
                    .background(theme.divider)
                    .padding(.horizontal, RSMSSpacing.md)
                
                metricView(title: "Average Ticket", value: averageTicket)
                
                Divider()
                    .frame(height: 30)
                    .background(theme.divider)
                    .padding(.horizontal, RSMSSpacing.md)
                
                metricView(title: "Returns", value: returns)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }
    
    private func metricView(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(value)
                .font(RSMSFonts.headline)
                .foregroundColor(theme.primaryText)
            
            Text(LocalizedStringKey(title))
                .font(.system(size: 10))
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        AppTheme().background.ignoresSafeArea()
        RevenueCardView(
            revenue: "₹1,25,000",
            trend: "+12.4% vs yesterday",
            transactions: "42",
            averageTicket: "₹2,976",
            returns: "2"
        )
        .padding()
    }
}
