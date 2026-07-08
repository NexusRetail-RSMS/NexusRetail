
//  AfterSalesTabView.swift
//  NexusRetail
//
//  After-Sales shell: Intake, Estimate, Repair, Return, Workload.
//  Styled with the premium RSMS cream and burgundy layout.
//

import SwiftUI

struct AfterSalesTabView: View {
    @State private var selectedTab: Int = 0
    @State private var dashboardPath = NavigationPath()
    @State private var posViewModel = SellViewModel()
    @State private var showScanner = false
    @Namespace private var namespace
    @Environment(AppTheme.self) private var theme



    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                // 1. Dashboard (hosts the after-sales scan/invoice/action flow)
                NavigationStack(path: $dashboardPath) {
                    AfterSalesDashboardView(path: $dashboardPath, namespace: namespace, showScanner: $showScanner)
                        .navigationBarHidden(true)
                        .navigationDestination(for: POSFlowDestination.self) { dest in
                            flowDestination(dest)
                        }
                }
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
                .tag(0)

                // 2. Repairs
                NavigationStack {
                    ActiveRepairsView()
                        .navigationBarHidden(true)
                }
                .tabItem { Label("Repairs", systemImage: "wrench.and.screwdriver.fill") }
                .tag(1)
            }
            .tint(theme.isDarkMode ? theme.antiqueGold : theme.burgundy)
        }
        .environment(theme)
        .environment(posViewModel)
        // Dynamic-island scanner cover with Upload / Enter-invoice options below the camera.
        .qrScanner(isScanning: $showScanner, showInvoiceOptions: true) { code in
            handleScannedInvoice(code)
        }
    }

    private func handleScannedInvoice(_ raw: String) {
        let id = raw.hasPrefix("nexus://invoice/")
            ? raw.replacingOccurrences(of: "nexus://invoice/", with: "")
            : raw
        selectedTab = 0
        dashboardPath.append(POSFlowDestination.invoiceItemsSelection(invoiceId: id))
    }

    // MARK: - Flow destinations (tab bar hidden across the scan flow)

    @ViewBuilder
    private func flowDestination(_ dest: POSFlowDestination) -> some View {
        switch dest {
        case .newSale:       NewSaleView(path: $dashboardPath)
        case .searchProduct: ProductSearchView(path: $dashboardPath)
        case .barcodeScanner:
            BarcodeScannerView(path: $dashboardPath)
                .toolbar(.hidden, for: .tabBar)
        case .invoiceScanner:
            Group {
                if #available(iOS 18.0, *) {
                    InvoiceScannerView(path: $dashboardPath)
                        .navigationTransition(.zoom(sourceID: "scannerButton", in: namespace))
                } else {
                    InvoiceScannerView(path: $dashboardPath)
                }
            }
            .toolbar(.hidden, for: .tabBar)
        case .invoiceItemsSelection(let invoiceId):
            InvoiceItemsSelectionView(path: $dashboardPath, invoiceId: invoiceId)
                .toolbar(.hidden, for: .tabBar)
        case .actionSelection(let invoiceId, let selectedItem, let purchaseDate, let warrantyEndDate, let customer):
            ActionSelectionView(path: $dashboardPath, invoiceId: invoiceId, selectedItem: selectedItem, purchaseDate: purchaseDate, warrantyEndDate: warrantyEndDate, customer: customer)
                .toolbar(.hidden, for: .tabBar)
        case .repairForm(let invoiceId, let selectedItem, let warrantyEndDate):
            AfterSalesRepairFormView(path: $dashboardPath, invoiceId: invoiceId, selectedItem: selectedItem, warrantyEndDate: warrantyEndDate)
                .toolbar(.hidden, for: .tabBar)
        case .afterSalesHistory:
            AfterSalesHistoryView(path: $dashboardPath)
                .toolbar(.hidden, for: .tabBar)
        case .cart:          CartView(path: $dashboardPath)
        case .checkout:      CheckoutView(path: $dashboardPath)
        case .payment:       PaymentFlowView(path: $dashboardPath)
        case .receipt:
            ReceiptView(onComplete: { dashboardPath = NavigationPath() })
        case .bopis:
            BOPISView()
        case .ordersHub:
            OrdersHubView(path: $dashboardPath)
        case .exchangeProduct(let invoiceId, let selectedItemIds):
            ExchangeProductView(path: $dashboardPath, invoiceId: invoiceId, selectedItemIds: selectedItemIds)
        case .exchangePayment(let originalProductId, let replacementProductId, let amount):
            ExchangePaymentView(path: $dashboardPath, originalProductId: originalProductId, replacementProductId: replacementProductId, amount: amount)
        case .exchangeSummary(let originalProductId, let replacementProductId, let amount):
            ExchangeSummaryView(path: $dashboardPath, originalProductId: originalProductId, replacementProductId: replacementProductId, amount: amount)
        }
    }


}

/// A view modifier that applies the common After-Sales toolbar (title + profile button).
struct AfterSalesToolbarModifier: ViewModifier {
    let title: String
    
    @Environment(AppTheme.self) private var theme
    @Environment(SessionStore.self) private var sessionStore
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: GlobalProfileView()) {
                        ZStack {
                            Circle()
                                .fill(theme.burgundy)
                                .frame(width: 32, height: 32)
                            
                            if let urlString = sessionStore.currentUser?.imageUrl, let url = URL(string: urlString) {
                                CachedAsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 32, height: 32)
                                }
                            } else {
                                Text(initials(for: sessionStore.currentUser?.name))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .accessibilityLabel("Profile")
                    .accessibilityHint("Opens your after-sales specialist profile")
                }
            }
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
}

/// A reusable placeholder view for the after-sales associate tabs.
struct AfterSalesPlaceholderView: View {
    @Environment(AppTheme.self) private var theme
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(theme.burgundy)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(RSMSFonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text(message)
                    .font(RSMSFonts.body)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text("Coming Soon")
                    .font(RSMSFonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.burgundy)
                    .cornerRadius(RSMSRadius.small)
            }
        }
    }
}

/// Simple sheet to allow After-Sales Associate to Sign Out
struct AfterSalesProfileSheet: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: RSMSSpacing.xl) {
                    VStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(theme.burgundy)
                        
                        Text(sessionStore.currentUser?.name ?? "After-Sales Specialist")
                            .font(RSMSFonts.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("After-Sales Specialist")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.top, RSMSSpacing.xxl)

                    LanguageSettingsButton()
                        .padding()
                        .background(theme.cardBackground)
                        .cornerRadius(RSMSRadius.large)
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.md)

                    Spacer()
                    
                    Button {
                        dismiss()
                        Task { try? await sessionStore.signOut() }
                    } label: {
                        Text("Sign Out")
                            .font(RSMSFonts.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.error)
                            .cornerRadius(RSMSRadius.medium)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .navigationTitle("Specialist Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(theme.burgundy)
                }
            }
        }
    }
}

#Preview {
    let mockSession = SessionStore()
    return AfterSalesTabView()
        .environment(mockSession)
}
