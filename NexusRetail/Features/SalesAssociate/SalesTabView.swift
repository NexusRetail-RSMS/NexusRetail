//
//  SalesTabView.swift
//  NexusRetail
//
//  Sales shell: Sell, Clients, Suggest, Settings.
//  Styled with the premium RSMS cream and burgundy layout.
//

import SwiftUI

struct SalesTabView: View {
    var body: some View {
        TabView {
            // 1. Sell
            NavigationStack {
                SalesPlaceholderView(
                    title: "Point of Sale",
                    message: "Create orders, scan items, and collect customer payments.",
                    icon: "cart.fill"
                )
                .modifier(SalesToolbarModifier(title: "Register"))
            }
            .tabItem {
                Label("Sell", systemImage: "cart.fill")
            }
            
            // 2. Clients
            NavigationStack {
                SalesPlaceholderView(
                    title: "Client Directory",
                    message: "Manage customer profiles, purchase history, and preference sheets.",
                    icon: "person.2.fill"
                )
                .modifier(SalesToolbarModifier(title: "Clients"))
            }
            .tabItem {
                Label("Clients", systemImage: "person.2.fill")
            }
            
            // 3. Suggest
            NavigationStack {
                SalesPlaceholderView(
                    title: "Smart Suggestions",
                    message: "AI-driven recommendation feed based on client preferences.",
                    icon: "sparkles"
                )
                .modifier(SalesToolbarModifier(title: "Suggest"))
            }
            .tabItem {
                Label("Suggest", systemImage: "sparkles")
            }
            
            // 4. Settings
            NavigationStack {
                SalesSettingsView()
                    .modifier(SalesToolbarModifier(title: "Settings"))
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(RSMSColors.burgundy)
    }
}

/// A view modifier that applies the common Sales toolbar (title + profile button).
struct SalesToolbarModifier: ViewModifier {
    let title: String
    
    @Environment(SessionStore.self) private var sessionStore
    @State private var isProfilePresented = false
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isProfilePresented = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(RSMSColors.burgundy)
                                .frame(width: 32, height: 32)
                            
                            Text(initials(for: sessionStore.currentUser?.name))
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Profile")
                    .accessibilityHint("Opens your associate profile")
                }
            }
            .sheet(isPresented: $isProfilePresented) {
                SalesProfileSheet()
            }
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "SA" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "SA"
    }
}

/// A reusable placeholder view for the sales associate tabs.
struct SalesPlaceholderView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(RSMSColors.burgundy)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(RSMSFonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(message)
                    .font(RSMSFonts.body)
                    .foregroundColor(RSMSColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text("Coming Soon")
                    .font(RSMSFonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSColors.burgundy)
                    .cornerRadius(RSMSRadius.small)
            }
        }
    }
}

/// Settings tab view for Sales Associates
struct SalesSettingsView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                Text("Account Preferences")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.darkBrown)
                    .padding(.leading, 4)
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(RSMSColors.burgundy)
                            .frame(width: 24)
                        Text("Notifications")
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .padding(RSMSSpacing.lg)
                    
                    Divider().padding(.leading, 48)
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(RSMSColors.burgundy)
                            .frame(width: 24)
                        Text("Language")
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                        Text("English")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .padding(RSMSSpacing.lg)
                }
                .background(RSMSColors.cardBackground)
                .cornerRadius(RSMSRadius.large)
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                
                Spacer()
                
                Button {
                    Task { try? await sessionStore.signOut() }
                } label: {
                    Text("Sign Out")
                        .font(RSMSFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSColors.error)
                        .cornerRadius(RSMSRadius.medium)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.xxl)
        }
    }
}

/// Simple sheet to allow Sales Associate to Sign Out
struct SalesProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: RSMSSpacing.xl) {
                    VStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(RSMSColors.burgundy)
                        
                        Text(sessionStore.currentUser?.name ?? "Sales Associate")
                            .font(RSMSFonts.title)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)
                        
                        Text("Sales Associate")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .padding(.top, RSMSSpacing.xxl)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                        Task { try? await sessionStore.signOut() }
                    } label: {
                        Text("Sign Out")
                            .font(RSMSFonts.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSColors.error)
                            .cornerRadius(RSMSRadius.medium)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .navigationTitle("Associate Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(RSMSColors.burgundy)
                }
            }
        }
    }
}

#Preview {
    let mockSession = SessionStore()
    return SalesTabView()
        .environment(mockSession)
}
