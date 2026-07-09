//
//  TopProductsSemiCard.swift
//  NexusRetail
//
//  A semicircle (half-donut) "Top Products" card: the top 5 products fanned
//  across the top with leader-line callouts (name / units / share pill),
//  a center total, and a bottom stats bar. Press-and-hold a segment to
//  highlight it and read its details.
//

import SwiftUI

struct TopProductsSemiCard: View {
    @Environment(AppTheme.self) private var theme

    let products: [ProductChartPoint]      // name, category, sales
    var onViewAll: () -> Void = {}

    // MARK: - Derived data

    private struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let units: Int
        let color: Color
        let start: CGFloat    // cumulative fraction (0 = left)
        let end: CGFloat
        var mid: CGFloat { (start + end) / 2 }
        let share: Int        // % of the shown top-5 total
    }

    private static let palette: [Color] = [
        Color(hex: "6C4CC4"),  // purple
        Color(hex: "4C8DE8"),  // blue
        Color(hex: "E4574C"),  // red
        Color(hex: "4FA895"),  // teal
        Color(hex: "EAB13F")   // gold
    ]

    private var top5: [ProductChartPoint] {
        Array(products.sorted { $0.sales > $1.sales }.prefix(5))
    }

    private var shownTotal: Int { top5.reduce(0) { $0 + $1.sales } }
    private var overallTotal: Int { products.reduce(0) { $0 + $1.sales } }

    private var contributePercent: Int {
        guard overallTotal > 0 else { return 0 }
        return Int((Double(shownTotal) / Double(overallTotal) * 100).rounded())
    }

    private var slices: [Slice] {
        guard shownTotal > 0 else { return [] }
        var result: [Slice] = []
        var cursor: CGFloat = 0
        for (i, p) in top5.enumerated() {
            let frac = CGFloat(p.sales) / CGFloat(shownTotal)
            let share = Int((Double(p.sales) / Double(shownTotal) * 100).rounded())
            result.append(Slice(name: p.name, units: p.sales, color: Self.palette[i % Self.palette.count],
                                 start: cursor, end: cursor + frac, share: share))
            cursor += frac
        }
        return result
    }

    @State private var activeIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if slices.isEmpty {
                emptyState
            } else {
                chart
                    .frame(height: 300)
                    .padding(.top, 8)
                bottomBar
                    .padding(.top, 8)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Top Products")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Text("By Units Sold")
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryText)
            }
            Spacer()
            Button(action: onViewAll) {
                HStack(spacing: 4) {
                    Text("View All").font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(theme.burgundy)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Chart

    private var chart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let center = CGPoint(x: w / 2, y: h * 0.92)
            let outerR = min(w * 0.30, h * 0.66)
            let innerR = outerR * 0.58
            let midR = (outerR + innerR) / 2
            let band = outerR - innerR

            ZStack {
                // Segments
                ForEach(Array(slices.enumerated()), id: \.element.id) { i, slice in
                    let dimmed = activeIndex != nil && activeIndex != i
                    SemiArc(center: center, radius: activeIndex == i ? midR + 4 : midR,
                            start: slice.start, end: slice.end, gap: 0.012)
                        .stroke(
                            LinearGradient(colors: [slice.color.opacity(0.9), slice.color],
                                           startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: activeIndex == i ? band + 6 : band, lineCap: .round)
                        )
                        .opacity(dimmed ? 0.3 : 1.0)
                }

                // Leader lines + callout labels
                ForEach(Array(slices.enumerated()), id: \.element.id) { i, slice in
                    let arcPt = pointOnSemicircle(slice.mid, radius: outerR, center: center)
                    let labelPt = pointOnSemicircle(slice.mid, radius: outerR + 34, center: center)

                    Path { p in
                        p.move(to: pointOnSemicircle(slice.mid, radius: outerR + 2, center: center))
                        p.addLine(to: labelPt)
                    }
                    .stroke(slice.color.opacity(0.55), style: StrokeStyle(lineWidth: 1.2))

                    Circle().fill(slice.color).frame(width: 5, height: 5).position(arcPt)

                    calloutLabel(slice)
                        .position(x: labelPt.x, y: labelPt.y - 16)
                        .opacity(activeIndex != nil && activeIndex != i ? 0.35 : 1.0)
                }

                // Center content
                centerContent
                    .position(x: center.x, y: center.y - outerR * 0.42)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        activeIndex = segmentIndex(at: value.location, center: center, innerR: innerR, outerR: outerR)
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) { activeIndex = nil }
                    }
            )
            .animation(.easeInOut(duration: 0.2), value: activeIndex)
        }
    }

    private func calloutLabel(_ slice: Slice) -> some View {
        VStack(spacing: 3) {
            Text(slice.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.primaryText)
                .lineLimit(1)
            Text("\(slice.units) units")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(slice.color)
            Text("\(slice.share)%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(slice.color)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(slice.color.opacity(0.14), in: Capsule())
        }
        .frame(width: 120)
    }

    private var centerContent: some View {
        VStack(spacing: 4) {
            if let idx = activeIndex, idx < slices.count {
                let s = slices[idx]
                ZStack {
                    Circle().fill(s.color.opacity(0.14)).frame(width: 44, height: 44)
                    Image(systemName: "bag.fill").font(.system(size: 18)).foregroundColor(s.color)
                }
                Text(s.name).font(.system(size: 12, weight: .medium)).foregroundColor(theme.secondaryText).lineLimit(1)
                Text("\(s.units)").font(.system(size: 30, weight: .bold)).foregroundColor(theme.primaryText)
                Text("units · \(s.share)%").font(.system(size: 11)).foregroundColor(s.color)
            } else {
                ZStack {
                    Circle().fill(theme.burgundy.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: "bag.fill").font(.system(size: 18)).foregroundColor(theme.burgundy)
                }
                Text("Total Units Sold").font(.system(size: 12, weight: .medium)).foregroundColor(theme.secondaryText)
                Text("\(shownTotal)").font(.system(size: 30, weight: .bold)).foregroundColor(theme.primaryText)
                RoundedRectangle(cornerRadius: 2).fill(theme.burgundy).frame(width: 26, height: 3)
            }
        }
        .frame(width: 150)
        .multilineTextAlignment(.center)
    }

    // MARK: - Bottom stats bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            statCell(icon: "chart.bar.fill", title: "Top 5 Products Contribute", value: "\(contributePercent)%")
            Divider().frame(height: 40)
            statCell(icon: "star.fill", title: "Best Selling Product", value: top5.first?.name ?? "—", valueColor: theme.burgundy)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(theme.burgundy.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(icon: String, title: String, value: String, valueColor: Color? = nil) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(theme.burgundy.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(theme.burgundy)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11)).foregroundColor(theme.secondaryText).lineLimit(1)
                Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(valueColor ?? theme.primaryText).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag").font(.system(size: 32)).foregroundColor(theme.secondaryText.opacity(0.5))
            Text("No product data").font(.system(size: 14)).foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Geometry helpers

    /// Point on the top semicircle for a fraction 0(left)…1(right).
    private func pointOnSemicircle(_ fraction: CGFloat, radius: CGFloat, center: CGPoint) -> CGPoint {
        let theta = Double(180 * (1 - fraction)) * .pi / 180   // radians, 0=right, 180=left
        return CGPoint(x: center.x + radius * CGFloat(cos(theta)),
                       y: center.y - radius * CGFloat(sin(theta)))
    }

    private func segmentIndex(at pt: CGPoint, center: CGPoint, innerR: CGFloat, outerR: CGFloat) -> Int? {
        let dx = pt.x - center.x
        let dy = center.y - pt.y            // up is positive
        guard dy >= -8 else { return nil }  // must be in the upper half
        let dist = sqrt(dx * dx + dy * dy)
        guard dist >= innerR - 12, dist <= outerR + 40 else { return nil }
        var deg = atan2(dy, dx) * 180 / .pi // 0=right, 90=top, 180=left
        deg = max(0, min(180, deg))
        let fraction = 1 - CGFloat(deg) / 180
        return slices.firstIndex { fraction >= $0.start && fraction <= $0.end }
    }
}

// MARK: - Semicircle arc shape

private struct SemiArc: Shape {
    let center: CGPoint
    let radius: CGFloat
    let start: CGFloat   // fraction 0(left)…1(right)
    let end: CGFloat
    var gap: CGFloat = 0.012

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let a0 = start + gap
        let a1 = end - gap
        guard a1 > a0 else { return path }
        let steps = max(2, Int((a1 - a0) * 240))
        for i in 0...steps {
            let f = a0 + (a1 - a0) * CGFloat(i) / CGFloat(steps)
            let theta = Double(180 * (1 - f)) * .pi / 180
            let p = CGPoint(x: center.x + radius * CGFloat(cos(theta)),
                            y: center.y - radius * CGFloat(sin(theta)))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }
}
