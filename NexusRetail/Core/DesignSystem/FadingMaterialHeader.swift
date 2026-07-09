//
//  FadingMaterialHeader.swift
//  NexusRetail
//
//  A sticky-header background that uses a frosted material which softly fades
//  out at its bottom edge (instead of a hard cut-off), so scrolling content
//  slides under it smoothly. Ported from the feature-harman UI refinements.
//

import SwiftUI

struct FadingMaterialHeader: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.915)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.8),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .top)
        )
    }
}

extension View {
    /// Applies a frosted material header background that fades out at the bottom.
    func fadingMaterialHeader() -> some View {
        modifier(FadingMaterialHeader())
    }
}
