//
//  LuxuryCardModifier.swift
//  NexusRetail
//
//  Reusable card styling modifier and View extension used across SalesAssociate tabs.
//

import SwiftUI

struct LuxuryCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.045), radius: 18, x: 0, y: 8)
    }
}

extension View {
    func luxuryCard() -> some View {
        modifier(LuxuryCardModifier())
    }

    func screenPadding() -> some View {
        padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 34)
    }
}
