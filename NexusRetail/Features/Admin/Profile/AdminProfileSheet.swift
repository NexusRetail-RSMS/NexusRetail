//
//  AdminProfileSheet.swift
//  NexusRetail
//

import SwiftUI

struct AdminProfileSheet: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.nexusRed)
                                .frame(width: 60, height: 60)
                            
                            Text(initials(for: sessionStore.currentUser?.name))
                                .font(.title2.bold())
                                .foregroundColor(Color.nexusGold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionStore.currentUser?.name ?? "Admin User")
                                .font(.headline)
                            
                            if let email = sessionStore.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Role: \(sessionStore.currentRole?.displayName ?? "Admin")")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.nexusGold.opacity(0.2))
                                .foregroundColor(Color.nexusRed)
                                .cornerRadius(8)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(role: .destructive) {
                        Task {
                            dismiss()
                            try? await sessionStore.signOut()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .accessibilityHint("Signs you out of your account and returns to the login screen")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "AD" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AD"
    }
}
