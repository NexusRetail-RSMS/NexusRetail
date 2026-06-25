//
//  DashboardDataProvider.swift
//  NexusRetail
//
//  Static sample dataset for the Admin Dashboard charts.
//  Provides realistic luxury retail revenue and product-sales data
//  across multiple countries and stores. Designed to be swapped for
//  Supabase queries when real data flows in.
//

import Foundation

// MARK: - Data Models

/// A single data point of revenue for a given store.
struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let label: String           // "Jan", "Feb" … or "Mon", "Tue" …
    let index: Int              // ordering index
    let revenue: Double         // in Lakhs (₹)
    let storeName: String
    let country: String
}

/// Sales volume for a product category in a time range.
struct ProductSalesData: Identifiable {
    let id = UUID()
    let category: String
    let weeklySales: Int
    let monthlySales: Int
    let country: String
}

/// Aggregate KPI snapshot per country.
struct CountryKPI {
    let country: String
    let totalRevenue: Double     // in Lakhs
    let activeStores: Int
    let pendingTransfers: Int
    let lowStockAlerts: Int
    let revenueTrend: String     // e.g. "+8.2% vs last month"
}

// MARK: - Sample Data

enum DashboardDataProvider {

    // MARK: Countries
    static let countries = ["All·Global", "India", "UAE", "UK", "Italy"]

    // MARK: Monthly Revenue (per store, Jan–Jun 2026, values in ₹ Lakhs)
    static let monthlyRevenue: [RevenueDataPoint] = {
        var data: [RevenueDataPoint] = []

        let storeData: [(String, String, [(String, Int, Double)])] = [
            ("Mumbai Flagship", "India", [
                ("Jan", 1, 62.0), ("Feb", 2, 71.0), ("Mar", 3, 85.0),
                ("Apr", 4, 78.0), ("May", 5, 92.0), ("Jun", 6, 110.0)
            ]),
            ("Delhi Chanakya", "India", [
                ("Jan", 1, 45.0), ("Feb", 2, 52.0), ("Mar", 3, 60.0),
                ("Apr", 4, 55.0), ("May", 5, 68.0), ("Jun", 6, 74.0)
            ]),
            ("Dubai Mall", "UAE", [
                ("Jan", 1, 88.0), ("Feb", 2, 95.0), ("Mar", 3, 102.0),
                ("Apr", 4, 91.0), ("May", 5, 115.0), ("Jun", 6, 130.0)
            ]),
            ("Abu Dhabi", "UAE", [
                ("Jan", 1, 38.0), ("Feb", 2, 42.0), ("Mar", 3, 50.0),
                ("Apr", 4, 44.0), ("May", 5, 55.0), ("Jun", 6, 60.0)
            ]),
            ("London Harrods", "UK", [
                ("Jan", 1, 72.0), ("Feb", 2, 80.0), ("Mar", 3, 90.0),
                ("Apr", 4, 85.0), ("May", 5, 98.0), ("Jun", 6, 115.0)
            ]),
            ("Milan Duomo", "Italy", [
                ("Jan", 1, 55.0), ("Feb", 2, 63.0), ("Mar", 3, 70.0),
                ("Apr", 4, 65.0), ("May", 5, 78.0), ("Jun", 6, 88.0)
            ])
        ]
        for (store, country, months) in storeData {
            for m in months {
                data.append(RevenueDataPoint(label: m.0, index: m.1, revenue: m.2, storeName: store, country: country))
            }
        }
        return data
    }()

    // MARK: Weekly Revenue (per store, current week, values in ₹ Lakhs)
    static let weeklyRevenue: [RevenueDataPoint] = {
        var data: [RevenueDataPoint] = []
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        let storeData: [(String, String, [Double])] = [
            ("Mumbai Flagship", "India",  [14.5, 12.8, 16.2, 15.0, 18.5, 22.0, 11.0]),
            ("Delhi Chanakya",  "India",  [9.0,  8.5,  10.2, 9.8,  12.0, 15.5, 8.0]),
            ("Dubai Mall",      "UAE",    [18.0, 16.5, 20.0, 17.5, 22.0, 26.0, 14.0]),
            ("Abu Dhabi",       "UAE",    [7.5,  6.8,  8.5,  7.2,  9.0,  11.5, 5.5]),
            ("London Harrods",  "UK",     [12.0, 11.5, 14.0, 13.0, 16.5, 20.0, 9.5]),
            ("Milan Duomo",     "Italy",  [9.5,  8.8,  11.0, 10.2, 12.5, 15.0, 7.0])
        ]
        for (store, country, revenues) in storeData {
            for (i, rev) in revenues.enumerated() {
                data.append(RevenueDataPoint(label: days[i], index: i + 1, revenue: rev, storeName: store, country: country))
            }
        }
        return data
    }()

