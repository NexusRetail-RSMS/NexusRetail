//
//  AdminTabView.swift
//  NexusRetail
//
//  Transforming the Admin Tab View placeholder into a full-featured dashboard.
//  Uses the RSMS design tokens and incorporates the new Payment Configuration module.
//

import SwiftUI
import Supabase

/// Admin shell: tabs for Dashboard, Stores, Products, Transfers, Managers.
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
        .tint(RSMSColors.burgundy)
    }
}

/// A view modifier that applies the common Admin toolbar (title only).
struct AdminToolbarModifier: ViewModifier {
    let title: String
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// A reusable placeholder view for the admin tabs.
struct AdminPlaceholderView: View {
    let title: String
    let message: String
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 60))
                    .foregroundColor(RSMSColors.burgundy)
                    .accessibilityHidden(true)
                
                Text("Coming Soon")
                    .font(RSMSFonts.title)
                    .fontWeight(.semibold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(message)
                    .font(RSMSFonts.body)
                    .foregroundColor(RSMSColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    let mockSession = SessionStore()
    return AdminTabView()
        .environment(mockSession)
}
