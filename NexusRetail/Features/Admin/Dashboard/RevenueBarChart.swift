import SwiftUI
import Charts

struct RevenueBarChart: View {
    var title: String = "Revenue Chart"
    let data: [RevenueChartPoint]
    let maxValue: Double
    @Binding var timeRange: SalesTimeRange

    private var peakLabel: String? {
        data.max(by: { $0.revenue < $1.revenue })?.label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {

            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(RSMSColors.burgundy)
                        .frame(width: 3, height: 16)
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                }

                Spacer()

                TimeRangeToggle(selection: $timeRange)
            }

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
                        width: .ratio(0.45)
                    )
                    .foregroundStyle(
                        point.label == peakLabel
                            ? LinearGradient(
                                colors: [RSMSColors.burgundy, RSMSColors.burgundy.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [RSMSColors.burgundy.opacity(0.6), RSMSColors.burgundy.opacity(0.28)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .cornerRadius(8)
                    .annotation(position: .top) {
                        if point.label == peakLabel {
                            Text("₹\(formatCompact(point.revenue))L")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RSMSColors.primaryText, in: RoundedRectangle(cornerRadius: 5))
                                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                        }
                    }
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
                .padding(.top, 6)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(RSMSColors.burgundy)
                    .frame(width: 7, height: 7)
                Text("Revenue in ₹ Lakhs")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(RSMSColors.burgundy.opacity(0.06), in: Capsule())
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: RSMSColors.burgundy.opacity(0.10), radius: 20, x: 0, y: 10)
        .animation(.easeInOut(duration: 0.3), value: data)
    }

    private func formatCompact(_ value: Double) -> String {
        String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value)
    }
}

struct TimeRangeToggle: View {
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
    .background(RSMSColors.background)
}
