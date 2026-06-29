//
//  RevenueBarChart.swift
//  NexusRetail
//
//  Store revenue bar chart using native SwiftUI Charts.
//  Has its OWN Weekly/Monthly toggle (independent from Product chart).
//  Uses the complementary chart color palette for a premium look.
//

import SwiftUI
import Charts

struct RevenueBarChart: View {
    let data: [RevenueChartPoint]
    let maxValue: Double
    @Binding var timeRange: SalesTimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {

            // Row 1: Title + time-range toggle
            HStack {
                Text("Store Revenue")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                TimeRangeToggle(selection: $timeRange)
            }

            // Chart
            if data.isEmpty {
                Chart {
                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                        BarMark(
                            x: .value("Day", day),
                            y: .value("Revenue", 5.0),
                            width: .ratio(0.45)
                        )
                        .foregroundStyle(RSMSColors.burgundy.opacity(0.12))
                        .cornerRadius(8)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(RSMSColors.divider)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.system(size: 10))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .overlay {
                    Text("No revenue data")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                }
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Period", point.label),
                        y: .value("Revenue", point.revenue),
                        width: .ratio(0.45) // Makes bars noticeably thinner and more modern
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [RSMSColors.burgundy.opacity(0.6), RSMSColors.burgundy],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8) // More rounded cap
                }
                .chartYScale(domain: 0...maxValue)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(RSMSColors.divider)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.system(size: 10))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }

            // Legend
            HStack(spacing: RSMSSpacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(RSMSColors.burgundy)
                    .frame(width: 16, height: 8)
                Text("Revenue in ₹ Lakhs")
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
}

// MARK: - Reusable Time Range Toggle

/// A segmented toggle used by both charts independently.
struct TimeRangeToggle: View {
    @Binding var selection: SalesTimeRange

    var body: some View {
        Picker("Time Range", selection: $selection) {
            ForEach(SalesTimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 160)
    }
}

#Preview {
    @Previewable @State var range: SalesTimeRange = .monthly
    let vm = DashboardViewModel()
    RevenueBarChart(
        data: vm.revenueChartData,
        maxValue: vm.revenueMaxValue,
        timeRange: $range
    )
    .padding()
    .background(RSMSColors.background)
}
