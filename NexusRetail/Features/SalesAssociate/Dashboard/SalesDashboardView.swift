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
    @State private var isProfilePresented = false
    @Namespace private var namespace

    // ViewModel
    @State private var vm = SalesDashboardViewModel()

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
            .sheet(isPresented: $isProfilePresented) { AdminProfileSheet().environment(theme) }
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
                case .exchangeProduct, .exchangePayment, .exchangeSummary:
                    EmptyView()
                }
            }
        }
        .environment(posViewModel)
        .refreshable {
            await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
        }
        .task { await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id) }
        .onAppear {
            // Refresh data when view appears (e.g., after completing a sale)
            Task { await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id) }
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
            Button { isProfilePresented = true } label: {
                ZStack {
                    Circle().fill(theme.isDarkMode ? Color(hex: "2C0000") : RSMSColors.burgundy).frame(width: 44, height: 44)
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
                themedKPICard(title: "Items Sold",       value: "\(vm.itemsSoldCount)",        icon: "shippingbox.fill", color: theme.isDarkMode ? RSMSColors.antiqueGold : Color(hex: "C0763A"))
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

    // MARK: - Revenue Chart
    private var revenueChartSection: some View {
        let accentColor = theme.isDarkMode ? RSMSColors.antiqueGold : RSMSColors.burgundy
        let cardBg: Color = theme.isDarkMode ? Color(hex: "1A0A0A") : Color.white
        let barGradient: [Color] = theme.isDarkMode
            ? [RSMSColors.antiqueGold.opacity(0.55), RSMSColors.antiqueGold]
            : [RSMSColors.burgundy.opacity(0.6), RSMSColors.burgundy]

        return VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack {
                Text("Store Revenue")
                    .font(RSMSFonts.headline)
                    .foregroundColor(theme.primaryText)
                Spacer()
                // ── Custom pill toggle (replaces segmented Picker) ──
                periodToggle(accentColor: accentColor)
            }

            Chart(vm.chartDataPoints) { point in
                BarMark(x: .value("Period", point.label), y: .value("Revenue", point.revenue), width: .ratio(0.45))
                    .foregroundStyle(LinearGradient(colors: barGradient, startPoint: .top, endPoint: .bottom))
                    .cornerRadius(8)
            }
            .chartYScale(domain: 0...vm.chartMaxValue)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(theme.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v >= 100000 ? "₹\(String(format: "%.1f", v / 100000))L" : "₹\(Int(v))")
                                .font(.system(size: 9))
                                .foregroundColor(theme.secondaryText)
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
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                }
            }
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
                : RSMSColors.burgundy.opacity(0.08)
        )
        .clipShape(Capsule())
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
