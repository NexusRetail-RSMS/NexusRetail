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
            Chart(data) { point in
                BarMark(
                    x: .value("Category", shortLabel(point.category)),
                    y: .value("Sales", point.sales)
                )
                .foregroundStyle(RSMSColors.chartBar)
                .cornerRadius(6)
                .annotation(position: .top, spacing: 4) {
                    Text("\(point.sales)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
            .chartYScale(domain: 0...maxValue)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(RSMSColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.system(size: 10))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let cat = value.as(String.self) {
                            Text(cat)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                }
            }
            .frame(height: 200)

            // Simple text legend — no colored dots needed since categories are on the X-axis
            HStack(spacing: RSMSSpacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(RSMSColors.chartBar)
                    .frame(width: 24, height: 8)
                Text("Units sold (\(timeRange.rawValue.lowercased()))")
                    .font(.system(size: 10))
                    .foregroundColor(RSMSColors.secondaryText)
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
}

#Preview {
    @Previewable @State var range: SalesTimeRange = .weekly
    let vm = DashboardViewModel()
    ProductSalesChart(data: vm.productChartData, maxValue: vm.productMaxValue, timeRange: $range)
        .padding()
        .background(RSMSColors.background)
}
