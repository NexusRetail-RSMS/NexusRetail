//
//  BOPISViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI
import Supabase

@Observable
class BOPISViewModel {
    var orders: [BOPISOrder] = []
    var searchText: String = ""
    var selectedFilter: BOPISOrderStatus? = nil // nil means "All"
    
    init() {
    }
    
    var filteredOrders: [BOPISOrder] {
        var result = orders
        
        // Exclude collected from default "All" view to keep it clean, unless explicitly searching?
        // Let's just filter strictly based on selectedFilter.
        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        } else {
            // For "All" we might want to exclude collected to keep active queue clean, but let's follow standard "All" definition.
            // Requirement says "The order disappears from the active pickup list." when collected.
            // So we will hide Collected from "All" by default.
            result = result.filter { $0.status != .collected }
        }
        
        if !searchText.isEmpty {
            result = result.filter { order in
                order.customerName.localizedCaseInsensitiveContains(searchText) ||
                order.orderId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    // MARK: - API Calls
    func loadData(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        do {
            let fetchedOrders: [StoreOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, client_id, store_id, associate_id, total, created_at, order_type, status, client!client_id(name, phone), order_line_item(id, quantity, products(item_id, item_name))")
                .eq("store_id", value: storeID)
                .eq("order_type", value: "bopis")
                .execute()
                .value
            
            let bopisOrders = fetchedOrders.map { dOrder -> BOPISOrder in
                
                let orderItems = dOrder.orderLineItems?.map { lineItem in
                    BOPISOrderItem(
                        id: lineItem.id ?? UUID(),
                        name: lineItem.products?.itemName ?? "Unknown Item",
                        sku: "SKU-\(lineItem.products?.itemId ?? 0)",
                        quantity: lineItem.quantity,
                        price: 0, // Mocked for BOPISOrderItem if not available
                        qrCode: "",
                        imageUrl: nil
                    )
                } ?? []
                
                let totalItems = orderItems.reduce(0) { $0 + $1.quantity }
                
                let bStatus: BOPISOrderStatus
                switch dOrder.status {
                case "pending": bStatus = .pending
                case "waitingForCustomer": bStatus = .waitingForCustomer
                case "collected", "completed": bStatus = .collected
                default: bStatus = .pending
                }
                
                return BOPISOrder(
                    id: dOrder.id,
                    orderId: "ORD-\(dOrder.id.uuidString.prefix(8).uppercased())",
                    customerName: dOrder.client?.name ?? "Guest",
                    phoneNumber: dOrder.client?.phone ?? "No Phone",
                    pickupTime: dOrder.createdAt.prefix(10).description,
                    status: bStatus,
                    items: orderItems,
                    itemCount: totalItems,
                    totalAmount: dOrder.total,
                    verificationCode: nil
                )
            }
            
            await MainActor.run {
                self.orders = bopisOrders.sorted { $0.pickupTime > $1.pickupTime }
            }
        } catch {
            print("Failed to fetch BOPIS orders: \(error)")
        }
    }
    
    // MARK: - State Transitions
    
    func packAndNotify(id: UUID) {
        if let index = orders.firstIndex(where: { $0.id == id }) {
            let order = orders[index]
            let initials = order.customerName.components(separatedBy: " ")
                .compactMap { $0.first }
                .map { String($0) }
                .joined()
                .uppercased()
            let randomCode = String(format: "%04d", Int.random(in: 1000...9999))
            let code = "\(initials)-\(randomCode)"
            
            orders[index].verificationCode = code
            orders[index].status = .waitingForCustomer
            
            // Execute Supabase update
            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("orders")
                        .update(["status": "waitingForCustomer"])
                        .eq("id", value: id)
                        .execute()
                } catch {
                    print("Error updating status to waitingForCustomer: \(error)")
                }
            }
        }
    }
    
    func markCollected(id: UUID) {
        if let index = orders.firstIndex(where: { $0.id == id }) {
            orders[index].status = .collected
            
            // Execute Supabase update
            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("orders")
                        .update(["status": "completed"])
                        .eq("id", value: id)
                        .execute()
                } catch {
                    print("Error updating status to completed: \(error)")
                }
            }
        }
    }
}
