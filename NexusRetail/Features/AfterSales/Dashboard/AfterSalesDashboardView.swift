//
//  AfterSalesDashboardView.swift
//  NexusRetail
//

import SwiftUI
import Charts

struct AfterSalesDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    // POS navigation state
    @State private var posViewModel    = SellViewModel()
    @State private var navigationPath  = NavigationPath()
    @Namespace private var namespace

    @State private var vm = AfterSalesDashboardViewModel()
    @State private var isProfilePresented = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                RSMSColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        kpiSection
                        serviceTrendChartSection
                        serviceStatusDonutSection
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
            .sheet(isPresented: $isProfilePresented) {
                AdminProfileSheet()
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
                case .invoiceScanner:
                    if #available(iOS 18.0, *) {
                        InvoiceScannerView(path: $navigationPath)
                            .navigationTransition(.zoom(sourceID: "scannerButton", in: namespace))
                    } else {
                        InvoiceScannerView(path: $navigationPath)
                    }
                case .invoiceItemsSelection(let invoiceId):
                    InvoiceItemsSelectionView(path: $navigationPath, invoiceId: invoiceId)
                case .actionSelection(let invoiceId, let selectedItem, let storeId):
                    AfterSalesActionSelectionView(path: $navigationPath, invoiceId: invoiceId, selectedItem: selectedItem, storeId: storeId)
                        .navigationTransition(.zoom(sourceID: "scannerButton", in: namespace))
                    
                case .repairForm(let invoiceId, let selectedItem, let warrantyMonths, let storeId):
                    AfterSalesRepairFormView(path: $navigationPath, invoiceId: invoiceId, selectedItem: selectedItem, remainingWarrantyMonths: warrantyMonths, storeId: storeId)
                        .navigationTransition(.zoom(sourceID: "scannerButton", in: namespace))
                    
                case .cart:          CartView(path: $navigationPath)
                case .checkout:      CheckoutView(path: $navigationPath)
                case .payment(let storeId):       
                    PaymentFlowView(path: $navigationPath, storeId: storeId)
                case .receipt:
                    ReceiptView(onComplete: { navigationPath = NavigationPath() })
                case .bopis:
                    BOPISView()
                case .ordersHub:
                    OrdersHubView(path: $navigationPath)
                }
            }
        }
        .environment(posViewModel)
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
                        Text(initials(for: sessionStore.currentUser?.name))
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
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "AS" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AS"
    }
    
    // MARK: - KPI Section
    private var kpiSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
            KPICardView(title: "Pending Service Requests", value: "\(vm.pendingServiceRequests)", icon: "wrench.and.screwdriver.fill", trend: nil, color: RSMSColors.warning)
            KPICardView(title: "Repairs In Progress", value: "\(vm.repairsInProgress)", icon: "hammer.fill", trend: nil, color: Color(hex: "2A9D8F"))
        }
    }
    
    // MARK: - Service Request Trend Chart
    private var serviceTrendChartSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack {
                Text("Service Requests")
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
            
            Chart(vm.serviceRequestChartData) { point in
                BarMark(x: .value("Period", point.label), y: .value("Requests", point.value), width: .ratio(0.45))
                    .foregroundStyle(LinearGradient(colors: [RSMSColors.burgundy.opacity(0.8), RSMSColors.burgundy], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(8)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(RSMSColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))")
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
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Service Status Donut Chart
    private var serviceStatusDonutSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            Text("Service Status")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.primaryText)
            
            Chart(vm.serviceStatusChartData) { point in
                SectorMark(
                    angle: .value("Requests", point.value),
                    innerRadius: .ratio(0.65),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Status", point.label))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                "Pending": Color(hex: "E9C46A"),
                "Repair": Color(hex: "2A9D8F"),
                "Completed": Color(hex: "264653"),
                "Returned": Color(hex: "8A2BE2")
            ])
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        VStack(spacing: 2) {
                            Text("\(vm.totalServiceRequests)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.primaryText)
                            Text("Total")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .frame(height: 220)
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Floating QR Button
    private var floatingQRButton: some View {
        Button {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                navigationPath.append(POSFlowDestination.invoiceScanner)
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
    
}
