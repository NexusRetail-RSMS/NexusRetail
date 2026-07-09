//
//  TopProductsDonut.swift
//  NexusRetail
//
//  Reusable, interactive donut chart for "Top Products".
//  Shows the top slices plus a grouped "Others" slice.
//  Tapping a slice reveals its label + unit count in the center.
//

import SwiftUI
import Charts

struct DonutSlice: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let value: Int
    let color: Color
}

enum TopProductsPalette {
    /// Attractive, theme-matching palette. Last color is reserved for "Others".
    static func colors(dark: Bool) -> [Color] {
        if dark {
            return [
                RSMSColors.burgundy,
                Color(hex: "E9C46A"),   // gold
                Color(hex: "2A9D8F"),   // teal
                Color(hex: "E76F51"),   // terracotta
                Color(hex: "9D8DF1"),   // periwinkle
                Color(hex: "457B9D")    // dusty blue
            ]
        } else {
            return [
                RSMSColors.burgundy,
                Color(hex: "E9C46A"),
                Color(hex: "2A9D8F"),
                Color(hex: "E76F51"),
                Color(hex: "6D597A"),
                Color(hex: "457B9D")
            ]
        }
    }

    /// Builds slices from (label, value) pairs: keep the top `maxSlices`,
    /// roll everything else into a single grey "Others" slice.
    static func makeSlices(from items: [(label: String, value: Int)], maxSlices: Int, dark: Bool) -> [DonutSlice] {
        let palette = colors(dark: dark)
        let sorted = items.sorted { $0.value > $1.value }
        var slices: [DonutSlice] = []

        let top = sorted.prefix(maxSlices)
        for (i, item) in top.enumerated() {
            slices.append(DonutSlice(label: item.label, value: item.value, color: palette[i % palette.count]))
        }

        let othersTotal = sorted.dropFirst(maxSlices).reduce(0) { $0 + $1.value }
        if othersTotal > 0 {
            slices.append(DonutSlice(label: "Others", value: othersTotal, color: Color.gray.opacity(0.5)))
        }
        return slices
    }
}

struct TopProductsDonut: View {
    @Environment(AppTheme.self) private var theme
    let slices: [DonutSlice]
    var height: CGFloat = 240
    var centerCaption: String = "Units sold"
    var unitLabel: String = "units"

    private var total: Int { slices.reduce(0) { $0 + $1.value } }

    // Precomputed slice angles as fractions of the whole (0...1, starting at 12 o'clock, clockwise).
    private struct Segment {
        let slice: DonutSlice
        let start: CGFloat   // fraction
        let end: CGFloat     // fraction
        var mid: CGFloat { (start + end) / 2 }
        var share: Int
    }

