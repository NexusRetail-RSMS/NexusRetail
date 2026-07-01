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
    let id = UUID()
    let label: String
    let online: Double
    let offline: Double
    var total: Double { online + offline }
}

// MARK: - View

struct SalesDetailView: View {
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
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                Menu {
                    Button("Weekly") { selectedRange = .weekly(Date()) }
                    Button("Monthly") { selectedRange = .monthly(Date()) }
                    Button("Yearly") { selectedRange = .yearly(Date()) }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedRange.isWeekly ? "Weekly" : (selectedRange.isMonthly ? "Monthly" : "Yearly"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
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

            // Total
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText)
                    .tracking(1)

                Text("₹\(formatNumber(Int(totalSales)))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)

            Text(periodLabel)
                .font(RSMSFonts.subheadline)
                .foregroundColor(RSMSColors.secondaryText)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.xs)

            // Legend
            HStack(spacing: RSMSSpacing.lg) {
                HStack(spacing: 6) {
                    Circle().fill(RSMSColors.burgundy).frame(width: 8, height: 8)
                    Text("Online").font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "2A9D8F")).frame(width: 8, height: 8)
                    Text("Offline").font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.md)

            // Chart
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(RSMSColors.burgundy)
                    Spacer()
                }
                .frame(height: 300)
            } else {
                GeometryReader { geo in
                    let hasData = dataPoints.contains { $0.online + $0.offline > 0 }
                    
                    if hasData {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Chart(dataPoints) { point in
                                BarMark(
                                    x: .value("Period", point.label),
                                    y: .value("Sales", point.online)
                                )
                                .foregroundStyle(RSMSColors.burgundy)
                                .cornerRadius(4)
                                .position(by: .value("Type", "Online"))

                                BarMark(
                                    x: .value("Period", point.label),
                                    y: .value("Sales", point.offline)
                                )
                                .foregroundStyle(Color(hex: "2A9D8F"))
                                .cornerRadius(4)
                                .position(by: .value("Type", "Offline"))
                            }
                            .chartYScale(domain: 0...maxValue)
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                        .foregroundStyle(RSMSColors.divider)
                                    AxisValueLabel {
                                        if let v = value.as(Double.self) {
                                            Text(shortCurrency(v))
                                                .font(.system(size: 10))
                                                .foregroundStyle(RSMSColors.secondaryText)
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .font(.system(size: 10))
                                        .foregroundStyle(RSMSColors.secondaryText)
                                }
                            }
                            .frame(width: max(geo.size.width, CGFloat(dataPoints.count * 30)))
                        }
                    } else {
                        // Empty state: show faint placeholder bars
                        Chart(dataPoints) { point in
                            BarMark(
                                x: .value("Period", point.label),
                                y: .value("Sales", 8.0)
                            )
                            .foregroundStyle(RSMSColors.burgundy.opacity(0.15))
                            .cornerRadius(4)
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    .foregroundStyle(RSMSColors.divider)
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(shortCurrency(v))
                                            .font(.system(size: 10))
                                            .foregroundStyle(RSMSColors.secondaryText)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.system(size: 10))
                                    .foregroundStyle(RSMSColors.secondaryText)
                            }
                        }
                        .overlay {
                            Text("No sales this period")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.lg)
                .animation(.easeInOut(duration: 0.3), value: selectedRange)
                .frame(height: 300)
            }

            // Ranked Category list
            VStack(alignment: .leading, spacing: 0) {
                Text("Sales by Category")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)
                    .padding(.bottom, RSMSSpacing.md)

                if isLoading {
                    ProgressView()
                        .padding()
                } else if categorySales.isEmpty {
                    VStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 28))
                            .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                        Text("No sales data available.")
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RSMSSpacing.xl)
                } else {
                    ForEach(Array(categorySales.enumerated()), id: \.element.id) { index, cat in
                        HStack(spacing: RSMSSpacing.md) {
                            Text("#\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(getColor(for: index))
                                .clipShape(Circle())
                                
                            Text(cat.category)
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                            
                        Spacer()
                        
                        Text("₹\(formatNumber(Int(cat.revenue)))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                    .padding(.vertical, RSMSSpacing.md)
                    
                    if index < categorySales.count - 1 {
                        Divider()
                            .foregroundColor(RSMSColors.divider)
                    }
                }
                }
            }
            .padding(RSMSSpacing.lg)
            .background(RSMSColors.cardBackground)
            .cornerRadius(RSMSRadius.large)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.xl)
            .padding(.bottom, RSMSSpacing.xxl)
        }
        }
        .background(RSMSColors.background.ignoresSafeArea())
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
                    .foregroundColor(RSMSColors.burgundy)
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
            RSMSColors.burgundy,
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


