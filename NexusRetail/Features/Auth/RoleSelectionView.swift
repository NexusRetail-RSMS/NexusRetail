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
        ZStack {
            // Screen-wide cream background
            RSMSColors.background
                .ignoresSafeArea()

            // Immersive background store image
            GeometryReader { geometry in
                HStack {
                    Spacer()
                    Image("ChatGPT Image Jun 25, 2026, 11_07_16 AM")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width * 0.5)
                        .clipped()
                        .opacity(0.15)
                        .ignoresSafeArea()
                }
            }
            .ignoresSafeArea()

            VStack(spacing: RSMSSpacing.xl) {
                Spacer(minLength: RSMSSpacing.md)

                // Header Image / Icon (colored in burgundy)
                Image(systemName: "person.3.sequence.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(RSMSColors.burgundy)
                    .padding(.top, RSMSSpacing.md)
                
                // Titles
                VStack(spacing: RSMSSpacing.sm) {
                    Text("Choose your role")
                        .font(RSMSFonts.title)
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text("Select the option that best describes\nyour responsibilities.")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, RSMSSpacing.sm)
                
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
                
                Spacer()
                
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
                .padding(.bottom, RSMSSpacing.xl)
            }
            .padding(.horizontal, RSMSSpacing.lg)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let role = selectedRole {
            LoginView()
        } else {
            EmptyView()
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
                
                // Text Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(role.displayName)
                        .font(RSMSFonts.headline)
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text(role.descriptionText)
                        .font(RSMSFonts.caption)
                        .foregroundColor(RSMSColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
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
                    .stroke(isSelected ? RSMSColors.burgundy : RSMSColors.cardBorder, lineWidth: isSelected ? 2 : 1)
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
