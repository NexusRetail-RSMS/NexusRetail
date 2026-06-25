//
//  DesignSystem.swift
//  NexusRetail
//

import SwiftUI

/// Luxury design tokens for NexusRetail
extension Color {
    /// Deep Navy Primary
    static let nexusNavy = Color(red: 0.05, green: 0.1, blue: 0.25)
    
    /// Gold Accent
    static let nexusGold = Color(red: 0.85, green: 0.75, blue: 0.45)
    
    /// Subtle background for cards/sections
    static let nexusBackground = Color(UIColor.systemGroupedBackground)
}

/// A primary button style matching the luxury aesthetic.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Color.nexusNavy : Color.gray.opacity(0.3))
            .foregroundColor(isEnabled ? Color.nexusGold : .gray)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// A reusable KPI card for dashboards.
struct KPICardView: View {
    let title: String
    let value: String
    let icon: String
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.08))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .foregroundColor(RSMSColors.burgundy)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trend.contains("+") || trend.contains("approved") ? RSMSColors.success : .orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(RSMSFonts.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(title)
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(RSMSSpacing.md)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(trend ?? "")
    }
}
