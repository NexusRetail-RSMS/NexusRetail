//
//  ProductSalesChart.swift
//  NexusRetail
//
//  Top product-sales ranked list with its OWN Weekly ↔ Monthly toggle
//  (independent from the Revenue chart).
//  Displays products as a ranked list with image, multiline text, and a slim progress bar.
//

import SwiftUI

struct ProductSalesChart: View {
    @Environment(AppTheme.self) private var theme
    let data: [ProductChartPoint]
    let maxValue: Int
    @Binding var timeRange: SalesTimeRange
    /// When true, the toggle also offers Yearly. Off by default so the Admin
    /// dashboard (weekly/monthly only) is unaffected; the Manager passes true.
    var allowsYearly: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {

            // Title row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {

                        Text("Top Products")
                            .font(RSMSFonts.headline)
                            .foregroundColor(theme.primaryText)
                    }
                }

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
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "bag")
                        .font(.system(size: 32))
                        .foregroundColor(theme.secondaryText.opacity(0.5))
                    Text("No product data")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
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
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.3), value: data)
    }
}

struct ProductRankRow: View {
    @Environment(AppTheme.self) private var theme
    let rank: Int
    let point: ProductChartPoint
    let maxValue: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Rank Block on the left
            ZStack {
                Rectangle()
                    .fill(rankGradient(for: rank))
                
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 40)
            
            HStack(spacing: 12) {
                // Product Image
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
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.05), lineWidth: 1))
                
                // Details and Progress Bar
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(point.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(point.category)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    // Slim Progress Bar
                    GeometryReader { geo in
                        let progress = CGFloat(point.sales) / CGFloat(maxValue)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 3)
                            
                            Capsule()
                                .fill(colorFor(category: point.category))
                                .frame(width: max(0, geo.size.width * progress), height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                
                Spacer(minLength: 8)
                
                // Units
                VStack(alignment: .trailing, spacing: 1) {
                    let formattedSales = NumberFormatter.localizedString(from: NSNumber(value: point.sales), number: .decimal)
                    Text("\(formattedSales)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    
                    Text("units")
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryText)
                }
            }
            .padding(10)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
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
        case 1: colors = [Color(hex: "F6D365"), Color(hex: "FDA085")] // Gold/Orange
        case 2: colors = [Color(hex: "E2E2E2"), Color(hex: "9B9B9B")] // Silver
        case 3: colors = [Color(hex: "E6B980"), Color(hex: "EACDA3")] // Bronze
        case 4: colors = [Color(hex: "C6A9FF"), Color(hex: "A385E0")] // Purple
        case 5: colors = [Color(hex: "A8E0D2"), Color(hex: "7FBBAF")] // Mint
        default: colors = [Color.gray.opacity(0.3), Color.gray.opacity(0.5)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private func colorFor(category: String) -> Color {
        switch category {
        case "Couture": return theme.burgundy
        case "Perfume", "Perfumes", "Fragrances", "Fragrance": return Color(hex: "F4A261")
        case "Jewellery", "Jewelry": return Color(hex: "E9C46A")
        case "Leather", "Leather Goods": return Color(hex: "2A9D8F")
        case "Watches": return Color(hex: "264653")
        case "Accessories": return Color(hex: "8A2BE2")
        case "Bags": return Color(hex: "2A9D8F")
        case "Clothes": return theme.burgundy
        default: return theme.chartBar
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
