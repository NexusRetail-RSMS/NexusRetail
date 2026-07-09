//
//  SalesDetailView.swift
//  NexusRetail
//
//  Full-screen detailed sales chart inspired by Apple Health's
//  step-count view — D / W / M / Y segmented picker, a large
//  total value, and an expanded bar chart.


import SwiftUI
import Charts
import Supabase

// Enum moved to SwipeableCalendarView.swift

// MARK: - Granular Data Point

struct SalesGranularPoint: Identifiable {
    var id: String { label }
    let label: String
    let online: Double
    let offline: Double
    var total: Double { online + offline }
}

// MARK: - View

struct SalesDetailView: View {
    @Environment(AppTheme.self) private var theme
    let store: Store
    // Default to yearly so there's always data visible on open.
    // Weekly default caused "no data" because current week may have no orders.
    @State private var selectedRange: StoreChartTimeRange = .yearly(Date())
    @Environment(\.dismiss) private var dismiss

    @State private var dataPoints: [SalesPeriodResult] = []
    @State private var categorySales: [StoreCategorySales] = []
    @State private var isLoading = false

    // MARK: - Derived Data

    private var totalSales: Double {
        dataPoints.reduce(0) { $0 + $1.online + $1.offline }
    }

    private var peakPoint: SalesPeriodResult? {
        dataPoints.max { ($0.online + $0.offline) < ($1.online + $1.offline) }
    }

    private var maxValue: Double {
        let m = dataPoints.map { $0.online + $0.offline }.max() ?? 0
        return m > 0 ? m * 1.15 : 100   // Show a reasonable scale even when empty
    }

