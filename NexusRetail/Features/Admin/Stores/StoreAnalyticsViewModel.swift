import Foundation
import SwiftUI
import Supabase

@Observable
class StoreAnalyticsViewModel {
    let store: Store
    var orders: [StoreOrder] = []
    
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Selected Time Range
    var timeRange: String = "This Year"
    
    init(store: Store) {
        self.store = store
    }
    
    // MARK: - Data Fetching
    
    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedOrders: [StoreOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, client_id, store_id, associate_id, total, created_at, order_line_item(id, order_id, quantity, applied_price, products(item_id, item_name, category))")
                .eq("store_id", value: store.id)
                .execute()
                .value
            
            self.orders = fetchedOrders
        } catch {
            if error is CancellationError { return }
            print("Error loading store analytics: \(error)")
            self.errorMessage = "Failed to load store analytics: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering Logic
    
    private var filteredOrders: [StoreOrder] {
        switch timeRange {
        case "This Month":
            let maxMonth = orders.map { String($0.createdAt.prefix(7)) }.max() ?? "2026-06"
            return orders.filter { $0.createdAt.hasPrefix(maxMonth) }
        case "This Year":
            let maxYear = orders.map { String($0.createdAt.prefix(4)) }.max() ?? "2026"
            return orders.filter { $0.createdAt.hasPrefix(maxYear) }
        case "All Time":
            return orders
        default:
            return orders
        }
    }
    
    // MARK: - KPIs
    
    var kpiOrders: Int {
        filteredOrders.count
    }
    
    var kpiSales: Int {
        Int(filteredOrders.reduce(0) { $0 + $1.total })
    }
    
    var kpiPaidOut: Int {
        Int(Double(kpiSales) * 0.30)
    }
    
    var kpiCustomers: Int {
        Set(filteredOrders.compactMap { $0.clientID }).count
    }
    
    // MARK: - Sales Chart Data (Monthly)
    
    var salesData: [SalesDataPoint] {
        let grouped = Dictionary(grouping: filteredOrders) { order -> String in
            String(order.createdAt.prefix(7))
        }
        
        let sortedMonths = grouped.keys.sorted()
        
        return sortedMonths.enumerated().map { index, monthStr in
            let monthOrders = grouped[monthStr] ?? []
            let total = monthOrders.reduce(0) { $0 + $1.total }
            
            let label: String
            let parts = monthStr.split(separator: "-")
            if parts.count == 2, let monthNum = Int(parts[1]) {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US")
                label = formatter.shortMonthSymbols[monthNum - 1]
            } else {
                label = monthStr
            }
            
            return SalesDataPoint(month: label, onlineSales: total, offlineSales: 0)
        }
    }
    
    // MARK: - Top Products Data
    
    var topProducts: [DashboardTopProduct] {
        var categoryUnits: [String: Int] = [:]
        var categoryRevenue: [String: Double] = [:]
        
        for order in filteredOrders {
            for item in order.orderLineItems ?? [] {
                let cat = item.products?.category ?? "Uncategorized"
                categoryUnits[cat, default: 0] += item.quantity
                categoryRevenue[cat, default: 0.0] += (Double(item.quantity) * item.appliedPrice)
            }
        }
        
        let products = categoryUnits.keys.map { cat -> DashboardTopProduct in
            DashboardTopProduct(
                id: Int64(abs(cat.hashValue)),
                name: cat,
                category: cat,
                units: categoryUnits[cat] ?? 0,
                revenue: categoryRevenue[cat] ?? 0.0
            )
        }
        
        return products.sorted { $0.units > $1.units }
    }
    
    var totalUnits: Int {
        topProducts.reduce(0) { $0 + $1.units }
    }
    
    var salesChartMax: Double {
        let maxSales = salesData.map { $0.onlineSales + $0.offlineSales }.max() ?? 100
        return max(maxSales * 1.15, 100)
    }
}
