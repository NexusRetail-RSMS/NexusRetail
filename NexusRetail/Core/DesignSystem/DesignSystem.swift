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
    var color: Color = Color(hex: "007AFF") // Default blue
    
    var body: some View {
        HStack(spacing: 0) {
            // Main content
            VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(RSMSFonts.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    
                    Text(title)
                        .font(RSMSFonts.caption)
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
            .padding(RSMSSpacing.md)
            
            Spacer(minLength: 0)
        }
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

/// Custom shape that gives the header a smooth curved bottom edge
/// instead of a harsh straight line. Used in premium top headers.
public struct HeaderCurve: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 20))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - 20),
            control: CGPoint(x: rect.midX, y: rect.maxY + 10)
        )
        path.closeSubpath()
        return path
    }
}
