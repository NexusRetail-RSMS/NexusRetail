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
    var selectedFilter: BOPISOrderStatus = .pending
    
    init() {
    }
    
    var filteredOrders: [BOPISOrder] {
        var result = orders.filter { $0.status == selectedFilter }
        
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
                .select("id, client_id, store_id, associate_id, total, created_at, order_type, status, client!client_id(name, phone), order_line_item(id, quantity, applied_price, products(item_id, item_name))")
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
                        price: lineItem.appliedPrice ?? 0,
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
                    createdAt: dOrder.createdAt,
                    status: bStatus,
                    items: orderItems,
                    itemCount: totalItems,
                    totalAmount: dOrder.total,
                    verificationCode: nil
                )
            }

            await MainActor.run {
                // Newest orders first.
                self.orders = bopisOrders.sorted { $0.createdDate > $1.createdDate }
            }
        } catch {
            print("Failed to fetch BOPIS orders: \(error)")
        }
    }
    
    // MARK: - State Transitions
    
    func packAndNotify(id: UUID, associateID: UUID? = nil) {
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

            Task {
                // Attribute fulfillment to the associate who packs the order.
                // Written separately from status because status persistence is a
                // known pending item ("waitingForCustomer" isn't a valid
                // order_status enum value yet); keeping this write standalone
                // ensures the associate stamp still succeeds.
                if let associateID {
                    do {
                        try await SupabaseManager.shared.client
                            .from("orders")
                            .update(["associate_id": associateID.uuidString])
                            .eq("id", value: id)
                            .execute()
                    } catch {
                        print("Error stamping associate_id on pack: \(error)")
                    }
                }

                // The "packed / waiting for customer" step is tracked in-app only.
                // We intentionally do NOT persist it: order_status is limited to
                // {open, completed, cancelled}, so there's no valid value for this
                // intermediate stage. The order stays 'open' in the DB until it's
                // collected (markCollected writes 'completed'). Persisting this
                // step would require a dedicated pickup_stage column.
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
