import SwiftUI
import Supabase

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

struct SalesDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    // POS Flow state and navigation path
    @State private var posViewModel = SellViewModel()
    @State private var navigationPath = NavigationPath()
    
    @State private var isProfilePresented = false
    @State private var showSalesAmount = true
    @State private var selectedPeriod: SalesPeriod = .today
    
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
            ZStack {
                RSMSColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Welcome Greeting Header
                        welcomeHeaderSection
                        
                        // 2. Today's Sales Banner
                        todaysSalesSection
                        
                        // 3. KPI metrics grid
                        kpiGridSection
                        
                        // 4. Quick Actions
                        quickActionsSection
                        
                        // 5. Recent Activity
                        recentActivitySection
                        
                        // 6. Deals & Offers Banner
                        dealsBannerSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 16)
                }
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
    
    // MARK: - Welcome Greeting
    private var welcomeHeaderSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning,")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
                
                Text("\(sessionStore.currentUser?.name?.components(separatedBy: " ").first ?? "Nirali") 👋")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text("Let's make today great!")
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
            
            // Profile Initials circle
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
    
    // MARK: - Today's Sales Card
    private var todaysSalesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Text("\(selectedPeriod.rawValue)'s Sales")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                    
                    Button {
                        withAnimation {
                            showSalesAmount.toggle()
                        }
                    } label: {
                        Image(systemName: showSalesAmount ? "eye" : "eye.slash")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Dropdown date tag (Menu Selector)
                Menu {
                    Button("Today") { selectedPeriod = .today }
                    Button("This Week") { selectedPeriod = .week }
                    Button("This Month") { selectedPeriod = .month }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPeriod.rawValue)
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(showSalesAmount ? salesAmountString : "••••••")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Trend text
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 11, weight: .bold))
                        Text(salesTrendString)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "34C759")) // Green
                }
                
                Spacer()
                
                // Visual mini bar graph mock
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(salesGraphHeights, id: \.self) { height in
                        barGraphColumn(height: CGFloat(height), opacity: 0.3 + Double(height)/100.0)
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: RSMSColors.burgundy.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    private func barGraphColumn(height: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white.opacity(opacity))
            .frame(width: 8, height: height)
    }
    
    // MARK: - KPI Grid Section
    private var kpiGridSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            kpiCard(title: "Orders Completed", value: "\(ordersCompletedCount)", trend: "+12% vs yesterday", isTrendUp: true, icon: "bag.fill", color: .purple)
            kpiCard(title: "Pending Payments", value: "\(pendingPaymentsCount)", trend: "-2 vs yesterday", isTrendUp: false, icon: "creditcard.fill", color: .orange)
            kpiCard(title: "Items Sold", value: "\(itemsSoldCount)", trend: "+8% vs yesterday", isTrendUp: true, icon: "shippingbox.fill", color: .blue)
            kpiCard(title: "Returns", value: "\(returnsCount)", trend: "+1 vs yesterday", isTrendUp: true, icon: "arrow.uturn.backward.circle.fill", color: .red)
        }
    }
    
    private func kpiCard(title: String, value: String, trend: String, isTrendUp: Bool, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            HStack(spacing: 3) {
                Image(systemName: isTrendUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                Text(trend)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(isTrendUp ? RSMSColors.success : Color.red)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.darkBrown)
                
                Spacer()
                
                Button {
                    // Customize triggers (optional)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Customize")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            Grid(horizontalSpacing: 14, verticalSpacing: 14) {
                GridRow {
                    // 1. New Sale
                    NavigationLink(value: POSFlowDestination.newSale) {
                        quickActionCard(title: "New Sale", subtitle: "Start a new sale", icon: "bag", color: RSMSColors.burgundy)
                    }
                    .buttonStyle(.plain)
                    
                    // 2. Scan Barcode
                    NavigationLink(value: POSFlowDestination.barcodeScanner) {
                        quickActionCard(title: "Scan Barcode", subtitle: "Scan product barcode", icon: "barcode.viewfinder", color: .orange)
                    }
                    .buttonStyle(.plain)
                }
                
                GridRow {
                    // 3. Search Product
                    NavigationLink(value: POSFlowDestination.searchProduct) {
                        quickActionCard(title: "Search Product", subtitle: "Search by name or code", icon: "magnifyingglass", color: .purple, centerAlign: true)
                    }
                    .buttonStyle(.plain)
                    .gridCellColumns(2)
                }
            }
        }
    }
    
    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color, centerAlign: Bool = false) -> some View {
        HStack(spacing: 12) {
            if centerAlign {
                Spacer()
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.08))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: centerAlign ? .center : .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(RSMSColors.secondaryText)
                    .lineLimit(1)
            }
            
            if centerAlign {
                Spacer()
            } else {
                Spacer()
            }
        }
        .padding(14)
        .frame(height: 68) // Fixed height to align all quick actions perfectly
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
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
        guard let storeID = sessionStore.currentUser?.storeID else { return }
        isStatsLoading = true
        do {
            let fetched: [StoreOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, client_id, store_id, associate_id, total, created_at, order_line_item(id, quantity)")
                .eq("store_id", value: storeID)
                .execute()
                .value
            
            await MainActor.run {
                self.dbOrders = fetched
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