    // MARK: Product Sales (per country)
    static let productSales: [ProductSalesData] = [
        // India
        ProductSalesData(category: "Watches",      weeklySales: 28, monthlySales: 112, country: "India"),
        ProductSalesData(category: "Jewelry",       weeklySales: 35, monthlySales: 140, country: "India"),
        ProductSalesData(category: "Leather Goods", weeklySales: 22, monthlySales: 88,  country: "India"),
        ProductSalesData(category: "Couture",       weeklySales: 15, monthlySales: 60,  country: "India"),
        ProductSalesData(category: "Fragrances",    weeklySales: 42, monthlySales: 168, country: "India"),
        // UAE
        ProductSalesData(category: "Watches",      weeklySales: 45, monthlySales: 180, country: "UAE"),
        ProductSalesData(category: "Jewelry",       weeklySales: 52, monthlySales: 208, country: "UAE"),
        ProductSalesData(category: "Leather Goods", weeklySales: 30, monthlySales: 120, country: "UAE"),
        ProductSalesData(category: "Couture",       weeklySales: 25, monthlySales: 100, country: "UAE"),
        ProductSalesData(category: "Fragrances",    weeklySales: 38, monthlySales: 152, country: "UAE"),
        // UK
        ProductSalesData(category: "Watches",      weeklySales: 33, monthlySales: 132, country: "UK"),
        ProductSalesData(category: "Jewelry",       weeklySales: 40, monthlySales: 160, country: "UK"),
        ProductSalesData(category: "Leather Goods", weeklySales: 48, monthlySales: 192, country: "UK"),
        ProductSalesData(category: "Couture",       weeklySales: 20, monthlySales: 80,  country: "UK"),
        ProductSalesData(category: "Fragrances",    weeklySales: 30, monthlySales: 120, country: "UK"),
        // Italy
        ProductSalesData(category: "Watches",      weeklySales: 25, monthlySales: 100, country: "Italy"),
        ProductSalesData(category: "Jewelry",       weeklySales: 30, monthlySales: 120, country: "Italy"),
        ProductSalesData(category: "Leather Goods", weeklySales: 55, monthlySales: 220, country: "Italy"),
        ProductSalesData(category: "Couture",       weeklySales: 40, monthlySales: 160, country: "Italy"),
        ProductSalesData(category: "Fragrances",    weeklySales: 20, monthlySales: 80,  country: "Italy"),
    ]

    // MARK: KPI Aggregates
    static let countryKPIs: [CountryKPI] = [
        CountryKPI(country: "India", totalRevenue: 853.0,  activeStores: 12, pendingTransfers: 5, lowStockAlerts: 8,  revenueTrend: "+12% this week"),
        CountryKPI(country: "UAE",   totalRevenue: 910.0,  activeStores: 8,  pendingTransfers: 3, lowStockAlerts: 5,  revenueTrend: "+9.4% this week"),
        CountryKPI(country: "UK",    totalRevenue: 740.0,  activeStores: 10, pendingTransfers: 4, lowStockAlerts: 6,  revenueTrend: "+6.1% this week"),
        CountryKPI(country: "Italy", totalRevenue: 619.0,  activeStores: 8,  pendingTransfers: 2, lowStockAlerts: 5,  revenueTrend: "+7.8% this week"),
    ]

    /// Global aggregate KPI (sum of all countries).
    static let globalKPI: CountryKPI = {
        let all = countryKPIs
        return CountryKPI(
            country: "All·Global",
            totalRevenue: all.reduce(0) { $0 + $1.totalRevenue },
            activeStores: all.reduce(0) { $0 + $1.activeStores },
            pendingTransfers: all.reduce(0) { $0 + $1.pendingTransfers },
            lowStockAlerts: all.reduce(0) { $0 + $1.lowStockAlerts },
            revenueTrend: "+8.2% vs last month"
        )
    }()
}
