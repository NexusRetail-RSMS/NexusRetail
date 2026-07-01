import SwiftUI
import Charts

struct SalesDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let onlineSales: Double
    let offlineSales: Double
}

struct VisitorSource: Identifiable {
    let id = UUID()
    let name: String
    let count: Double
    let color: Color
}

struct StoreAnalyticsView: View {
    let store: Store
    let manager: DisplayManager?
    @Bindable var viewModel: StoresViewModel
    @State private var analyticsVM: StoreAnalyticsViewModel
    let namespace: Namespace.ID
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingStoreInfo     = false
    @State private var isShowingEditForm      = false
    @State private var isShowingSalesDetail   = false
    @State private var isShowingProductsDetail = false

    private let timeRanges = ["This Month", "This Year", "All Time"]
    private let heroHeight: CGFloat = 300

    init(store: Store, manager: DisplayManager?, viewModel: StoresViewModel, namespace: Namespace.ID) {
        self.store     = store
        self.manager   = manager
        self.viewModel = viewModel
        self.namespace = namespace
        self._analyticsVM = State(initialValue: StoreAnalyticsViewModel(store: store))
    }

    private var isActive: Bool { store.status == .active }

    private var locationLine: String {
        [store.city, store.country]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: ", ")
            .nonEmptyOrNil ?? "Location not set"
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero(topInset: topInset)
                    analyticsPanel
                        .offset(y: -20)
                        .padding(.bottom, -20)
                }
                .frame(width: geo.size.width)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .navigationTransition(.zoom(sourceID: store.id, in: namespace))
        .navigationBarBackButtonHidden(false)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { isShowingStoreInfo = true } label: {
                        Label("Store Info", systemImage: "info.circle")
                    }
                    Button { isShowingEditForm = true } label: {
                        Label("Edit Store", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .accessibilityLabel("More options")
            }
        }
        .refreshable { await analyticsVM.load() }
        .task {
            if analyticsVM.orders.isEmpty { await analyticsVM.load() }
        }
        .sheet(isPresented: $isShowingStoreInfo) {
            NavigationStack {
                StoreDetailView(store: store, manager: manager, viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { isShowingStoreInfo = false }
                                .tint(RSMSColors.burgundy)
                        }
                    }
            }
        }
        .sheet(isPresented: $isShowingEditForm) {
            StoreFormView(viewModel: viewModel, editingStore: store)
        }
        .fullScreenCover(isPresented: $isShowingSalesDetail) {
            NavigationStack { SalesDetailView(store: store) }
        }
        .fullScreenCover(isPresented: $isShowingProductsDetail) {
            NavigationStack { TopProductsDetailView(store: store) }
        }
    }

    private func hero(topInset: CGFloat) -> some View {
        let totalHeight = heroHeight + topInset
        return ZStack(alignment: .bottom) {
            Group {
                if let url = store.imageURL, !url.isEmpty {
                    CachedStoreImage(urlString: url)
                } else {
                    heroBrandedPlaceholder
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: totalHeight)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.black.opacity(0.08), location: 0.30),
                    .init(color: Color.black.opacity(0.55), location: 0.60),
                    .init(color: Color.black.opacity(0.92), location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: totalHeight)

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(isActive ? Color(hex: "34C759") : .gray)
                        .frame(width: 6, height: 6)
                    Text(isActive ? "Active" : "In-Active")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .environment(\.colorScheme, .dark)

                Text(store.name)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

                HStack(spacing: 14) {
                    HStack(spacing: 5) {
                        Image(systemName: "location")
                            .font(.system(size: 11))
                        Text(locationLine)
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if let name = manager?.name {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.white.opacity(0.16))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Text(initials(name))
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            Text(name)
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                }
                .foregroundColor(.white.opacity(0.80))
            }
            .padding(.horizontal, RSMSSpacing.xxxxl)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: totalHeight)
    }

    private var heroBrandedPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "2C1010"), RSMSColors.burgundy.opacity(0.5), Color(hex: "1C1C1E")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle()
                .fill(RSMSColors.burgundy.opacity(0.15))
                .frame(width: 200, height: 200)
                .blur(radius: 55)
                .offset(x: 60, y: -20)
            Circle()
                .fill(RSMSColors.burgundy.opacity(0.09))
                .frame(width: 140, height: 140)
                .blur(radius: 38)
                .offset(x: -60, y: 40)
        }
    }

    private var analyticsPanel: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
            if analyticsVM.isLoading && analyticsVM.orders.isEmpty {
                VStack(spacing: 14) {
                    ProgressView().tint(RSMSColors.burgundy)
                    Text("Loading analytics…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 320)
            } else {
                if let err = analyticsVM.errorMessage {
                    Text(err)
                        .foregroundColor(RSMSColors.error)
                        .font(RSMSFonts.caption)
                }
                timeRangePicker
                kpiGrid
                salesCard
                productsCard
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.xl)
        .padding(.bottom, 120)
        .frame(maxWidth: .infinity)
        .background(RSMSColors.background)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24
            )
        )
    }

    private var timeRangePicker: some View {
        Picker("Time range", selection: $analyticsVM.timeRange) {
            ForEach(timeRanges, id: \.self) { range in
                Text(range).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .tint(RSMSColors.burgundy)
        .frame(maxWidth: .infinity)
    }

    private var salesTrend: [Double] {
        analyticsVM.salesData.map(\.onlineSales)
    }

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
            PremiumKPICard(
                icon: "bag",
                value: formatNum(analyticsVM.kpiOrders),
                title: "New Orders",
                trend: salesTrend
            )
            PremiumKPICard(
                icon: "indianrupeesign.circle",
                value: "₹\(formatNum(analyticsVM.kpiSales))",
                title: "Total Sales",
                trend: salesTrend
            )
            PremiumKPICard(
                icon: "arrow.up.right.circle",
                value: "₹\(formatNum(analyticsVM.kpiPaidOut))",
                title: "Paid Out",
                trend: salesTrend.map { $0 * 0.3 }
            )
            PremiumKPICard(
                icon: "person.2",
                value: "\(analyticsVM.kpiCustomers)",
                title: "Customers",
                emptyCaption: analyticsVM.kpiCustomers == 0 ? "No activity yet" : nil
            )
        }
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1000 { return String(format: "%.0fk", value / 1000) }
        return String(format: "%.0f", value)
    }

    private var salesCard: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            sectionHeader("Sales Report")

            HStack(spacing: 6) {
                Circle().fill(RSMSColors.burgundy).frame(width: 7, height: 7)
                Text("Total Sales")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }

            if analyticsVM.salesData.isEmpty {
                emptyBarChart
            } else {
                let peakMonth = analyticsVM.salesData.max(by: { $0.onlineSales < $1.onlineSales })?.month

                Chart(analyticsVM.salesData) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Sales", item.onlineSales)
                    )
                    .foregroundStyle(item.month == peakMonth ? RSMSColors.burgundy : RSMSColors.burgundy.opacity(0.22))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        if item.month == peakMonth {
                            Text("₹\(formatCompact(item.onlineSales))")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RSMSColors.primaryText, in: RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
                .chartYScale(domain: 0...analyticsVM.salesChartMax)
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(RSMSColors.divider)
                        AxisValueLabel {
                            if let i = value.as(Int.self) {
                                Text(i >= 1000 ? "₹\(i / 1000)k" : "₹\(i)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(RSMSColors.secondaryText)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 11))
                            .foregroundStyle(RSMSColors.secondaryText)
                    }
                }
                .frame(height: 200)
                .padding(.top, 18)
            }

            drillFooter("Full Report")
                .onTapGesture { isShowingSalesDetail = true }
        }
        .analyticsCard()
    }

    private func percentage(for units: Int) -> Double {
        guard analyticsVM.totalUnits > 0 else { return 0 }
        return (Double(units) / Double(analyticsVM.totalUnits)) * 100
    }

    private var productsCard: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            sectionHeader("Top Products")

            if analyticsVM.topProducts.isEmpty {
                emptyDonut
            } else {
                HStack(alignment: .center, spacing: RSMSSpacing.lg) {
                    ZStack {
                        Chart(analyticsVM.topProducts) { p in
                            SectorMark(
                                angle: .value("Units", p.units),
                                innerRadius: .ratio(0.64),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("Category", p.category))
                            .cornerRadius(4)
                        }
                        .chartForegroundStyleScale(categoryColorScale)
                        .chartLegend(.hidden)
                        .frame(width: 100, height: 100)

                        VStack(spacing: 2) {
                            Text(formatNum(analyticsVM.totalUnits))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                            Text("units")
                                .font(.system(size: 9.5))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                    }

                    VStack(alignment: .leading, spacing: 11) {
                        ForEach(analyticsVM.topProducts) { p in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(p.category)
                                        .font(.system(size: 11.5))
                                        .foregroundColor(RSMSColors.primaryText)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(Int(percentage(for: p.units)))%")
                                        .font(.system(size: 11.5))
                                        .foregroundColor(RSMSColors.secondaryText)
                                }
                                ProgressView(value: percentage(for: p.units), total: 100)
                                    .tint(colorFor(p.category))
                            }
                        }
                    }
                }
            }

            drillFooter("Full Breakdown")
                .onTapGesture { isShowingProductsDetail = true }
        }
        .analyticsCard()
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(RSMSColors.burgundy)
                .frame(width: 3, height: 18)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
            Spacer()
            Text(analyticsVM.timeRange)
                .font(.system(size: 11))
                .foregroundColor(RSMSColors.secondaryText)
        }
    }

    private func drillFooter(_ label: String) -> some View {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                Text(label).font(.system(size: 12, weight: .semibold))
                Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(RSMSColors.burgundy)
        }
    }

    private var emptyBarChart: some View {
        Chart {
            ForEach(["Jan", "Feb", "Mar", "Apr", "May", "Jun"], id: \.self) { m in
                BarMark(x: .value("Month", m), y: .value("Sales", 5.0))
                    .foregroundStyle(RSMSColors.burgundy.opacity(0.12))
                    .cornerRadius(4)
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { v in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(RSMSColors.divider)
                AxisValueLabel {
                    if let i = v.as(Int.self) {
                        Text("₹\(i)").font(.system(size: 10)).foregroundStyle(RSMSColors.secondaryText)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel().font(.system(size: 11)).foregroundStyle(RSMSColors.secondaryText)
            }
        }
        .frame(height: 200)
        .overlay {
            VStack(spacing: 6) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 22))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.35))
                Text("No sales data for this period")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
    }

    private var emptyDonut: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(RSMSColors.burgundy.opacity(0.08), lineWidth: 28)
                    .frame(width: 110, height: 110)
                VStack(spacing: 4) {
                    Image(systemName: "bag")
                        .font(.system(size: 20))
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                    Text("No data")
                        .font(.system(size: 11))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSSpacing.lg)
    }

    private var categoryColorScale: KeyValuePairs<String, Color> {
        [
            "Couture": RSMSColors.burgundy,
            "Clothes": RSMSColors.burgundy,
            "Perfume": RSMSColors.burgundy.opacity(0.65),
            "Perfumes": RSMSColors.burgundy.opacity(0.65),
            "Fragrances": RSMSColors.burgundy.opacity(0.65),
            "Fragrance": RSMSColors.burgundy.opacity(0.65),
            "Jewellery": RSMSColors.burgundy.opacity(0.45),
            "Jewelry": RSMSColors.burgundy.opacity(0.45),
            "Leather Goods": RSMSColors.burgundy.opacity(0.3),
            "Leather": RSMSColors.burgundy.opacity(0.3),
            "Bags": RSMSColors.burgundy.opacity(0.3),
            "Watches": RSMSColors.secondaryText,
            "Accessories": RSMSColors.cardBorder
        ]
    }

    private func colorFor(_ category: String) -> Color {
        switch category {
        case "Couture", "Clothes":                          return RSMSColors.burgundy
        case "Perfume","Perfumes","Fragrance","Fragrances": return RSMSColors.burgundy.opacity(0.65)
        case "Jewellery","Jewelry":                         return RSMSColors.burgundy.opacity(0.45)
        case "Leather","Leather Goods","Bags":               return RSMSColors.burgundy.opacity(0.3)
        case "Watches":                                     return RSMSColors.secondaryText
        case "Accessories":                                 return RSMSColors.cardBorder
        default:                                            return RSMSColors.chartBar
        }
    }

    private func formatNum(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private struct PremiumKPICard: View {
    let icon: String
    let value: String
    let title: String
    var trend: [Double]? = nil
    var emptyCaption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 11.5))
                    .foregroundColor(RSMSColors.secondaryText)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
            }

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(RSMSColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let trend, trend.count > 1 {
                SparklineView(values: trend, color: RSMSColors.burgundy.opacity(0.55))
            } else if let emptyCaption {
                Text(emptyCaption)
                    .font(.system(size: 10.5))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.6))
                    .frame(height: 22, alignment: .center)
            } else {
                Spacer().frame(height: 22)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RSMSSpacing.md)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.medium)
        .overlay(RoundedRectangle(cornerRadius: RSMSRadius.medium).stroke(RSMSColors.cardBorder, lineWidth: 0.5))
    }
}

private struct SparklineView: View {
    let values: [Double]
    let color: Color

    var body: some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                LineMark(x: .value("Index", index), y: .value("Value", value))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
        .foregroundStyle(color)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plot in plot.padding(0) }
        .frame(height: 22)
    }
}

private extension View {
    func analyticsCard() -> some View {
        self
            .padding(RSMSSpacing.lg)
            .background(RSMSColors.cardBackground)
            .cornerRadius(RSMSRadius.large)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .overlay(RoundedRectangle(cornerRadius: RSMSRadius.large).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }
}

private extension String {
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}
