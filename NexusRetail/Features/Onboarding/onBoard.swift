//
//  onBoard.swift
//  NexusRetail
//
//  Created by ANOOP on 02/07/26.
//

import SwiftUI

struct OnboardingPageData {
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @Environment(AppTheme.self) private var theme
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var stage = 0
    @State private var morphFirstPair = false
    @State private var morphSecondPair = false
    @State private var hasAppeared = false

    private let morphDuration = 0.6

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            icon: "bag.fill",
            title: "Welcome to NexusRetail",
            subtitle: "Run every store, manager, and sale from one command center."
        ),
        OnboardingPageData(
            icon: "building.2.fill",
            title: "Manage Every Store",
            subtitle: "Track performance, assign managers, and stay in sync across locations."
        ),
        OnboardingPageData(
            icon: "chart.bar.fill",
            title: "Insights That Matter",
            subtitle: "Real-time analytics keep your whole team moving in the right direction."
        )
    ]

    private var currentIndex: Int {
        if stage == 0 { return morphFirstPair ? 1 : 0 }
        return morphSecondPair ? 2 : 1
    }

    private var isLastPage: Bool {
        currentIndex == pages.count - 1
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()
                Group {
                    if stage == 0 {
                        MorphingView(
                            blurRadius: 24,
                            isMorphed: $morphFirstPair,
                            from: { OnboardingPageView(data: pages[0], isMorphed: morphFirstPair, role: .from) },
                            to: { OnboardingPageView(data: pages[1], isMorphed: morphFirstPair, role: .to) }
                        )
                    } else {
                        MorphingView(
                            blurRadius: 24,
                            isMorphed: $morphSecondPair,
                            from: { OnboardingPageView(data: pages[1], isMorphed: morphSecondPair, role: .from) },
                            to: { OnboardingPageView(data: pages[2], isMorphed: morphSecondPair, role: .to) }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(hasAppeared ? 1 : 0)
                .scaleEffect(hasAppeared ? 1 : 0.96)

                Spacer()

                VStack(spacing: RSMSSpacing.lg) {
                    pageIndicator
                    nextButton
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.xl)
                .opacity(hasAppeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            GeometryReader { geometry in
                Image("ChatGPT Image Jun 25, 2026, 11_07_16 AM")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width + 240, height: geometry.size.height)
                    .offset(x: -180)
                    .opacity(0.12)
            }
            .ignoresSafeArea()

            RadialGradient(
                colors: [theme.burgundy.opacity(0.08), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? theme.burgundy : theme.cardBorder)
                    .frame(width: index == currentIndex ? 24 : 7, height: 7)
                    .shadow(
                        color: index == currentIndex ? theme.burgundy.opacity(0.35) : .clear,
                        radius: 4, x: 0, y: 2
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentIndex)
            }
        }
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            advance()
        } label: {
            HStack(spacing: 8) {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.system(size: 15.5, weight: .semibold))
                if !isLastPage {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.burgundy)
            .cornerRadius(24)
            .shadow(color: theme.burgundy.opacity(0.25), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation

    private func advance() {
        switch (stage, morphFirstPair, morphSecondPair) {
        case (0, false, _):
            withAnimation(.easeInOut(duration: morphDuration)) {
                morphFirstPair = true
            }
        case (0, true, _):
            stage = 1
            withAnimation(.easeInOut(duration: morphDuration)) {
                morphSecondPair = true
            }
        default:
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Page Content

private struct OnboardingPageView: View {
    @Environment(AppTheme.self) private var theme
    enum Role {
        case from, to
    }

    let data: OnboardingPageData
    var isMorphed: Bool = false
    var role: Role = .to

    private var textOffsetX: CGFloat {
        switch role {
        case .from: return isMorphed ? -70 : 0
        case .to: return isMorphed ? 0 : 70
        }
    }

    private var textOpacity: Double {
        switch role {
        case .from: return isMorphed ? 0 : 1
        case .to: return isMorphed ? 1 : 0
        }
    }

    var body: some View {
        VStack(spacing: RSMSSpacing.xxl) {
            ZStack {
                Circle()
                    .fill(theme.burgundy.opacity(0.05))
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.burgundy.opacity(0.20), theme.burgundy.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 148, height: 148)
                    .overlay(
                        Circle()
                            .stroke(theme.burgundy.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: theme.burgundy.opacity(0.18), radius: 24, x: 0, y: 14)

                Image(systemName: data.icon)
                    .font(.system(size: 150, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.burgundy, theme.burgundy.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: RSMSSpacing.sm) {
                Text(data.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(data.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, RSMSSpacing.xxl)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .offset(x: textOffsetX)
            .opacity(textOpacity)
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
}

#Preview {
    OnboardingView()
}
