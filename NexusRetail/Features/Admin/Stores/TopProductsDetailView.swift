//
//  TopProductsDetailView.swift
//  NexusRetail
//
//  Full-screen detailed top-products view with D / W / M / Y
//  segmented picker, a donut chart of top products, and a
//  ranked product list.
//

import SwiftUI
import Charts
import Supabase

// MARK: - Product Data Model

struct TopProduct: Identifiable {
    let id = UUID()
    let name: String
    let unitsSold: Int
    let revenue: Double
    let color: Color
}

// MARK: - View

struct TopProductsDetailView: View {
    let store: Store
    @State private var selectedRange: StoreChartTimeRange = .weekly(Date())
    @Environment(\.dismiss) private var dismiss

    // Colors for the donut slices
    static let sliceColors: [Color] = [
        RSMSColors.burgundy,
        Color(hex: "2A9D8F"),
        Color(hex: "F4A261"),
        RSMSColors.success,
        Color(hex: "E76F51"),
        Color(hex: "264653"),
    ]

    @State private var products: [TopProduct] = []
    @State private var isLoading = false

    private var totalUnits: Int {
        products.reduce(0) { $0 + $1.unitsSold }
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Back button + title
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(RSMSColors.burgundy)
                            .frame(width: 36, height: 36)
                            .background(RSMSColors.burgundy.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.md)

                HStack {
                    Text("Top Products")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Spacer()
                    
                    Menu {
                        Button("Weekly") { selectedRange = .weekly(Date()) }
                        Button("Monthly") { selectedRange = .monthly(Date()) }
                        Button("Yearly") { selectedRange = .yearly(Date()) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(selectedRange.isWeekly ? "Weekly" : (selectedRange.isMonthly ? "Monthly" : "Yearly"))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.md)

                // Segmented picker
                SwipeableCalendarView(selectedRange: $selectedRange)
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.md)

                Text(periodLabel)
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.secondaryText)
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.md)

                // Donut chart
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(RSMSColors.burgundy)
                        Spacer()
                    }
                    .frame(height: 240)
                } else if products.isEmpty {
                    ZStack {
                        Chart {
                            SectorMark(
                                angle: .value("Placeholder", 1),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(RSMSColors.burgundy.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .frame(height: 240)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "bag")
                                .font(.system(size: 24))
                                .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                            Text("No products data")
                                .font(.system(size: 11))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                } else {
                    ZStack {
                        Chart(products) { product in
                        SectorMark(
                            angle: .value("Units", product.unitsSold),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(product.color)
                        .cornerRadius(6)
                    }
                    .frame(height: 240)

                    VStack(spacing: 2) {
                        Text(formatNumber(totalUnits))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                        Text("Units sold")
                            .font(.system(size: 11))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.xl)
                .animation(.easeInOut(duration: 0.3), value: selectedRange)
                }

                // Legend (2-column grid)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.sm) {
                    ForEach(products) { product in
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
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.lg)

                // Ranked product list
                VStack(alignment: .leading, spacing: 0) {
                    Text("Product Ranking")
                        .font(RSMSFonts.headline)
                        .foregroundColor(RSMSColors.primaryText)
                        .padding(.bottom, RSMSSpacing.md)

                    if products.isEmpty {
                        VStack(spacing: RSMSSpacing.sm) {
                            Image(systemName: "list.number")
                                .font(.system(size: 28))
                                .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                            Text("No ranking data available")
                                .foregroundColor(RSMSColors.secondaryText)
                                .font(RSMSFonts.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RSMSSpacing.xl)
                    } else {
                        ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                            HStack(spacing: RSMSSpacing.md) {
                                // Rank badge
                                Text("#\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(product.color)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.name)
                                        .font(RSMSFonts.body)
                                        .foregroundColor(RSMSColors.primaryText)
                                    Text("\(formatNumber(product.unitsSold)) units")
                                        .font(RSMSFonts.caption)
                                        .foregroundColor(RSMSColors.secondaryText)
                                }

                                Spacer()

                                Text("₹\(formatNumber(Int(product.revenue)))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(RSMSColors.primaryText)
                            }
                            .padding(.vertical, RSMSSpacing.md)

                            if index < products.count - 1 {
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
        .navigationBarHidden(true)
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
        let p_limit: Int
    }
    
    private func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        let storeId: UUID? = store.id.uuidString == "00000000-0000-0000-0000-000000000000" ? nil : store.id
        let params = RpcParams(p_store_id: NullableUUID(value: storeId), p_period: selectedRange.rawValue, p_limit: 5)
        
        do {
            let fetchedProducts: [DashboardTopProduct] = try await SupabaseManager.shared.client
                .rpc("store_top_products_by_period", params: params)
                .execute()
                .value
                
            let mapped = fetchedProducts.enumerated().map { index, p in
                TopProduct(
                    name: p.name,
                    unitsSold: p.units,
                    revenue: p.revenue,
                    color: TopProductsDetailView.sliceColors[index % TopProductsDetailView.sliceColors.count]
                )
            }
            
            await MainActor.run {
                self.products = mapped
            }
        } catch {
            print("Error fetching top products: \(error)")
        }
    }

    private func formatNumber(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
