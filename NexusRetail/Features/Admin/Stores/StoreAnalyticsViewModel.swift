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
    // timeRange drives the segmented picker ("This Month" / "This Year" / "All Time")
    var timeRange: String = "This Year" {
        didSet {
            // When the segmented picker changes, reset the calendar-based filter
            // so both controls stay in sync
            let cal = Calendar.current
            let now = Date()
            switch timeRange {
            case "This Month":
                calendarRange = .monthly(now)
            case "All Time":
                calendarRange = .yearly(now)
            default: // "This Year"
                calendarRange = .yearly(now)
            }
        }
    }

    // calendarRange drives the SwipeableCalendarView.
    // When swiped it takes precedence over timeRange for filtering.
    var calendarRange: StoreChartTimeRange = .yearly(Date())

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
    // Priority: calendarRange (from swiping) overrides timeRange picker when
    // the user has swiped away from the current period.

    private var filteredOrders: [StoreOrder] {
        let cal = Calendar.current
        let now = Date()

        switch calendarRange {
        case .weekly(let date):
            // Filter to the ISO week containing `date`
            let weekStart = cal.date(
                from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            ) ?? date
            let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? date
            return orders.filter {
                guard let d = iso8601Date($0.createdAt) else { return false }
                return d >= weekStart && d < weekEnd
            }

        case .monthly(let date):
            // Filter to the calendar month containing `date`
            let monthStr = String(format: "%04d-%02d",
                                  cal.component(.year, from: date),
                                  cal.component(.month, from: date))
            return orders.filter { $0.createdAt.hasPrefix(monthStr) }

        case .yearly(let date):
            if timeRange == "All Time" {
                return orders
            }
            // Filter to the calendar year containing `date`
            let yearStr = String(format: "%04d", cal.component(.year, from: date))
            return orders.filter { $0.createdAt.hasPrefix(yearStr) }
        }
    }

    // Parse ISO8601 date string from Supabase (e.g. "2026-06-28T10:30:00+00:00")
    private func iso8601Date(_ str: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: str)
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
