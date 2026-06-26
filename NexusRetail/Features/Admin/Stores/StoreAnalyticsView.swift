//
//  StoreAnalyticsView.swift
//  NexusRetail
//
//  Analytics dashboard for a single store — KPIs, Sales bar chart,
//  and Visitors donut chart using Apple-native Swift Charts.
//

import SwiftUI
import Charts

// MARK: - Data Models

struct SalesDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let onlineSales: Double
    let offlineSales: Double
}

struct VisitorSource: Identifiable {
    let id = UUID()
    let name: String
    let count: Double
    let color: Color
}

// MARK: - Static Sample Data

enum StoreAnalyticsSampleData {
    static func salesData(for store: Store, timeRange: String) -> [SalesDataPoint] {
        let seed = abs(store.name.hashValue)
        let multiplier: Double = timeRange == "This Month" ? 0.3 : timeRange == "All Time" ? 3.0 : 1.0
        func rand(_ base: Double, _ range: Double, _ offset: Int) -> Double {
            let v = Double((seed + offset) % 1000) / 1000.0
            return (base + v * range) * multiplier
        }
        if timeRange == "This Month" {
            return [
                SalesDataPoint(month: "W1", onlineSales: rand(400, 300, 1), offlineSales: rand(200, 200, 2)),
                SalesDataPoint(month: "W2", onlineSales: rand(350, 350, 3), offlineSales: rand(250, 250, 4)),
                SalesDataPoint(month: "W3", onlineSales: rand(500, 200, 5), offlineSales: rand(300, 200, 6)),
                SalesDataPoint(month: "W4", onlineSales: rand(450, 250, 7), offlineSales: rand(280, 220, 8)),
            ]
        }
        return [
            SalesDataPoint(month: "Jan", onlineSales: rand(400, 600, 1), offlineSales: rand(300, 400, 2)),
            SalesDataPoint(month: "Feb", onlineSales: rand(500, 500, 3), offlineSales: rand(350, 350, 4)),
            SalesDataPoint(month: "Mar", onlineSales: rand(450, 550, 5), offlineSales: rand(280, 420, 6)),
            SalesDataPoint(month: "Apr", onlineSales: rand(600, 400, 7), offlineSales: rand(320, 380, 8)),
            SalesDataPoint(month: "May", onlineSales: rand(550, 450, 9), offlineSales: rand(300, 400, 10)),
            SalesDataPoint(month: "Jun", onlineSales: rand(700, 300, 11), offlineSales: rand(350, 350, 12)),
        ]
    }

    static func kpiData(for store: Store, timeRange: String) -> (orders: Int, sales: Int, paidOut: Int, customers: Int) {
        let seed = abs(store.name.hashValue)
        let multiplier: Double = timeRange == "This Month" ? 0.08 : timeRange == "All Time" ? 3.5 : 1.0
        let orders = Int(Double(1200 + (seed % 3000)) * multiplier)
        let sales = Int(Double(50000 + (seed % 80000)) * multiplier)
        let paidOut = Int(Double(15000 + (seed % 25000)) * multiplier)
        let customers = Int(Double(100 + (seed % 300)) * multiplier)
        return (orders, sales, paidOut, customers)
    }

    static func visitorSources(for store: Store) -> [VisitorSource] {
        let seed = abs(store.name.hashValue)
        let total = 15000 + (seed % 12000)
        let a = Double(total) * 0.58
        let b = Double(total) * 0.15
        let c = Double(total) * 0.12
        let d = Double(total) * 0.15
        return [
            VisitorSource(name: "Walk-In", count: a, color: RSMSColors.burgundy),
            VisitorSource(name: "Online", count: b, color: Color(hex: "F4A261")),
            VisitorSource(name: "Referral", count: c, color: RSMSColors.success),
            VisitorSource(name: "Social", count: d, color: Color(hex: "2A9D8F")),
        ]
    }
}

// MARK: - Main View

struct StoreAnalyticsView: View {
    let store: Store
    let manager: AppUser?
    @Bindable var viewModel: StoresViewModel

    @State private var selectedTimeRange = "This Year"
    @State private var isShowingStoreInfo = false
    @State private var isShowingSalesDetail = false
    @State private var isShowingProductsDetail = false

    private let timeRanges = ["This Month", "This Year", "All Time"]

    private var salesData: [SalesDataPoint] {
        StoreAnalyticsSampleData.salesData(for: store, timeRange: selectedTimeRange)
    }

    private var kpi: (orders: Int, sales: Int, paidOut: Int, customers: Int) {
        StoreAnalyticsSampleData.kpiData(for: store, timeRange: selectedTimeRange)
    }

    private var productTimeRange: StoreChartTimeRange {
        switch selectedTimeRange {
        case "This Month": return .month
        case "All Time":   return .year
        default:           return .year
        }
    }

    private var topProducts: [TopProduct] {
        TopProductsSampleData.products(for: store, range: productTimeRange)
    }

    private var totalUnits: Int {
        topProducts.reduce(0) { $0 + $1.unitsSold }
    }

