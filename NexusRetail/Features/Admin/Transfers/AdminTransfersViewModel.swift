import Foundation
import SwiftUI
import Supabase

@Observable
class AdminTransfersViewModel {
    var requests: [AdminStockRequest] = []
    var products: [AdminTransferProduct] = []
    var purchaseOrders: [AdminPurchaseOrder] = []
    var deliveries: [AdminDelivery] = []
    
    // The warehouse store ID
    var warehouseStoreID: UUID?
    
    var isLoading = false
    var errorMessage: String?
    
    init() {
        // Will be called by views
    }
    
    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Get warehouse store or fallback to first available store
            let stores: [Store] = try await SupabaseManager.shared.client
                .from("store")
                .select("*")
                .execute()
                .value
            
            // Try to find a warehouse, otherwise just use any store (useful for dev/mock environments)
            guard let warehouse = stores.first(where: { $0.isWarehouse == true }) ?? stores.first else {
                errorMessage = "No store found in DB to use as warehouse."
                isLoading = false
                return
            }
            
            self.warehouseStoreID = warehouse.id
            
            // 2. Fetch warehouse inventory
            let inventoryItems: [InventoryItemRow] = try await SupabaseManager.shared.client
                .from("inventory_item")
                .select("*, products(*)")
                .eq("store_id", value: warehouse.id)
                .execute()
                .value
            
            self.products = inventoryItems.map { item in
                AdminTransferProduct(
                    id: item.itemId, // Using SKU id as product ID for easy lookup
                    name: item.products.name,
                    sku: item.products.skuCode ?? "—",
                    category: item.products.category ?? "Uncategorized",
                    warehouseQuantity: item.onHand,
                    reorderLevel: 20, // Default reorder level
                    lastUpdated: Date()
                )
            }
            
