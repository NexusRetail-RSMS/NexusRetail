import SwiftUI

struct SalesTabView: View {
    @Environment(AppTheme.self) private var theme

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house") {
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
        .tint(theme.isDarkMode ? RSMSColors.antiqueGold : RSMSColors.burgundy)
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        .environment(theme)
        .onAppear { updateTabBarAppearance() }
        .onChange(of: theme.isDarkMode) { _, _ in updateTabBarAppearance() }
    }

    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        if theme.isDarkMode {
            // Midnight black background
            appearance.backgroundColor = UIColor(Color(hex: "1A1A1A"))
            // Thin dark burgundy top separator line
            appearance.shadowColor = UIColor(Color(hex: "3D0000").opacity(0.6))

            let itemAppearance = UITabBarItemAppearance()
            // Unselected: wood brown (muted warm tone)
            itemAppearance.normal.iconColor = UIColor(Color(hex: "7A5C3A"))
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "7A5C3A"))]
            // Selected: antique gold
            itemAppearance.selected.iconColor = UIColor(Color(hex: "C9A84C"))
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "C9A84C")),
                                                           .font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
        } else {
            // Warm cream background
            appearance.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 0.98)
            appearance.shadowColor = UIColor(Color(hex: "8B0000").opacity(0.18))

            let itemAppearance = UITabBarItemAppearance()
            // Unselected: muted warm gray-brown
            itemAppearance.normal.iconColor = UIColor(Color(hex: "9E8E7A"))
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "9E8E7A"))]
            // Selected: dark burgundy
            let burgundyColor = UIColor(red: 0.55, green: 0.0, blue: 0.01, alpha: 1.0) // #8B0002
            itemAppearance.selected.iconColor = burgundyColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: burgundyColor,
                                                           .font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    SalesTabView()
        .environment(SessionStore())
        .environment(AppTheme())
}
