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
    var color: Color = RSMSColors.burgundy
    
    var body: some View {
        HStack(spacing: RSMSSpacing.sm) {
            // Double-circle icon on the left
            ZStack {
                Circle()
                    .fill(color.opacity(0.08))
                    .frame(width: 56, height: 56)
                
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            // Value + label on the right
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, RSMSSpacing.md)
        .padding(.vertical, 18) // Make card bigger vertically
        .background(color.opacity(0.04))
        .cornerRadius(RSMSRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
