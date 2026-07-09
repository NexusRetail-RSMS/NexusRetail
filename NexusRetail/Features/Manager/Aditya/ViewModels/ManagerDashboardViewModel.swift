//
//  ManagerDashboardViewModel.swift
//  NexusRetail
//

import SwiftUI
import Observation
import Supabase

struct StaffPerformancePoint: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let score: Int
}

struct OrderSumResult: Decodable {
    let total: Double
}

struct ManagerNullableUUID: Encodable {
    let value: UUID?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = value {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}

struct ManagerSalesParams: Encodable {
    let p_store_id: ManagerNullableUUID
    let p_period: String
}

struct ManagerTopProductsParams: Encodable {
    let p_store_id: ManagerNullableUUID
    let p_period: String
    let p_limit: Int
}

@Observable
final class ManagerDashboardViewModel {
    
    // MARK: - Properties
    
    // Toggles for the main dashboard charts
    var topProductsTimeRange: SalesTimeRange = .monthly
    // (staff performance has no period toggle — get_staff_stats is all-time)
    var revenueTimeRange: SalesTimeRange = .yearly
    var revenueDate: Date = Date()
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // MARK: - Live Data
    
    var managerName = "Manager"
    var storeName = "Loading..."
    
    // KPIs
    var todayRevenue = "₹0"
    var pendingRequests = "0"
    var lowStockItems = "0"
    var afterServiceCount = "0" // total after-sales tickets for this store
    
    // Detail Chart Data (Revenue History)
    var sixMonthTotal: String = "₹0"
    var peakMonth: String = "N/A"
    
    var revenueChartData: [ManagerRevenueChartPoint] = []
    var revenueMaxValue: Double = 1.0
    
    var topProductsData: [ProductChartPoint] = []
    var topProductsMaxValue: Int = 100
    
    var staffPerformanceData: [StaffPerformancePoint] = []
    
    // MARK: - API Calls
    
    func fetchData(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            async let storeTask: Store = SupabaseManager.shared.client
                .from("store")
                .select()
                .eq("id", value: storeID.uuidString)
                .single()
                .execute()
                .value
            
            let today = Date()
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: today)
            
            // 1. Fetch Today's Orders for Revenue
            async let ordersTask: [OrderSumResult] = SupabaseManager.shared.client
                .from("orders")
                .select("total")
                .eq("store_id", value: storeID.uuidString)
                .eq("status", value: "completed")
                .gte("created_at", value: ISO8601DateFormatter().string(from: startOfDay))
                .execute()
                .value
            
