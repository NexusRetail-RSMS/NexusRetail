import SwiftUI

struct InvoiceItemsSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    let invoiceId: String

    // Real purchased items on the scanned invoice.
    @State private var items: [AfterSalesInvoiceItem] = []
    @State private var isLoading = true
    @State private var loadError: String? = nil

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
                            HStack { Spacer(); ProgressView("Loading invoice...").tint(RSMSColors.burgundy); Spacer() }
                                .padding(.top, 40)
                        } else if let loadError {
                            emptyState(message: loadError, icon: "exclamationmark.triangle")
                        } else if items.isEmpty {
                            emptyState(message: "No items found for this invoice. Check the invoice number and try again.", icon: "doc.text.magnifyingglass")
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
            if !items.isEmpty {
                bottomActionBar
            }
        }
        .navigationBarHidden(true)
        .task { await loadItems() }
    }

    private func emptyState(message: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 40)
    }

    private func loadItems() async {
        isLoading = true
        loadError = nil
        do {
            let fetched = try await AfterSalesService.fetchInvoiceItems(orderId: invoiceId)
            self.items = fetched
        } catch {
            self.loadError = "Couldn't load this invoice. It may not exist or belongs to another store."
            print("After Sales invoice fetch error: \(error)")
        }
        isLoading = false
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
    
    private func itemRow(_ item: AfterSalesInvoiceItem) -> some View {
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
                    
                    Text("\(item.category) • Qty: \(item.quantity)")
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
                    // Map the real invoice line to a POSProduct so downstream views (which
                    // are POSProduct-based) can display it. itemId carries the DB key used
                    // for eligibility/processing.
                    let posProduct = POSProduct(
                        id: selectedItem.id,
                        itemId: selectedItem.itemId,
                        name: selectedItem.name,
                        sku: selectedItem.sku,
                        category: selectedItem.category,
                        price: selectedItem.price,
                        stock: selectedItem.quantity,
                        size: "—",
                        imageUrl: selectedItem.imageUrl
                    )
                    path.append(POSFlowDestination.actionSelection(invoiceId: invoiceId, selectedItem: posProduct))
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
}
