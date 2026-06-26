//
//  DashboardDataProvider.swift
//  NexusRetail
//
//  Provides dashboard chart and KPI data by aggregating the parsed
//  retail_sales.csv transactions. Falls back to empty results if
//  the CSV is missing or cannot be loaded.
//
//  The CSV (Kaggle Retail Sales Dataset format) contains:
//    Transaction ID, Date, Customer ID, Gender, Age,
//    Product Category, Quantity, Price per Unit, Total Amount,
//    Store, Country
//

import Foundation

// MARK: - Data Models

/// A single data point of revenue for a given period.
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

// MARK: - Data Provider (CSV-backed)

enum DashboardDataProvider {

    // MARK: - Loaded Transactions (cached)

    /// All transactions parsed from the bundled CSV, loaded once.
    static let allTransactions: [SalesTransaction] = CSVDataLoader.loadTransactions()

    // MARK: Countries

    static let countries: [String] = {
        var unique = Set(allTransactions.map(\.country))
        let sorted = unique.sorted()
        return ["All·Global"] + sorted
    }()

    // MARK: Unique Stores per Country

    private static let storesPerCountry: [String: Set<String>] = {
        var result: [String: Set<String>] = [:]
        for txn in allTransactions {
            result[txn.country, default: []].insert(txn.store)
        }
        return result
    }()

    // MARK: Monthly Revenue (per store, values in ₹ Lakhs)

    static let monthlyRevenue: [RevenueDataPoint] = {
        let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        // Group by (store, country, month) → sum totalAmount
        var grouped: [String: Double] = [:]  // key: "store|country|month"
        for txn in allTransactions {
            let key = "\(txn.store)|\(txn.country)|\(txn.month)"
            grouped[key, default: 0] += txn.totalAmount
        }

        var data: [RevenueDataPoint] = []
        for (key, total) in grouped {
            let parts = key.split(separator: "|")
            guard parts.count == 3,
                  let monthIndex = Int(parts[2]),
                  monthIndex >= 1, monthIndex <= 12
            else { continue }

            data.append(RevenueDataPoint(
                label: monthLabels[monthIndex - 1],
                index: monthIndex,
                revenue: total / 100_000.0,   // convert ₹ to Lakhs
                storeName: String(parts[0]),
                country: String(parts[1])
            ))
        }
        return data.sorted { $0.index < $1.index }
    }()

    // MARK: Weekly Revenue (latest week in dataset, per store, in ₹ Lakhs)

    static let weeklyRevenue: [RevenueDataPoint] = {
        let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        // Find the last 7 days in the dataset
        guard let maxDate = allTransactions.map(\.date).max() else { return [] }
        let calendar = Calendar.current
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: maxDate) else { return [] }

        let lastWeekTxns = allTransactions.filter { $0.date >= weekStart && $0.date <= maxDate }

        // Group by (store, country, weekday) → sum totalAmount
        var grouped: [String: Double] = [:]
        for txn in lastWeekTxns {
            let key = "\(txn.store)|\(txn.country)|\(txn.weekday)"
            grouped[key, default: 0] += txn.totalAmount
        }

