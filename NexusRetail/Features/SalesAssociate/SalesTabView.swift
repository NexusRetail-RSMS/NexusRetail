//
//  SalesTabView.swift
//  NexusRetail
//
//  Root tab container for the Sales Associate role.
//  Each tab delegates entirely to its own View + ViewModel.
//

import SwiftUI

struct SalesTabView: View {
    @State private var clientelingVM = ClientelingViewModel()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Light cream background matching design system theme
        appearance.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 0.98)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.systemGray2
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray2]
        
        let burgundyColor = UIColor(red: 0.45, green: 0.05, blue: 0.1, alpha: 1.0)
        itemAppearance.selected.iconColor = burgundyColor
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: burgundyColor]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            SalesDashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
            
            NavigationStack {
                ClientelingView()
            }
            .tabItem { Label("Clients", systemImage: "person.2.fill") }
            
            NavigationStack {
                SalesAssociateDashboardView()
            }
            .tabItem { Label("Legacy Clients", systemImage: "person.3.fill") }
            
            BOPISView()
                .tabItem { Label("BOPIS", systemImage: "bag.fill") }
            
            NavigationStack {
                AppointmentsView(clients: clientelingVM.clients)
            }
            .tabItem { Label("Appointments", systemImage: "calendar.badge.clock") }
        }
        .tint(RSMSColors.burgundy)
    }
}

#Preview {
    SalesTabView()
        .environment(SessionStore())
}
