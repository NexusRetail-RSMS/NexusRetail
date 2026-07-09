//
//  TopProductsSemiCard.swift
//  NexusRetail
//
//  A semicircle (half-donut) "Top Products" card: the top 3 products plus a
//  grouped "Others" slice, fanned across the top with leader-line callouts
//  (name / units / share pill) and a center total. Press-and-hold a segment
//  to highlight it and read its details.
//

import SwiftUI

struct TopProductsSemiCard: View {
    @Environment(AppTheme.self) private var theme

    let products: [ProductChartPoint]      // name, category, sales
    var onViewAll: () -> Void = {}

    // MARK: - Slice model

    private struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let units: Int
        let color: Color
        let start: CGFloat    // cumulative fraction (0 = left)
        let end: CGFloat
        var mid: CGFloat { (start + end) / 2 }
        let share: Int
    }

    // Theme palette (burgundy / gold / warm accent + grey for Others)
    private var paletteColors: [Color] {
        [theme.burgundy, theme.gold, Color(hex: "C0705B")]
    }
    private var othersColor: Color { Color.gray.opacity(0.45) }

    private var ranked: [ProductChartPoint] { products.sorted { $0.sales > $1.sales } }
    private var total: Int { products.reduce(0) { $0 + $1.sales } }

    private var slices: [Slice] {
        guard total > 0 else { return [] }
        var raw: [(name: String, units: Int, color: Color)] = []
        for (i, p) in ranked.prefix(3).enumerated() {
            raw.append((p.name, p.sales, paletteColors[i % paletteColors.count]))
        }
        let othersUnits = ranked.dropFirst(3).reduce(0) { $0 + $1.sales }
        if othersUnits > 0 { raw.append(("Others", othersUnits, othersColor)) }

        var result: [Slice] = []
        var cursor: CGFloat = 0
        for item in raw {
            let frac = CGFloat(item.units) / CGFloat(total)
            let share = Int((Double(item.units) / Double(total) * 100).rounded())
            result.append(Slice(name: item.name, units: item.units, color: item.color,
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
                    .frame(height: 360)
                    .padding(.top, 12)
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
            let center = CGPoint(x: w / 2, y: h * 0.88)
            let outerR = min(w * 0.34, h * 0.74)
            let innerR = outerR * 0.60
            let midR = (outerR + innerR) / 2
            let band = outerR - innerR

            ZStack {
                // Segments
                ForEach(Array(slices.enumerated()), id: \.element.id) { i, slice in
                    let isActive = activeIndex == i
                    let dimmed = activeIndex != nil && !isActive
                    SemiArc(center: center, radius: isActive ? midR + 5 : midR,
                            start: slice.start, end: slice.end, gap: 0.02)
                        .stroke(
                            LinearGradient(colors: [slice.color.opacity(0.88), slice.color],
                                           startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: isActive ? band + 8 : band, lineCap: .round)
                        )
                        .opacity(dimmed ? 0.28 : 1.0)
                }

                // Leader lines + callout labels
                ForEach(Array(slices.enumerated()), id: \.element.id) { i, slice in
                    let arcPt = pointOnSemicircle(slice.mid, radius: outerR, center: center)
                    let labelPt = pointOnSemicircle(slice.mid, radius: outerR + 40, center: center)

                    Path { p in
                        p.move(to: pointOnSemicircle(slice.mid, radius: outerR + 3, center: center))
                        p.addLine(to: labelPt)
                    }
                    .stroke(slice.color.opacity(0.55), style: StrokeStyle(lineWidth: 1.2))

                    Circle().fill(slice.color).frame(width: 5, height: 5).position(arcPt)

                    calloutLabel(slice)
                        .position(x: clampedX(labelPt.x, width: w), y: labelPt.y - 18)
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

    /// Keeps callout labels from spilling off the card edges.
    private func clampedX(_ x: CGFloat, width: CGFloat) -> CGFloat {
        min(max(x, 62), width - 62)
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
        .frame(width: 116)
    }

    private var centerContent: some View {
        VStack(spacing: 4) {
            if let idx = activeIndex, idx < slices.count {
                let s = slices[idx]
                ZStack {
                    Circle().fill(s.color.opacity(0.16)).frame(width: 46, height: 46)
                    Image(systemName: "bag.fill").font(.system(size: 18)).foregroundColor(s.color)
                }
                Text(s.name).font(.system(size: 12, weight: .medium)).foregroundColor(theme.secondaryText).lineLimit(1)
                Text("\(s.units)").font(.system(size: 32, weight: .bold)).foregroundColor(theme.primaryText)
                Text("units · \(s.share)%").font(.system(size: 11)).foregroundColor(s.color)
            } else {
                ZStack {
                    Circle().fill(theme.burgundy.opacity(0.12)).frame(width: 46, height: 46)
                    Image(systemName: "bag.fill").font(.system(size: 18)).foregroundColor(theme.burgundy)
                }
                Text("Total Units Sold").font(.system(size: 12, weight: .medium)).foregroundColor(theme.secondaryText)
                Text("\(total)").font(.system(size: 32, weight: .bold)).foregroundColor(theme.primaryText)
                RoundedRectangle(cornerRadius: 2).fill(theme.burgundy).frame(width: 28, height: 3)
            }
        }
        .frame(width: 150)
        .multilineTextAlignment(.center)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag").font(.system(size: 32)).foregroundColor(theme.secondaryText.opacity(0.5))
            Text("No product data").font(.system(size: 14)).foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
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
        guard dy >= -8 else { return nil }
        let dist = sqrt(dx * dx + dy * dy)
        guard dist >= innerR - 16, dist <= outerR + 44 else { return nil }
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
    var gap: CGFloat = 0.02

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let a0 = start + gap
        let a1 = end - gap
        guard a1 > a0 else { return path }
        let steps = max(2, Int((a1 - a0) * 260))
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
