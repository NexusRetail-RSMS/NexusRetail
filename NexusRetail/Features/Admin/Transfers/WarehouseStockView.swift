import SwiftUI

struct WarehouseStockView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Filters Dashboard Grid
            WarehouseDashboardGrid(products: viewModel.products)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Divider()
                .padding(.vertical)
            
            // Active Deliveries
            ActiveDeliveriesSection()
        }
        .padding(.bottom, 30)
        .background(Color.nexusBackground)
    }
}

struct WarehouseDashboardGrid: View {
    let products: [AdminTransferProduct]
    
    var allItemsCount: Int { products.count }
    var inStockCount: Int { products.filter { $0.stockHealth == .inStock }.count }
    var lowStockCount: Int { products.filter { $0.stockHealth == .lowStock }.count }
    var outOfStockCount: Int { products.filter { $0.stockHealth == .outOfStock }.count }
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            NavigationLink(destination: AllItemsView()) {
                WarehouseDashboardCard(
                    title: "All Items",
                    icon: "shippingbox.fill",
                    count: allItemsCount
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: InStockView()) {
                WarehouseDashboardCard(
                    title: "In Stock",
                    icon: "checkmark.circle.fill",
                    count: inStockCount
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: LowStockView()) {
                WarehouseDashboardCard(
                    title: "Low Stock",
                    icon: "exclamationmark.triangle.fill",
                    count: lowStockCount
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: OutOfStockView()) {
                WarehouseDashboardCard(
                    title: "Out of Stock",
                    icon: "xmark.octagon.fill",
                    count: outOfStockCount
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct WarehouseDashboardCard: View {
    let title: String
    let icon: String
    let count: Int
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.nexusRed.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.nexusRed)
                }
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
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
                    
                    HStack(spacing: 12) {
                        Text("Available: \(product.warehouseQuantity)")
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        Text("Reorder: \(product.reorderLevel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
