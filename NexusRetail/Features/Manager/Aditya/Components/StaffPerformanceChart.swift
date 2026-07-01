//
//  StaffPerformanceChart.swift
//  NexusRetail
//

import SwiftUI
import Charts

struct StaffPerformanceChart: View {
    let data: [StaffPerformancePoint]
    @Binding var timeRange: SalesTimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {

            // Title row with toggle
            HStack {
                Text("Staff Performance")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                Picker("Time Range", selection: $timeRange) {
                    ForEach(SalesTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            Chart(data) { point in
                BarMark(
                    x: .value("Staff", point.name),
                    y: .value("Score", point.score),
                    width: .fixed(32)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            RSMSColors.burgundy,
                            RSMSColors.burgundy.opacity(0.7)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
                .annotation(position: .top) {
                    if point.score > 0 {
                        Text("\(point.score)%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel()
                        .font(.system(size: 11))
                        .foregroundStyle(RSMSColors.secondaryText)
                }
            }
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel()
                        .font(.system(size: 11))
                        .foregroundStyle(RSMSColors.secondaryText)
                }
            }
            .frame(height: 220)
        }
        .padding(RSMSSpacing.lg)
        .background(Color.white)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
