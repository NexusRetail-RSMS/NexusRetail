//
//  DesignSystem.swift
//  NexusRetail
//

import SwiftUI

/// Luxury design tokens for NexusRetail
extension Color {
    /// Deep Maroon / Red Primary
    static let nexusRed = Color(hex: "#720B0D")
    
    /// Warm Cream Background
    static let nexusBackground = Color(hex: "#FAF6F0")
    
    /// Gold/Bronze Accent
    static let nexusGold = Color(hex: "#A68153")
    
    /// Dark Brown/Black for text and solid dark buttons
    static let nexusDark = Color(hex: "#1A1513")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// A primary button style matching the luxury aesthetic.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Color.nexusDark : Color.gray.opacity(0.3))
            .foregroundColor(isEnabled ? Color.nexusBackground : .gray)
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
