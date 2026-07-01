//
//  AdminTabView.swift
//  NexusRetail
//

import SwiftUI
import Supabase

/// Admin shell: tabs for Dashboard, Stores, Products, Transfers, Managers.
struct AdminTabView: View {
    @State private var isAddManagerPresented = false
    @State private var navStore = AdminNavigationStore()
    @State private var transfersVM = AdminTransfersViewModel()
    
    var body: some View {
        TabView(selection: $navStore.selectedTab) {
            // 1. Dashboard
            NavigationStack {
                AdminDashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }
            .tag(AdminTab.dashboard)

            // 2. Stores
            NavigationStack {
                StoreListView()
            }
            .tabItem {
                Label("Stores", systemImage: "building.2")
            }
            .tag(AdminTab.stores)

            // 3. Products
            NavigationStack {
                ProductCatalogueView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("Products", systemImage: "tag")
            }
            .tag(AdminTab.products)

            // 4. Transfers
            NavigationStack {
                AdminTransfersView()
            }
            .tabItem {
                Label("Transfers", systemImage: "arrow.left.arrow.right")
            }
            .tag(AdminTab.transfers)

            // 5. Managers
            NavigationStack {
                ManagersTabRoot(isAddManagerPresented: $isAddManagerPresented)
            }
            .tabItem {
                Label("Managers", systemImage: "person.2")
            }
            .tag(AdminTab.managers)
        }
        .tint(RSMSColors.burgundy)
        .environment(navStore)
        .environment(transfersVM)
    }
}

/// Wrapper that provides a custom header for the Managers tab matching the Stores page style.
private struct ManagersTabRoot: View {
    @Binding var isAddManagerPresented: Bool
    @State private var searchText = ""

    var body: some View {
        AdminManagersView(isAddManagerPresented: $isAddManagerPresented, searchText: $searchText)
            .toolbar(.hidden, for: .navigationBar)
    }
}

/// Wrapper that provides a custom large-title header for the Transfers tab, matching the Managers tab style.
private struct TransfersTabRoot: View {

    var body: some View {
        AdminTransfersView()
            .toolbar(.hidden, for: .navigationBar)
    }
}

/// A view modifier that applies the common Admin toolbar (title only).
struct AdminToolbarModifier: ViewModifier {
    let title: String
    @State private var isProfilePresented = false
    @Environment(SessionStore.self) private var sessionStore

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
                                AsyncImage(url: url) { image in
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
