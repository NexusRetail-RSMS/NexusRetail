import SwiftUI

struct CardStyleModifier: ViewModifier {
    @Environment(AppTheme.self) private var theme
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat
    var shadowY: CGFloat

    func body(content: Content) -> some View {
        content
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: theme.shadow, radius: shadowRadius, x: 0, y: shadowY)
    }
}

extension View {
    func standardCard(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 6, shadowY: CGFloat = 2) -> some View {
        modifier(CardStyleModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowY: shadowY))
    }
    
    func luxuryCard() -> some View {
        modifier(CardStyleModifier(cornerRadius: 24, shadowRadius: 18, shadowY: 8))
    }
    
    func screenPadding() -> some View {
        padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 34)
    }
}
