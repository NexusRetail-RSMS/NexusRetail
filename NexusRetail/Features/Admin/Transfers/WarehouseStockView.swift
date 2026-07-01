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
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedFilter.rawValue)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSColors.darkBrown)

                    Text("\(filteredProducts.count) item\(filteredProducts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

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
                            .fill(
                                LinearGradient(
                                    colors: [RSMSColors.burgundy.opacity(0.14), RSMSColors.burgundy.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(RSMSColors.burgundy.opacity(0.14), lineWidth: 1))
                            .shadow(color: RSMSColors.burgundy.opacity(0.1), radius: 6, x: 0, y: 3)

                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundColor(RSMSColors.burgundy)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.md)
            .padding(.bottom, RSMSSpacing.sm)

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

    private var stockRatio: CGFloat {
        let ceiling = max(product.reorderLevel * 2, 1)
        return min(CGFloat(product.warehouseQuantity) / CGFloat(ceiling), 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 13)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.16), Color.gray.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(product.name)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(product.sku)
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.09))
                            .clipShape(Capsule())

                        Text(product.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(product.stockHealth.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(product.stockHealth.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(product.stockHealth.color.opacity(0.1))
                    .overlay(Capsule().stroke(product.stockHealth.color.opacity(0.18), lineWidth: 1))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 7) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 7)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [product.stockHealth.color.opacity(0.7), product.stockHealth.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * stockRatio, height: 7)

                        let ceiling = max(product.reorderLevel * 2, 1)
                        let markerX = geo.size.width * min(CGFloat(product.reorderLevel) / CGFloat(ceiling), 1.0)
                        Rectangle()
                            .fill(Color.black.opacity(0.25))
                            .frame(width: 1.5, height: 11)
                            .offset(x: markerX, y: -2)
                    }
                }
                .frame(height: 9)

                HStack {
                    Text("Available: \(product.warehouseQuantity)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("Reorder at \(product.reorderLevel)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                showingPurchaseOrderSheet = true
            } label: {
                Label("Order Stock", systemImage: "cart.badge.plus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.nexusGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.nexusRed, Color.nexusRed.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(11)
                    .shadow(color: Color.nexusRed.opacity(0.28), radius: 7, x: 0, y: 3)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 5)
                .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.045), lineWidth: 1)
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
                VStack(alignment: .leading, spacing: 3) {
                    Text(order.id)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(product?.name ?? "Unknown Product")
                        .font(.system(size: 16, weight: .bold))
                }

                Spacer()

                Text(order.status.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(order.status.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(order.status.color.opacity(0.1))
                    .overlay(Capsule().stroke(order.status.color.opacity(0.18), lineWidth: 1))
                    .clipShape(Capsule())
            }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Qty: \(order.quantity)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Supplier: \(order.supplierName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
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
                                .overlay(Capsule().stroke(Color.green.opacity(0.2), lineWidth: 1))
                                .clipShape(Capsule())
                        }
                    } else if let delivered = order.deliveryDate {
                        Text("Delivered on \(delivered.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}
