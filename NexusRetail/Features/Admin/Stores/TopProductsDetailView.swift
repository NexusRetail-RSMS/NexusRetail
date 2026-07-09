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
    let category: String
    let unitsSold: Int
    let revenue: Double
    let color: Color
    let imageURL: URL?
}

// MARK: - View

struct TopProductsDetailView: View {
    @Environment(AppTheme.self) private var theme
    let store: Store
    // Default to yearly so there's always data visible on open.
    @State private var selectedRange: StoreChartTimeRange = .yearly(Date())
    @Environment(\.dismiss) private var dismiss

    // Colors for the donut slices
    var sliceColors: [Color] {
        [
            theme.burgundy,
            theme.success,
            theme.warning,
            theme.gold,
            theme.error,
            theme.primaryAction
        ]
    }

    @State private var products: [TopProduct] = []
    @State private var isLoading = false

    private var totalUnits: Int {
        products.reduce(0) { $0 + $1.unitsSold }
    }

    private var donutSlices: [DonutSlice] {
        TopProductsPalette.makeSlices(
            from: products.map { (label: $0.name, value: $0.unitsSold) },
            maxSlices: 6,
            dark: theme.isDarkMode
        )
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

                HStack {
                    Text("Top Products")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    
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

                Text(periodLabel)
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.md)

                // Donut chart
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(theme.burgundy)
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
                            .foregroundStyle(theme.burgundy.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .frame(height: 240)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "bag")
                                .font(.system(size: 24))
                                .foregroundColor(theme.secondaryText.opacity(0.5))
                            Text("No products data")
                                .font(.system(size: 11))
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                } else {
                    TopProductsDonut(slices: donutSlices, height: 320, centerCaption: "Units sold")
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.lg)
                        .animation(.easeInOut(duration: 0.3), value: selectedRange)

                    Text("Tap a slice to see its details")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, RSMSSpacing.sm)
                }

                // Ranked product list
                VStack(alignment: .leading, spacing: 0) {
                    Text("Product Ranking")
                        .font(RSMSFonts.headline)
                        .foregroundColor(theme.primaryText)
                        .padding(.bottom, RSMSSpacing.md)

                    if products.isEmpty {
                        VStack(spacing: RSMSSpacing.sm) {
                            Image(systemName: "list.number")
                                .font(.system(size: 28))
                                .foregroundColor(theme.secondaryText.opacity(0.4))
                            Text("No ranking data available")
                                .foregroundColor(theme.secondaryText)
                                .font(RSMSFonts.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RSMSSpacing.xl)
                    } else {
                        ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                            HStack(spacing: RSMSSpacing.md) {
                                // Product image
                                productThumbnail(product)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.name)
                                        .font(RSMSFonts.body)
                                        .foregroundColor(theme.primaryText)
                                        .lineLimit(1)
                                    Text(product.category)
                                        .font(RSMSFonts.caption)
                                        .foregroundColor(theme.secondaryText)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("₹\(formatNumber(Int(product.revenue)))")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(theme.primaryText)
                                    Text("\(formatNumber(product.unitsSold)) units")
                                        .font(RSMSFonts.caption)
                                        .foregroundColor(theme.secondaryText)
                                }
                            }
                            .padding(.vertical, RSMSSpacing.md)
                            .accessibilityElement(children: .combine)

                            if index < products.count - 1 {
                                Divider()
                                    .foregroundColor(theme.divider)
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
        let p_limit: Int
    }
    
    private func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        let storeId: UUID? = store.id.uuidString == "00000000-0000-0000-0000-000000000000" ? nil : store.id
        let params = RpcParams(p_store_id: NullableUUID(value: storeId), p_period: selectedRange.rawValue, p_limit: 15)
        
        do {
            let fetchedProducts: [DashboardTopProduct] = try await SupabaseManager.shared.client
                .rpc("store_top_products_by_period", params: params)
                .execute()
                .value
                
            let mapped = fetchedProducts.enumerated().map { index, p in
                TopProduct(
                    name: p.name,
                    category: p.category,
                    unitsSold: p.units,
                    revenue: p.revenue,
                    color: sliceColors[index % sliceColors.count],
                    imageURL: p.imageUrl.flatMap { URL(string: $0) }
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

    @ViewBuilder
    private func productThumbnail(_ product: TopProduct) -> some View {
        Group {
            if let url = product.imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder(product)
                }
            } else {
                thumbnailPlaceholder(product)
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.divider, lineWidth: 1))
    }

    private func thumbnailPlaceholder(_ product: TopProduct) -> some View {
        ZStack {
            product.color.opacity(0.15)
            Image(systemName: "bag.fill")
                .font(.system(size: 16))
                .foregroundColor(product.color)
        }
    }
}
