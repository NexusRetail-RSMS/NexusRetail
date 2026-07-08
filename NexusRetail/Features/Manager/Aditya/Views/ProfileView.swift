//
//  ProfileView.swift
//  NexusRetail
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RSMSSpacing.lg) {
                        // Profile Card
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(theme.burgundy)
                                        .frame(width: 60, height: 60)
                                    
                                    Text(initials(for: sessionStore.currentUser?.name ?? "Manager"))
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sessionStore.currentUser?.name ?? "Aryavansh")
                                        .font(.headline)
                                        .foregroundColor(theme.primaryText)
                                    
                                    Text(sessionStore.currentUser?.email ?? "manager@nexus.com")
                                        .font(.subheadline)
                                        .foregroundColor(theme.secondaryText)
                                    
                                    Text("Role: \(sessionStore.currentUser?.role.rawValue.capitalized ?? "Manager")")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.brown.opacity(0.2))
                                        .foregroundColor(.brown)
                                        .cornerRadius(4)
                                        .padding(.top, 2)
                                }
                                
                                Spacer()
                            }
                            .padding(RSMSSpacing.lg)
                        }
                        .background(theme.cardBackground)
                        .cornerRadius(RSMSRadius.large)
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.lg)
                        
                        // Store Settings Section (Admin Only)
                        if sessionStore.currentUser?.role == .admin {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Store Settings")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryText)
                                    .padding(.horizontal, RSMSSpacing.lg)
                                
                                VStack(spacing: 0) {
                                    Button {
                                        // Action
                                    } label: {
                                        HStack {
                                            Image(systemName: "creditcard")
                                                .foregroundColor(theme.burgundy)
                                            Text("Payment Configuration")
                                                .foregroundColor(theme.primaryText)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(theme.secondaryText)
                                                .font(.caption)
                                        }
                                        .padding()
                                    }
                                }
                                .background(theme.cardBackground)
                                .cornerRadius(RSMSRadius.large)
                                .padding(.horizontal, RSMSSpacing.lg)
                            }
                        }
                        
                        // Language preference
                        LanguageSettingsButton()
                            .padding()
                            .background(theme.cardBackground)
                            .cornerRadius(RSMSRadius.large)
                            .padding(.horizontal, RSMSSpacing.lg)
                            .padding(.top, RSMSSpacing.md)

                        // Sign Out Button
                        Button {
                            Task {
                                dismiss()
                                // Wait for sheet to dismiss before signing out to avoid transition glitches
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                try? await sessionStore.signOut()
                            }
                        } label: {
                            Text("Sign Out")
                                .font(.body.weight(.medium))
                                .foregroundColor(theme.error)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.cardBackground)
                                .cornerRadius(RSMSRadius.large)
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.md)
                        
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.burgundy)
                }
            }
        }
    }
    
    private func initials(for name: String) -> String {
        guard !name.isEmpty else { return "M" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "M"
    }
}

#Preview {
    ProfileView()
        .environment(SessionStore())
}
