
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
    @Namespace private var namespace

    // ┌─────────────────────────────────────────────────────────────┐
    // │ SCANNER BUTTON ALIGNMENT — tweak these to position it        │
    // │  • scannerSize    : diameter of the circle                   │
    // │  • scannerOffsetX : + moves RIGHT, − moves LEFT              │
    // │  • scannerOffsetY : + moves DOWN,  − moves UP                │
    // └─────────────────────────────────────────────────────────────┘
    private let scannerSize: CGFloat = 64
    private let scannerOffsetX: CGFloat = -24
    private let scannerOffsetY: CGFloat = 20

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                // 1. Dashboard (hosts the after-sales scan/invoice/action flow)
                NavigationStack(path: $dashboardPath) {
                    AfterSalesDashboardView()
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
                        .navigationTitle("Repairs")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem { Label("Repairs", systemImage: "wrench.and.screwdriver.fill") }
                .tag(1)
            }
            .tint(RSMSColors.burgundy)

            // Scanner button sits on the same line as the native tab bar, to its right.
            // Hidden while a scan/invoice/action screen is pushed.
            if dashboardPath.isEmpty {
                scannerButton
                    .padding(.trailing, 12)
                    .padding(.bottom, 4)
                    .offset(x: scannerOffsetX, y: scannerOffsetY)
            }
        }
        .environment(posViewModel)
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
        case .cart:          CartView(path: $dashboardPath)
        case .checkout:      CheckoutView(path: $dashboardPath)
        case .payment:       PaymentFlowView(path: $dashboardPath)
        case .receipt:
            ReceiptView(onComplete: { dashboardPath = NavigationPath() })
        case .bopis:
            BOPISView()
        case .ordersHub:
            OrdersHubView(path: $dashboardPath)
        }
    }

    // MARK: - Scanner button (beside the tab bar)

    private var scannerButton: some View {
        Group {
            if #available(iOS 18.0, *) {
                scannerButtonLabel
                    .matchedTransitionSource(id: "scannerButton", in: namespace)
            } else {
                scannerButtonLabel
            }
        }
    }

    private var scannerButtonLabel: some View {
        // Separate frosted circle beside the native tab bar (GitHub Copilot-style),
        // matching the tab bar's material, height, and vertical position.
        Button {
            selectedTab = 0
            dashboardPath.append(POSFlowDestination.invoiceScanner)
        } label: {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: scannerSize * 0.38, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: scannerSize, height: scannerSize)
                .background(RSMSColors.burgundy, in: Circle())
                .shadow(color: RSMSColors.burgundy.opacity(0.35), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan bill")
    }
}

/// A view modifier that applies the common After-Sales toolbar (title + profile button).
struct AfterSalesToolbarModifier: ViewModifier {
    let title: String
    
    @Environment(SessionStore.self) private var sessionStore
    @State private var isProfilePresented = false
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isProfilePresented = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(RSMSColors.burgundy)
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
            .sheet(isPresented: $isProfilePresented) {
                AdminProfileSheet()
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
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(RSMSColors.burgundy)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(RSMSFonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(message)
                    .font(RSMSFonts.body)
                    .foregroundColor(RSMSColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text("Coming Soon")
                    .font(RSMSFonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSColors.burgundy)
                    .cornerRadius(RSMSRadius.small)
            }
        }
    }
}

/// Simple sheet to allow After-Sales Associate to Sign Out
struct AfterSalesProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: RSMSSpacing.xl) {
                    VStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(RSMSColors.burgundy)
                        
                        Text(sessionStore.currentUser?.name ?? "After-Sales Specialist")
                            .font(RSMSFonts.title)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)
                        
                        Text("After-Sales Specialist")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    .padding(.top, RSMSSpacing.xxl)
                    
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
                            .background(RSMSColors.error)
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
                    .foregroundColor(RSMSColors.burgundy)
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
