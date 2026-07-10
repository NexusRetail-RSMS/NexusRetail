//
//  DashboardViewModel.swift
//  NexusRetail
//
//  Observable view model for the Admin Dashboard.
//  Each chart has its OWN independent time-range toggle so
//  switching one does not refresh the other.
//
//  Data source: retail_sales.csv (Kaggle-format), parsed by
//  CSVDataLoader and aggregated by DashboardDataProvider.
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Time Range

enum SalesTimeRange: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

// MARK: - Chart-ready data points

/// A single bar in the revenue chart.
struct RevenueChartPoint: Identifiable, Equatable {
    var id: String { label }
    let label: String
    let index: Int
    let revenue: Double

    static func == (lhs: RevenueChartPoint, rhs: RevenueChartPoint) -> Bool {
        lhs.label == rhs.label && lhs.revenue == rhs.revenue
    }
}

/// A single bar/slice in the product-sales chart.
struct ProductChartPoint: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let category: String
    let sales: Int
    var imageURL: URL? = nil

    static func == (lhs: ProductChartPoint, rhs: ProductChartPoint) -> Bool {
        lhs.name == rhs.name && lhs.sales == rhs.sales
    }
}

// MARK: - ViewModel

@Observable
class DashboardViewModel {
    
    // MARK: - Backend State
    var kpis: DashboardKPIs?
    var monthly: [MonthlyRevenue] = []
    var weekly: [WeeklyRevenue] = []
    var byCountry: [CountryRevenue] = []
    var storeCountries: [String] = []
    var footprint: [CountryFootprint] = []
    var storePoints: [StorePoint] = []
    var indiaStates: [StateFootprint] = []
    var topProductsWeekly: [DashboardTopProduct] = []
    var topProductsMonthly: [DashboardTopProduct] = []
    
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Product Count State
    var totalProducts: Int = 0
    private var realtimeChannel: RealtimeChannelV2?
    
    // MARK: - Filter State
    // nil means "All Global"
    var selectedCountry: String? = nil {
        didSet {
            // Automatically reload when country filter changes
            Task {
                await load()
            }
        }
    }
    
    /// Every country that has a store (so newly-added regions appear even with
    /// no sales yet), unioned with any country that has revenue, for safety.
    var countries: [String] {
        Array(Set(storeCountries).union(byCountry.map(\.country)))
            .sorted()
    }
    
    var displayCountry: String {
        selectedCountry ?? "All Global"
    }
    
    // MARK: - Independent Time Range Toggles
    var revenueTimeRange: SalesTimeRange = .monthly
    var productTimeRange: SalesTimeRange = .monthly
    
    // MARK: - Computed KPI Formatters
    
    var formattedRevenue: String {
        guard let total = kpis?.totalRevenue else { return "₹0" }
        return formatIndianCurrency(total)
    }
    
    var activeStoresText: String {
        "\(kpis?.activeStores ?? 0)"
    }
    
    var pendingTransfersText: String {
        "\(kpis?.pendingTransfers ?? 0)"
    }
    
    var totalProductsText: String {
        "\(totalProducts)"
    }
    
    // MARK: - Chart Data Adapters
    
    var revenueChartData: [RevenueChartPoint] {
        let calendar = Calendar.current
        let now = Date()

        if revenueTimeRange == .weekly {
            // Backfill the last 8 ISO weeks so the line always renders
            var revByKey: [String: Double] = [:]
            for w in weekly { revByKey[w.week] = w.revenue }
            var points: [RevenueChartPoint] = []
            for i in (0..<8).reversed() {
                guard let d = calendar.date(byAdding: .weekOfYear, value: -i, to: now) else { continue }
                let week = calendar.component(.weekOfYear, from: d)
                let year = calendar.component(.yearForWeekOfYear, from: d)
                let key  = String(format: "%04d-%02d", year, week)
                let rev  = (revByKey[key] ?? 0) / 100000.0
                points.append(RevenueChartPoint(label: "W\(week)", index: 7 - i, revenue: rev))
            }
            return points
        } else {
            // Backfill the last 6 months so the line always renders
            var revByKey: [String: Double] = [:]
            for m in monthly { revByKey[m.month] = m.revenue }
            let keyFmt = DateFormatter(); keyFmt.locale = Locale(identifier: "en_US"); keyFmt.dateFormat = "yyyy-MM"
            let monFmt = DateFormatter(); monFmt.locale = Locale(identifier: "en_US"); monFmt.dateFormat = "MMM"
            var points: [RevenueChartPoint] = []
            for i in (0..<6).reversed() {
                guard let d = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
                let key = keyFmt.string(from: d)
                let rev = (revByKey[key] ?? 0) / 100000.0
                points.append(RevenueChartPoint(label: monFmt.string(from: d), index: 5 - i, revenue: rev))
            }
            return points
        }
    }
    
    var revenueMaxValue: Double {
        let maxRev = revenueChartData.map(\.revenue).max() ?? 100
        return ceil(maxRev / 50) * 50
    }
    
    // MARK: - Product Sales Chart Data
    var productChartData: [ProductChartPoint] {
        let sourceData = productTimeRange == .weekly ? topProductsWeekly : topProductsMonthly
        
        return sourceData.map { product in
            let url = product.imageUrl.flatMap { URL(string: $0) }
            return ProductChartPoint(name: product.name, category: product.category, sales: product.units, imageURL: url)
        }
        .sorted { $0.sales > $1.sales }
    }
    
