import SwiftUI

struct WarehouseCategoryView: View {
    let title: String
    let filter: StockHealth?

    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var searchText = ""
    @State private var isRefreshing = false

    var filteredProducts: [AdminTransferProduct] {
        var result = viewModel.products
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.sku.localizedCaseInsensitiveContains(searchText) }
        }
        if let f = filter {
            result = result.filter { $0.stockHealth == f }
        }
        return result
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if filteredProducts.isEmpty {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.07))
                                .frame(width: 92, height: 92)
                            Image(systemName: "shippingbox")
                                .font(.system(size: 34, weight: .light))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        Text("No products found")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 64)
                } else {
                    ForEach(filteredProducts) { product in
                        WarehouseProductRow(product: product)
                    }
                }
            }
            .padding()
        }
        .background(Color.nexusBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search products or SKUs")
        .refreshable {
            isRefreshing = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isRefreshing = false
        }
    }
}

struct AllItemsView: View {
    var body: some View {
        WarehouseCategoryView(title: "All Items", filter: nil)
    }
}

struct InStockView: View {
    var body: some View {
        WarehouseCategoryView(title: "In Stock", filter: .inStock)
    }
}

struct LowStockView: View {
    var body: some View {
        WarehouseCategoryView(title: "Low Stock", filter: .lowStock)
    }
}

struct OutOfStockView: View {
    var body: some View {
        WarehouseCategoryView(title: "Out of Stock", filter: .outOfStock)
    }
}
