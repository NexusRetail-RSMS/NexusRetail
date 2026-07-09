import SwiftUI
import Supabase
import CoreImage.CIFilterBuiltins

struct ReceiptView: View {
    @Environment(AppTheme.self) private var theme
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
    @State private var cachedFullOrderId: String = ""   // full UUID, encoded in the QR
    @State private var cachedClientName: String? = nil
    @State private var cachedPaymentMethod: String = ""

    // Fetched from DB
    @State private var storeName: String = "NexusRetail"

    @State private var generatedReceiptImage: UIImage? = nil
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

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
                    .background(theme.success)
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
                    cachedFullOrderId = oid.uuidString
                } else {
                    cachedOrderId = "ORD-\(Int(Date().timeIntervalSince1970))"
                    cachedFullOrderId = ""
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
        .background(LinearGradient(colors: [theme.burgundy, theme.darkBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(HeaderCurve())
    }

    // MARK: - Paper Receipt
    private var paperReceiptView: some View {
        VStack(spacing: 16) {
            // Branding
            VStack(spacing: 4) {
                Text("NEXUS RETAIL")
                    .font(.system(size: 16, weight: .black)).foregroundColor(theme.primaryText).kerning(2.0)
                Text("Official Store Receipt")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(theme.secondaryText)
                Text(storeName)
                    .font(.system(size: 12)).foregroundColor(theme.secondaryText)
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
                                .font(.system(size: 13, weight: .bold)).foregroundColor(theme.primaryText)
                            HStack(spacing: 8) {
                                Text("SKU: \(item.product.sku)")
                                    .font(.system(size: 11)).foregroundColor(theme.secondaryText)
                                Text("Qty: \(item.count)")
                                    .font(.system(size: 11, weight: .semibold)).foregroundColor(theme.secondaryText)
                            }
                        }
                        Spacer()
                        Text(formatIndianCurrency(item.product.price * Double(item.count)))
                            .font(.system(size: 13, weight: .bold)).foregroundColor(theme.primaryText)
                    }
                }
            }

            dashedDivider

            // Totals
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal").font(.system(size: 13)).foregroundColor(theme.secondaryText)
                    Spacer()
                    Text(formatIndianCurrency(cachedSubtotal)).font(.system(size: 13, weight: .bold)).foregroundColor(theme.primaryText)
                }
                HStack {
                    Text("GST (18% incl.)").font(.system(size: 13)).foregroundColor(theme.secondaryText)
                    Spacer()
                    Text(formatIndianCurrency(cachedTotal * 0.18)).font(.system(size: 13)).foregroundColor(theme.secondaryText)
                }
                HStack {
                    Text("Total Paid").font(.system(size: 16, weight: .bold)).foregroundColor(theme.primaryText)
                    Spacer()
                    Text(formatIndianCurrency(cachedTotal)).font(.system(size: 18, weight: .black)).foregroundColor(theme.burgundy)
                }
            }
            .padding(.bottom, 10)

            // QR code — scanned at After Sales to pull up this order for repair/exchange.
            if !cachedFullOrderId.isEmpty {
                dashedDivider
                VStack(spacing: 6) {
                    if let qr = qrImage(for: "nexus://invoice/\(cachedFullOrderId)") {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 110, height: 110)
                    }
                    Text("Scan for service, returns & exchange")
                        .font(.system(size: 9)).foregroundColor(theme.secondaryText)
                }
                .padding(.top, 6)
            }

            // Footer
            VStack(spacing: 2) {
                Text("Thank you for shopping at Nexus Retail")
                    .font(.system(size: 10)).foregroundColor(theme.secondaryText)
                Text("For returns & exchanges visit any store within 30 days")
                    .font(.system(size: 9)).foregroundColor(theme.secondaryText.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(theme.cardBackground)
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

    /// Generates a QR code image for the given string (used to embed the order link).
    private func qrImage(for string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func receiptMetaRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(theme.secondaryText)
            Spacer()
            Text(value).font(.system(size: 12, weight: .bold)).foregroundColor(theme.primaryText)
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