    private var salesChartMax: Double {
        let maxOnline = salesData.map(\.onlineSales).max() ?? 0
        let maxOffline = salesData.map(\.offlineSales).max() ?? 0
        return max(maxOnline, maxOffline) * 1.15
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RSMSSpacing.xl) {

                // MARK: - Overview Header
                overviewSection

                // MARK: - KPI Cards
                kpiGrid

                // MARK: - Sales Report Chart
                salesReportSection
                    .onTapGesture { isShowingSalesDetail = true }

                // MARK: - Top Products Donut Chart
                visitorsSection
                    .onTapGesture { isShowingProductsDetail = true }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.xxl)
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle(store.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingStoreInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(RSMSColors.burgundy)
                }
                .accessibilityLabel("Store Info")
            }
        }
        .sheet(isPresented: $isShowingStoreInfo) {
            NavigationStack {
                StoreDetailView(store: store, manager: manager, viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { isShowingStoreInfo = false }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $isShowingSalesDetail) {
            NavigationStack {
                SalesDetailView(store: store)
            }
        }
        .fullScreenCover(isPresented: $isShowingProductsDetail) {
            NavigationStack {
                TopProductsDetailView(store: store)
            }
        }
    }

    // MARK: - Overview Header

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text("Overview")
                .font(RSMSFonts.title)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)

            HStack {
                Text("Show:")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.secondaryText)

                Menu {
                    ForEach(timeRanges, id: \.self) { range in
                        Button(range) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedTimeRange = range
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedTimeRange)
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(RSMSColors.burgundy)
                }
            }
        }
        .padding(.top, RSMSSpacing.md)
    }

    // MARK: - KPI Grid

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
            AnalyticsKPICard(
                value: "\(formatNumber(kpi.orders))",
                title: "New Orders",
                trend: "+2.5%",
                trendUp: true
            )
            AnalyticsKPICard(
                value: "\(formatNumber(kpi.sales))",
                title: "Total Sales",
                trend: "+0.5%",
                trendUp: true
            )
            AnalyticsKPICard(
                value: "₹\(formatNumber(kpi.paidOut))",
                title: "Total Paid Out",
                trend: "-2.5%",
                trendUp: false
            )
            AnalyticsKPICard(
                value: "\(kpi.customers)",
                title: "New Customers",
                trend: "-5%",
                trendUp: false
            )
        }
    }

    // MARK: - Sales Report

    private var salesReportSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sales Report")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                Text(selectedTimeRange)
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
            }

            // Legend
            HStack(spacing: RSMSSpacing.lg) {
                LegendDot(color: RSMSColors.burgundy, label: "Online Sales")
                LegendDot(color: Color(hex: "2A9D8F"), label: "Offline Sales")
            }

            // Bar Chart
            Chart(salesData) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Sales", item.onlineSales)
                )
                .foregroundStyle(RSMSColors.burgundy)
                .cornerRadius(4)
                .position(by: .value("Type", "Online"))

                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Sales", item.offlineSales)
                )
                .foregroundStyle(Color(hex: "2A9D8F"))
                .cornerRadius(4)
                .position(by: .value("Type", "Offline"))
            }
            .chartYScale(domain: 0...salesChartMax)
            .chartYAxis {
                AxisMarks(values: [0, 250, 500, 750, 1000]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(RSMSColors.divider)
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text(intVal >= 1000 ? "₹\(intVal / 1000)k" : "₹\(intVal)")
                                .font(.system(size: 10))
                                .foregroundStyle(RSMSColors.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 11))
                        .foregroundStyle(RSMSColors.secondaryText)
                }
            }
            .frame(height: 220)
            .padding(.top, RSMSSpacing.sm)
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Top Products Donut

    private var visitorsSection: some View {
        VStack(spacing: RSMSSpacing.lg) {

            // Header
            HStack {
                Text("Top Products")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                Text(selectedTimeRange)
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.secondaryText)
            }

            // Donut Chart
            ZStack {
                Chart(topProducts) { product in
                    SectorMark(
                        angle: .value("Units", product.unitsSold),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(product.color)
                    .cornerRadius(6)
                }
                .frame(height: 200)

                // Center label
                VStack(spacing: 2) {
                    Text(formatNumber(totalUnits))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text("Units sold")
                        .font(.system(size: 10))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }

            // Legend grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.sm) {
                ForEach(topProducts) { product in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(product.color)
                            .frame(width: 8, height: 8)
                        Text(product.name)
                            .font(.system(size: 12))
                            .foregroundColor(RSMSColors.secondaryText)
                            .lineLimit(1)
                        Text(formatNumber(product.unitsSold))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                    }
                }
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Helpers

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Analytics KPI Card

private struct AnalyticsKPICard: View {
    let value: String
    let title: String
    let trend: String
    let trendUp: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(RSMSFonts.subheadline)
                .foregroundColor(RSMSColors.secondaryText)

            HStack(spacing: 2) {
                Text(trend)
                    .font(.system(size: 12, weight: .bold))
                Image(systemName: trendUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(trendUp ? RSMSColors.success : RSMSColors.error)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Legend Dot

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(RSMSColors.secondaryText)
        }
    }
}
