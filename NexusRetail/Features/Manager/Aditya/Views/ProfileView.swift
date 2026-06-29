//
//  ProfileView.swift
//  NexusRetail
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RSMSSpacing.lg) {
                        // Profile Card
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(RSMSColors.burgundy)
                                        .frame(width: 60, height: 60)
                                    
                                    Text(initials(for: sessionStore.currentUser?.name ?? "Manager"))
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sessionStore.currentUser?.name ?? "Aryavansh")
                                        .font(.headline)
                                        .foregroundColor(RSMSColors.primaryText)
                                    
                                    Text(sessionStore.currentUser?.email ?? "manager@nexus.com")
                                        .font(.subheadline)
                                        .foregroundColor(RSMSColors.secondaryText)
                                    
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
                        .background(Color.white)
                        .cornerRadius(RSMSRadius.large)
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.lg)
                        
                        // Store Settings Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Store Settings")
                                .font(.subheadline)
                                .foregroundColor(RSMSColors.secondaryText)
                                .padding(.horizontal, RSMSSpacing.lg)
                            
                            VStack(spacing: 0) {
                                Button {
                                    // Action
                                } label: {
                                    HStack {
                                        Image(systemName: "creditcard")
                                            .foregroundColor(RSMSColors.burgundy)
                                        Text("Payment Configuration")
                                            .foregroundColor(RSMSColors.primaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(RSMSColors.secondaryText)
                                            .font(.caption)
                                    }
                                    .padding()
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(RSMSRadius.large)
                            .padding(.horizontal, RSMSSpacing.lg)
                        }
                        
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
                                .foregroundColor(RSMSColors.error)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
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
                    .foregroundColor(RSMSColors.burgundy)
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
