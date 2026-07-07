import SwiftUI
import Supabase

struct ReceiptView: View {
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore

    var onComplete: (() -> Void)? = nil

    @State private var email = ""
    @State private var phone = ""
    @State private var showShareToast = false
    @State private var isSaving = false

    // Cached state — prevents SwiftUI re-renders resetting values after resetFlow()
    @State private var cachedItems: [POSProduct] = []
    @State private var cachedTotal: Double = 0.0
    @State private var cachedSubtotal: Double = 0.0
    @State private var cachedOrderId: String = ""
    @State private var cachedClientName: String? = nil
    @State private var cachedPaymentMethod: String = ""

    // Fetched from DB
    @State private var storeName: String = "NexusRetail"

    @State private var generatedReceiptImage: UIImage? = nil
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    customHeaderSection

                    VStack(spacing: 28) {
                        paperReceiptView.padding(.top, 10)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)

            if showShareToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                        Text("Digital receipt shared successfully!")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 24)
                    .background(RSMSColors.success)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .padding(.bottom, 36)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // Cache immediately before viewModel.resetFlow() is ever called
            if cachedItems.isEmpty {
                cachedItems    = viewModel.cartItems
                cachedTotal    = viewModel.totalAmount
                cachedSubtotal = viewModel.subtotalAmount
                cachedClientName    = viewModel.selectedClient
                cachedPaymentMethod = viewModel.selectedPaymentMethod.rawValue
                if let oid = viewModel.lastOrderId {
                    cachedOrderId = "ORD-\(oid.uuidString.prefix(8).uppercased())"
                } else {
                    cachedOrderId = "ORD-\(Int(Date().timeIntervalSince1970))"
                }
            }
        }
        .task {
            // Fetch real store name from DB
            if let storeID = sessionStore.currentUser?.storeID {
                struct StoreRow: Decodable { let name: String }
                if let rows: [StoreRow] = try? await SupabaseManager.shared.client
                    .from("store")
                    .select("name")
                    .eq("id", value: storeID)
                    .execute()
                    .value,
                   let first = rows.first {
                    storeName = first.name
                }
            }
            
            // Send email receipt automatically in background
            let targetEmail = viewModel.receiptSharedEmail
            if !targetEmail.isEmpty && !viewModel.isReceiptShared {
                viewModel.isReceiptShared = true
                await viewModel.sendReceiptEmail(
                    to: targetEmail,
                    orderId: cachedOrderId,
                    storeName: storeName,
                    cashierName: sessionStore.currentUser?.name ?? "Sales Associate",
                    items: groupedCachedItems,
                    total: cachedTotal,
                    subtotal: cachedSubtotal
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = generatedReceiptImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .top) {
            // Save/Download Receipt (Left)
            Button { shareReceipt() } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            
            VStack(spacing: 2) {
                Text("Transaction Complete")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text("Payment Authorized")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 4)
            
            Spacer()

            // Complete Sale (Right)
            Button { completeSale() } label: {
                if isSaving {
                    ProgressView().tint(.white).frame(width: 44, height: 44)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(HeaderCurve())
    }

    // MARK: - Paper Receipt
    private var paperReceiptView: some View {
        VStack(spacing: 16) {
            // Branding
            VStack(spacing: 4) {
                Text("NEXUS RETAIL")
                    .font(.system(size: 16, weight: .black)).foregroundColor(RSMSColors.primaryText).kerning(2.0)
                Text("Official Store Receipt")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(RSMSColors.secondaryText)
                Text(storeName)
                    .font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
            }
            .padding(.top, 10)

            dashedDivider

            // Order meta
            VStack(spacing: 6) {
                receiptMetaRow(label: "Order ID", value: cachedOrderId)
                receiptMetaRow(label: "Date",     value: Date.now.formatted(date: .abbreviated, time: .shortened))
                receiptMetaRow(label: "Cashier",  value: sessionStore.currentUser?.name ?? "Sales Associate")
                if let client = cachedClientName {
                    receiptMetaRow(label: "Customer", value: client)
                }
                receiptMetaRow(label: "Payment",  value: cachedPaymentMethod)
            }

            dashedDivider

            // Line items
            VStack(spacing: 10) {
                ForEach(groupedCachedItems, id: \.product.id) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.product.name)
                                .font(.system(size: 13, weight: .bold)).foregroundColor(RSMSColors.primaryText)
                            HStack(spacing: 8) {
                                Text("SKU: \(item.product.sku)")
                                    .font(.system(size: 11)).foregroundColor(RSMSColors.secondaryText)
                                Text("Qty: \(item.count)")
                                    .font(.system(size: 11, weight: .semibold)).foregroundColor(RSMSColors.secondaryText)
                            }
                        }
                        Spacer()
                        Text(formatIndianCurrency(item.product.price * Double(item.count)))
                            .font(.system(size: 13, weight: .bold)).foregroundColor(RSMSColors.primaryText)
                    }
                }
            }

            dashedDivider

            // Totals
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal").font(.system(size: 13)).foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                    Text(formatIndianCurrency(cachedSubtotal)).font(.system(size: 13, weight: .bold)).foregroundColor(RSMSColors.primaryText)
                }
                HStack {
                    Text("GST (18% incl.)").font(.system(size: 13)).foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                    Text(formatIndianCurrency(cachedTotal * 0.18)).font(.system(size: 13)).foregroundColor(RSMSColors.secondaryText)
                }
                HStack {
                    Text("Total Paid").font(.system(size: 16, weight: .bold)).foregroundColor(RSMSColors.primaryText)
                    Spacer()
                    Text(formatIndianCurrency(cachedTotal)).font(.system(size: 18, weight: .black)).foregroundColor(RSMSColors.burgundy)
                }
            }
            .padding(.bottom, 10)

            // Footer
            VStack(spacing: 2) {
                Text("Thank you for shopping at Nexus Retail")
                    .font(.system(size: 10)).foregroundColor(RSMSColors.secondaryText)
                Text("For returns & exchanges visit any store within 30 days")
                    .font(.system(size: 9)).foregroundColor(RSMSColors.secondaryText.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var dashedDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.25))
            .frame(height: 1)
            .padding(.horizontal, 4)
    }

    private func receiptMetaRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
            Spacer()
            Text(value).font(.system(size: 12, weight: .bold)).foregroundColor(RSMSColors.primaryText)
        }
    }


    
    private var groupedCachedItems: [(product: POSProduct, count: Int)] {
        var counts: [UUID: Int] = [:]
        var uniqueProducts: [POSProduct] = []
        for item in cachedItems {
            if counts[item.id] == nil { uniqueProducts.append(item); counts[item.id] = 1 }
            else { counts[item.id]! += 1 }
        }
        return uniqueProducts.map { ($0, counts[$0.id] ?? 1) }
    }

    // MARK: - Actions
    @MainActor
    private func shareReceipt() {
        let renderer = ImageRenderer(content: paperReceiptView.frame(width: 350))
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            generatedReceiptImage = image
            showShareSheet = true
        } else {
            withAnimation { showShareToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { self.showShareToast = false }
            }
        }
    }

    private func completeSale() {
        isSaving = true
        Task {
            // DB write already happened in PaymentFlowView via processCheckout().
            // Refresh in-memory product stock from DB so next scan shows updated values.
            await POSProductRepository.shared.refreshStockForStore(
                storeID: sessionStore.currentUser?.storeID
            )

            await MainActor.run {
                isSaving = false
                viewModel.resetFlow()
                onComplete?()
            }
        }
    }
}

// MARK: - Share Sheet
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
