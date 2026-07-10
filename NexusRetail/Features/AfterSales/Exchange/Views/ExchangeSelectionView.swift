//
//  ExchangeSelectionView.swift
//  NexusRetail
//
//  Product selection screen for the exchange flow: browse inventory,
//  pick replacement products, review pricing, and proceed to checkout.
//

import SwiftUI

struct ExchangeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var sellViewModel
    @Environment(SessionStore.self) private var sessionStore
    @Binding var path: NavigationPath

    let invoiceId: String
    let selectedItem: POSProduct
    let purchaseDate: Date?
    let warrantyEndDate: Date?
    let customer: RequestCustomer?

    @State private var viewModel: ExchangeViewModel
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(
        path: Binding<NavigationPath>,
        invoiceId: String,
        selectedItem: POSProduct,
        purchaseDate: Date?,
        warrantyEndDate: Date?,
        customer: RequestCustomer?
    ) {
        self._path = path
        self.invoiceId = invoiceId
        self.selectedItem = selectedItem
        self.purchaseDate = purchaseDate
        self.warrantyEndDate = warrantyEndDate
        self.customer = customer
        self._viewModel = State(initialValue: ExchangeViewModel(
            originalProduct: selectedItem,
            invoiceId: invoiceId,
            purchaseDate: purchaseDate,
            warrantyEndDate: warrantyEndDate,
            customer: customer
        ))
    }

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    customHeaderSection

                    VStack(alignment: .leading, spacing: 24) {
                        // Original product card
                        originalProductSection

                        // Selected replacement
                        if let _ = viewModel.selectedReplacement {
                            selectedReplacementsSection
                        }

                        // Search & filter
                        VStack(alignment: .leading, spacing: 14) {
                            searchBarSection

                            categoryFilterSection
                        }

                        // Product listing
                        productListSection
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                    .padding(.bottom, 120)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            bottomSummaryBar
        }
        .task {
            await viewModel.loadProducts(storeID: sessionStore.currentUser?.storeID)
        }
        .alert("Exchange Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(localized: errorMessage)
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
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Exchange Product")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }

    // MARK: - Original Product

    private var originalProductSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.left.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(RSMSColors.burgundy)
                Text("Returning Product")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSColors.burgundy)
            }

            HStack(spacing: 16) {
                CachedAsyncImage(url: URL(string: selectedItem.imageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.1)
                        .overlay(
                            Image(systemName: "shippingbox")
                                .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                        )
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedItem.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(2)

                    Text("SKU: \(selectedItem.sku)  •  Size: \(selectedItem.size)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)

                    Text("Invoice: \(invoiceId.prefix(8))...")
                        .font(.system(size: 11))
                        .foregroundColor(RSMSColors.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatIndianCurrency(selectedItem.price))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)

                    Text("Qty: \(viewModel.originalQuantity)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
        }
        .padding(16)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(RSMSColors.burgundy.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    // MARK: - Selected Replacements

    private var selectedReplacementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(RSMSColors.success)
                Text("Replacement Selected")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSColors.success)
            }

            if let item = viewModel.selectedReplacement {
                replacementItemRow(item)
            }
        }
        .padding(16)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(RSMSColors.success.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private func replacementItemRow(_ item: ExchangeReplacementItem) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: item.product.imageUrl ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)

                Text(formatIndianCurrency(item.product.price))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(RSMSColors.burgundy)
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.removeReplacement()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(RSMSColors.error)
                    .frame(width: 32, height: 32)
                    .background(RSMSColors.error.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(RSMSColors.secondaryText)

            TextField("Search by name, SKU, or category...", text: Bindable(viewModel).searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.6))
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryPill(title: "All", isSelected: viewModel.selectedCategory == nil) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.selectedCategory = nil
                    }
                }

                ForEach(viewModel.availableCategories, id: \.self) { category in
                    categoryPill(title: category, isSelected: viewModel.selectedCategory == category) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    private func categoryPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(localized: title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : RSMSColors.burgundy)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(RSMSColors.burgundy.opacity(0.08))
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Product List

    private var productListSection: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading products...")
                        .tint(RSMSColors.burgundy)
                    Spacer()
                }
                .padding(.top, 40)
            } else if viewModel.filteredProducts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                    Text(viewModel.searchText.isEmpty ? "No products available" : "No products found matching '\(viewModel.searchText)'")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40)
            } else {
                ForEach(viewModel.filteredProducts) { product in
                    productCard(product)
                }
            }
        }
    }

    private func productCard(_ product: POSProduct) -> some View {
        let isSelected = viewModel.isProductSelected(product)

        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.toggleReplacement(product)
            }
        } label: {
            HStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    CachedAsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                            .overlay(
                                Image(systemName: "shippingbox")
                                    .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                            )
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(RSMSColors.success)
                                .frame(width: 20, height: 20)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 4, y: 4)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(2)

                    Text("SKU: \(product.sku)  •  Size: \(product.size)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)

                    Text(formatIndianCurrency(product.price))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    if product.stock > 10 {
                        Text("In Stock")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(RSMSColors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RSMSColors.success.opacity(0.08))
                            .clipShape(Capsule())
                    } else {
                        Text("Only \(product.stock) left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(RSMSColors.warning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RSMSColors.warning.opacity(0.08))
                            .clipShape(Capsule())
                    }

                    if isSelected {
                        Text("Selected")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(RSMSColors.success)
                    } else {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(RSMSColors.burgundy)
                    }
                }
            }
            .padding(14)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? RSMSColors.success.opacity(0.5) : RSMSColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Summary Bar

    private var bottomSummaryBar: some View {
        VStack(spacing: 0) {
            if viewModel.isExchangeValid {
                VStack(spacing: 12) {
                    // Pricing breakdown
                    HStack {
                        Text("Original Value")
                            .font(.system(size: 13))
                            .foregroundColor(RSMSColors.secondaryText)
                        Spacer()
                        Text(formatIndianCurrency(viewModel.originalValue))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }

                    HStack {
                        Text("Replacement Price")
                            .font(.system(size: 13))
                            .foregroundColor(RSMSColors.secondaryText)
                        Spacer()
                        Text(formatIndianCurrency(viewModel.replacementTotal))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }

                    if viewModel.difference > 0 {
                        HStack {
                            Text("Price Difference")
                                .font(.system(size: 13))
                                .foregroundColor(RSMSColors.secondaryText)
                            Spacer()
                            Text(formatIndianCurrency(viewModel.difference))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(RSMSColors.burgundy)
                        }
                    }

                    Divider()

                    HStack {
                        Text(viewModel.requiresPayment ? "Amount Payable" : "Amount Due")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                        Spacer()
                        Text(viewModel.amountPayable > 0 ? formatIndianCurrency(viewModel.amountPayable) : "FREE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(viewModel.amountPayable > 0 ? RSMSColors.burgundy : RSMSColors.success)
                    }

                    // CTA Button
                    Button {
                        Task { await handleProceed() }
                    } label: {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .controlSize(.small)
                            }
                            Text(localized: ctaButtonText)
                                .font(.system(size: 16, weight: .bold))
                            if !isProcessing {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: viewModel.isExchangeValid
                                    ? [RSMSColors.burgundy, RSMSColors.darkBurgundy]
                                    : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: viewModel.isExchangeValid ? RSMSColors.burgundy.opacity(0.25) : .clear, radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.isExchangeValid || isProcessing)
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.vertical, RSMSSpacing.lg)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isExchangeValid)
    }

    private var ctaButtonText: String {
        if isProcessing { return "Processing..." }
        if !viewModel.requiresPayment {
            return "Confirm Exchange"
        }
        return "Proceed to Checkout — \(formatIndianCurrency(viewModel.amountPayable))"
    }

    // MARK: - Actions

    private func handleProceed() async {
        guard viewModel.isExchangeValid, let replacement = viewModel.selectedReplacement else { return }
        isProcessing = true

        // Build a checkout line for the REAL replacement product, priced at the
        // exchange difference. This makes the POS checkout RPC validate the item,
        // deduct its stock, and charge only the delta (0 for an even exchange) —
        // instead of a fake "item_id 0" line that inventory rejects.
        let exchangeLine = POSProduct(
            id: UUID(),
            itemId: replacement.product.itemId,
            name: replacement.product.name,
            sku: replacement.product.sku,
            category: replacement.product.category,
            price: viewModel.amountPayable,
            stock: replacement.product.stock,
            size: replacement.product.size,
            imageUrl: replacement.product.imageUrl
        )

        sellViewModel.resetFlow()
        sellViewModel.addToCart(product: exchangeLine)
        // Store exchange context so it can be recorded after checkout.
        sellViewModel.pendingExchange = PendingExchange(
            invoiceId: invoiceId,
            originalProduct: selectedItem,
            originalQuantity: viewModel.originalQuantity,
            replacementItem: replacement,
            customer: customer,
            amountPayable: viewModel.amountPayable
        )
        if let customer {
            sellViewModel.selectedClient = customer.name
            sellViewModel.receiptSharedEmail = customer.email
            sellViewModel.receiptSharedPhone = customer.phone
        }

        if viewModel.requiresPayment {
            // Collect the difference via the standard checkout → payment flow.
            // PaymentFlowView finalizes the exchange (restock + ticket) after payment.
            await MainActor.run {
                isProcessing = false
                path.append(POSFlowDestination.checkout)
            }
        } else {
            // Even exchange (no money due): record the sale + exchange, then show success.
            do {
                try await sellViewModel.processCheckout(
                    storeID: sessionStore.currentUser?.storeID,
                    associateID: sessionStore.currentUser?.id
                )
                try await sellViewModel.finalizeExchange(
                    storeID: sessionStore.currentUser?.storeID,
                    associateID: sessionStore.currentUser?.id
                )
                let transaction = ExchangeFlowTransaction(
                    transactionId: "EXC-\(UUID().uuidString.prefix(8).uppercased())",
                    invoiceId: invoiceId,
                    originalProduct: selectedItem,
                    originalQuantity: viewModel.originalQuantity,
                    replacementItem: replacement,
                    amountPaid: 0,
                    date: Date()
                )
                await MainActor.run {
                    isProcessing = false
                    path.append(POSFlowDestination.exchangeSuccess(transaction: transaction))
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Unable to process exchange: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
