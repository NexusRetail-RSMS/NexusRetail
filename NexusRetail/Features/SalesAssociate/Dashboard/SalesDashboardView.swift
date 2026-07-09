//
//  SalesDashboardView.swift
//  NexusRetail
//
//  View-only file for the Sales Associate Dashboard tab.
//  All business logic lives in SalesDashboardViewModel.
//

import SwiftUI
import Charts

struct SalesDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppTheme.self) private var theme

    // POS navigation state
    @State private var posViewModel    = SellViewModel()
    @State private var navigationPath  = NavigationPath()

    // UI state
    @State private var isNotificationPresented = false
    @Namespace private var namespace

    // ViewModels
    @State private var vm = SalesDashboardViewModel()
    @State private var notificationVM = SalesNotificationViewModel()

    // MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                theme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        kpiSection
                        revenueChartSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 16)
                }

                if #available(iOS 18.0, *) {
                    floatingQRButton
                        .matchedTransitionSource(id: "scannerButton", in: namespace)
                } else {
                    floatingQRButton
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isNotificationPresented) {
                SalesNotificationListView(viewModel: notificationVM)
            }
            .navigationDestination(for: POSFlowDestination.self) { dest in
                switch dest {
                case .newSale:       NewSaleView(path: $navigationPath)
                case .searchProduct: ProductSearchView(path: $navigationPath)
                case .barcodeScanner: 
                    if #available(iOS 18.0, *) {
                        BarcodeScannerView(path: $navigationPath)
                            .navigationTransition(.zoom(sourceID: "scannerButton", in: namespace))
                    } else {
                        BarcodeScannerView(path: $navigationPath)
                    }
                case .cart:          CartView(path: $navigationPath)
                case .checkout:      CheckoutView(path: $navigationPath)
                case .payment:       PaymentFlowView(path: $navigationPath)
                case .receipt:
                    ReceiptView(onComplete: { navigationPath = NavigationPath() })
                case .bopis:
                    BOPISView()
                case .ordersHub:
                    OrdersHubView(path: $navigationPath)
                case .invoiceScanner, .invoiceItemsSelection, .actionSelection, .repairForm:
                    EmptyView()
                case .afterSalesHistory:
                    AfterSalesHistoryView(path: $navigationPath)
                case .exchangeProduct, .exchangePayment, .exchangeSummary,
                     .exchangeWarrantyCheck, .exchangeSelection, .exchangeSuccess:
                    EmptyView()
                }
            }
            .navigationDestination(for: RevenueDetailRoute.self) { _ in
                if #available(iOS 18.0, *) {
                    SalesRevenueDetailView(vm: vm)
                        .navigationTransition(.zoom(sourceID: "revenueChart", in: namespace))
                } else {
                    SalesRevenueDetailView(vm: vm)
                }
            }
        }
        .environment(posViewModel)
        .refreshable {
            await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
            await notificationVM.load(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
        }
        .task {
            await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
            await notificationVM.load(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
            Task {
                await notificationVM.startListening(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
            }
        }
        .onAppear {
            // Refresh data when view appears (e.g., after completing a sale)
            Task {
                await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
                await notificationVM.load(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
            }
        }
        .onChange(of: navigationPath.count) { _, newCount in
            // Refresh when returning to dashboard (path becomes empty)
            if newCount == 0 {
                Task { await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id) }
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            Spacer()
            NotificationBellView(unreadCount: notificationVM.unreadCount) {
                isNotificationPresented = true
            }
            NavigationLink(destination: GlobalProfileView()) {
                ZStack {
                    Circle().fill(theme.isDarkMode ? Color(hex: "2C0000") : theme.burgundy).frame(width: 44, height: 44)
                    if let urlString = sessionStore.currentUser?.imageUrl, let url = URL(string: urlString) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        Text(salesInitials(for: sessionStore.currentUser?.name))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Top Actions & KPIs
    private var kpiSection: some View {
        VStack(spacing: RSMSSpacing.md) {
            startOrderCard

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
                themedKPICard(title: "Orders Completed", value: "\(vm.ordersCompletedCount)", icon: "bag.fill",       color: theme.burgundy)
                themedKPICard(title: "Items Sold",       value: "\(vm.itemsSoldCount)",        icon: "shippingbox.fill", color: theme.isDarkMode ? theme.antiqueGold : Color(hex: "C0763A"))
            }
        }
    }

    /// KPI card that respects AppTheme for background and text
    private func themedKPICard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: RSMSSpacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, RSMSSpacing.md)
        .frame(height: 94)
        .background(
            theme.isDarkMode
                ? color.opacity(0.08)
                : color.opacity(0.04)
        )
        .cornerRadius(RSMSRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                .stroke(color.opacity(theme.isDarkMode ? 0.25 : 0.12), lineWidth: 1)
        )
    }
    
    private var startOrderCard: some View {
        NavigationLink(value: POSFlowDestination.ordersHub) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "bag.fill").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("View All Orders")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(LinearGradient(
                colors: [theme.burgundy, theme.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: theme.darkBurgundy.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Revenue Chart (line, no inline period control — tap expand for detail)
    private var revenueChartSection: some View {
        let accentColor = theme.isDarkMode ? theme.antiqueGold : theme.burgundy
        let cardBg: Color = theme.isDarkMode ? Color(hex: "1A0A0A") : Color.white
        let barGradient: [Color] = theme.isDarkMode
            ? [theme.antiqueGold.opacity(0.55), theme.antiqueGold]
            : [theme.burgundy.opacity(0.6), theme.burgundy]

        return VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack {
                Text("Store Revenue")
                    .font(RSMSFonts.headline)
                    .foregroundColor(theme.primaryText)
                Spacer()
                expandButton
            }

            SalesRevenueLineChart(points: vm.chartDataPoints, maxValue: vm.chartMaxValue)
                .frame(height: 200)

            HStack(spacing: RSMSSpacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 16, height: 8)
                Text("Revenue in Indian Rupees (₹)")
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(cardBg)
        .cornerRadius(RSMSRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .strokeBorder(accentColor.opacity(theme.isDarkMode ? 0.22 : 0.0), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.35 : 0.05), radius: 8, x: 0, y: 4)
    }

    /// Pill-style Weekly / Monthly toggle that replaces the segmented Picker.
    private func periodToggle(accentColor: Color) -> some View {
        HStack(spacing: 0) {
            ForEach(ChartPeriod.allCases) { period in
                let isSelected = vm.selectedChartPeriod == period
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        vm.selectedChartPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .foregroundColor(
                            isSelected
                                ? (theme.isDarkMode ? Color(hex: "1A0A0A") : .white)
                                : theme.secondaryText
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            isSelected
                                ? accentColor
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.72), value: vm.selectedChartPeriod)
            }
        }
        .padding(3)
        .background(
            theme.isDarkMode
                ? Color.white.opacity(0.07)
                : theme.burgundy.opacity(0.08)
        )
        .clipShape(Capsule())
    }

    private var expandButton: some View {
        let label = Button {
            navigationPath.append(RevenueDetailRoute())
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.burgundy)
                .padding(8)
                .background(theme.burgundy.opacity(0.1), in: Circle())
        }
        .accessibilityLabel("Expand chart")

        return Group {
            if #available(iOS 18.0, *) {
                label.matchedTransitionSource(id: "revenueChart", in: namespace)
            } else {
                label
            }
        }
    }

    // (Quick Actions removed as it's now at the top)

    // MARK: - Floating QR Button
    private var floatingQRButton: some View {
        Button {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                navigationPath.append(POSFlowDestination.barcodeScanner)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(red: 122/255, green: 22/255, blue: 34/255))
                    .frame(width: 60, height: 60)
                    .shadow(color: Color(red: 122/255, green: 22/255, blue: 34/255).opacity(0.5), radius: 8, x: 0, y: 4)
                
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(AnimatedFloatingButtonStyle())
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .accessibilityLabel("Scan QR Code")
    }

    // (Recent Activity section moved to startOrderCard)

}

struct AnimatedFloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Revenue detail route

struct RevenueDetailRoute: Hashable {}

// MARK: - Reusable smooth line chart (app theme)

struct SalesRevenueLineChart: View {
    @Environment(AppTheme.self) private var theme
    let points: [StoreRevenueChartPoint]
    let maxValue: Double
    var showYAxis: Bool = true

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Period", point.label),
                y: .value("Revenue", point.revenue)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [theme.burgundy.opacity(0.22), theme.burgundy.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Period", point.label),
                y: .value("Revenue", point.revenue)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(theme.burgundy)
        }
        .chartYScale(domain: 0...max(maxValue, 1))
        .chartYAxis {
            if showYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(theme.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v >= 100000 ? "₹\(String(format: "%.1f", v / 100000))L" : "₹\(Int(v))")
                                .font(.system(size: 9)).foregroundColor(theme.secondaryText)
                        }
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(theme.secondaryText)
                    }
                }
            }
        }
    }
}

