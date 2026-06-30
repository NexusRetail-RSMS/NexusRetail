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
        
        VStack(alignment: .leading, spacing: 0) {
            // Header: Manager & Store + Badges
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager?.name ?? "Unknown Manager")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(store?.name ?? "Unknown Store")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: request.status)
            }
            
            Divider()
                .padding(.top, 10)
                .padding(.bottom, 12)
            
            // Product Info
            VStack(alignment: .leading, spacing: 2) {
                Text(product?.name ?? "Unknown Item")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(product?.category ?? "Category")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Stock Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Requested")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(request.requestedQuantity)")
                        .font(.system(size: 20, weight: .bold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    let available = product?.warehouseQuantity ?? 0
                    Text("Available")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(available)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(available >= request.requestedQuantity ? .primary : .red)
                }
            }
            .padding(.top, 12)
            
            // Actions
            if request.status == .pending || request.status == .awaitingRestock {
                let isSufficient = (product?.warehouseQuantity ?? 0) >= request.requestedQuantity
                
                HStack(spacing: 10) {
                    if isSufficient {
                        Button {
                            withAnimation { viewModel.approveRequest(request) }
                        } label: {
                            Text("Approve")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(Color.nexusRed)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button {
                            showingPurchaseOrderSheet = true
                        } label: {
                            Text("Purchase Order")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(Color.nexusRed)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button {
                        showingDenialAlert = true
                    } label: {
                        Text("Deny")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.nexusRed.opacity(0.1))
                            .foregroundColor(Color.nexusRed)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 16)
            }
            
            if let reason = request.denialReason {
                Text("Reason: \(reason)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.1))
            .cornerRadius(6)
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
