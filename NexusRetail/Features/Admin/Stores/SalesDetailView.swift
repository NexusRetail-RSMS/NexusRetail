//
//  SalesDetailView.swift
//  NexusRetail
//
//  Full-screen detailed sales chart inspired by Apple Health's
//  step-count view — D / W / M / Y segmented picker, a large
//  total value, and an expanded bar chart.
//

import SwiftUI
import Charts

// MARK: - Time Range

enum StoreChartTimeRange: String, CaseIterable, Identifiable {
    case day = "D"
    case week = "W"
    case month = "M"
    case year = "Y"
    var id: String { rawValue }
}

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
    @State private var selectedRange: StoreChartTimeRange = .month
    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived Data

    private var dataPoints: [SalesGranularPoint] {
        SalesDetailSampleData.points(for: store, range: selectedRange)
    }

    private var totalSales: Double {
        dataPoints.reduce(0) { $0 + $1.total }
    }

    private var maxValue: Double {
        let m = dataPoints.map(\.total).max() ?? 1
        return m * 1.15   // 15 % headroom
    }

    private var periodLabel: String {
        switch selectedRange {
        case .day:   return "Today"
        case .week:  return "This Week"
        case .month: return "This Month"
        case .year:  return "This Year"
        }
    }

    // MARK: - Body

    var body: some View {
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

            Text("Sales Report")
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
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)
            .animation(.easeInOut(duration: 0.3), value: selectedRange)

            Spacer()
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
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
}

// MARK: - Sample data generator

enum SalesDetailSampleData {
    static func points(for store: Store, range: StoreChartTimeRange) -> [SalesGranularPoint] {
        let seed = abs(store.name.hashValue)
        func r(_ base: Double, _ span: Double, _ i: Int) -> Double {
            let v = Double((seed + i * 7) % 1000) / 1000.0
            return base + v * span
        }

        switch range {
        case .day:
            // Hourly buckets (6 AM – 9 PM)
            return (6...21).map { hour in
                SalesGranularPoint(
                    label: "\(hour > 12 ? hour - 12 : hour)\(hour >= 12 ? "P" : "A")",
                    online: r(5, 40, hour),
                    offline: r(3, 30, hour + 50)
                )
            }
        case .week:
            let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            return days.enumerated().map { i, d in
                SalesGranularPoint(label: d, online: r(200, 500, i), offline: r(150, 400, i + 20))
            }
        case .month:
            return (1...4).map { w in
                SalesGranularPoint(label: "W\(w)", online: r(1500, 3000, w), offline: r(1000, 2500, w + 30))
            }
        case .year:
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return months.enumerated().map { i, m in
                SalesGranularPoint(label: m, online: r(4000, 8000, i), offline: r(3000, 6000, i + 40))
            }
        }
    }
}
