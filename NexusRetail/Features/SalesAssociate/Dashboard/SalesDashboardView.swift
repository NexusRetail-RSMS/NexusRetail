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
                RSMSColors.background.ignoresSafeArea()

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
            .sheet(isPresented: $isProfilePresented) { AdminProfileSheet() }
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
                case .exchangePayment, .exchangeSummary:
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
                .foregroundColor(RSMSColors.primaryText)
            Spacer()
            Button { isProfilePresented = true } label: {
                ZStack {
                    Circle().fill(RSMSColors.burgundy).frame(width: 44, height: 44)
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
                KPICardView(title: "Orders Completed",  value: "\(vm.ordersCompletedCount)",  icon: "bag.fill",                    trend: nil, color: RSMSColors.burgundy)
                KPICardView(title: "Items Sold",        value: "\(vm.itemsSoldCount)",         icon: "shippingbox.fill",            trend: nil, color: Color(hex: "E76F51"))
            }
        }
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
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: RSMSColors.darkBurgundy.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Revenue Chart
    private var revenueChartSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack {
                Text("Store Revenue")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)
                Spacer()
                Picker("Period", selection: $vm.selectedChartPeriod) {
                    ForEach(ChartPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            Chart(vm.chartDataPoints) { point in
                BarMark(x: .value("Period", point.label), y: .value("Revenue", point.revenue), width: .ratio(0.45))
                    .foregroundStyle(LinearGradient(colors: [RSMSColors.burgundy.opacity(0.6), RSMSColors.burgundy], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(8)
            }
            .chartYScale(domain: 0...vm.chartMaxValue)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(RSMSColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v >= 100000 ? "₹\(String(format: "%.1f", v / 100000))L" : "₹\(Int(v))")
                                .font(.system(size: 9)).foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                }
            }
            .frame(height: 200)

            HStack(spacing: RSMSSpacing.sm) {
                RoundedRectangle(cornerRadius: 2).fill(RSMSColors.burgundy).frame(width: 16, height: 8)
                Text("Revenue in Indian Rupees (₹)").font(.system(size: 10)).foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
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
