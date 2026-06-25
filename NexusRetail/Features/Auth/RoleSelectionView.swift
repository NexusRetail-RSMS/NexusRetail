//
//  RoleSelectionView.swift
//  NexusRetail
//
//  This file is deprecated and no longer used in the auth flow.
//

import SwiftUI

/// Pre-login screen where the user selects their expected role before proceeding.
/// Refactored to use the RSMS brand colors and design guidelines.
struct RoleSelectionView: View {
    @State private var selectedRole: UserRole? = nil

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Half: Centered Logo
                VStack {
                    Spacer()
                    logoHeader
                    Spacer()
                }
                .frame(height: geometry.size.height * 0.30)
                .frame(maxWidth: .infinity)
                
                // Bottom Half: Scrollable bottom card
                VStack(spacing: 0) {
                    // Top drag/indicator handle pill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(RSMSColors.burgundy.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: RSMSSpacing.xl) {
                            // Title
                            Text("Choose your role")
                                .font(RSMSFonts.title)
                                .foregroundColor(RSMSColors.primaryText)
                                .padding(.top, RSMSSpacing.sm)
                            
                            // Role Cards
                            VStack(spacing: RSMSSpacing.md) {
                                ForEach(UserRole.allCases, id: \.self) { role in
                                    RoleCardView(
                                        role: role,
                                        isSelected: selectedRole == role
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedRole = role
                                        }
                                    }
                                }
                            }
                            
                            // Continue Button (uses RSMSColors.burgundy and RSMSColors.disabled)
                            NavigationLink(destination: destinationView) {
                                Text("Continue")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(selectedRole == nil ? RSMSColors.disabled : RSMSColors.burgundy)
                                    .foregroundColor(.white)
                                    .cornerRadius(RSMSRadius.medium)
                                    .shadow(color: selectedRole == nil ? Color.clear : RSMSColors.burgundy.opacity(0.15), radius: 6, x: 0, y: 3)
                            }
                            .disabled(selectedRole == nil)
                            .padding(.top, RSMSSpacing.md)
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 24)
                    }
                }
                .frame(height: geometry.size.height * 0.70)
                .frame(maxWidth: .infinity)
                .background(RSMSColors.cardBackground)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 40, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 40))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: -4)
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .background(
            ZStack {
                RSMSColors.background
                    .ignoresSafeArea()

                GeometryReader { geometry in
                    Image("ChatGPT Image Jun 25, 2026, 11_07_16 AM")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width + 240, height: geometry.size.height)
                        .offset(x: -180)
                        .opacity(0.25)
                }
                .ignoresSafeArea()
            }
        )
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let role = selectedRole {
            LoginView(role: role)
        } else {
            EmptyView()
        }
    }

    // MARK: - Logo Header View
    private var logoHeader: some View {
        HStack(spacing: RSMSSpacing.md) {
            ZStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 48))
                    .foregroundColor(RSMSColors.burgundy)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(RSMSColors.background)
                    .offset(y: 3)
            }
            
            Text("NexusRetail")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(RSMSColors.primaryText)
                .tracking(0.5)
        }
    }
}

fileprivate struct RoleCardView: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: RSMSSpacing.md) {
                // Icon (burgundy themed)
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.12))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: role.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(RSMSColors.burgundy)
                }
                
                // Text Content - Header only
                Text(role.displayName)
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                // Radio Button (burgundy themed)
                ZStack {
                    Circle()
                        .stroke(isSelected ? RSMSColors.burgundy : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(RSMSColors.burgundy)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(RSMSSpacing.md)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.large)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: isSelected ? RSMSColors.burgundy.opacity(0.04) : Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        RoleSelectionView()
    }
}
