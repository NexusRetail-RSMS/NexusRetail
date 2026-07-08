import SwiftUI

@Observable
class AppTheme {
    var isDarkMode = false

    var background: Color {
        isDarkMode ? Color(hex: "1A1A1A") : Color(hex: "F9F8F3")
    }
    var cardBackground: Color {
        isDarkMode ? Color(hex: "1E1E1E") : Color.white
    }
    var headerBackground: Color {
        isDarkMode ? Color(hex: "2C0000") : Color(hex: "8B0000")
    }

    var primaryText: Color {
        isDarkMode ? Color(hex: "EDE7C7") : Color(hex: "200E01")
    }
    var secondaryText: Color {
        isDarkMode ? Color(hex: "9E8E7A") : Color.gray
    }

    var burgundy: Color {
        isDarkMode ? Color(hex: "A52A2A") : Color(hex: "8B0000")
    }
    var darkBurgundy: Color {
        isDarkMode ? Color(hex: "3D0000") : Color(hex: "5B0202")
    }
    var gold: Color {
        isDarkMode ? Color(hex: "C9A84C") : Color(hex: "D4AF37")
    }
    var darkBrown: Color {
        isDarkMode ? Color(hex: "3E2723") : Color(hex: "200E01")
    }

    var primaryAction: Color {
        isDarkMode ? Color(hex: "C9A84C") : Color(hex: "8B0000")
    }
    var error: Color {
        isDarkMode ? Color(hex: "CF6679") : Color(hex: "D32F2F")
    }
    var success: Color {
        isDarkMode ? Color(hex: "81C784") : Color(hex: "2E7D32")
    }

    var cardBorder: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.15)
    }
    var divider: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.gray.opacity(0.15)
    }
    var warning: Color {
        isDarkMode ? Color(hex: "F4A261") : Color(hex: "F57C00")
    }
    var inputBorder: Color {
        isDarkMode ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }
    var disabled: Color {
        isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.4)
    }
}
