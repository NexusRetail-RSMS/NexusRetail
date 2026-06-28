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

/// Toggle between weekly and monthly views.
enum SalesTimeRange: String, CaseIterable {
    case weekly  = "Weekly"
    case monthly = "Monthly"
}

// MARK: - Chart-ready data points

/// A single bar in the revenue chart.
struct RevenueChartPoint: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let index: Int
    let revenue: Double

    static func == (lhs: RevenueChartPoint, rhs: RevenueChartPoint) -> Bool {
        lhs.label == rhs.label && lhs.revenue == rhs.revenue
    }
}

/// A single bar/slice in the product-sales chart.
struct ProductChartPoint: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let sales: Int

    static func == (lhs: ProductChartPoint, rhs: ProductChartPoint) -> Bool {
        lhs.category == rhs.category && lhs.sales == rhs.sales
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
    var topProductsWeekly: [DashboardTopProduct] = []
    var topProductsMonthly: [DashboardTopProduct] = []
    
    var isLoading = false
    var errorMessage: String?
    
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
    
    var countries: [String] {
        byCountry.map(\.country).sorted()
    }
    
    var displayCountry: String {
        selectedCountry ?? "All Global"
    }
    
    // MARK: - Independent Time Range Toggles
    var revenueTimeRange: SalesTimeRange = .monthly
    var productTimeRange: SalesTimeRange = .weekly
    
    // MARK: - Computed KPI Formatters
    
    var formattedRevenue: String {
        guard let total = kpis?.totalRevenue else { return "₹0" }
        if total >= 10000000 {
            let crores = total / 10000000.0
            return "₹\(String(format: "%.1f", crores))Cr"
        } else if total >= 100000 {
            let lakhs = total / 100000.0
            return "₹\(String(format: "%.1f", lakhs))L"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: total)) ?? "₹\(total)"
        }
    }
    
    var activeStoresText: String {
        "\(kpis?.activeStores ?? 0)"
    }
    
    var pendingTransfersText: String {
        "\(kpis?.pendingTransfers ?? 0)"
    }
    
    var lowStockText: String {
        "\(kpis?.lowStockAlerts ?? 0)"
    }
    
    // MARK: - Chart Data Adapters
    
    var revenueChartData: [RevenueChartPoint] {
        if revenueTimeRange == .weekly {
            return weekly.enumerated().map { index, point in
                // week format is "YYYY-WW" (e.g. "2026-06" for 6th week)
                let label: String
                let parts = point.week.split(separator: "-")
                if parts.count == 2 {
                    label = "W\(parts[1])"
                } else {
                    label = point.week
                }
                return RevenueChartPoint(
                    label: label,
                    index: index,
                    revenue: point.revenue / 100000.0 // UI expects Lakhs
                )
            }.suffix(12) // Show last 12 weeks so chart isn't too squished
        } else {
            return monthly.enumerated().map { index, point in
                // Try to extract just the month abbreviation from "YYYY-MM"
                let label: String
                let parts = point.month.split(separator: "-")
                if parts.count == 2, let monthNum = Int(parts[1]) {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "en_US")
                    label = formatter.shortMonthSymbols[monthNum - 1]
                } else {
                    label = point.month
                }
                
                return RevenueChartPoint(
                    label: label,
                    index: index,
                    revenue: point.revenue / 100000.0 // UI expects Lakhs
                )
            }
        }
    }
    
    var revenueMaxValue: Double {
        let maxRev = revenueChartData.map(\.revenue).max() ?? 100
        return ceil(maxRev / 50) * 50
    }
    
    // MARK: - Product Sales Chart Data
    var productChartData: [ProductChartPoint] {
        let sourceData = productTimeRange == .weekly ? topProductsWeekly : topProductsMonthly
        
        // Group the top products by category and sum up their units
        let grouped = Dictionary(grouping: sourceData) { $0.category }
        let categories = grouped.keys.sorted()
        
        return categories.compactMap { cat in
            guard let items = grouped[cat] else { return nil }
            let total = items.reduce(0) { $0 + $1.units }
            return ProductChartPoint(category: cat, sales: total)
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
                
            async let topWeeklyTask: [DashboardTopProduct] = SupabaseManager.shared.client
                .rpc("top_products", params: weekParams).execute().value
                
            async let topMonthlyTask: [DashboardTopProduct] = SupabaseManager.shared.client
                .rpc("top_products", params: monthParams).execute().value
                
            self.kpis = try await kpisTask
            self.monthly = try await monthlyTask
            self.weekly = try await weeklyTask
            self.byCountry = try await countryTask
            self.topProductsWeekly = try await topWeeklyTask
            self.topProductsMonthly = try await topMonthlyTask
            
        } catch {
            self.errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
            print("Dashboard Error: \(error)")
        }
        
        isLoading = false
    }
}