// MARK: - Expanded revenue detail (scroll-over sheet: chart on background, cream panel slides up)

struct SalesRevenueDetailView: View {
    @Environment(AppTheme.self) private var theme
    @Bindable var vm: SalesDashboardViewModel
    @Environment(\.dismiss) private var dismiss

    // Currently-selected point label in the calendar strip (nil => default to peak)
    @State private var selectedLabel: String? = nil

    // White card fill used across the page
    private let cardFill = Color.white

    // Category-wise sales for the selected window
    private struct CategorySales: Identifiable {
        let id = UUID()
        let category: String
        let units: Int
        let revenue: Double
    }

    private var points: [StoreRevenueChartPoint] { vm.chartDataPoints }
    private var total: Double { points.reduce(0) { $0 + $1.revenue } }
    private var peak: StoreRevenueChartPoint? { points.max { $0.revenue < $1.revenue } }

    private var selectedPoint: StoreRevenueChartPoint? {
        if let selectedLabel, let p = points.first(where: { $0.label == selectedLabel }) { return p }
        return peak
    }

    private var catColors: [Color] {
        theme.isDarkMode 
            ? [theme.antiqueGold, Color(hex: "DDA15E"), Color(hex: "BC6C25"), theme.burgundy, Color(hex: "9A031E"), Color.gray]
            : [theme.burgundy, Color(hex: "D87A6A"), Color(hex: "E6A87C"), Color(hex: "9D4A4A"), Color(hex: "C28D75"), Color.gray]
    }

