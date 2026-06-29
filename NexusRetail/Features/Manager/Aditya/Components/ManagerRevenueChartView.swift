//
//  ManagerRevenueChartView.swift
//  NexusRetail
//

import SwiftUI
import Charts

struct ManagerRevenueChartView: View {
    let data: [ManagerRevenueChartPoint]
    let maxValue: Double
    let sixMonthTotal: String
    let peakMonth: String
    @Binding var timeRange: ManagerSalesTimeRange
    
    @State private var selectedPointLabel: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
            
            // Header Row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Revenue Trend")
                        .font(RSMSFonts.headline)
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text("Total: \(sixMonthTotal)")
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                }
                
                Spacer()
                
                SegmentControlView(selection: $timeRange)
            }
            
            // Chart
            Chart(data) { point in
                BarMark(
                    x: .value("Period", point.label),
                    y: .value("Revenue", point.revenue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [RSMSColors.darkBurgundy, RSMSColors.burgundy],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
                .opacity(selectedPointLabel == nil || selectedPointLabel == point.label ? 1.0 : 0.4)
                .annotation(position: .top, spacing: 0) {
                    if selectedPointLabel == point.label {
                        VStack(spacing: 4) {
                            Text(point.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(RSMSColors.secondaryText)
                            
                            // Format number to remove trailing zero if it's a whole number
                            Text("₹\(String(format: point.revenue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", point.revenue))L")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(RSMSColors.darkBurgundy)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSColors.divider, lineWidth: 1)
                        )
                        .offset(y: -10)
                        // Make sure the tooltip stays above other bars
                        .zIndex(1)
                    }
                }
            }
            .chartXSelection(value: $selectedPointLabel)
            .chartYScale(domain: 0...maxValue)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(RSMSColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))L")
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
            .frame(height: 220)
            
            // Bottom Summary
            HStack(spacing: RSMSSpacing.md) {
                HStack(spacing: RSMSSpacing.xs) {
                    Circle()
                        .fill(RSMSColors.darkBurgundy)
                        .frame(width: 8, height: 8)
                    Text("Peak: \(peakMonth)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    @Previewable @State var range: ManagerSalesTimeRange = .monthly
    let vm = ManagerDashboardViewModel()
    
    ManagerRevenueChartView(
        data: vm.revenueChartData,
        maxValue: vm.revenueMaxValue,
        sixMonthTotal: vm.sixMonthTotal,
        peakMonth: vm.peakMonth,
        timeRange: $range
    )
    .padding()
    .background(RSMSColors.background)
}
