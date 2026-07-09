//
//  InventoryCatalogView.swift
//  NexusRetail
//
//  Read-only product catalog for the Sales Associate: name, price, and stock.
//

import SwiftUI
import Supabase

struct InventoryCatalogView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SessionStore.self) private var sessionStore

    @State private var products: [POSProduct] = []
    @State private var isLoading = false
    @State private var searchText = ""

    var filteredProducts: [POSProduct] {
        var base = products
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            base = base.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.sku.localizedCaseInsensitiveContains(query) ||
                $0.category.localizedCaseInsensitiveContains(query)
            }
        }
        return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading catalog...")
                                .tint(theme.burgundy)
                            Spacer()
                        }
                        .padding(.top, 40)
                    } else if filteredProducts.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredProducts) { product in
                                catalogRow(product)
                            }
                        }
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 16)
                .padding(.bottom, RSMSSpacing.xxl)
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Search")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        Spacer()
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    NexusSearchBar(text: $searchText, placeholder: "Search products by name, SKU, or category...")
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 12)
                }
                .fadingMaterialHeader()
            }
        }
        .task { await loadProducts() }
        .refreshable { await loadProducts() }
    }



    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundColor(theme.secondaryText.opacity(0.5))
            Text(searchText.isEmpty ? "No products available." : "No products found matching '\(searchText)'")
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 40)
    }

    // MARK: - Row (read-only, no tap action)
    private func catalogRow(_ product: POSProduct) -> some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.1)
                        .overlay(Image(systemName: "shippingbox").foregroundColor(theme.secondaryText))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                Text("\(product.category) • \(product.sku)")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("₹\(String(format: "%.2f", product.price))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.burgundy)

                stockBadge(for: product.stock)
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private func stockBadge(for stock: Int) -> some View {
        let (text, color): (String, Color) = {
            if stock <= 0 { return ("Out of Stock", theme.error) }
            if stock <= 5 { return ("Low Stock: \(stock)", Color(hex: "D4A017")) }
            return ("In Stock: \(stock)", Color(hex: "2A9D8F"))
        }()

        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.08))
            .clipShape(Capsule())
    }

    // MARK: - Data Loading
    private func loadProducts() async {
        isLoading = true
        // Use the shared repository which joins real per-store inventory (on_hand),
        // real sku_code, and store-specific pricing. Stock is scoped to THIS associate's
        // store, so the search results match the actual backend inventory.
        //
        // Run the fetch in a detached task so it isn't torn down by SwiftUI cancelling the
        // view's `.task` (which the searchable field / tab switches can trigger, surfacing
        // as CancellationError and leaving stale/empty stock).
        let storeID = sessionStore.currentUser?.storeID
        let fetched = await Task.detached(priority: .userInitiated) {
            await POSProductRepository.shared.fetchProducts(storeID: storeID)
        }.value
        self.products = fetched
        isLoading = false
    }
}

#Preview {
    InventoryCatalogView()
        .environment(SessionStore())
}
