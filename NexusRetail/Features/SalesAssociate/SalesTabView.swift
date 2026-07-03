import SwiftUI

struct SalesTabView: View {
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
            Tab("Dashboard", systemImage: "square.grid.2x2") {
                SalesDashboardView()
            }
            
            Tab("Clients", systemImage: "person.3.fill") {
                NavigationStack {
                    ClientelingView()
                }
            }
            
            Tab("Appointments", systemImage: "calendar.badge.clock") {
                NavigationStack {
                    AppointmentsView()
                }
            }
            
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                InventoryCatalogView()
            }
        }
        .tint(RSMSColors.burgundy)
    }
}

#Preview {
    SalesTabView().environment(SessionStore())
}

