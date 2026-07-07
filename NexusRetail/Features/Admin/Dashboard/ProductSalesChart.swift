import SwiftUI

struct ProductSalesChart: View {
    let data: [ProductChartPoint]
    let maxValue: Int
    @Binding var timeRange: SalesTimeRange
    var allowsYearly: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack(alignment: .top) {
                Text("Top Products")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                if allowsYearly {
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(SalesTimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                } else {
                    TimeRangeToggle(selection: $timeRange)
                }
            }

            if data.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bag")
                        .font(.system(size: 32))
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                    Text("No product data")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .padding(.top, RSMSSpacing.sm)
            } else {
                VStack(spacing: RSMSSpacing.sm) {
                    ForEach(Array(data.prefix(4).enumerated()), id: \.element.id) { index, point in
                        ProductRankRow(
                            rank: index + 1,
                            point: point,
                            maxValue: max(1, data.map(\.sales).max() ?? 1)
                        )
                    }
                }
                .padding(.top, RSMSSpacing.xs)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(Color.white)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.3), value: data)
    }
}

struct ProductRankRow: View {
    let rank: Int
    let point: ProductChartPoint
    let maxValue: Int

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(rankGradient(for: rank))

                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(rankTextColor(for: rank))
            }
            .frame(width: 40)

            HStack(spacing: 12) {
                Group {
                    if let url = point.imageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            imagePlaceholder
                        }
                    } else {
                        imagePlaceholder
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.nexusDark.opacity(0.06), lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(point.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(point.category)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(RSMSColors.secondaryText)
                    }

                    GeometryReader { geo in
                        let progress = CGFloat(point.sales) / CGFloat(maxValue)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.nexusDark.opacity(0.06))
                                .frame(height: 3)

                            Capsule()
                                .fill(colorFor(category: point.category))
                                .frame(width: max(0, geo.size.width * progress), height: 3)
                        }
                    }
                    .frame(height: 3)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    let formattedSales = NumberFormatter.localizedString(from: NSNumber(value: point.sales), number: .decimal)
                    Text("\(formattedSales)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)

                    Text("units")
                        .font(.system(size: 10))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
            .padding(10)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rank == 1 ? Color.nexusGold.opacity(0.35) : Color.nexusDark.opacity(0.06), lineWidth: rank == 1 ? 1.25 : 1)
        )
    }

    private var imagePlaceholder: some View {
        ZStack {
            Color(hex: "F8F9FA")
            Image(systemName: "bag.fill")
                .foregroundColor(Color.gray.opacity(0.3))
                .font(.system(size: 16))
        }
    }

    private func rankGradient(for rank: Int) -> LinearGradient {
        let colors: [Color]
        switch rank {
        case 1: colors = [Color.nexusGold, Color(hex: "8A6A42")]
        case 2: colors = [Color.nexusDark.opacity(0.85), Color.nexusDark]
        case 3: colors = [RSMSColors.burgundy.opacity(0.85), RSMSColors.burgundy]
        default: colors = [Color.nexusDark.opacity(0.35), Color.nexusDark.opacity(0.5)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func rankTextColor(for rank: Int) -> Color {
        rank == 1 ? Color.nexusDark : .white
    }

    private func colorFor(category: String) -> Color {
        switch category {
        case "Couture": return RSMSColors.burgundy
        case "Perfume", "Perfumes", "Fragrances", "Fragrance": return Color.nexusGold
        case "Jewellery", "Jewelry": return Color(hex: "8A6A42")
        case "Leather", "Leather Goods": return Color(hex: "2A9D8F")
        case "Watches": return Color.nexusDark
        case "Accessories": return Color(hex: "8E6C88")
        case "Bags": return Color(hex: "2A9D8F")
        case "Clothes": return RSMSColors.burgundy
        default: return RSMSColors.chartBar
        }
    }
}

#Preview {
    @Previewable @State var range: SalesTimeRange = .monthly
    let vm = DashboardViewModel()
    ProductSalesChart(data: vm.productChartData, maxValue: vm.productMaxValue, timeRange: $range)
        .padding()
        .background(Color(hex: "F5F5F7"))
}
