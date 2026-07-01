//
//  InventoryCatalogView.swift
//  NexusRetail
//
//  Read-only product catalog for the Sales Associate: name, price, and stock.
//

import SwiftUI

struct InventoryCatalogView: View {
    @Environment(SessionStore.self) private var sessionStore

    @State private var products: [POSProduct] = []
    @State private var isLoading = false
    @State private var searchText = ""

    var filteredProducts: [POSProduct] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = query.isEmpty
            ? products
            : products.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.sku.localizedCaseInsensitiveContains(query) ||
                $0.category.localizedCaseInsensitiveContains(query)
            }
        return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: RSMSSpacing.lg) {

                        searchBar

                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Loading catalog...")
                                    .tint(RSMSColors.burgundy)
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
            }
            .navigationTitle("Inventory Catalog")
            .navigationBarTitleDisplayMode(.large)
            .task { await loadProducts() }
            .refreshable { await loadProducts() }
        }
    }



    // MARK: - Search
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(RSMSColors.secondaryText)

            TextField("Search by name, SKU, or category...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.6))
                }
            }
        }
        .padding(14)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
            Text(searchText.isEmpty ? "No products available." : "No products found matching '\(searchText)'")
                .font(.system(size: 14))
                .foregroundColor(RSMSColors.secondaryText)
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
                        .overlay(Image(systemName: "shippingbox").foregroundColor(RSMSColors.secondaryText))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)
                Text("\(product.category) • \(product.sku)")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("₹\(String(format: "%.2f", product.price))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)

                stockBadge(for: product.stock)
            }
        }
        .padding(14)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private func stockBadge(for stock: Int) -> some View {
        let (text, color): (String, Color) = {
            if stock <= 0 { return ("Out of Stock", RSMSColors.error) }
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
        products = await POSProductRepository.shared.fetchProducts(storeID: sessionStore.currentUser?.storeID)
        isLoading = false
    }
}

#Preview {
    InventoryCatalogView()
        .environment(SessionStore())
}
