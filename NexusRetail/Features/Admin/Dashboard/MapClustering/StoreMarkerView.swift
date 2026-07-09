//
//  StoreMarkerView.swift
//  NexusRetail
//

import SwiftUI

/// A branded map marker with a burgundy pin appearance.
struct StoreMarkerView: View {
    @Environment(AppTheme.self) private var theme
    let store: StoreMapItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Outer glow when selected
                if isSelected {
                    Circle()
                        .fill(theme.burgundy.opacity(0.15))
                        .frame(width: 40, height: 40)
                }

                // Main pin circle
                Circle()
                    .fill(isSelected ? theme.darkBurgundy : theme.burgundy)
                    .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)
                    .shadow(color: theme.burgundy.opacity(0.35), radius: 4, x: 0, y: 2)

                // Icon
                Image(systemName: "building.2.fill")
                    .font(.system(size: isSelected ? 12 : 9, weight: .bold))
                    .foregroundColor(.white)
            }

            // Triangle pointer
            Triangle()
                .fill(isSelected ? theme.darkBurgundy : theme.burgundy)
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.clear)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
