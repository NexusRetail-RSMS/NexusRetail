//
//  ProductSalesChart.swift
//  NexusRetail
//
//  Top product-sales bar chart with its OWN Weekly ↔ Monthly toggle
//  (independent from the Revenue chart).
//  Each category bar uses a shade from the brand gradient palette
//  (#200E01 → #5B0202 → #8B0000 → #EDE7C7) for a homogenous look.
//  Categories are labeled on the X-axis so no separate legend is needed.
//

import SwiftUI
import Charts

struct ProductSalesChart: View {
    let data: [ProductChartPoint]
    let maxValue: Int
    @Binding var timeRange: SalesTimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {

            // Title row with toggle
            HStack {
                Text("Top Products")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                TimeRangeToggle(selection: $timeRange)
            }

            // Chart
            if data.isEmpty {
                VStack {
                    Spacer()
                    Text("No product sales data available.")
                        .foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                }
                .frame(height: 200)
                .padding(.top, RSMSSpacing.sm)
            } else {
                ZStack {
                    Chart(data) { point in
                        SectorMark(
                            angle: .value("Sales", point.sales),
                            innerRadius: .ratio(0.65),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Category", shortLabel(point.category)))
                        .cornerRadius(4)
                    }
                    .chartForegroundStyleScale([
                        "Couture": RSMSColors.burgundy,
                        "Fragrance": Color(hex: "F4A261"),
                        "Jewelry": Color(hex: "E9C46A"),
                        "Leather": Color(hex: "2A9D8F"),
                        "Watches": Color(hex: "264653"),
                        "Accessories": Color(hex: "8A2BE2")
                    ])
                    .chartLegend(.hidden)
                    .frame(height: 200)

                    VStack {
                        Text("Total Units")
                            .font(.system(size: 10))
                            .foregroundColor(RSMSColors.secondaryText)
                        Text("\(data.map(\.sales).reduce(0, +))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
                .padding(.top, RSMSSpacing.sm)
            }

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.sm) {
                ForEach(data) { point in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorFor(category: shortLabel(point.category)))
                            .frame(width: 8, height: 8)
                        Text(shortLabel(point.category))
                            .font(.system(size: 12))
                            .foregroundColor(RSMSColors.secondaryText)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.3), value: data)
    }

    /// Shortens category labels so they fit under the bars.
    private func shortLabel(_ category: String) -> String {
        switch category {
        case "Leather Goods": return "Leather"
        case "Fragrances":    return "Fragrance"
        default:              return category
        }
    }
    
    private func colorFor(category: String) -> Color {
        switch category {
        case "Couture": return RSMSColors.burgundy
        case "Fragrance": return Color(hex: "F4A261")
        case "Jewelry": return Color(hex: "E9C46A")
        case "Leather": return Color(hex: "2A9D8F")
        case "Watches": return Color(hex: "264653")
        case "Accessories": return Color(hex: "8A2BE2")
        default: return RSMSColors.chartBar
        }
    }
}

#Preview {
    @Previewable @State var range: SalesTimeRange = .weekly
    let vm = DashboardViewModel()
    ProductSalesChart(data: vm.productChartData, maxValue: vm.productMaxValue, timeRange: $range)
        .padding()
        .background(RSMSColors.background)
}
