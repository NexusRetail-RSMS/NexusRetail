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
                        quickActionsSection
                        recentActivitySection
                        dealsBannerSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 16)
                }

                floatingQRButton
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isProfilePresented) { SalesProfileSheet() }
            .navigationDestination(for: POSFlowDestination.self) { dest in
                switch dest {
                case .newSale:       NewSaleView(path: $navigationPath)
                case .searchProduct: ProductSearchView(path: $navigationPath)
                case .barcodeScanner: BarcodeScannerView(path: $navigationPath)
                case .cart:          CartView(path: $navigationPath)
                case .checkout:      CheckoutView(path: $navigationPath)
                case .payment:       PaymentFlowView(path: $navigationPath)
                case .receipt:
                    ReceiptView(onComplete: { navigationPath = NavigationPath() })
                }
            }
        }
        .environment(posViewModel)
        .task { await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID) }
        .onAppear { Task { await vm.fetchStoreOrders(storeID: sessionStore.currentUser?.storeID) } }
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
                    Text(salesInitials(for: sessionStore.currentUser?.name))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.vertical, 4)
    }

    // MARK: - KPI Cards
    private var kpiSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
            KPICardView(title: "Total Revenue",     value: vm.salesAmountString,         icon: "indianrupeesign.circle.fill", trend: nil, color: Color(hex: "2A9D8F"))
            KPICardView(title: "Orders Completed",  value: "\(vm.ordersCompletedCount)",  icon: "bag.fill",                    trend: nil, color: RSMSColors.burgundy)
            KPICardView(title: "Items Sold",        value: "\(vm.itemsSoldCount)",         icon: "shippingbox.fill",            trend: nil, color: Color(hex: "E76F51"))
            KPICardView(title: "Returns",           value: "\(vm.returnsCount)",           icon: "arrow.uturn.backward.circle.fill", trend: nil, color: Color(hex: "D4A017"))
        }
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

    // MARK: - Quick Actions (single burgundy button)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(RSMSColors.darkBrown)
                .padding(.horizontal, 4)

            NavigationLink(value: POSFlowDestination.newSale) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                        Image(systemName: "bag.fill").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("New Sale").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Text("Start a new point of sale checkout session").font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.8))
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

    // MARK: - Floating QR Button
    private var floatingQRButton: some View {
        NavigationLink(value: POSFlowDestination.barcodeScanner) {
            ZStack {
                Circle().fill(Color.red).frame(width: 60, height: 60)
                    .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                Image(systemName: "qrcode.viewfinder").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
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
                    Text("View All").font(.system(size: 12, weight: .bold)).foregroundColor(RSMSColors.burgundy)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(Array(posViewModel.completedOrders.prefix(3))) { order in
                    activityRow(
                        orderId: order.id,
                        client: order.client,
                        amount: "₹\(Int(order.amount))",
                        status: order.status,
                        statusColor: vm.statusColor(for: order.status),
                        time: order.time
                    )
                }
            }
        }
    }

    private func activityRow(orderId: String, client: String, amount: String, status: String, statusColor: Color, time: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(RSMSColors.burgundy.opacity(0.06)).frame(width: 40, height: 40)
                Image(systemName: "shippingbox.fill").font(.system(size: 15)).foregroundColor(RSMSColors.burgundy)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Order \(orderId)").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(RSMSColors.primaryText)
                Text(client).font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount).font(.system(size: 13, weight: .bold)).foregroundColor(RSMSColors.primaryText)
                HStack(spacing: 4) {
                    Text(status).font(.system(size: 9, weight: .bold)).foregroundColor(statusColor)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(statusColor.opacity(0.08)).clipShape(Capsule())
                    Text(time).font(.system(size: 10)).foregroundColor(RSMSColors.secondaryText.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }

    // MARK: - Deals Banner
    private var dealsBannerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "tag.fill").font(.system(size: 16)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Deals & Offers").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text("Check ongoing offers and discounts").font(.system(size: 11)).foregroundColor(.white.opacity(0.75))
            }
            Spacer()
            HStack(spacing: 4) {
                Text("View Offers").font(.system(size: 11, weight: .bold))
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.white.opacity(0.16)).clipShape(Capsule())
        }
        .padding(16)
        .background(LinearGradient(colors: [RSMSColors.darkBurgundy, Color(red: 0.3, green: 0.02, blue: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
