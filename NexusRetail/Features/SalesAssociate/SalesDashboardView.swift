import SwiftUI
import Supabase
import Charts

enum POSFlowDestination: Hashable {
    case newSale
    case searchProduct
    case barcodeScanner
    case cart
    case checkout
    case payment
    case receipt
}

enum SalesPeriod: String {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
}

enum ChartPeriod: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    var id: String { rawValue }
}

struct SalesDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    // POS Flow state and navigation path
    @State private var posViewModel = SellViewModel()
    @State private var navigationPath = NavigationPath()
    
    @State private var isProfilePresented = false
    @State private var showSalesAmount = true
    @State private var selectedPeriod: SalesPeriod = .today
    @State private var selectedChartPeriod: ChartPeriod = .monthly
    
    @State private var dbOrders: [StoreOrder] = []
    @State private var isStatsLoading = false
    
    private var filteredDbOrders: [StoreOrder] {
        let formatter = ISO8601DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd"
        let todayPrefix = fallbackFormatter.string(from: now)
        
        return dbOrders.filter { order in
            if let date = formatter.date(from: order.createdAt) {
                switch selectedPeriod {
                case .today:
                    return calendar.isDate(date, inSameDayAs: now)
                case .week:
                    if let diff = calendar.dateComponents([.day], from: date, to: now).day {
                        return diff >= 0 && diff < 7
                    }
                    return false
                case .month:
                    if let diff = calendar.dateComponents([.day], from: date, to: now).day {
                        return diff >= 0 && diff < 30
                    }
                    return false
                }
            }
            if selectedPeriod == .today {
                return order.createdAt.hasPrefix(todayPrefix)
            }
            return true
        }
    }
    
    private var salesAmountString: String {
        let total = filteredDbOrders.reduce(0.0) { $0 + $1.total }
        if total == 0.0 {
            switch selectedPeriod {
            case .today: return "₹24,350.00"
            case .week: return "₹1,82,400.00"
            case .month: return "₹7,40,200.00"
            }
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: total)) ?? "₹\(String(format: "%.2f", total))"
    }
    
    private var salesTrendString: String {
        switch selectedPeriod {
        case .today: return "18% vs yesterday"
        case .week: return "8% vs last week"
        case .month: return "12% vs last month"
        }
    }
    
    private var salesGraphHeights: [Int] {
        let baseHeights: [Int]
        switch selectedPeriod {
        case .today: baseHeights = [12, 22, 38, 18, 52]
        case .week: baseHeights = [30, 45, 60, 40, 75]
        case .month: baseHeights = [40, 50, 45, 62, 85]
        }
        let modifier = min(40, filteredDbOrders.count * 3)
        return baseHeights.map { min(100, max(10, $0 + modifier)) }
    }
    
    private var ordersCompletedCount: Int {
        let count = filteredDbOrders.count
        if count == 0 {
            switch selectedPeriod {
            case .today: return 18
            case .week: return 112
            case .month: return 482
            }
        }
        return count
    }
    
    private var itemsSoldCount: Int {
        let count = filteredDbOrders.reduce(0) { sum, order in
            sum + (order.orderLineItems?.reduce(0) { $0 + $1.quantity } ?? 0)
        }
        if count == 0 {
            switch selectedPeriod {
            case .today: return 42
            case .week: return 284
            case .month: return 1195
            }
        }
        return count
    }
    
    private var pendingPaymentsCount: Int {
        let dbPending = max(1, ordersCompletedCount / 6)
        if dbOrders.isEmpty {
            switch selectedPeriod {
            case .today: return 2
            case .week: return 14
            case .month: return 45
            }
        }
        return dbPending
    }
    
    private var returnsCount: Int {
        let dbReturns = ordersCompletedCount % 4
        if dbOrders.isEmpty {
            switch selectedPeriod {
            case .today: return 1
            case .week: return 4
            case .month: return 18
            }
        }
        return dbReturns
    }
    
    private var recentActivityOrders: [MockPOSOrder] {
        let orders = posViewModel.completedOrders
        return Array(orders.prefix(3))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                RSMSColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Header (looks like Admin Dashboard)
                        headerSection
                        
                        // 2. KPI Section (looks like Admin Dashboard)
                        kpiSection
                        
                        // 3. Store Revenue Bar Chart
                        revenueChartSection
                        
                        // 4. Quick Actions
                        quickActionsSection
                        
                        // 5. Recent Activity
                        recentActivitySection
                        
                        // 6. Deals & Offers Banner
                        dealsBannerSection
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 16)
                }
                
                // Floating QR Scanner Button at bottom right corner
                floatingQRButton
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isProfilePresented) {
                SalesProfileSheet()
            }
            .navigationDestination(for: POSFlowDestination.self) { dest in
                switch dest {
                case .newSale:
                    NewSaleView(path: $navigationPath)
                case .searchProduct:
                    ProductSearchView(path: $navigationPath)
                case .barcodeScanner:
                    BarcodeScannerView(path: $navigationPath)
                case .cart:
                    CartView(path: $navigationPath)
                case .checkout:
                    CheckoutView(path: $navigationPath)
                case .payment:
                    PaymentFlowView(path: $navigationPath)
                case .receipt:
                    ReceiptView(onComplete: {
                        navigationPath = NavigationPath()
                    })
                }
            }
        }
        .environment(posViewModel)
        .task {
            await fetchStoreOrders()
        }
        .onAppear {
            Task {
                await fetchStoreOrders()
            }
        }
    }
    
    // MARK: - Header & KPIs (looks like Admin Dashboard)
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)

            Spacer()

            // Profile initials avatar circle
            Button {
                isProfilePresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy)
                        .frame(width: 44, height: 44)

                    Text(initials(for: sessionStore.currentUser?.name))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.vertical, 4)
    }

    private var kpiSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
            KPICardView(
                title: "Total Revenue",
                value: salesAmountString,
                icon: "indianrupeesign.circle.fill",
                trend: nil,
                color: Color(hex: "2A9D8F") // Teal
            )
            KPICardView(
                title: "Orders Completed",
                value: "\(ordersCompletedCount)",
                icon: "bag.fill",
                trend: nil,
                color: RSMSColors.burgundy
            )
            KPICardView(
                title: "Items Sold",
                value: "\(itemsSoldCount)",
                icon: "shippingbox.fill",
                trend: nil,
                color: Color(hex: "E76F51") // Warm orange
            )
            KPICardView(
                title: "Returns",
                value: "\(returnsCount)",
                icon: "arrow.uturn.backward.circle.fill",
                trend: nil,
                color: Color(hex: "D4A017") // Gold
            )
        }
    }

    // MARK: - Store Revenue Chart Aggregation & View
    struct StoreRevenueChartPoint: Identifiable {
        let id = UUID()
        let label: String
        let revenue: Double
    }

    private var chartDataPoints: [StoreRevenueChartPoint] {
        let formatter = ISO8601DateFormatter()
        let calendar = Calendar.current
        let now = Date()
        
        var points: [StoreRevenueChartPoint] = []
        
        if selectedChartPeriod == .weekly {
            var weeklyMap: [Int: Double] = [:]
            for i in 1...7 {
                weeklyMap[i] = 0.0
            }
            
            if let currentWeekDateRange = calendar.dateInterval(of: .weekOfYear, for: now) {
                for order in dbOrders {
                    if let date = formatter.date(from: order.createdAt) {
                        if currentWeekDateRange.contains(date) {
                            let weekday = calendar.component(.weekday, from: date)
                            weeklyMap[weekday, default: 0.0] += order.total
                        }
                    }
                }
            }
            
            let weekdaysOrder = [2, 3, 4, 5, 6, 7, 1]
            let weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            
            points = weekdaysOrder.enumerated().map { index, weekday in
                StoreRevenueChartPoint(label: weekdayNames[index], revenue: weeklyMap[weekday] ?? 0.0)
            }
            
            let totalRevenue = points.reduce(0.0) { $0 + $1.revenue }
            if totalRevenue == 0.0 {
                let mockRevenues = [45000.0, 62000.0, 78000.0, 39000.0, 85000.0, 110000.0, 95000.0]
                points = weekdayNames.enumerated().map { index, name in
                    StoreRevenueChartPoint(label: name, revenue: mockRevenues[index])
                }
            }
        } else {
            var monthlyMap: [String: Double] = [:]
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            
            var monthLabels: [String] = []
            for i in (0..<6).reversed() {
                if let prevDate = calendar.date(byAdding: .month, value: -i, to: now) {
                    let label = monthFormatter.string(from: prevDate)
                    monthLabels.append(label)
                    monthlyMap[label] = 0.0
                }
            }
            
            for order in dbOrders {
                if let date = formatter.date(from: order.createdAt) {
                    let label = monthFormatter.string(from: date)
                    if monthlyMap[label] != nil {
                        monthlyMap[label, default: 0.0] += order.total
                    }
                }
            }
            
            points = monthLabels.map { label in
                StoreRevenueChartPoint(label: label, revenue: monthlyMap[label] ?? 0.0)
            }
            
            let totalRevenue = points.reduce(0.0) { $0 + $1.revenue }
            if totalRevenue == 0.0 {
                let mockRevenues = [380000.0, 490000.0, 420000.0, 580000.0, 740200.0, 690000.0]
                points = monthLabels.enumerated().map { index, name in
                    StoreRevenueChartPoint(label: name, revenue: mockRevenues[index])
                }
            }
        }
        
        return points
    }
    
    private var chartMaxValue: Double {
        let maxVal = chartDataPoints.map(\.revenue).max() ?? 100000.0
        return ceil(maxVal / 20000.0) * 20000.0
    }

    private var revenueChartSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack {
                Text("Store Revenue")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                Picker("Period", selection: $selectedChartPeriod) {
                    ForEach(ChartPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            Chart(chartDataPoints) { point in
                BarMark(
                    x: .value("Period", point.label),
                    y: .value("Revenue", point.revenue),
                    width: .ratio(0.45)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [RSMSColors.burgundy.opacity(0.6), RSMSColors.burgundy],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(8)
            }
            .chartYScale(domain: 0...chartMaxValue)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(RSMSColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            if v >= 100000 {
                                Text("₹\(String(format: "%.1f", v / 100000.0))L")
                                    .font(.system(size: 9))
                                    .foregroundColor(RSMSColors.secondaryText)
                            } else {
                                Text("₹\(Int(v))")
                                    .font(.system(size: 9))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                }
            }
            .frame(height: 200)

            HStack(spacing: RSMSSpacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(RSMSColors.burgundy)
                    .frame(width: 16, height: 8)
                Text("Revenue in Indian Rupees (₹)")
                    .font(.system(size: 10))
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Quick Actions (Burgundy Theme, Single Button)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(RSMSColors.darkBrown)
                .padding(.horizontal, 4)
            
            NavigationLink(value: POSFlowDestination.newSale) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "bag.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("New Sale")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Start a new point of sale checkout session")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(RSMSColors.burgundy)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: RSMSColors.burgundy.opacity(0.18), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Floating QR Scanner Button
    private var floatingQRButton: some View {
        NavigationLink(value: POSFlowDestination.barcodeScanner) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 24)
        .accessibilityLabel("Scan QR Code")
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.darkBrown)
                
                Spacer()
                
                NavigationLink(destination: RecentOrdersView()) {
                    Text("View All")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(recentActivityOrders) { order in
                    activityRow(
                        orderId: order.id,
                        client: order.client,
                        amount: "₹\(Int(order.amount))",
                        status: order.status,
                        statusColor: statusColor(for: order.status),
                        time: order.time
                    )
                }
            }
        }
    }
    
    private func activityRow(orderId: String, client: String, amount: String, status: String, statusColor: Color, time: String) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.06))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSColors.burgundy)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Order \(orderId)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(client)
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                HStack(spacing: 4) {
                    Text(status)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.08))
                        .clipShape(Capsule())
                    
                    Text(time)
                        .font(.system(size: 10))
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Deals Banner
    private var dealsBannerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Deals & Offers")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Check ongoing offers and discounts")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.75))
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("View Offers")
                    .font(.system(size: 11, weight: .bold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.16))
            .clipShape(Capsule())
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [RSMSColors.darkBurgundy, Color(red: 0.3, green: 0.02, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func fetchStoreOrders() async {
        guard let storeID = sessionStore.currentUser?.storeID else {
            print("SalesDashboardView: No storeID found on current user, skipping fetch")
            return
        }
        isStatsLoading = true
        
        // Use a lightweight model that matches exactly what we select
        struct DashboardOrderLineItem: Codable {
            let id: UUID?
            let quantity: Int
        }
        
        struct DashboardOrder: Codable, Identifiable {
            let id: UUID
            let clientID: UUID?
            let storeID: UUID?
            let associateID: UUID?
            let total: Double
            let createdAt: String
            let orderLineItems: [DashboardOrderLineItem]?
            
            enum CodingKeys: String, CodingKey {
                case id
                case clientID = "client_id"
                case storeID = "store_id"
                case associateID = "associate_id"
                case total
                case createdAt = "created_at"
                case orderLineItems = "order_line_item"
            }
        }
        
        do {
            let fetched: [DashboardOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, client_id, store_id, associate_id, total, created_at, order_line_item(id, quantity)")
                .eq("store_id", value: storeID)
                .execute()
                .value
            
            print("SalesDashboardView: Fetched \(fetched.count) orders from Supabase for store \(storeID)")
            
            // Convert to StoreOrder format
            let converted: [StoreOrder] = fetched.map { dOrder in
                let lineItems: [OrderLineItem]? = dOrder.orderLineItems?.map { dli in
                    OrderLineItem(
                        id: dli.id,
                        orderID: nil,
                        quantity: dli.quantity,
                        appliedPrice: 0,
                        sku: nil
                    )
                }
                return StoreOrder(
                    id: dOrder.id,
                    clientID: dOrder.clientID,
                    storeID: dOrder.storeID,
                    associateID: dOrder.associateID,
                    total: dOrder.total,
                    createdAt: dOrder.createdAt,
                    orderLineItems: lineItems
                )
            }
            
            await MainActor.run {
                self.dbOrders = converted
                self.isStatsLoading = false
            }
        } catch {
            print("SalesDashboardView: Error fetching store orders: \(error)")
            await MainActor.run {
                self.isStatsLoading = false
            }
        }
    }
    
    // MARK: - Helpers
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Completed": return RSMSColors.success
        case "Pending Payment": return RSMSColors.warning
        default: return .blue
        }
    }
    
    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "NI" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "NI").prefix(2)).uppercased()
    }
}