        var data: [RevenueDataPoint] = []
        for (key, total) in grouped {
            let parts = key.split(separator: "|")
            guard parts.count == 3,
                  let weekday = Int(parts[2]),
                  weekday >= 1, weekday <= 7
            else { continue }

            // Calendar weekday: 1=Sun, 2=Mon, … 7=Sat
            // Reorder to Mon=1, Tue=2, … Sun=7 for display
            let displayIndex = weekday == 1 ? 7 : weekday - 1

            data.append(RevenueDataPoint(
                label: dayLabels[weekday - 1],
                index: displayIndex,
                revenue: total / 100_000.0,
                storeName: String(parts[0]),
                country: String(parts[1])
            ))
        }
        return data.sorted { $0.index < $1.index }
    }()

    // MARK: Product Sales (per country)

    static let productSales: [ProductSalesData] = {
        guard let maxDate = allTransactions.map(\.date).max() else { return [] }
        let calendar = Calendar.current
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: maxDate) else { return [] }
        let currentMonth = calendar.component(.month, from: maxDate)

        let categories = Set(allTransactions.map(\.productCategory)).sorted()
        let countries = Set(allTransactions.map(\.country)).sorted()

        var data: [ProductSalesData] = []

        for country in countries {
            let countryTxns = allTransactions.filter { $0.country == country }

            for category in categories {
                let catTxns = countryTxns.filter { $0.productCategory == category }

                // Weekly: last 7 days
                let weeklyQty = catTxns
                    .filter { $0.date >= weekStart && $0.date <= maxDate }
                    .reduce(0) { $0 + $1.quantity }

                // Monthly: current month
                let monthlyQty = catTxns
                    .filter { calendar.component(.month, from: $0.date) == currentMonth }
                    .reduce(0) { $0 + $1.quantity }

                data.append(ProductSalesData(
                    category: category,
                    weeklySales: weeklyQty,
                    monthlySales: monthlyQty,
                    country: country
                ))
            }
        }
        return data
    }()

    // MARK: KPI Aggregates

    static let countryKPIs: [CountryKPI] = {
        let countries = Set(allTransactions.map(\.country)).sorted()
        let calendar = Calendar.current

        return countries.map { country in
            let countryTxns = allTransactions.filter { $0.country == country }
            let totalRevenue = countryTxns.reduce(0.0) { $0 + $1.totalAmount }
            let storeCount = storesPerCountry[country]?.count ?? 0

            // Compute trend: compare last month vs previous month
            guard let maxDate = countryTxns.map(\.date).max() else {
                return CountryKPI(
                    country: country,
                    totalRevenue: totalRevenue / 100_000.0,
                    activeStores: storeCount,
                    pendingTransfers: 0,
                    lowStockAlerts: 0,
                    revenueTrend: "—"
                )
            }

            let lastMonth = calendar.component(.month, from: maxDate)
            let prevMonth = lastMonth > 1 ? lastMonth - 1 : 12

            let lastMonthRevenue = countryTxns
                .filter { calendar.component(.month, from: $0.date) == lastMonth }
                .reduce(0.0) { $0 + $1.totalAmount }

            let prevMonthRevenue = countryTxns
                .filter { calendar.component(.month, from: $0.date) == prevMonth }
                .reduce(0.0) { $0 + $1.totalAmount }

            let trend: String
            if prevMonthRevenue > 0 {
                let pctChange = ((lastMonthRevenue - prevMonthRevenue) / prevMonthRevenue) * 100
                let sign = pctChange >= 0 ? "+" : ""
                trend = "\(sign)\(String(format: "%.1f", pctChange))% vs last month"
            } else {
                trend = "—"
            }

            // Simulated operational metrics (scale with store count)
            let pendingTransfers = max(1, storeCount * 2 + Int.random(in: 0...3))
            let lowStockAlerts = max(1, storeCount + Int.random(in: 1...5))

            return CountryKPI(
                country: country,
                totalRevenue: totalRevenue / 100_000.0,
                activeStores: storeCount,
                pendingTransfers: pendingTransfers,
                lowStockAlerts: lowStockAlerts,
                revenueTrend: trend
            )
        }
    }()

    /// Global aggregate KPI (sum of all countries).
    static let globalKPI: CountryKPI = {
        let all = countryKPIs
        // Compute global trend from raw transactions
        let calendar = Calendar.current
        guard let maxDate = allTransactions.map(\.date).max() else {
            return CountryKPI(
                country: "All·Global",
                totalRevenue: all.reduce(0) { $0 + $1.totalRevenue },
                activeStores: all.reduce(0) { $0 + $1.activeStores },
                pendingTransfers: all.reduce(0) { $0 + $1.pendingTransfers },
                lowStockAlerts: all.reduce(0) { $0 + $1.lowStockAlerts },
                revenueTrend: "—"
            )
        }

        let lastMonth = calendar.component(.month, from: maxDate)
        let prevMonth = lastMonth > 1 ? lastMonth - 1 : 12

        let lastMonthTotal = allTransactions
            .filter { calendar.component(.month, from: $0.date) == lastMonth }
            .reduce(0.0) { $0 + $1.totalAmount }

        let prevMonthTotal = allTransactions
            .filter { calendar.component(.month, from: $0.date) == prevMonth }
            .reduce(0.0) { $0 + $1.totalAmount }

        let trend: String
        if prevMonthTotal > 0 {
            let pctChange = ((lastMonthTotal - prevMonthTotal) / prevMonthTotal) * 100
            let sign = pctChange >= 0 ? "+" : ""
            trend = "\(sign)\(String(format: "%.1f", pctChange))% vs last month"
        } else {
            trend = "—"
        }

        return CountryKPI(
            country: "All·Global",
            totalRevenue: all.reduce(0) { $0 + $1.totalRevenue },
            activeStores: all.reduce(0) { $0 + $1.activeStores },
            pendingTransfers: all.reduce(0) { $0 + $1.pendingTransfers },
            lowStockAlerts: all.reduce(0) { $0 + $1.lowStockAlerts },
            revenueTrend: trend
        )
    }()
}
