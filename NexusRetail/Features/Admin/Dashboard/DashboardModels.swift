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

/// Customer footprint per country (for the Top Customer Locations choropleth).
/// Decoded from the `customer_footprint_by_country` RPC.
struct CountryFootprint: Decodable, Identifiable {
    var id: String { country }
    let country: String
    let customerCount: Int
    let orderCount: Int
    let revenue: Double

    enum CodingKeys: String, CodingKey {
        case country
        case customerCount = "customer_count"
        case orderCount = "order_count"
        case revenue
    }
}

/// A single store plotted on the footprint map (bubble).
/// Decoded from the `store_footprint_points` RPC.
struct StorePoint: Decodable, Identifiable {
    var id: UUID { storeId }
    let storeId: UUID
    let name: String
    let city: String?
    let country: String
    let latitude: Double
    let longitude: Double
    let customerCount: Int
    let orderCount: Int
    let revenue: Double

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case name, city, country, latitude, longitude, revenue
        case customerCount = "customer_count"
        case orderCount = "order_count"
    }
}

/// Customer footprint per Indian state (drill-down choropleth).
/// Decoded from the `customer_footprint_india_by_state` RPC.
struct StateFootprint: Decodable, Identifiable {
    var id: String { state }
    let state: String
    let customerCount: Int
    let orderCount: Int
    let revenue: Double

    enum CodingKeys: String, CodingKey {
        case state
        case customerCount = "customer_count"
        case orderCount = "order_count"
        case revenue
    }
}

/// Top products data point from RPC
struct DashboardTopProduct: Decodable, Identifiable {
    let id: Int64
    let name: String
    let category: String
    let units: Int
    let revenue: Double
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case units
        case revenue
        case imageUrl = "image_url"
    }
}

/// Sales grouped by period (month/quarter) and channel (online vs offline)
struct SalesPeriodResult: Decodable, Identifiable {
    var id: String { label }
    let label: String
    let online: Double
    let offline: Double
}

/// Sales grouped by product category
struct StoreCategorySales: Decodable, Identifiable {
    var id: String { category }
    let category: String
    let revenue: Double
}