            // 3. Fetch all transfer requests
            let fetchedRequests: [AdminStockRequest] = try await SupabaseManager.shared.client
                .from("transfer_request")
                .select("*, products(*), store!requesting_store_id(*, manager:app_user!store_manager_fk(*))")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.requests = fetchedRequests
            
        } catch is CancellationError {
            // Ignore task cancellation
            print("Admin transfers load cancelled")
        } catch {
            print("Failed to load admin transfers data: \(error)")
            self.errorMessage = "Error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    struct StatusUpdate: Encodable {
        let status: String
    }
    
    func approveRequest(_ request: AdminStockRequest) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }),
              let productIndex = products.firstIndex(where: { $0.id == request.itemId }) else { return }
        
        if products[productIndex].warehouseQuantity >= request.quantity {
            guard let warehouseId = self.warehouseStoreID else { return }
            
            Task {
                do {
                    // Update transfer request status
                    try await SupabaseManager.shared.client
                        .from("transfer_request")
                        .update(StatusUpdate(status: TransferStatus.approved.rawValue))
                        .eq("id", value: request.id)
                        .execute()
                    
                    struct UpdateQty: Encodable { let on_hand: Int }
                    struct SimpleInventoryItem: Decodable {
                        let id: UUID
                        let on_hand: Int
                    }
                    
                    // 1. Fetch and update warehouse item
                    let warehouseItems: [SimpleInventoryItem] = try await SupabaseManager.shared.client
                        .from("inventory_item")
                        .select()
                        .eq("store_id", value: warehouseId)
                        .eq("item_id", value: Int(request.itemId))
                        .execute()
                        .value
                    
                    if let warehouseItem = warehouseItems.first {
                        let newQty = warehouseItem.on_hand - request.quantity
                        try await SupabaseManager.shared.client
                            .from("inventory_item")
                            .update(UpdateQty(on_hand: newQty))
                            .eq("id", value: warehouseItem.id)
                            .execute()
                    }
                    
                    // 2. Fetch and update/insert destination store item
                    let destItems: [SimpleInventoryItem] = try await SupabaseManager.shared.client
                        .from("inventory_item")
                        .select()
                        .eq("store_id", value: request.requestingStoreId)
                        .eq("item_id", value: Int(request.itemId))
                        .execute()
                        .value
                    
                    if let destItem = destItems.first {
                        let newQty = destItem.on_hand + request.quantity
                        try await SupabaseManager.shared.client
                            .from("inventory_item")
                            .update(UpdateQty(on_hand: newQty))
                            .eq("id", value: destItem.id)
                            .execute()
                    } else {
                        struct InsertItem: Encodable {
                            let item_id: Int64
                            let store_id: UUID
                            let on_hand: Int
                            let reorder_threshold: Int
                        }
                        try await SupabaseManager.shared.client
                            .from("inventory_item")
                            .insert(InsertItem(
                                item_id: request.itemId,
                                store_id: request.requestingStoreId,
                                on_hand: request.quantity,
                                reorder_threshold: 10
                            ))
                            .execute()
                    }
                    
                    await MainActor.run {
                        // Deduct stock locally
                        products[productIndex].warehouseQuantity -= request.quantity
                        products[productIndex].lastUpdated = Date()
                        
                        // Update request
                        requests[index].status = .approved
                        
                        // Create a mock delivery for the UI
                        let newDelivery = AdminDelivery(
                            id: "DEL-\(Int.random(in: 1000...9999))",
                            transferRequestID: request.id.uuidString,
                            productID: request.itemId,
                            quantity: request.quantity,
                            destinationStoreID: request.requestingStoreId,
                            destinationStoreName: request.storeName,
                            managerID: UUID(), // We don't have manager ID directly
                            managerName: request.managerName,
                            managerAvatarInitials: String(request.managerName.prefix(2)),
                            dispatchDate: Date(),
                            estimatedArrival: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                            status: .preparing,
                            trackingNumber: "TRK\(Int.random(in: 10000000...99999999))"
                        )
                        deliveries.insert(newDelivery, at: 0)
                    }
                } catch {
                    print("Failed to approve request: \(error)")
                }
            }
        }
    }
    
    func denyRequest(_ request: AdminStockRequest, reason: String) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else { return }
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("transfer_request")
                    .update(StatusUpdate(status: TransferStatus.unfulfillable.rawValue))
                    .eq("id", value: request.id)
                    .execute()
                
                await MainActor.run {
                    requests[index].status = .unfulfillable
                }
            } catch {
                print("Failed to deny request: \(error)")
            }
        }
    }
    
    func createPurchaseOrder(for product: AdminTransferProduct, quantity: Int, supplier: String, notes: String?) {
        let newPO = AdminPurchaseOrder(
            id: "PO-\(Int.random(in: 1000...9999))",
            productID: product.id,
            supplierName: supplier,
            quantity: quantity,
            createdDate: Date(),
            estimatedDeliveryDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            status: .ordered,
            notes: notes
        )
        purchaseOrders.insert(newPO, at: 0)
        
        if let productIndex = products.firstIndex(where: { $0.id == product.id }) {
            products[productIndex].warehouseQuantity += quantity
            products[productIndex].lastUpdated = Date()
            
            // Auto-check pending requests that were blocked
            for (reqIndex, request) in requests.enumerated() {
                if request.status == .pending && request.itemId == product.id {
                    if products[productIndex].warehouseQuantity >= request.quantity {
                        // requests[reqIndex].status = .pending
                    }
                }
            }
        }
    }
    
    func simulateDelivery(for order: AdminPurchaseOrder) {
        guard let index = purchaseOrders.firstIndex(where: { $0.id == order.id }),
              let productIndex = products.firstIndex(where: { $0.id == order.productID }) else { return }
        
        // Update PO
        purchaseOrders[index].status = .delivered
        purchaseOrders[index].deliveryDate = Date()
        
        // Update Inventory
        products[productIndex].warehouseQuantity += order.quantity
        products[productIndex].lastUpdated = Date()
        
        // Auto-check pending requests that were blocked
        for (reqIndex, request) in requests.enumerated() {
            if request.status == .pending && request.itemId == order.productID {
                if products[productIndex].warehouseQuantity >= request.quantity {
                    // Make it ready to approve
                    // requests[reqIndex].status = .pending
                }
            }
        }
    }
    
    func simulateStoreDelivery(for delivery: AdminDelivery) {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else { return }
        
        // Update delivery status
        deliveries[index].status = .delivered
        deliveries[index].actualDeliveryDate = Date()
        
        // Update associated transfer request
        if let reqIndex = requests.firstIndex(where: { $0.id.uuidString == delivery.transferRequestID }) {
            requests[reqIndex].status = .delivered
        }
    }
    
    func simulateFullDelivery(for delivery: AdminDelivery) async {
        let stepDuration = UInt64(20 * 1_000_000_000) // 20 seconds per transition (3 transitions = 60s / 1 min)
        let id = delivery.id
        
        await MainActor.run {
            if let idx = self.deliveries.firstIndex(where: { $0.id == id }) {
                self.deliveries[idx].status = .preparing
            }
        }
        
        try? await Task.sleep(nanoseconds: stepDuration)
        
        await MainActor.run {
            if let idx = self.deliveries.firstIndex(where: { $0.id == id }) {
                self.deliveries[idx].status = .dispatched
            }
        }
        
        try? await Task.sleep(nanoseconds: stepDuration)
        
        await MainActor.run {
            if let idx = self.deliveries.firstIndex(where: { $0.id == id }) {
                self.deliveries[idx].status = .inTransit
            }
        }
        
        try? await Task.sleep(nanoseconds: stepDuration)
        
        await MainActor.run {
            if let idx = self.deliveries.firstIndex(where: { $0.id == id }) {
                self.deliveries[idx].status = .delivered
                self.deliveries[idx].actualDeliveryDate = Date()
                if let reqIndex = self.requests.firstIndex(where: { $0.id.uuidString == self.deliveries[idx].transferRequestID }) {
                    self.requests[reqIndex].status = .delivered
                }
            }
        }
    }
    
    func product(for id: Int64) -> AdminTransferProduct? {
        products.first(where: { $0.id == id })
    }
    
    private func loadMockData() {
        // Mock data removed
    }
}
