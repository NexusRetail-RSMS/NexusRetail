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
    @Environment(AppTheme.self) private var theme
    var title: String = "Store Revenue"
    let data: [RevenueChartPoint]
    let maxValue: Double
    @Binding var timeRange: SalesTimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {

            // Row 1: Title + tap-to-expand hint
            HStack {
                Text(title)
                    .font(RSMSFonts.headline)
                    .foregroundColor(theme.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
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
                        .foregroundStyle(theme.burgundy.opacity(0.12))
                        .cornerRadius(8)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(theme.divider)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.secondaryText)
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
                                    .foregroundColor(theme.secondaryText)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .overlay {
                    Text("No revenue data")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
            } else {
                Chart(data) { point in
                    AreaMark(
                        x: .value("Period", point.label),
                        y: .value("Revenue", point.revenue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.burgundy.opacity(0.22), theme.burgundy.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Period", point.label),
                        y: .value("Revenue", point.revenue)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(theme.burgundy)
                }
                .chartYScale(domain: 0...maxValue)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(theme.divider)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.secondaryText)
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
                                    .foregroundColor(theme.secondaryText)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }

            // Legend
            HStack(spacing: RSMSSpacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.burgundy)
                    .frame(width: 16, height: 8)
                Text("Revenue in ₹ Lakhs")
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Revenue Chart")
        .animation(.easeInOut(duration: 0.3), value: data)
    }
}

// MARK: - Reusable Time Range Toggle

/// A segmented toggle used by both charts independently.
struct TimeRangeToggle: View {
    @Environment(AppTheme.self) private var theme
    @Binding var selection: SalesTimeRange

    var body: some View {
        Picker("Time Range", selection: $selection) {
            ForEach([SalesTimeRange.weekly, SalesTimeRange.monthly], id: \.self) { range in
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
    .background(AppTheme().background)
}
