import SwiftUI
import Supabase

struct InvoiceItemsSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    let invoiceId: String
    
    @State private var items: [POSProduct] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var fetchedStoreId: UUID? = nil
    @State private var fetchedClientId: UUID? = nil
    
    @State private var selectedItemId: UUID? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                RSMSColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select item to process")
                            .font(.system(size: 14, weight: .medium))
                            .textCase(.uppercase)
                            .foregroundColor(RSMSColors.secondaryText.opacity(0.8))
                            .padding(.horizontal, RSMSSpacing.lg)
                            .padding(.bottom, 4)
                        
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Fetching Invoice...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding(.bottom, 120)
                        } else if let errorMessage = errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.system(size: 15))
                                    .foregroundColor(RSMSColors.primaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding(.bottom, 120)
                        } else if items.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 32))
                                    .foregroundColor(RSMSColors.secondaryText)
                                Text("No items found in this invoice")
                                    .font(.system(size: 15))
                                    .foregroundColor(RSMSColors.primaryText)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding(.bottom, 120)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(items) { item in
                                    itemRow(item)
                                }
                            }
                            .padding(.horizontal, RSMSSpacing.lg)
                            .padding(.bottom, 120) // Give space for bottom bar
                        }
                    }
                    .padding(.top, 150) // Give space for header
                }
                .ignoresSafeArea(edges: .top)
                
                customHeaderSection
            }
            
            // Bottom Action Bar
            bottomActionBar
        }
        .navigationBarHidden(true)
        .task {
            await fetchInvoiceItems()
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Invoice Item")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(invoiceId)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .ignoresSafeArea(edges: .top)
    }
    
    private func itemRow(_ item: POSProduct) -> some View {
        let isSelected = selectedItemId == item.id
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedItemId = nil
                } else {
                    selectedItemId = item.id
                }
            }
        } label: {
            HStack(spacing: 16) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? RSMSColors.burgundy : RSMSColors.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(RSMSColors.burgundy)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Product Image
                AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                            .overlay(Image(systemName: "shippingbox").foregroundColor(.gray))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(item.category) • Size: \(item.size)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Text(formatIndianCurrency(item.price))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                }
                
                Spacer()
            }
            .padding(16)
            .background(RSMSColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? RSMSColors.burgundy : RSMSColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack {
            Button {
                if let selectedId = selectedItemId, let selectedItem = items.first(where: { $0.id == selectedId }) {
                    path.append(POSFlowDestination.actionSelection(invoiceId: invoiceId, selectedItem: selectedItem, storeId: fetchedStoreId, clientId: fetchedClientId))
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedItemId == nil ? RSMSColors.secondaryText.opacity(0.5) : RSMSColors.burgundy)
                    .cornerRadius(12)
            }
            .disabled(selectedItemId == nil)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.bottom, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Data Fetching
    private func fetchInvoiceItems() async {
        guard let invoiceUUID = UUID(uuidString: invoiceId) else {
            await MainActor.run {
                self.errorMessage = "Invalid invoice format."
                self.isLoading = false
            }
            return
        }
        
        do {
            let fetchedOrders: [StoreOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, store_id, total, created_at, client_id, client(name), order_line_item(id, quantity, applied_price, products(item_id, item_name, category, sku_code, price, pexels_page, image_url))")
                .eq("id", value: invoiceUUID)
                .execute()
                .value
            
            guard let order = fetchedOrders.first else {
                await MainActor.run {
                    self.errorMessage = "Invoice not found."
                    self.isLoading = false
                }
                return
            }
            
            // Store the client ID to pass down the flow
            let clientId = order.clientID
            
            var mappedItems: [POSProduct] = []
            
            if let lineItems = order.orderLineItems {
                for item in lineItems {
                    if let nested = item.products {
                        let sizes = ["S", "M", "L", "XL"]
                        let randomSize = sizes.randomElement() ?? "S"
                        
                        // Extract image from pexels_page or fallback to image_url
                        let pexelsImageUrl = POSProductRepository.shared.extractPexelsImageUrl(from: nested.pexelsPage ?? "") ?? nested.imageUrl
                        
                        let product = POSProduct(
                            id: item.id ?? UUID(),
                            itemId: nested.itemId ?? 0,
                            name: nested.itemName ?? "Unknown Item",
                            sku: nested.skuCode ?? "SKU-\(nested.itemId ?? 0)",
                            category: nested.category ?? "General",
                            price: item.appliedPrice ?? nested.price ?? 0.0,
                            stock: item.quantity,
                            size: randomSize,
                            imageUrl: pexelsImageUrl
                        )
                        mappedItems.append(product)
                    }
                }
            }
            
            await MainActor.run {
                self.items = mappedItems
                self.fetchedStoreId = order.storeID
                self.fetchedClientId = clientId
                self.isLoading = false
            }
        } catch {
            print("Invoice fetch error: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load invoice items. Make sure you entered a valid Database Order ID."
                self.isLoading = false
            }
        }
    }
}
