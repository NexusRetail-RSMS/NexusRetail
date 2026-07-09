//
//  AddCircleButton.swift
//  NexusRetail
//
//  The app-wide "Add" button: a burgundy gradient circle with a white plus,
//  soft shadow, and press animation. Matches the Stores screen design so every
//  add action looks consistent across roles.
//

import SwiftUI

struct AddCircleButton: View {
    @Environment(AppTheme.self) private var theme
    var accessibilityLabel: String = "Add"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(
                        colors: [theme.burgundy, theme.burgundy.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: theme.burgundy.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PremiumPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
