//
//  ProductSalesChart.swift
//  NexusRetail
//
//  Top product-sales bar chart with its OWN Weekly ↔ Monthly toggle
//  (independent from the Revenue chart).
//  Uses gold/tan bars matching the screenshot aesthetic.
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
                .foregroundStyle(
                    LinearGradient(
                        colors: [RSMSColors.darkBrown, RSMSColors.darkBrown.opacity(0.8)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
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

            // Legend
            HStack(spacing: RSMSSpacing.sm) {
                Circle()
                    .fill(RSMSColors.darkBrown)
                    .frame(width: 8, height: 8)
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
