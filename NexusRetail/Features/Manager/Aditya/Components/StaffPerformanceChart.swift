//
//  StaffPerformanceChart.swift
//  NexusRetail
//

import SwiftUI

struct StaffPerformanceChart: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let data: [StaffPerformancePoint]

    @State private var animateIn = false
    @State private var ghostPulse = false

    private let barAreaHeight: CGFloat = 130
    private let labelClearance: CGFloat = 24
    private let axisWidth: CGFloat = 26
    private let columnSpacing: CGFloat = 10
    private let gridValues: [Int] = [100, 75, 50, 25, 0]
    private let ghostHeights: [CGFloat] = [55, 82, 66, 30, 42]

    private var sortedData: [StaffPerformancePoint] {
        data.sorted { $0.score > $1.score }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack {
                Text("Staff Performance")
                    .font(RSMSFonts.headline)
                    .foregroundColor(theme.primaryText)
                Spacer()
            }

            if data.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        axisColumn

                        ZStack(alignment: .bottomLeading) {
                            gridLines

                            HStack(alignment: .bottom, spacing: columnSpacing) {
                                ForEach(Array(sortedData.enumerated()), id: \.element.id) { index, point in
                                    barColumn(rank: index + 1, point: point)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .frame(height: barAreaHeight)
                    }
                    .padding(.top, labelClearance)

                    HStack(spacing: 8) {
                        Color.clear.frame(width: axisWidth)

                        HStack(spacing: columnSpacing) {
                            ForEach(sortedData) { point in
                                nameLabel(point.name)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Staff Performance Chart")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
                animateIn = true
            }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                ghostPulse = true
            }
        }
    }

    // MARK: - Chart

    private var axisColumn: some View {
        VStack {
            ForEach(gridValues, id: \.self) { value in
                Text("\(value)")
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText.opacity(0.6))
                if value != gridValues.last {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(width: axisWidth, height: barAreaHeight, alignment: .trailing)
    }

    private var gridLines: some View {
        VStack {
            ForEach(gridValues, id: \.self) { value in
                Rectangle()
                    .fill(theme.secondaryText.opacity(0.1))
                    .frame(height: 1)
                if value != gridValues.last {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: barAreaHeight)
    }

    private func barColumn(rank: Int, point: StaffPerformancePoint) -> some View {
        let isTop = rank == 1
        let barColor: Color = isTop ? theme.antiqueGold : theme.burgundy
        let targetHeight = max(barAreaHeight * CGFloat(point.score) / 100.0, 4)

        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [barColor.opacity(0.75), barColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 26, height: animateIn ? targetHeight : 0)
            .shadow(color: barColor.opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay(alignment: .top) {
                Text("\(point.score)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isTop ? theme.antiqueGold : theme.primaryText)
                    .fixedSize()
                    .offset(y: -16)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(point.name), rank \(rank), \(point.score) percent")
    }

    private func nameLabel(_ name: String) -> some View {
        let parts = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let first = parts.first ?? name
        let rest = parts.count >= 2 ? parts[1...].joined(separator: " ") : ""

        return VStack(spacing: 1) {
            Text(first).lineLimit(1)
            Text(rest).lineLimit(1).opacity(rest.isEmpty ? 0 : 1)
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(theme.secondaryText)
        .multilineTextAlignment(.center)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(ghostHeights.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.secondaryText.opacity(ghostPulse ? 0.16 : 0.08))
                }
                .frame(width: 26)
            }
            .frame(height: 90, alignment: .bottom)
            .overlay(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(ghostHeights.enumerated()), id: \.offset) { index, height in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(theme.secondaryText.opacity(ghostPulse ? 0.16 : 0.08))
                            .frame(width: 26, height: height)
                    }
                }
            }

            Text("Performance data will appear here once your team logs sales")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
}

#Preview("Staff Performance") {
    StaffPerformanceChart(data: [
        StaffPerformancePoint(name: "Prakarti Sharma", score: 100),
        StaffPerformancePoint(name: "Ananya Iyer", score: 77),
        StaffPerformancePoint(name: "Lucas Moreau", score: 77),
        StaffPerformancePoint(name: "Aditya Kumar", score: 1),
        StaffPerformancePoint(name: "Arya Singh", score: 1)
    ])
    .environment(AppTheme())
    .padding(RSMSSpacing.lg)
    .background(RSMSColors.background)
}

#Preview("Empty State") {
    StaffPerformanceChart(data: [])
        .environment(AppTheme())
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.background)
}
