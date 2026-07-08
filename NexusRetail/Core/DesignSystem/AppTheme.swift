import SwiftUI

private func dynamicColor(lightHex: String, darkHex: String) -> Color {
    Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(Color(hex: darkHex)) : UIColor(Color(hex: lightHex))
    })
}

private func dynamicColor(light: Color, dark: Color) -> Color {
    Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
    })
}

@Observable
class AppTheme {
    var isDarkMode = false // Kept for legacy/manual overrides if needed

    let background = dynamicColor(lightHex: "F9F8F3", darkHex: "1A1A1A")
    let groupedBackground = dynamicColor(lightHex: "F2F2F7", darkHex: "000000")
    let cardBackground = dynamicColor(light: .white, dark: Color(hex: "1E1E1E"))
    let elevatedSurface = dynamicColor(light: .white, dark: Color(hex: "2C2C2E"))
    let headerBackground = dynamicColor(lightHex: "8B0000", darkHex: "2C0000")

    let primaryText = dynamicColor(lightHex: "200E01", darkHex: "EDE7C7")
    let secondaryText = dynamicColor(light: .gray, dark: Color(hex: "9E8E7A"))
    let tertiaryText = dynamicColor(light: Color.gray.opacity(0.8), dark: Color(hex: "9E8E7A").opacity(0.8))

    let burgundy = dynamicColor(lightHex: "8B0000", darkHex: "A52A2A")
    let darkBurgundy = dynamicColor(lightHex: "5B0202", darkHex: "3D0000")
    let gold = dynamicColor(lightHex: "D4AF37", darkHex: "C9A84C")
    let darkBrown = dynamicColor(lightHex: "200E01", darkHex: "3E2723")
    let darkWoodBrown = dynamicColor(lightHex: "3E2723", darkHex: "3E2723")

    let cream = dynamicColor(lightHex: "EDE7C7", darkHex: "2C2C2E")
    let antiqueGold = dynamicColor(lightHex: "C9A84C", darkHex: "C9A84C")

    let chartBar = dynamicColor(lightHex: "A44A33", darkHex: "A44A33")

    let primaryAction = dynamicColor(lightHex: "8B0000", darkHex: "C9A84C")
    let accent = dynamicColor(lightHex: "8B0000", darkHex: "C9A84C")
    
    let error = dynamicColor(lightHex: "D32F2F", darkHex: "CF6679")
    let success = dynamicColor(lightHex: "2E7D32", darkHex: "81C784")
    let warning = dynamicColor(lightHex: "F57C00", darkHex: "F4A261")

    let cardBorder = dynamicColor(light: Color.gray.opacity(0.15), dark: Color.white.opacity(0.1))
    let divider = dynamicColor(light: Color.gray.opacity(0.15), dark: Color.white.opacity(0.08))
    let inputBorder = dynamicColor(light: Color.gray.opacity(0.3), dark: Color.white.opacity(0.2))
    
    let shadow = dynamicColor(light: Color.black.opacity(0.05), dark: Color.clear)

    let disabled = dynamicColor(light: Color.gray.opacity(0.4), dark: Color.gray.opacity(0.3))
}
