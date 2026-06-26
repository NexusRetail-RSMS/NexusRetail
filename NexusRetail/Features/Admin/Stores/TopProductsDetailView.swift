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
    @State private var selectedRange: StoreChartTimeRange = .month
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

    private var products: [TopProduct] {
        TopProductsSampleData.products(for: store, range: selectedRange)
    }

    private var totalUnits: Int {
        products.reduce(0) { $0 + $1.unitsSold }
    }

    private var periodLabel: String {
        switch selectedRange {
        case .day:   return "Today"
        case .week:  return "This Week"
        case .month: return "This Month"
        case .year:  return "This Year"
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

                Text("Top Products")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.md)

                // Segmented picker
                Picker("Range", selection: $selectedRange) {
                    ForEach(StoreChartTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.md)

                // Total units label
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL UNITS SOLD")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(RSMSColors.secondaryText)
                        .tracking(1)

                    Text(formatNumber(totalUnits))
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

                // Donut chart
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
    }

    private func formatNumber(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Sample data

enum TopProductsSampleData {
    static func products(for store: Store, range: StoreChartTimeRange) -> [TopProduct] {
        let seed = abs(store.name.hashValue)
        let multiplier: Double
        switch range {
        case .day:   multiplier = 0.03
        case .week:  multiplier = 0.25
        case .month: multiplier = 1.0
        case .year:  multiplier = 12.0
        }

        let colors = TopProductsDetailView.sliceColors

        let productNames = [
            "iPhone 16 Pro",
            "MacBook Air M4",
            "AirPods Pro 3",
            "Apple Watch Ultra",
            "iPad Air M3",
            "HomePod Mini",
        ]

        let baseSales = [420, 280, 350, 190, 230, 150]

        return productNames.enumerated().map { i, name in
            let units = Int(Double(baseSales[i] + (seed + i * 13) % 200) * multiplier)
            let price = Double([79990, 114900, 24900, 89900, 69900, 10900][i])
            return TopProduct(
                name: name,
                unitsSold: max(units, 1),
                revenue: Double(units) * price,
                color: colors[i % colors.count]
            )
        }
        .sorted { $0.unitsSold > $1.unitsSold }
    }
}
