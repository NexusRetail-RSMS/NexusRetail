import SwiftUI

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
    
    private var salesAmountString: String {
        switch selectedPeriod {
        case .today: return "₹24,350.00"
        case .week: return "₹1,82,400.00"
        case .month: return "₹7,40,200.00"
        }
    }
    
    private var salesTrendString: String {
        switch selectedPeriod {
        case .today: return "18% vs yesterday"
        case .week: return "8% vs last week"
        case .month: return "12% vs last month"
        }
    }
    
    private var salesGraphHeights: [Int] {
        switch selectedPeriod {
        case .today: return [12, 22, 38, 18, 52]
        case .week: return [30, 45, 60, 40, 75]
        case .month: return [40, 50, 45, 62, 85]
        }
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
            kpiCard(title: "Orders Completed", value: "18", trend: "+12% vs yesterday", isTrendUp: true, icon: "bag.fill", color: .purple)
            kpiCard(title: "Pending Payments", value: "2", trend: "-2 vs yesterday", isTrendUp: false, icon: "creditcard.fill", color: .orange)
            kpiCard(title: "Items Sold", value: "42", trend: "+8% vs yesterday", isTrendUp: true, icon: "shippingbox.fill", color: .blue)
            kpiCard(title: "Returns", value: "1", trend: "+1 vs yesterday", isTrendUp: true, icon: "arrow.uturn.backward.circle.fill", color: .red)
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
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
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
                
                // 3. Search Product
                NavigationLink(value: POSFlowDestination.searchProduct) {
                    quickActionCard(title: "Search Product", subtitle: "Search by name or code", icon: "magnifyingglass", color: .purple)
                }
                .buttonStyle(.plain)
                
                // 4. Client Directory
                NavigationLink(destination: SalesAssociateDashboardView()) {
                    quickActionCard(title: "Client Directory", subtitle: "Manage client profiles", icon: "person.2.fill", color: .green)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.08))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(RSMSColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
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
