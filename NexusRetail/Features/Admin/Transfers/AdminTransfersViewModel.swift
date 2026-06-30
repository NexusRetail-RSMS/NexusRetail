import Foundation
import SwiftUI

@Observable
class AdminTransfersViewModel {
    var requests: [AdminStockRequest] = []
    var products: [AdminTransferProduct] = []
    var purchaseOrders: [AdminPurchaseOrder] = []
    var deliveries: [AdminDelivery] = []
    
    // Shared managers & stores across view models
    var managers: [AdminTransferManager] = []
    var stores: [AdminTransferStore] = []
    
    init() {
        loadMockData()
    }
    
    func approveRequest(_ request: AdminStockRequest) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }),
              let productIndex = products.firstIndex(where: { $0.id == request.productID }) else { return }
        
        if products[productIndex].warehouseQuantity >= request.requestedQuantity {
            // Deduct stock
            products[productIndex].warehouseQuantity -= request.requestedQuantity
            products[productIndex].lastUpdated = Date()
            
            // Update request
            requests[index].status = .approved
            requests[index].dispatchStatus = "Ready for Dispatch"
            
            // Increment manager's approved count
            if let managerIndex = managers.firstIndex(where: { $0.id == request.managerID }) {
                managers[managerIndex].approvedRequests += 1
                managers[managerIndex].pendingRequests = max(0, managers[managerIndex].pendingRequests - 1)
                
                // Create a delivery
                if let store = store(for: request.storeID) {
                    let newDelivery = AdminDelivery(
                        id: "DEL-\(Int.random(in: 1000...9999))",
                        transferRequestID: request.id,
                        productID: request.productID,
                        quantity: request.requestedQuantity,
                        destinationStoreID: store.id,
                        destinationStoreName: store.name,
                        managerID: managers[managerIndex].id,
                        managerName: managers[managerIndex].name,
                        managerAvatarInitials: managers[managerIndex].avatarInitials,
                        dispatchDate: Date(),
                        estimatedArrival: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                        status: .preparing,
                        trackingNumber: "TRK\(Int.random(in: 10000000...99999999))"
                    )
                    deliveries.insert(newDelivery, at: 0)
                }
            }
        }
    }
    
    func denyRequest(_ request: AdminStockRequest, reason: String) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else { return }
        
        requests[index].status = .denied
        requests[index].denialReason = reason
        
        if let managerIndex = managers.firstIndex(where: { $0.id == request.managerID }) {
            managers[managerIndex].pendingRequests = max(0, managers[managerIndex].pendingRequests - 1)
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
                if request.status == .awaitingRestock && request.productID == product.id {
                    if products[productIndex].warehouseQuantity >= request.requestedQuantity {
                        requests[reqIndex].status = .pending
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
            if request.status == .awaitingRestock && request.productID == order.productID {
                if products[productIndex].warehouseQuantity >= request.requestedQuantity {
                    // Make it ready to approve
                    requests[reqIndex].status = .pending
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
        if let reqIndex = requests.firstIndex(where: { $0.id == delivery.transferRequestID }) {
            requests[reqIndex].status = .approved
            requests[reqIndex].dispatchStatus = "Delivered"
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
                if let reqIndex = self.requests.firstIndex(where: { $0.id == self.deliveries[idx].transferRequestID }) {
                    self.requests[reqIndex].status = .approved
                    self.requests[reqIndex].dispatchStatus = "Delivered"
                }
            }
        }
    }
    
    func product(for id: UUID) -> AdminTransferProduct? {
        products.first(where: { $0.id == id })
    }
    
    func manager(for id: UUID) -> AdminTransferManager? {
        managers.first(where: { $0.id == id })
    }
    
    func store(for id: UUID) -> AdminTransferStore? {
        stores.first(where: { $0.id == id })
    }
    
    private func loadMockData() {
        let m1 = AdminTransferManager(id: UUID(), name: "Aisha Sharma", storeName: "Dehradun Mall Store", email: "aisha@nexus.com", phone: "+91 9876543210", avatarInitials: "AS", totalRequests: 15, approvedRequests: 12, pendingRequests: 3)
        let m2 = AdminTransferManager(id: UUID(), name: "Ravi Kumar", storeName: "Delhi Central", email: "ravi@nexus.com", phone: "+91 9123456789", avatarInitials: "RK", totalRequests: 8, approvedRequests: 7, pendingRequests: 1)
        managers = [m1, m2]
        
        let s1 = AdminTransferStore(id: UUID(), name: "Dehradun Mall Store", location: "Dehradun", managerID: m1.id)
        let s2 = AdminTransferStore(id: UUID(), name: "Delhi Central", location: "New Delhi", managerID: m2.id)
        stores = [s1, s2]
        
        let p1 = AdminTransferProduct(id: UUID(), name: "Nike Running Shoes", sku: "NRS-100", category: "Footwear", warehouseQuantity: 12, reorderLevel: 20, lastUpdated: Date())
        let p2 = AdminTransferProduct(id: UUID(), name: "Adidas Classic Tee", sku: "ACT-200", category: "Apparel", warehouseQuantity: 50, reorderLevel: 10, lastUpdated: Date())
        let p3 = AdminTransferProduct(id: UUID(), name: "Puma Sports Bag", sku: "PSB-300", category: "Accessories", warehouseQuantity: 2, reorderLevel: 5, lastUpdated: Date())
        let p4 = AdminTransferProduct(id: UUID(), name: "Under Armour Cap", sku: "UAC-400", category: "Accessories", warehouseQuantity: 0, reorderLevel: 15, lastUpdated: Date())
        products = [p1, p2, p3, p4]
        
        let r1 = AdminStockRequest(id: "SR-1001", managerID: m1.id, storeID: s1.id, productID: p1.id, requestedQuantity: 20, warehouseQuantityAtRequest: 12, requestDate: Date().addingTimeInterval(-86400), priority: .high, status: .pending)
        let r2 = AdminStockRequest(id: "SR-1002", managerID: m2.id, storeID: s2.id, productID: p2.id, requestedQuantity: 10, warehouseQuantityAtRequest: 50, requestDate: Date().addingTimeInterval(-3600), priority: .low, status: .pending)
        let r3 = AdminStockRequest(id: "SR-1003", managerID: m1.id, storeID: s1.id, productID: p3.id, requestedQuantity: 5, warehouseQuantityAtRequest: 2, requestDate: Date().addingTimeInterval(-172800), priority: .medium, status: .awaitingRestock)
        let r4 = AdminStockRequest(id: "SR-1004", managerID: m2.id, storeID: s2.id, productID: p4.id, requestedQuantity: 10, warehouseQuantityAtRequest: 0, requestDate: Date().addingTimeInterval(-400000), priority: .high, status: .denied, denialReason: "No expected stock for next 3 months")
        requests = [r1, r2, r3, r4]
        let po1 = AdminPurchaseOrder(id: "PO-4050", productID: p4.id, supplierName: "Global Sports Inc", quantity: 50, createdDate: Date().addingTimeInterval(-86400 * 2), estimatedDeliveryDate: Date().addingTimeInterval(86400), status: .inTransit, notes: "Urgent refill")
        purchaseOrders = [po1]
        
        let d1 = AdminDelivery(
            id: "DEL-8812",
            transferRequestID: r1.id,
            productID: p1.id,
            quantity: 5,
            destinationStoreID: s1.id,
            destinationStoreName: s1.name,
            managerID: m1.id,
            managerName: m1.name,
            managerAvatarInitials: m1.avatarInitials,
            dispatchDate: Date().addingTimeInterval(-86400),
            estimatedArrival: Date().addingTimeInterval(3600),
            status: .inTransit,
            trackingNumber: "TRK987654321"
        )
        deliveries = [d1]
    }
}
