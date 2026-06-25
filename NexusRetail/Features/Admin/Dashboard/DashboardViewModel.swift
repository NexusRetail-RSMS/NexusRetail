//
//  DashboardViewModel.swift
//  NexusRetail
//
//  Observable view model for the Admin Dashboard.
//  Each chart has its OWN independent time-range toggle so
//  switching one does not refresh the other.
//

import Foundation
import SwiftUI

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

/// A single bar in the product-sales chart.
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

    // MARK: - Filter State (shared across KPIs + revenue chart)
    var selectedCountry: String = "All·Global"

    // MARK: - Independent Time Range Toggles
    /// Revenue chart has its own toggle
    var revenueTimeRange: SalesTimeRange = .monthly
    /// Product chart has its own toggle
    var productTimeRange: SalesTimeRange = .weekly

    // MARK: Available Countries
    let countries: [String] = DashboardDataProvider.countries

    // MARK: - Computed KPI

    var currentKPI: CountryKPI {
        if selectedCountry == "All·Global" {
            return DashboardDataProvider.globalKPI
        }
        return DashboardDataProvider.countryKPIs.first { $0.country == selectedCountry }
            ?? DashboardDataProvider.globalKPI
    }

    /// Formatted total revenue string (e.g. "₹12.4Cr" or "₹8.5L").
    var formattedRevenue: String {
        let lakhs = currentKPI.totalRevenue
        if lakhs >= 100 {
            let crores = lakhs / 100.0
            return "₹\(String(format: "%.1f", crores))Cr"
        } else {
            return "₹\(String(format: "%.0f", lakhs))L"
        }
    }

    var activeStoresText: String {
        "\(currentKPI.activeStores)"
    }

    var pendingTransfersText: String {
        "\(currentKPI.pendingTransfers)"
    }

    var lowStockText: String {
        "\(currentKPI.lowStockAlerts)"
    }

    var revenueTrend: String {
        currentKPI.revenueTrend
    }

    var pendingTransfersTrend: String {
        let urgentCount = max(1, currentKPI.pendingTransfers / 3)
        return "\(urgentCount) high urgency"
    }

    var lowStockTrend: String {
        let criticalCount = max(1, currentKPI.lowStockAlerts / 2)
        return "\(criticalCount) critical SKUs"
    }

    var activeStoresTrend: String? {
        if selectedCountry == "All·Global" {
            return "+2 this quarter"
        }
        return nil
    }

    // MARK: - Revenue Chart Data

    /// Revenue data filtered by country AND by the revenue chart's own time range.
    var revenueChartData: [RevenueChartPoint] {
        let sourceData: [RevenueDataPoint]
        switch revenueTimeRange {
        case .monthly:
            sourceData = DashboardDataProvider.monthlyRevenue
        case .weekly:
            sourceData = DashboardDataProvider.weeklyRevenue
        }

        let filtered: [RevenueDataPoint]
        if selectedCountry == "All·Global" {
            filtered = sourceData
        } else {
            filtered = sourceData.filter { $0.country == selectedCountry }
        }

        // Group by index and sum revenue
        let grouped = Dictionary(grouping: filtered) { $0.index }
        let maxIndex = revenueTimeRange == .monthly ? 6 : 7
        let labels: [String]
        switch revenueTimeRange {
        case .monthly:
            labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        case .weekly:
            labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        }

        return (1...maxIndex).map { idx in
            let totalForPeriod = grouped[idx]?.reduce(0.0) { $0 + $1.revenue } ?? 0
            return RevenueChartPoint(
                label: labels[idx - 1],
                index: idx,
                revenue: totalForPeriod
            )
        }
    }

    /// Maximum revenue value — used for Y-axis scaling.
    var revenueMaxValue: Double {
        let maxRev = revenueChartData.map(\.revenue).max() ?? 100
        return ceil(maxRev / 50) * 50
    }

    // MARK: - Product Sales Chart Data

    /// Product category sales filtered by country and the product chart's own time range.
    var productChartData: [ProductChartPoint] {
        let filtered: [ProductSalesData]
        if selectedCountry == "All·Global" {
            filtered = DashboardDataProvider.productSales
        } else {
            filtered = DashboardDataProvider.productSales.filter { $0.country == selectedCountry }
        }

        let grouped = Dictionary(grouping: filtered) { $0.category }
        let categories = ["Watches", "Jewelry", "Leather Goods", "Couture", "Fragrances"]

        return categories.compactMap { cat in
            guard let items = grouped[cat] else { return nil }
            let total: Int
            switch productTimeRange {
            case .weekly:
                total = items.reduce(0) { $0 + $1.weeklySales }
            case .monthly:
                total = items.reduce(0) { $0 + $1.monthlySales }
            }
            return ProductChartPoint(category: cat, sales: total)
        }
        .sorted { $0.sales > $1.sales }
    }

    /// Maximum product sales value — used for Y-axis scaling.
    var productMaxValue: Int {
        let maxVal = productChartData.map(\.sales).max() ?? 100
        return ((maxVal / 50) + 1) * 50
    }
}
