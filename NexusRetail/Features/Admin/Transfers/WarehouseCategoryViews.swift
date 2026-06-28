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
            LazyVStack(spacing: 16) {
                ForEach(filteredProducts) { product in
                    WarehouseProductRow(product: product)
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
