//
//  ManagerTabView.swift
//  NexusRetail
//

import SwiftUI

/// Manager shell: Inventory, Requests, Pricing, Events, Staff.
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
                InventoryDashboardView()
            }
            .tabItem {
                Label("Inventory", systemImage: "square.grid.3x3.fill")
            }
            
            // 2. Events
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
            
            // 3. Employees
            NavigationStack {
                ManagerPlaceholderView(
                    title: "Employees",
                    message: "Monitor staff check-ins, tasks, and sales metrics.",
                    icon: "person.2.fill"
                )
                .modifier(ManagerToolbarModifier(title: "Employees"))
            }
            .tabItem {
                Label("Employees", systemImage: "person.2")
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
                            
                            if let urlString = sessionStore.currentUser?.imageUrl, let url = URL(string: urlString) {
                                CachedAsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 32, height: 32)
                                }
                            } else {
                                Text(initials(for: sessionStore.currentUser?.name))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isProfilePresented) {
                AdminProfileSheet()
            }
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "MGR" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "MGR"
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
