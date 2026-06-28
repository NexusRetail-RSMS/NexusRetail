import Foundation

// MARK: - Dashboard Data Models

/// Overview KPIs for the admin dashboard
struct DashboardKPIs: Decodable {
    let totalRevenue: Double
    let activeStores: Int
    let pendingTransfers: Int
    let lowStockAlerts: Int
    
    enum CodingKeys: String, CodingKey {
        case totalRevenue = "total_revenue"
        case activeStores = "active_stores"
        case pendingTransfers = "pending_transfers"
        case lowStockAlerts = "low_stock_alerts"
    }
}

/// Monthly revenue data points
struct MonthlyRevenue: Decodable, Identifiable {
    var id: String { month }
    let month: String
    let revenue: Double
    
    // We don't need a CodingKeys enum if the keys match exactly
    // but just to be explicit if they were snake_case it would be here.
}

struct WeeklyRevenue: Decodable, Identifiable {
    var id: String { week }
    let week: String
    let revenue: Double
}

/// Country revenue data points
struct CountryRevenue: Decodable, Identifiable {
    var id: String { country }
    let country: String
    let revenue: Double
}

/// Top products data point from RPC
struct DashboardTopProduct: Decodable, Identifiable {
    var id: String { skuId }
    let skuId: String
    let name: String
    let category: String
    let units: Int
    let revenue: Double
    
    enum CodingKeys: String, CodingKey {
        case skuId = "sku_id"
        case name
        case category
        case units
        case revenue
    }
}
