//
//  ManagerTabView.swift
//  NexusRetail
//
//  Manager shell: Inventory, Requests, Pricing, Events, Staff.
//  Styled with the premium RSMS cream and burgundy layout.
//

import SwiftUI

struct ManagerTabView: View {
    var body: some View {
        TabView {
            // 0. Dashboard
            NavigationStack {
                ManagerDashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "squareshape.split.2x2")
            }

            // 1. Inventory
            NavigationStack {
                ManagerPlaceholderView(
                    title: "Inventory",
                    message: "View store stock levels and configure low-stock alerts.",
                    icon: "box.truck.fill"
                )
                .modifier(ManagerToolbarModifier(title: "Inventory"))
            }
            .tabItem {
                Label("Inventory", systemImage: "square.grid.3x3.fill")
            }
            
            // 2. Requests
            NavigationStack {
                ManagerPlaceholderView(
                    title: "Stock Requests",
                    message: "Approve or create inventory transfer requests.",
                    icon: "arrow.left.arrow.right"
                )
                .modifier(ManagerToolbarModifier(title: "Requests"))
            }
            .tabItem {
                Label("Requests", systemImage: "shippingbox.fill")
            }
            
            // 3. Pricing
            NavigationStack {
                ManagerPlaceholderView(
                    title: "Pricing & Discounts",
                    message: "Manage local store pricing promotions and adjustments.",
                    icon: "tag.fill"
                )
                .modifier(ManagerToolbarModifier(title: "Pricing"))
            }
            .tabItem {
                Label("Pricing", systemImage: "percent")
            }
            
            // 4. Events
            NavigationStack {
                ManagerPlaceholderView(
                    title: "Store Events",
                    message: "Track and organize upcoming promotional events and product launches.",
                    icon: "calendar"
                )
                .modifier(ManagerToolbarModifier(title: "Events"))
            }
            .tabItem {
                Label("Events", systemImage: "sparkles")
            }
            
            // 5. Staff
            NavigationStack {
                ManagerPlaceholderView(
                    title: "Staff Performance",
                    message: "Monitor staff check-ins, tasks, and sales metrics.",
                    icon: "person.2.fill"
                )
                .modifier(ManagerToolbarModifier(title: "Staff"))
            }
            .tabItem {
                Label("Staff", systemImage: "person.2")
            }
        }
        .tint(RSMSColors.burgundy)
    }
}

/// A view modifier that applies the common Manager toolbar (title + profile button).
struct ManagerToolbarModifier: ViewModifier {
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
                    .accessibilityHint("Opens your manager profile")
                }
            }
            .sheet(isPresented: $isProfilePresented) {
                ManagerProfileSheet()
            }
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "MG" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "MG"
    }
}

/// A reusable placeholder view for the manager tabs.
struct ManagerPlaceholderView: View {
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

/// Simple sheet to allow Manager to Sign Out
struct ManagerProfileSheet: View {
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
                        
                        Text(sessionStore.currentUser?.name ?? "Store Manager")
                            .font(RSMSFonts.title)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)
                        
                        Text("Store Manager")
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
            .navigationTitle("Manager Profile")
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
    return ManagerTabView()
        .environment(mockSession)
}
