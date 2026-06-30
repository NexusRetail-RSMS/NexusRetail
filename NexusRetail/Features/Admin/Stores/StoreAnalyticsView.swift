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

// MARK: - Main View

struct StoreAnalyticsView: View {
    let store: Store
    let manager: AppUser?
    @Bindable var viewModel: StoresViewModel
    @State private var analyticsVM: StoreAnalyticsViewModel

    @State private var isShowingStoreInfo = false
    @State private var isShowingSalesDetail = false
    @State private var isShowingProductsDetail = false

    private let timeRanges = ["This Month", "This Year", "All Time"]
    
    init(store: Store, manager: AppUser?, viewModel: StoresViewModel) {
        self.store = store
        self.manager = manager
        self.viewModel = viewModel
        self._analyticsVM = State(initialValue: StoreAnalyticsViewModel(store: store))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                if analyticsVM.isLoading && analyticsVM.orders.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView("Loading store data...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    // MARK: - Overview Header
                    overviewSection
                    
                    if let errorMessage = analyticsVM.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(RSMSColors.error)
                            .padding()
                    }

                    // MARK: - KPI Cards
                    kpiGrid

                    // MARK: - Sales Report Chart
                    salesReportSection
                        .onTapGesture { isShowingSalesDetail = true }

                    // MARK: - Top Products Donut Chart
                    visitorsSection
                        .onTapGesture { isShowingProductsDetail = true }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.xxl)
        }
        .refreshable {
            await analyticsVM.load()
        }
        .task {
            if analyticsVM.orders.isEmpty {
                await analyticsVM.load()
            }
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
                                analyticsVM.timeRange = range
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(analyticsVM.timeRange)
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
                value: "\(formatNumber(analyticsVM.kpiOrders))",
                title: "New Orders",
                trend: "",
                trendUp: true
            )
            AnalyticsKPICard(
                value: "₹\(formatNumber(analyticsVM.kpiSales))",
                title: "Total Sales",
                trend: "",
                trendUp: true
            )
            AnalyticsKPICard(
                value: "₹\(formatNumber(analyticsVM.kpiPaidOut))",
                title: "Total Paid Out",
                trend: "",
                trendUp: false
            )
            AnalyticsKPICard(
                value: "\(analyticsVM.kpiCustomers)",
                title: "New Customers",
                trend: "",
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

                Text(analyticsVM.timeRange)
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
            }

            // Legend
            HStack(spacing: RSMSSpacing.lg) {
                LegendDot(color: RSMSColors.burgundy, label: "Total Sales")
            }

            // Bar Chart
            if analyticsVM.salesData.isEmpty {
                Chart {
                    ForEach(["Jan", "Feb", "Mar", "Apr", "May", "Jun"], id: \.self) { month in
                        BarMark(
                            x: .value("Month", month),
                            y: .value("Sales", 5.0)
                        )
                        .foregroundStyle(RSMSColors.burgundy.opacity(0.15))
                        .cornerRadius(4)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(RSMSColors.divider)
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("₹\(intVal)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(RSMSColors.secondaryText)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 11))
                            .foregroundStyle(RSMSColors.secondaryText)
                    }
                }
                .frame(height: 220)
                .padding(.top, RSMSSpacing.sm)
                .overlay {
                    Text("No sales data available")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                }
            } else {
                Chart(analyticsVM.salesData) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Sales", item.onlineSales)
                    )
                    .foregroundStyle(RSMSColors.burgundy)
                    .cornerRadius(4)
                }
                .chartYScale(domain: 0...analyticsVM.salesChartMax)
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

                Text(analyticsVM.timeRange)
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.secondaryText)
            }

            // Donut Chart
            if analyticsVM.topProducts.isEmpty {
                ZStack {
                    Chart {
                        SectorMark(
                            angle: .value("Placeholder", 1),
                            innerRadius: .ratio(0.65),
                            angularInset: 2
                        )
                        .foregroundStyle(RSMSColors.burgundy.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .chartLegend(.hidden)
                    .frame(height: 200)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "bag")
                            .font(.system(size: 22))
                            .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                        Text("No products data")
                            .font(.system(size: 10))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }
            } else {
                ZStack {
                    Chart(analyticsVM.topProducts) { product in
                        SectorMark(
                            angle: .value("Units", product.units),
                            innerRadius: .ratio(0.65),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Category", product.category))
                        .cornerRadius(6)
                    }
                    .chartForegroundStyleScale([
                        "Couture": RSMSColors.burgundy,
                        "Perfume": Color(hex: "F4A261"),
                        "Perfumes": Color(hex: "F4A261"),
                        "Fragrances": Color(hex: "F4A261"),
                        "Fragrance": Color(hex: "F4A261"),
                        "Jewellery": Color(hex: "E9C46A"),
                        "Jewelry": Color(hex: "E9C46A"),
                        "Leather Goods": Color(hex: "2A9D8F"),
                        "Leather": Color(hex: "2A9D8F"),
                        "Watches": Color(hex: "264653"),
                        "Accessories": Color(hex: "8A2BE2"),
                        "Bags": Color(hex: "2A9D8F"),
                        "Clothes": RSMSColors.burgundy
                    ])
                    .chartLegend(.hidden)
                    .frame(height: 200)

                    // Center label
                    VStack(spacing: 2) {
                        Text(formatNumber(analyticsVM.totalUnits))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                        Text("Units sold")
                            .font(.system(size: 10))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }

                // Legend grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.sm) {
                    ForEach(analyticsVM.topProducts) { product in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorFor(category: product.category))
                                .frame(width: 8, height: 8)
                            Text(product.name)
                                .font(.system(size: 12))
                                .foregroundColor(RSMSColors.secondaryText)
                                .lineLimit(1)
                            Text(formatNumber(product.units))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                            Spacer()
                        }
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
    
    private func colorFor(category: String) -> Color {
        switch category {
        case "Couture": return RSMSColors.burgundy
        case "Perfume", "Perfumes", "Fragrances", "Fragrance": return Color(hex: "F4A261")
        case "Jewellery", "Jewelry": return Color(hex: "E9C46A")
        case "Leather", "Leather Goods": return Color(hex: "2A9D8F")
        case "Watches": return Color(hex: "264653")
        case "Accessories": return Color(hex: "8A2BE2")
        case "Bags": return Color(hex: "2A9D8F")
        case "Clothes": return RSMSColors.burgundy
        default: return RSMSColors.chartBar
        }
    }

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