    // ISO parser shared by grouping/summary
    private func parseDate(_ raw: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: raw) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: raw)
    }

    // Completed orders inside the currently-selected window
    private var periodOrders: [StoreOrder] {
        vm.dbOrders.filter { order in
            guard order.status?.lowercased() == "completed" else { return false }
            guard let date = parseDate(order.createdAt) else { return false }
            return vm.chartWindow.contains(date)
        }
    }

    // Category breakdown for the window, sorted by revenue desc
    private var categorySales: [CategorySales] {
        var units:   [String: Int]    = [:]
        var revenue: [String: Double] = [:]
        for order in periodOrders {
            for item in order.orderLineItems ?? [] {
                let cat = (item.products?.category?.isEmpty == false) ? item.products!.category! : "Uncategorized"
                units[cat,   default: 0] += item.quantity
                revenue[cat, default: 0] += Double(item.quantity) * (item.appliedPrice ?? 0)
            }
        }
        return units.keys
            .map { CategorySales(category: $0, units: units[$0] ?? 0, revenue: revenue[$0] ?? 0) }
            .sorted { $0.revenue > $1.revenue }
    }

    private var salesCount: Int { periodOrders.count }

    // Swipe left/right on the chart to move the timeline window
    private var timelineSwipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy), abs(dx) > 40 else { return }
                withAnimation(.easeInOut(duration: 0.28)) {
                    if dx > 0 {
                        vm.chartOffset += 1        // swipe right → older window
                    } else if vm.chartOffset > 0 {
                        vm.chartOffset -= 1        // swipe left → newer window
                    }
                }
            }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Swipeable calendar strip
                calendarStrip

                // Chart directly on the background (no card box)
                chartOnBackground
                    .frame(height: 250)
                    .contentShape(Rectangle())
                    .gesture(timelineSwipe)

                // Total + Peak tiles (equal size)
                HStack(spacing: 12) {
                    summaryTile(title: "Total", value: formatIndianCurrency(total), caption: "\(salesCount) sale\(salesCount == 1 ? "" : "s")")
                    summaryTile(title: "Peak", value: formatIndianCurrency(peak?.revenue ?? 0), caption: (peak?.revenue ?? 0) > 0 ? peak?.label : "—")
                }

                breakdownSection
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .top) { fixedHeader }
        .navigationBarHidden(true)
        .onChange(of: vm.chartOffset) { _, _ in selectedLabel = nil }
        .onChange(of: vm.selectedChartPeriod) { _, _ in selectedLabel = nil }
    }

    // MARK: Swipeable calendar strip (weekday/month picker)
    private struct CalendarChip: Identifiable {
        let id = UUID()
        let label: String     // S M T W ... or Jan Feb ...
        let sub: String       // date number (weekly) or short month (monthly)
        let value: Double
        let date: Date?
    }

    private var calendarChips: [CalendarChip] {
        let calendar = Calendar.current

        if vm.selectedChartPeriod == .weekly {
            var dateByWeekday: [Int: Date] = [:]
            var d = vm.chartWindow.start
            for _ in 0..<7 {
                dateByWeekday[calendar.component(.weekday, from: d)] = d
                d = calendar.date(byAdding: .day, value: 1, to: d) ?? d
            }
            let orderWD  = [2, 3, 4, 5, 6, 7, 1]
            let letters  = ["M", "T", "W", "T", "F", "S", "S"]
            return points.enumerated().map { i, p in
                let date = dateByWeekday[orderWD[i]]
                let dnum = date.map { String(calendar.component(.day, from: $0)) } ?? ""
                return CalendarChip(label: letters[i], sub: dnum, value: p.revenue, date: date)
            }
        } else {
            let monthLetter = DateFormatter(); monthLetter.dateFormat = "MMMMM"   // single initial
            return points.enumerated().map { i, p in
                let date = calendar.date(byAdding: .month, value: i, to: vm.chartWindow.start)
                let initial = date.map { monthLetter.string(from: $0) } ?? String(p.label.prefix(1))
                return CalendarChip(label: initial, sub: p.label, value: p.revenue, date: date)
            }
        }
    }

    private var effectiveSelectedLabel: String? { selectedLabel ?? peak?.label }
    private var selectedIndex: Int? { points.firstIndex { $0.label == effectiveSelectedLabel } }

    // Full text below the strip for the selected period
    private var selectedDetailText: String {
        guard let idx = selectedIndex, idx < calendarChips.count, let date = calendarChips[idx].date else {
            return vm.chartRangeTitle
        }
        let f = DateFormatter()
        f.dateFormat = vm.selectedChartPeriod == .weekly ? "EEEE – d MMM yyyy" : "MMMM yyyy"
        return f.string(from: date)
    }

    private var calendarStrip: some View {
        VStack(spacing: 0) {
            // Weekday/month letters row
            HStack(spacing: 0) {
                ForEach(Array(calendarChips.enumerated()), id: \.offset) { _, chip in
                    Text(chip.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)

            // Date-number / month row with selection circle
            HStack(spacing: 0) {
                ForEach(Array(calendarChips.enumerated()), id: \.offset) { i, chip in
                    let isSelected = i == selectedIndex
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if i < points.count { selectedLabel = points[i].label }
                        }
                    } label: {
                        Text(chip.sub)
                            .font(.system(size: 17, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? .white : (chip.value > 0 ? theme.primaryText : theme.secondaryText.opacity(0.5)))
                            .frame(width: 38, height: 38)
                            .background(isSelected ? theme.burgundy : Color.clear, in: Circle())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().background(theme.cardBorder.opacity(0.5)).padding(.vertical, 12)

            // Full selected label + its revenue
            HStack {
                Text(selectedDetailText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                Text(formatIndianCurrency(selectedPoint?.revenue ?? 0))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.burgundy)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .highPriorityGesture(timelineSwipe)
    }

    // MARK: Fixed header (back + title + period dropdown)
    private var fixedHeader: some View {
        HStack(spacing: RSMSSpacing.md) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(theme.burgundy.opacity(0.1)).frame(width: 40, height: 40)
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)).foregroundColor(theme.primaryText)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Store Revenue").font(.system(size: 22, weight: .bold)).foregroundColor(theme.primaryText)
                Text("Detailed view").font(.system(size: 13)).foregroundColor(theme.secondaryText)
            }
            Spacer()
            periodMenu
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, 12)
        .background(theme.background)
    }

    private var periodMenu: some View {
        Menu {
            ForEach(ChartPeriod.allCases) { period in
                Button {
                    vm.selectedChartPeriod = period
                } label: {
                    if vm.selectedChartPeriod == period {
                        Label(period.rawValue, systemImage: "checkmark")
                    } else {
                        Text(period.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(vm.selectedChartPeriod.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.burgundy)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.burgundy)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(theme.burgundy.opacity(0.1), in: Capsule())
        }
    }

    // MARK: Chart on background (peak highlighted)
    private var chartOnBackground: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Revenue")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                Spacer()
                Image(systemName: "hand.draw")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.secondaryText.opacity(0.6))
                Text("Swipe to change")
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText.opacity(0.6))
            }

            Chart {
                ForEach(points) { point in
                    AreaMark(x: .value("Period", point.label), y: .value("Revenue", point.revenue))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(colors: [theme.burgundy.opacity(0.22), theme.burgundy.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Period", point.label), y: .value("Revenue", point.revenue))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(theme.burgundy)
                }

                if let sel = selectedPoint, sel.revenue > 0 {
                    RuleMark(x: .value("Period", sel.label))
                        .foregroundStyle(theme.burgundy.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    PointMark(x: .value("Period", sel.label), y: .value("Revenue", sel.revenue))
                        .foregroundStyle(theme.burgundy)
                        .symbolSize(120)
                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                            Text(formatIndianCurrency(sel.revenue))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.primaryText)
                                .padding(.horizontal, 9).padding(.vertical, 4)
                                .background(theme.cardBackground, in: Capsule())
                                .overlay(Capsule().stroke(theme.cardBorder.opacity(0.6), lineWidth: 1))
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        }
                }
            }
            .chartYScale(domain: 0...max(vm.chartMaxValue, 1))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(theme.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v >= 100000 ? "₹\(String(format: "%.1f", v / 100000))L" : "₹\(Int(v))")
                                .font(.system(size: 9)).foregroundColor(theme.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(theme.secondaryText)
                        }
                    }
                }
            }
            .frame(height: 240)
            .animation(.easeInOut(duration: 0.3), value: points)
        }
    }

    private func summaryTile(title: String, value: String, caption: String? = nil) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.system(size: 13, weight: .medium)).foregroundColor(theme.secondaryText)
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(theme.burgundy).lineLimit(1).minimumScaleFactor(0.6)
            // Always reserve a caption line so both tiles are the same height
            Text(caption ?? " ")
                .font(.system(size: 11)).foregroundColor(theme.secondaryText).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder.opacity(0.6), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Sales by Category")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                if !categorySales.isEmpty {
                    Text("\(categorySales.count) categor\(categorySales.count == 1 ? "y" : "ies")")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                }
            }

            if categorySales.isEmpty {
                emptyBreakdown
            } else {
                // Single grouped container holding
                VStack(alignment: .leading, spacing: 0) {
                    // Donut Chart
                    Chart {
                        ForEach(Array(categorySales.enumerated()), id: \.element.id) { index, cat in
                            SectorMark(
                                angle: .value("Revenue", cat.revenue),
                                innerRadius: .ratio(0.65),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(catColors[index % catColors.count])
                        }
                    }
                    .frame(height: 180)
                    .padding(.vertical, RSMSSpacing.lg)
                    .overlay {
                        VStack(spacing: 2) {
                            Text("Total")
                                .font(.system(size: 12))
                                .foregroundColor(theme.secondaryText)
                            Text(formatIndianCurrency(grandTotalRevenue))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(theme.primaryText)
                        }
                    }

                    // Legend List
                    VStack(spacing: 0) {
                        ForEach(Array(categorySales.enumerated()), id: \.element.id) { idx, cat in
                            categoryRow(cat, color: catColors[idx % catColors.count])
                            if idx < categorySales.count - 1 {
                                Divider().background(theme.cardBorder.opacity(0.5))
                                    .padding(.leading, 14)
                            }
                        }
                    }
                }
                .background(cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
            }
        }
    }

    private var grandTotalRevenue: Double { categorySales.reduce(0) { $0 + $1.revenue } }

    private func categoryRow(_ cat: CategorySales, color: Color) -> some View {
        let share  = grandTotalRevenue > 0 ? Int((cat.revenue / grandTotalRevenue) * 100) : 0
        return VStack(spacing: 4) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(cat.category)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                Spacer()
                Text("\(share)%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                Text(formatIndianCurrency(cat.revenue))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.primaryText)
            }
            HStack {
                Text("\(cat.units) unit\(cat.units == 1 ? "" : "s") sold")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
                Spacer()
            }
        }
        .padding(14)
    }

    private var emptyBreakdown: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(theme.burgundy.opacity(0.08)).frame(width: 64, height: 64)
                Image(systemName: "cart.badge.questionmark")
                    .font(.system(size: 26))
                    .foregroundColor(theme.burgundy.opacity(0.6))
            }
            Text("No completed sales")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.primaryText)
            Text(vm.selectedChartPeriod == .weekly
                 ? "There are no sales recorded in this week."
                 : "There are no sales recorded in this period.")
                .font(.system(size: 13))
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Rounded specific corners helper

struct RoundedCorner: Shape {
    var radius: CGFloat = 20
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
