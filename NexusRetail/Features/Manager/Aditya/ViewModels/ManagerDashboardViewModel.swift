//
//  ManagerDashboardViewModel.swift
//  NexusRetail
//

import SwiftUI
import Observation
import Supabase

struct StaffPerformancePoint: Identifiable, Equatable {
    let id = UUID()
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
    var staffTimeRange: SalesTimeRange = .monthly
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // MARK: - Live Data
    
    var managerName = "Manager"
    var storeName = "Loading..."
    
    // KPIs
    var todayRevenue = "₹0"
    var pendingRequests = "0"
    var lowStockItems = "0"
    var todayReturns = "0" // Mocked to 0 for now
    
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
                
            // Wait for basic info
            let store = try? await storeTask
            let orders = try? await ordersTask
            let requests = try? await requestsTask
            let inventory = try? await inventoryTask
            
            // 4. Fetch Charts (Top Products & Revenue)
            let periodPrefix = topProductsTimeRange == .monthly ? "M" : "Y"
            let params = ManagerSalesParams(
                p_store_id: ManagerNullableUUID(value: storeID),
                p_period: "\(periodPrefix):\(ISO8601DateFormatter().string(from: Date()))"
            )
            
            let topParams = ManagerTopProductsParams(
                p_store_id: ManagerNullableUUID(value: storeID),
                p_period: "\(periodPrefix):\(ISO8601DateFormatter().string(from: Date()))",
                p_limit: 5
            )
            
            async let salesChartTask: [SalesPeriodResult] = SupabaseManager.shared.client
                .rpc("store_sales_by_period", params: params)
                .execute()
                .value
                
            async let topProductsTask: [DashboardTopProduct] = SupabaseManager.shared.client
                .rpc("store_top_products_by_period", params: topParams)
                .execute()
                .value
                
            let salesChart = try? await salesChartTask
            let topProds = try? await topProductsTask
            
            await MainActor.run {
                if let store = store {
                    self.storeName = store.name
                }
                
                let todayTotal = (orders ?? []).reduce(0) { $0 + $1.total }
                self.todayRevenue = formatIndianCurrency(todayTotal)
                
                self.pendingRequests = "\(requests?.count ?? 0)"
                
                let lowStock = (inventory ?? []).filter { $0.onHand <= $0.reorderThreshold }.count
                self.lowStockItems = "\(lowStock)"
                
                // Top Products Chart
                if let prods = topProds {
                    self.topProductsData = prods.map { ProductChartPoint(category: $0.name, sales: Int($0.revenue)) }
                    self.topProductsMaxValue = self.topProductsData.map(\.sales).max() ?? 100
                }
                
                // Revenue Chart
                if let chart = salesChart {
                    self.revenueChartData = chart.map { ManagerRevenueChartPoint(label: $0.label, revenue: ($0.online + $0.offline) / 100000.0) } // Assuming Laks
                    self.revenueMaxValue = self.revenueChartData.map(\.revenue).max() ?? 1.0
                    
                    let totalLaks = self.revenueChartData.reduce(0) { $0 + $1.revenue }
                    self.sixMonthTotal = String(format: "₹%.2fL", totalLaks)
                    
                    if let peak = self.revenueChartData.max(by: { $0.revenue < $1.revenue }) {
                        self.peakMonth = peak.label
                    }
                }
                
                // Mock staff performance for now since we don't have an RPC for it
                self.staffPerformanceData = [
                    StaffPerformancePoint(name: "Aman", score: 92),
                    StaffPerformancePoint(name: "Priya", score: 85),
                    StaffPerformancePoint(name: "Rahul", score: 80),
                    StaffPerformancePoint(name: "Sneha", score: 75)
                ]
                
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
}