    private var segments: [Segment] {
        guard total > 0 else { return [] }
        var result: [Segment] = []
        var cursor: CGFloat = 0
        for slice in slices {
            let frac = CGFloat(slice.value) / CGFloat(total)
            let share = Int((Double(slice.value) / Double(total) * 100).rounded())
            result.append(Segment(slice: slice, start: cursor, end: cursor + frac, share: share))
            cursor += frac
        }
        return result
    }

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        segments.map { "\($0.slice.label) \($0.share) percent" }.joined(separator: ", ")
    }

    // MARK: - Geometry

    private func point(_ fraction: CGFloat, radius: CGFloat, center: CGPoint) -> CGPoint {
        let theta = fraction * 2 * .pi
        return CGPoint(x: center.x + radius * sin(theta),
                       y: center.y - radius * cos(theta))
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        // Leave horizontal room for the callout labels on both sides.
        let outerR = min(size.height * 0.36, size.width * 0.20)
        guard outerR > 8 else { return }
        let innerR = outerR * 0.60
        let band = outerR - innerR
        let midR = (outerR + innerR) / 2
        let gap: CGFloat = 0.012   // fraction gap between segments for rounded separation

        // 1) Draw each segment as a thick rounded arc
        for seg in segments {
            let a0 = seg.start + gap
            let a1 = seg.end - gap
            guard a1 > a0 else { continue }

            var path = Path()
            let steps = max(2, Int((a1 - a0) * 240))
            for i in 0...steps {
                let f = a0 + (a1 - a0) * CGFloat(i) / CGFloat(steps)
                let p = point(f, radius: midR, center: center)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            let shading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [seg.slice.color.opacity(0.82), seg.slice.color]),
                startPoint: point(seg.start, radius: outerR, center: center),
                endPoint: point(seg.end, radius: innerR, center: center)
            )
            context.stroke(path, with: shading, style: StrokeStyle(lineWidth: band, lineCap: .round))
        }

        // 2) Center total + caption
        let totalText = Text(formatCount(total)).font(.system(size: min(26, outerR * 0.42), weight: .bold)).foregroundColor(theme.primaryText)
        let captionText = Text(centerCaption).font(.system(size: 11)).foregroundColor(theme.secondaryText)
        context.draw(totalText, at: CGPoint(x: center.x, y: center.y - 8), anchor: .center)
        context.draw(captionText, at: CGPoint(x: center.x, y: center.y + 12), anchor: .center)

        // 3) Callout labels with leader lines
        drawCallouts(in: &context, size: size, center: center, outerR: outerR)
    }

    private func drawCallouts(in context: inout GraphicsContext, size: CGSize, center: CGPoint, outerR: CGFloat) {
        // Split segments by which side of the donut their midpoint falls on.
        let left  = segments.filter { point($0.mid, radius: outerR, center: center).x <  center.x }
        let right = segments.filter { point($0.mid, radius: outerR, center: center).x >= center.x }

        let topMargin: CGFloat = 18
        let usableH = size.height - topMargin * 2

        func placeSide(_ segs: [Segment], isLeft: Bool) {
            let ordered = segs.sorted { $0.mid < $1.mid } // top-to-bottom by angle
            let n = ordered.count
            guard n > 0 else { return }
            for (i, seg) in ordered.enumerated() {
                let labelY = topMargin + usableH * (CGFloat(i) + 0.5) / CGFloat(n)
                let anchor = point(seg.mid, radius: outerR + 2, center: center)
                let elbowX = isLeft ? center.x - outerR - 18 : center.x + outerR + 18
                let lineEndX = isLeft ? size.width * 0.22 : size.width * 0.78

                // Dotted leader: segment -> elbow(at label height) -> horizontal to column
                var line = Path()
                line.move(to: anchor)
                line.addLine(to: CGPoint(x: elbowX, y: labelY))
                line.addLine(to: CGPoint(x: lineEndX, y: labelY))
                context.stroke(line, with: .color(theme.secondaryText.opacity(0.35)),
                               style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                // Percentage (colored, bold) + label (secondary), stacked
                let pctText = Text("\(seg.share)%")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(seg.slice.color)
                let nameText = Text(seg.slice.label)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)

                let textX = isLeft ? lineEndX - 6 : lineEndX + 6
                let textAnchor: UnitPoint = isLeft ? .trailing : .leading
                context.draw(pctText, at: CGPoint(x: textX, y: labelY - 8), anchor: textAnchor)
                context.draw(nameText, at: CGPoint(x: textX, y: labelY + 9), anchor: textAnchor)
            }
        }

        placeSide(left, isLeft: true)
        placeSide(right, isLeft: false)
    }

    private func formatCount(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Compact legend used alongside the donut

struct TopProductsDonutLegend: View {
    @Environment(AppTheme.self) private var theme
    let slices: [DonutSlice]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 8) {
            ForEach(slices) { slice in
                HStack(spacing: 6) {
                    Circle().fill(slice.color).frame(width: 8, height: 8)
                    Text(slice.label)
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                }
            }
        }
    }
}