            // 2. Fetch Pending Transfer Requests
            struct PartialTransfer: Codable { let id: UUID }
            async let requestsTask: [PartialTransfer] = SupabaseManager.shared.client
                .from("transfer_request")
                .select("id")
                .eq("requesting_store_id", value: storeID.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value
            
            // 3. Fetch Low Stock Items count
            struct PartialInventory: Codable {
                let onHand: Int
                let reorderThreshold: Int
                enum CodingKeys: String, CodingKey {
                    case onHand = "on_hand"
                    case reorderThreshold = "reorder_threshold"
                }
            }
            async let inventoryTask: [PartialInventory] = SupabaseManager.shared.client
                .from("inventory_item")
                .select("on_hand, reorder_threshold")
                .eq("store_id", value: storeID.uuidString)
                .execute()
                .value
                
            // After-sales tickets for this store (all types/stages)
            struct PartialTicket: Decodable { let id: UUID }
            async let ticketsTask: [PartialTicket] = SupabaseManager.shared.client
                .from("after_sales_ticket")
                .select("id")
                .eq("store_id", value: storeID.uuidString)
                .execute()
                .value

            // Wait for basic info
            let store = try? await storeTask
            let orders = try? await ordersTask
            let requests = try? await requestsTask
            let inventory = try? await inventoryTask
            let tickets = try? await ticketsTask
            
            // 4. Fetch Charts (Top Products & Revenue)
            // Map every period, not just W/M — the RPC supports a Y: prefix, and
            // the old `== .weekly ? "W" : "M"` silently turned Yearly into Monthly.
            let periodPrefix: String
            switch topProductsTimeRange {
            case .weekly:  periodPrefix = "W"
            case .monthly: periodPrefix = "M"
            case .yearly:  periodPrefix = "Y"
            }

            
            let topParams = ManagerTopProductsParams(
                p_store_id: ManagerNullableUUID(value: storeID),
                p_period: "\(periodPrefix):\(ISO8601DateFormatter().string(from: Date()))",
                p_limit: 5
            )
            
            async let topProductsTask: [DashboardTopProduct] = SupabaseManager.shared.client
                .rpc("store_top_products_by_period", params: topParams)
                .execute()
                .value
                
            let topProds = try? await topProductsTask
            
            // Fetch real staff data
            let staffStatsTask: [StaffStatsRPC] = try await SupabaseManager.shared.client
                .rpc("get_staff_stats")
                .execute()
                .value
            
            await MainActor.run {
                if let store = store {
                    self.storeName = store.name
                }
                
                let todayTotal = (orders ?? []).reduce(0) { $0 + $1.total }
                self.todayRevenue = formatIndianCurrency(todayTotal)
                
                self.pendingRequests = "\(requests?.count ?? 0)"
                
                let lowStock = (inventory ?? []).filter { $0.onHand <= $0.reorderThreshold }.count
                self.lowStockItems = "\(lowStock)"

                self.afterServiceCount = "\(tickets?.count ?? 0)"
                
                // Top Products Chart
                if let prods = topProds {
                    self.topProductsData = prods.map { prod in
                        let url = prod.imageUrl.flatMap { URL(string: $0) }
                        return ProductChartPoint(name: prod.name, category: prod.category, sales: prod.units, imageURL: url)
                    }.sorted { $0.sales > $1.sales }
                    
                    self.topProductsMaxValue = self.topProductsData.map(\.sales).max() ?? 100
                }
                // Revenue Chart fetching is now decoupled
                // Wait for independent fetch

                // Calculate performance
                let storeStaff = staffStatsTask.filter { $0.storeId == storeID }
                
                let maxRev = storeStaff.compactMap { $0.revenue }.max() ?? 1.0
                let maxRevSafe = maxRev > 0 ? maxRev : 1.0
                
                let maxProducts = storeStaff.compactMap { $0.productsSold }.max() ?? 1
                let maxProductsSafe = maxProducts > 0 ? Double(maxProducts) : 1.0
                
                self.staffPerformanceData = storeStaff.compactMap { stat in
                    let rev = stat.revenue ?? 0.0
                    let prods = Double(stat.productsSold ?? 0)
                    
                    // Performance Formula: 60% Revenue + 40% Products Sold
                    let revScore = (rev / maxRevSafe) * 60.0
                    let prodScore = (prods / maxProductsSafe) * 40.0
                    let totalScore = Int(revScore + prodScore)
                    
                    guard totalScore > 0 else { return nil } // Skip staff with no data if desired, or keep them with 0. Let's keep them with their score.
                    return StaffPerformancePoint(name: stat.name ?? "Unknown", score: totalScore)
                }.sorted { $0.score > $1.score }.prefix(5).map { $0 }
                
                self.isLoading = false
            }
            
        } catch {
            print("Manager Dashboard fetch error: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Independent Chart Fetchers
    func fetchRevenueData(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        let prefix: String
        let allLabels: [String]
        switch revenueTimeRange {
        case .weekly: 
            prefix = "W"
            allLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        case .monthly: 
            prefix = "M"
            allLabels = ["W1", "W2", "W3", "W4", "W5"]
        case .yearly: 
            prefix = "Y"
            allLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: revenueDate)
        
        let params = ManagerSalesParams(
            p_store_id: ManagerNullableUUID(value: storeID),
            p_period: "\(prefix):\(dateString)"
        )
        
        do {
            let salesChart: [SalesPeriodResult] = try await SupabaseManager.shared.client
                .rpc("store_sales_by_period", params: params)
                .execute()
                .value
            
            await MainActor.run {
                // Pad data with 0 for missing periods
                var paddedData: [ManagerRevenueChartPoint] = []
                for label in allLabels {
                    if let existing = salesChart.first(where: { $0.label == label }) {
                        paddedData.append(ManagerRevenueChartPoint(label: label, revenue: (existing.online + existing.offline) / 100000.0))
                    } else {
                        paddedData.append(ManagerRevenueChartPoint(label: label, revenue: 0.0))
                    }
                }
                
                self.revenueChartData = paddedData
                self.revenueMaxValue = self.revenueChartData.map(\.revenue).max() ?? 1.0
                
                let totalLaks = self.revenueChartData.reduce(0) { $0 + $1.revenue }
                self.sixMonthTotal = String(format: "₹%.2fL", totalLaks)
                
                if let peak = self.revenueChartData.max(by: { $0.revenue < $1.revenue }), peak.revenue > 0 {
                    self.peakMonth = peak.label
                } else {
                    self.peakMonth = "-"
                }
            }
        } catch {
            print("Manager Dashboard Revenue fetch error: \(error)")
        }
    }
}
