// GradientButton.swift

import SwiftUI

struct GradientButton: View {
    var title: String
    var icon: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 15) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(localized: title)
                    Image(systemName: icon)
                }
            }
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 35)
            .background(
                .linearGradient(colors: [RSMSColors.burgundy], startPoint: .top, endPoint: .bottom),
                in: .capsule
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? "Loading" : "")
    }
}

#Preview("Enabled") {
    GradientButton(title: "Login", icon: "arrow.right", isEnabled: true) {}
        .padding()
        .background(RSMSColors.background)
}

#Preview("Loading") {
    GradientButton(title: "Login", icon: "arrow.right", isLoading: true, isEnabled: true) {}
        .padding()
        .background(RSMSColors.background)
}

#Preview("Disabled") {
    GradientButton(title: "Login", icon: "arrow.right", isEnabled: false) {}
        .padding()
        .background(RSMSColors.background)
}
