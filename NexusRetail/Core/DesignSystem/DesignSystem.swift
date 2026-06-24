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
    let trend: String? // e.g. "+5% this week"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: icon)
                    .foregroundColor(.nexusGold)
                    .font(.system(size: 20))
            }
            
            Text(value)
                .font(.system(.title, design: .rounded).weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 0)
            
            if let trend = trend {
                Text(trend)
                    .font(.caption)
                    .foregroundColor(.green)
                    .lineLimit(1)
            } else {
                Text(" ")
                    .font(.caption)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(trend ?? "")
    }
}
