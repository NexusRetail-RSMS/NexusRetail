//
//  MorphingView.swift
//  NexusRetail
//
//  Created by ANOOP on 02/07/26.
//

import SwiftUI

struct MorphingView<From: View, To: View>: View {
    var blurRadius: CGFloat = 24
    @Binding var isMorphed: Bool
    @ViewBuilder var from: From
    @ViewBuilder var to: To

    var body: some View {
        ZStack {
            from
                .opacity(isMorphed ? 0 : 1)

            to
                .opacity(isMorphed ? 1 : 0)
        }
        .modifier(MorphingModifier(progress: isMorphed ? 1 : 0, bluredRadius: blurRadius))
    }
}

@Animatable
fileprivate struct MorphingModifier: ViewModifier {
    var progress: CGFloat
    @AnimatableIgnored var bluredRadius: CGFloat
    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .blur(radius: bluredRadius * blurProgress)
            .visualEffect { content, proxy in
                content
                    .layerEffect(
                        ShaderLibrary.alphaThreshold(),
                        maxSampleOffset: proxy.size
                    )
            }
    }

    private var blurProgress: CGFloat {
        progress > 0.5 ? abs(1 - progress) : progress
    }
}