    private var periodLabel: String {
        switch selectedRange {
        case .weekly(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        case .monthly(let date): 
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        case .yearly(let date): 
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

            HStack {
                Text("Sales Report")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Menu {
                    Button("Weekly") { selectedRange = .weekly(Date()) }
                    Button("Monthly") { selectedRange = .monthly(Date()) }
                    Button("Yearly") { selectedRange = .yearly(Date()) }
                } label: {
                    HStack(spacing: 4) {
                        Text(localized: selectedRange.isWeekly ? "Weekly" : (selectedRange.isMonthly ? "Monthly" : "Yearly"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.md)

            // Segmented picker
            SwipeableCalendarView(selectedRange: $selectedRange)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.md)

            // Legend
            HStack(spacing: RSMSSpacing.sm) {
                RoundedRectangle(cornerRadius: 2).fill(theme.burgundy).frame(width: 16, height: 8)
                Text("Revenue (₹)").font(.system(size: 12)).foregroundColor(theme.secondaryText)
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.md)

            // Chart
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(theme.burgundy)
                    Spacer()
                }
                .frame(height: 300)
            } else {
                GeometryReader { geo in
                    let hasData = dataPoints.contains { $0.online + $0.offline > 0 }
                    
                    if hasData {
                        Chart(dataPoints) { point in
                            AreaMark(
                                x: .value("Period", point.label),
                                y: .value("Revenue", point.online + point.offline)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(LinearGradient(colors: [theme.burgundy.opacity(0.22), theme.burgundy.opacity(0.02)], startPoint: .top, endPoint: .bottom))

                            LineMark(
                                x: .value("Period", point.label),
                                y: .value("Revenue", point.online + point.offline)
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .foregroundStyle(theme.burgundy)
                        }
                        .chartYScale(domain: 0...maxValue)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    .foregroundStyle(theme.divider)
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(shortCurrency(v))
                                            .font(.system(size: 10))
                                            .foregroundStyle(theme.secondaryText)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.system(size: 10))
                                    .foregroundStyle(theme.secondaryText)
                            }
                        }
                    } else {
                        // Empty state: faint flat placeholder line
                        Chart(dataPoints) { point in
                            LineMark(
                                x: .value("Period", point.label),
                                y: .value("Revenue", 8.0)
                            )
                            .foregroundStyle(theme.burgundy.opacity(0.15))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    .foregroundStyle(theme.divider)
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(shortCurrency(v))
                                            .font(.system(size: 10))
                                            .foregroundStyle(theme.secondaryText)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.system(size: 10))
                                    .foregroundStyle(theme.secondaryText)
                            }
                        }
                        .overlay {
                            Text("No sales this period")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.lg)
                .animation(.easeInOut(duration: 0.3), value: selectedRange)
                .frame(height: 300)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Sales Chart, Total sales: \(formatNumber(Int(totalSales)))")
            }

            // Total + Peak cards (matching the Sales Associate detail view)
            HStack(spacing: 12) {
                summaryTile(title: "Total", value: shortCurrency(totalSales), caption: periodLabel)
                summaryTile(title: "Peak",
                            value: shortCurrency(peakPoint.map { $0.online + $0.offline } ?? 0),
                            caption: (peakPoint.map { $0.online + $0.offline } ?? 0) > 0 ? peakPoint?.label : "—")
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)

            // Ranked Category list
            VStack(alignment: .leading, spacing: 0) {
                Text("Sales by Category")
                    .font(RSMSFonts.headline)
                    .foregroundColor(theme.primaryText)
                    .padding(.bottom, RSMSSpacing.md)

                if isLoading {
                    ProgressView()
                        .padding()
                } else if categorySales.isEmpty {
                    VStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 28))
                            .foregroundColor(theme.secondaryText.opacity(0.5))
                        Text("No sales data available.")
                            .foregroundColor(theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RSMSSpacing.xl)
                } else {
                    // Clean native-style list: category name + revenue
                    ForEach(Array(categorySales.enumerated()), id: \.element.id) { index, cat in
                        HStack {
                            Text(localized: cat.category)
                                .font(.system(size: 16))
                                .foregroundColor(theme.primaryText)
                                .lineLimit(1)
                            Spacer()
                            Text("₹\(formatNumber(Int(cat.revenue)))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.secondaryText)
                        }
                        .padding(.vertical, RSMSSpacing.md)
                        .accessibilityElement(children: .combine)

                        if index < categorySales.count - 1 {
                            Divider().foregroundColor(theme.divider)
                        }
                    }
                }
            }
            .padding(RSMSSpacing.lg)
            .background(theme.cardBackground)
            .cornerRadius(RSMSRadius.large)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.xl)
            .padding(.bottom, RSMSSpacing.xxl)
        }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(theme.burgundy)
                }
            }
        }
        .task(id: selectedRange) {
            await fetchData()
        }
    }
    
    // MARK: - Data Fetching
    
    struct NullableUUID: Encodable {
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

    struct RpcParams: Encodable {
        let p_store_id: NullableUUID
        let p_period: String
    }
    
    private func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        let storeId: UUID? = store.id.uuidString == "00000000-0000-0000-0000-000000000000" ? nil : store.id
        let params = RpcParams(p_store_id: NullableUUID(value: storeId), p_period: selectedRange.rawValue)
        
        do {
            async let salesTask: [SalesPeriodResult] = SupabaseManager.shared.client
                .rpc("store_sales_by_period", params: params)
                .execute()
                .value
                
            async let catTask: [StoreCategorySales] = SupabaseManager.shared.client
                .rpc("store_sales_by_category", params: params)
                .execute()
                .value
                
            let (sales, categories) = try await (salesTask, catTask)
            
            let completeSales = generateCompleteBuckets(for: selectedRange, data: sales)
            
            await MainActor.run {
                self.dataPoints = completeSales
                self.categorySales = categories
            }
        } catch {
            print("Error fetching sales detail data: \(error)")
        }
    }

    // MARK: - Helpers

    private func summaryTile(title: String, value: String, caption: String?) -> some View {
        VStack(spacing: 6) {
            Text(localized: title).font(.system(size: 13, weight: .medium)).foregroundColor(theme.secondaryText)
            Text(localized: value).font(.system(size: 22, weight: .bold)).foregroundColor(theme.burgundy).lineLimit(1).minimumScaleFactor(0.6)
            Text(caption ?? " ")
                .font(.system(size: 11)).foregroundColor(theme.secondaryText).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder.opacity(0.6), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func formatNumber(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func shortCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return "₹\(String(format: "%.1f", value / 1_000_000))M" }
        if value >= 1_000 { return "₹\(String(format: "%.0f", value / 1_000))k" }
        return "₹\(Int(value))"
    }
    
    private func getColor(for index: Int) -> Color {
        let colors: [Color] = [
            theme.burgundy,
            Color(hex: "2A9D8F"),
            Color(hex: "E76F51"),
            Color(hex: "E9C46A"),
            Color(hex: "264653")
        ]
        return colors[index % colors.count]
    }
    
    private func generateCompleteBuckets(for range: StoreChartTimeRange, data: [SalesPeriodResult]) -> [SalesPeriodResult] {
        let labels: [String]
        switch range {
        case .weekly:
            labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        case .monthly:
            labels = ["W1", "W2", "W3", "W4", "W5"]
        case .yearly:
            labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        }
        
        var result = [SalesPeriodResult]()
        let dataDict = Dictionary(uniqueKeysWithValues: data.map { ($0.label, $0) })
        
        for label in labels {
            if let existing = dataDict[label] {
                result.append(existing)
            } else {
                result.append(SalesPeriodResult(label: label, online: 0, offline: 0))
            }
        }
        return result
    }
}

