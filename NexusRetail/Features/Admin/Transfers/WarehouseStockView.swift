import SwiftUI

enum StockHealthFilter: String, CaseIterable {
    case all = "All Items"
    case inStock = "In Stock"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
}

struct WarehouseStockView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var selectedFilter: StockHealthFilter = .all
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    var filteredProducts: [AdminTransferProduct] {
        var result = viewModel.products
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.sku.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch selectedFilter {
        case .all: break
        case .inStock: result = result.filter { $0.stockHealth == .inStock }
        case .lowStock: result = result.filter { $0.stockHealth == .lowStock }
        case .outOfStock: result = result.filter { $0.stockHealth == .outOfStock }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(selectedFilter.rawValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.darkBrown)
                
                Spacer()
                
                Menu {
                    ForEach(StockHealthFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            if selectedFilter == filter {
                                Label(filter.rawValue, systemImage: "checkmark")
                            } else {
                                Text(filter.rawValue)
                            }
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundColor(RSMSColors.burgundy)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.md)
            .padding(.bottom, RSMSSpacing.sm)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    if filteredProducts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No products found")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(filteredProducts) { product in
                            WarehouseProductRow(product: product)
                        }
                    }
                }
                .padding()
            }
        }
        .background(RSMSColors.background)
        .searchable(text: $searchText, prompt: "Search products or SKUs")
        .refreshable {
            isRefreshing = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isRefreshing = false
        }
    }
}

struct WarehouseProductRow: View {
    let product: AdminTransferProduct
    @State private var showingPurchaseOrderSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Image Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("SKU: \(product.sku) • \(product.category)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Available: \(product.warehouseQuantity)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(product.stockHealth.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(product.stockHealth.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(product.stockHealth.color.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button {
                        showingPurchaseOrderSheet = true
                    } label: {
                        Text("Order Stock")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.nexusGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.nexusRed)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
        .sheet(isPresented: $showingPurchaseOrderSheet) {
            let suggestedQty = max(product.reorderLevel * 2, 50)
            PurchaseOrderSheet(product: product, suggestedQuantity: suggestedQty, initialRequest: nil)
        }
    }
}

struct PurchaseOrderCard: View {
    let order: AdminPurchaseOrder
    @Environment(AdminTransfersViewModel.self) private var viewModel
    
    var body: some View {
        let product = viewModel.product(for: order.productID)
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(product?.name ?? "Unknown Product")
                        .font(.headline)
                }
                
                Spacer()
                
                Text(order.status.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(order.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(order.status.color.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Qty: \(order.quantity)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Supplier: \(order.supplierName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Expected: \(order.estimatedDeliveryDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if order.status != .delivered {
                        Button {
                            withAnimation {
                                viewModel.simulateDelivery(for: order)
                            }
                        } label: {
                            Text("Simulate Delivery")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                    } else if let delivered = order.deliveryDate {
                        Text("Delivered on \(delivered.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
    }
}
