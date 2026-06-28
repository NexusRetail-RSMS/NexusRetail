import SwiftUI

struct TransferRequestCard: View {
    let request: AdminStockRequest
    
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @Environment(AdminNavigationStore.self) private var navStore
    
    @State private var showingDenialAlert = false
    @State private var denialReason = ""
    @State private var showingPurchaseOrderSheet = false
    
    var body: some View {
        let product = viewModel.product(for: request.productID)
        let manager = viewModel.manager(for: request.managerID)
        let store = viewModel.store(for: request.storeID)
        
        VStack(alignment: .leading, spacing: 20) {
            // Header: Manager & Store + Badges
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(manager?.name ?? "Unknown Manager")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(store?.name ?? "Unknown Store")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: request.status)
            }
            
            Divider()
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product?.name ?? "Unknown Item")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(product?.category ?? "Category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Stock Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Requested")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(request.requestedQuantity)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    let available = product?.warehouseQuantity ?? 0
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(available)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(available >= request.requestedQuantity ? .green : .red)
                }
            }
            
            // Actions
            if request.status == .pending || request.status == .awaitingRestock {
                let isSufficient = (product?.warehouseQuantity ?? 0) >= request.requestedQuantity
                
                HStack(spacing: 12) {
                    if isSufficient {
                        Button {
                            withAnimation { viewModel.approveRequest(request) }
                        } label: {
                            Text("Approve")
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.nexusRed)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        Button {
                            showingPurchaseOrderSheet = true
                        } label: {
                            Text("Purchase Order")
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.nexusRed)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button {
                        showingDenialAlert = true
                    } label: {
                        Text("Deny")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.nexusRed.opacity(0.1))
                            .foregroundColor(Color.nexusRed)
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 8)
            }
            
            if let reason = request.denialReason {
                Text("Reason: \(reason)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .alert("Deny Request", isPresented: $showingDenialAlert) {
            TextField("Reason (optional)", text: $denialReason)
            Button("Cancel", role: .cancel) { }
            Button("Deny", role: .destructive) {
                withAnimation {
                    viewModel.denyRequest(request, reason: denialReason.isEmpty ? "No stock available" : denialReason)
                }
            }
        } message: {
            Text("Are you sure you want to deny this transfer request?")
        }
        .sheet(isPresented: $showingPurchaseOrderSheet) {
            if let product = product {
                PurchaseOrderSheet(product: product, suggestedQuantity: request.requestedQuantity * 2, initialRequest: request)
            }
        }
    }
}

struct StatusBadge: View {
    let status: TransferRequestStatus
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.1))
            .cornerRadius(8)
    }
}

struct PriorityBadge: View {
    let priority: RequestPriority
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flag.fill")
                .font(.system(size: 10))
            Text(priority.rawValue)
        }
        .font(.caption2)
        .fontWeight(.bold)
        .foregroundColor(priority.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priority.color.opacity(0.1))
        .cornerRadius(8)
    }
}
