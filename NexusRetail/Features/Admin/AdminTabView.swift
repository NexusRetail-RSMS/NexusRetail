//
//  AdminTabView.swift
//  NexusRetail
//

import SwiftUI

/// Admin shell: tabs for Dashboard, Stores, Products, Transfers, People.
struct AdminTabView: View {
    var body: some View {
        TabView {
            // 1. Dashboard
            NavigationStack {
                AdminDashboardView()
                    .modifier(AdminToolbarModifier(title: "Dashboard"))
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }
            
            // 2. Stores
            NavigationStack {
                StoreListView()
                    .modifier(AdminToolbarModifier(title: "Stores"))
            }
            .tabItem {
                Label("Stores", systemImage: "building.2")
            }
            
            // 3. Products
            NavigationStack {
                AdminPlaceholderView(title: "Products", message: "Product management coming soon.")
                    .modifier(AdminToolbarModifier(title: "Products"))
            }
            .tabItem {
                Label("Products", systemImage: "tag")
            }
            
            // 4. Transfers
            NavigationStack {
                AdminPlaceholderView(title: "Transfers", message: "Inventory transfers coming soon.")
                    .modifier(AdminToolbarModifier(title: "Transfers"))
            }
            .tabItem {
                Label("Transfers", systemImage: "arrow.left.arrow.right")
            }
            
            // 5. Managers
            NavigationStack {
                AdminPlaceholderView(title: "Managers", message: "Manager and staff tracking coming soon.")
                    .modifier(AdminToolbarModifier(title: "Managers"))
            }
            .tabItem {
                Label("Managers", systemImage: "person.2")
            }
        }
        .tint(Color.nexusGold)
    }
}

/// A view modifier that applies the common Admin toolbar (title + profile button).
struct AdminToolbarModifier: ViewModifier {
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
                                .fill(Color.nexusNavy)
                                .frame(width: 32, height: 32)
                            
                            Text(initials(for: sessionStore.currentUser?.name))
                                .font(.caption.bold())
                                .foregroundColor(Color.nexusGold)
                        }
                    }
                    .accessibilityLabel("Profile")
                    .accessibilityHint("Opens your profile and settings")
                }
            }
            .sheet(isPresented: $isProfilePresented) {
                AdminProfileSheet()
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

/// A reusable placeholder view for the admin tabs.
struct AdminPlaceholderView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.nexusGold)
                .accessibilityHidden(true)
            
            Text("Coming Soon")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.nexusNavy)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