    var productMaxValue: Int {
        let maxVal = productChartData.map(\.sales).max() ?? 100
        return ((maxVal / 50) + 1) * 50
    }
    
    // MARK: - Loading Backend Data
    
    struct DashboardRPCParams: Encodable {
        let p_country: String?
    }
    
    struct TopProductsRPCParams: Encodable {
        let p_period: String
        let p_limit: Int
        let p_country: String?
    }
    
    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let params = DashboardRPCParams(p_country: selectedCountry)
            let weekParams = TopProductsRPCParams(p_period: "week", p_limit: 20, p_country: selectedCountry)
            let monthParams = TopProductsRPCParams(p_period: "month", p_limit: 20, p_country: selectedCountry)
            
            // We use async let for concurrent loading (as requested)
            async let kpisTask: DashboardKPIs = SupabaseManager.shared.client
                .rpc("dashboard_kpis", params: params).execute().value
                
            async let monthlyTask: [MonthlyRevenue] = SupabaseManager.shared.client
                .rpc("revenue_by_month", params: params).execute().value
                
            async let weeklyTask: [WeeklyRevenue] = SupabaseManager.shared.client
                .rpc("revenue_by_week", params: params).execute().value
                
            async let countryTask: [CountryRevenue] = SupabaseManager.shared.client
                .rpc("revenue_by_country").execute().value

            async let footprintTask: [CountryFootprint] = SupabaseManager.shared.client
                .rpc("customer_footprint_by_country").execute().value

            async let indiaStatesTask: [StateFootprint] = SupabaseManager.shared.client
                .rpc("customer_footprint_india_by_state").execute().value

            async let storePointsTask: [StorePoint] = SupabaseManager.shared.client
                .rpc("store_footprint_points").execute().value
                
            async let topWeeklyTask: [DashboardTopProduct] = SupabaseManager.shared.client
                .rpc("top_products", params: weekParams).execute().value
                
            async let topMonthlyTask: [DashboardTopProduct] = SupabaseManager.shared.client
                .rpc("top_products", params: monthParams).execute().value
                
            async let productsCountTask = fetchTotalProducts()

            async let storeCountriesTask = fetchStoreCountries()
                
            self.kpis = try await kpisTask
            self.monthly = try await monthlyTask
            self.weekly = try await weeklyTask
            self.byCountry = try await countryTask
            self.footprint = try await footprintTask
            self.indiaStates = try await indiaStatesTask
            self.storePoints = try await storePointsTask
            self.topProductsWeekly = try await topWeeklyTask
            self.topProductsMonthly = try await topMonthlyTask
            self.totalProducts = try await productsCountTask
            self.storeCountries = try await storeCountriesTask
            
        } catch is CancellationError {
            // A newer load() superseded this one (e.g. view re-rendered or
            // country filter changed). Not a real failure — ignore silently.
            print("Dashboard: load cancelled, ignoring")
        } catch let urlError as URLError where urlError.code == .cancelled {
            print("Dashboard: request cancelled, ignoring")
        } catch {
            self.errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
            print("Dashboard Error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Realtime and Product Count
    
    /// Distinct countries that currently have a store, so the region filter
    /// reflects every region we operate in — even brand-new ones with no sales.
    private func fetchStoreCountries() async throws -> [String] {
        struct Row: Decodable { let country: String? }
        let rows: [Row] = try await SupabaseManager.shared.client
            .from("store")
            .select("country")
            .execute()
            .value
        return Array(Set(rows.compactMap { $0.country?.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty })).sorted()
    }

    private func fetchTotalProducts() async throws -> Int {
        let response = try await SupabaseManager.shared.client
            .from("products")
            .select("item_id", head: true, count: .exact)
            .execute()
        return response.count ?? 0
    }
    
    func startListening() {
        if realtimeChannel != nil { return }
        
        // Unique channel name per instance so we never reuse a stale, already
        // subscribed channel (which makes adding postgresChange callbacks throw
        // "Cannot add postgres_changes callbacks after subscribe()").
        realtimeChannel = SupabaseManager.shared.client.channel("admin_dashboard_products_\(UUID().uuidString)")
        
        let insertions = realtimeChannel?.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "products"
        )
        let deletions = realtimeChannel?.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "products"
        )
        
        Task {
            if let insertions = insertions {
                for await _ in insertions {
                    if let count = try? await fetchTotalProducts() {
                        await MainActor.run { self.totalProducts = count }
                    }
                }
            }
        }
        
        Task {
            if let deletions = deletions {
                for await _ in deletions {
                    if let count = try? await fetchTotalProducts() {
                        await MainActor.run { self.totalProducts = count }
                    }
                }
            }
        }
        
        Task {
            try? await realtimeChannel?.subscribeWithError()
        }
    }
    
    deinit {
        // Fully remove the channel (not just unsubscribe) so it doesn't linger
        // in the client's registry and get reused in a subscribed state.
        Task { [channel = realtimeChannel] in
            if let channel {
                await SupabaseManager.shared.client.removeChannel(channel)
            }
        }
    }
}
