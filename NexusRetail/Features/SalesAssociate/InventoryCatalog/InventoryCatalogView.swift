//
//  InventoryCatalogView.swift
//  NexusRetail
//
//  Read-only product catalog for the Sales Associate: name, price, and stock.
//

import SwiftUI
import Supabase

struct InventoryCatalogView: View {
    @Environment(SessionStore.self) private var sessionStore

    @State private var products: [POSProduct] = []
    @State private var isLoading = false
    @State private var searchText = ""

    @State private var selectedCategory: String? = nil

    var categories: [String] {
        let allCategories = Set(products.map { $0.category })
        return Array(allCategories).sorted()
    }

    var filteredProducts: [POSProduct] {
        var base = products
        
        if let category = selectedCategory {
            base = base.filter { $0.category == category }
        }
        
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
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: RSMSSpacing.lg) {

                        searchBar
                        
                        filterScrollView

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

    // MARK: - Filter Pills
    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                filterPill(title: "All", isSelected: selectedCategory == nil) {
                    withAnimation { selectedCategory = nil }
                }
                ForEach(categories, id: \.self) { category in
                    filterPill(title: category, isSelected: selectedCategory == category) {
                        withAnimation {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
    }

    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? RSMSColors.background : RSMSColors.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? RSMSColors.primaryText : RSMSColors.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : RSMSColors.cardBorder, lineWidth: 1)
                )
        }
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
        do {
            struct ProductResponse: Codable {
                let item_id: Int64
                let item_name: String
                let category: String
                let price: Double
                let pexels_page: String?
                let image_url: String?
            }
            
            let response: [ProductResponse] = try await SupabaseManager.shared.client
                .from("products")
                .select("item_id, item_name, category, price, pexels_page, image_url")
                .execute()
                .value
            
            var mapped: [POSProduct] = []
            for product in response {
                let uuid = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", product.item_id)) ?? UUID()
                let pexelsImageUrl = POSProductRepository.shared.extractPexelsImageUrl(from: product.pexels_page ?? "") ?? product.image_url
                
                mapped.append(POSProduct(
                    id: uuid,
                    itemId: product.item_id,
                    name: product.item_name,
                    sku: "SKU-\(product.item_id)",
                    category: product.category,
                    price: product.price,
                    stock: Int.random(in: 1...50), // Random stock for now or join with inventory
                    size: "M",
                    imageUrl: pexelsImageUrl
                ))
            }
            self.products = mapped
        } catch {
            print("Error fetching from Supabase products table: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    InventoryCatalogView()
        .environment(SessionStore())
}
