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
    var height: CGFloat = 220
    var centerCaption: String = "Units sold"
    var unitLabel: String = "units"

    @State private var selectedValue: Int?

    private var total: Int { slices.reduce(0) { $0 + $1.value } }

    private var selectedSlice: DonutSlice? {
        guard let selectedValue else { return nil }
        var cumulative = 0
        for slice in slices {
            cumulative += slice.value
            if selectedValue <= cumulative { return slice }
        }
        return slices.last
    }

    var body: some View {
        VStack(spacing: 6) {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Units", slice.value),
                    innerRadius: .ratio(0.62),
                    outerRadius: selectedSlice == slice ? .ratio(1.0) : .ratio(0.92),
                    angularInset: 2
                )
                .cornerRadius(6)
                .foregroundStyle(
                    LinearGradient(
                        colors: [slice.color.opacity(0.82), slice.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(selectedSlice == nil || selectedSlice == slice ? 1.0 : 0.3)
            }
            .chartAngleSelection(value: $selectedValue)
            .chartLegend(.hidden)
            .frame(height: height)
            .animation(.easeInOut(duration: 0.25), value: selectedSlice)
            .chartBackground { proxy in
                GeometryReader { geo in
                    if let anchor = proxy.plotFrame {
                        let frame = geo[anchor]
                        centerContent
                            .frame(width: frame.width * 0.6)
                            .position(x: frame.midX, y: frame.midY)
                    }
                }
            }

            // Small hint — tapping/holding a segment reveals its details
            if !slices.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 9))
                    Text(selectedSlice == nil ? "Touch & hold a segment for details" : "Release to dismiss")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(theme.secondaryText.opacity(0.7))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Top Products Chart")
        .accessibilityValue(selectedSlice != nil ? "\(selectedSlice!.label): \(formatCount(selectedSlice!.value)) \(unitLabel)" : "Donut chart showing \(formatCount(total)) \(unitLabel) total.")
        .accessibilityHint(selectedSlice == nil ? "Double tap and hold to explore chart segments." : "Release to stop exploring.")
    }

    private var centerContent: some View {
        VStack(spacing: 2) {
            if let sel = selectedSlice {
                Text(sel.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(1)
                Text(formatCount(sel.value))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Text(unitLabel)
                    .font(.system(size: 11))
                    .foregroundColor(theme.secondaryText)
            } else {
                Text(formatCount(total))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Text(centerCaption)
                    .font(.system(size: 11))
                    .foregroundColor(theme.secondaryText)
            }
        }
        .multilineTextAlignment(.center)
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
