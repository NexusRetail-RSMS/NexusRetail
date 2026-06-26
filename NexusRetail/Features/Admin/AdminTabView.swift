//
//  AdminTabView.swift
//  NexusRetail
//

import SwiftUI

/// Admin shell: tabs for Dashboard, Stores, Products, Transfers, People.
struct AdminTabView: View {
    @State private var isAddManagerPresented = false
    
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
                AdminManagersView()
                    .modifier(AdminToolbarModifier(title: "Managers", showPlusButton: true, plusAction: {
                        isAddManagerPresented = true
                    }))
            }
            .tabItem {
                Label("Managers", systemImage: "person.2")
            }
        }
        .tint(Color.nexusGold)
        .sheet(isPresented: $isAddManagerPresented) {
            NewManagerSheet()
        }
    }
}

/// A view modifier that applies the common Admin toolbar (title + profile button).
struct AdminToolbarModifier: ViewModifier {
    let title: String
    var showPlusButton: Bool = false
    var plusAction: (() -> Void)? = nil
    
    @Environment(SessionStore.self) private var sessionStore
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 40, weight: .bold))
                
                Spacer()
                
                if showPlusButton {
                    Button {
                        plusAction?()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 42, height: 42)
                            .background(Color(UIColor.secondarySystemFill))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top,  16)
            .padding(.bottom, 8)
            .background(Color.white)
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
