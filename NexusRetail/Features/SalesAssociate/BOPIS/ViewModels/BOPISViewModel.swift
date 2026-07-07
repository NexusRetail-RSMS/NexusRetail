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
        lastLoadedStoreID = storeID
        
        do {
            let fetchedOrders: [StoreOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, client_id, store_id, associate_id, total, created_at, order_type, status, pickup_code, client!client_id(name, phone), order_line_item(id, quantity, applied_price, products(item_id, item_name))")
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

                // Derive pickup stage from persisted fields (no invalid enum value):
                //   completed              -> collected
                //   open + pickup_code set -> waiting for customer (packed)
                //   open + no code         -> pending
                let bStatus: BOPISOrderStatus
                if dOrder.status == "completed" || dOrder.status == "collected" {
                    bStatus = .collected
                } else if let code = dOrder.pickupCode, !code.isEmpty {
                    bStatus = .waitingForCustomer
                } else {
                    bStatus = .pending
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
    
    /// Outcome of packing an order, so the UI can show an accurate message.
    enum PackOutcome {
        case emailed        // code sent to the customer
        case noEmail        // customer has no email on file
        case sendFailed     // email service rejected/failed the send
    }

    /// Packs the order: stamps the associate, then asks the backend to generate a
    /// pickup code and email it to the customer. The code is NEVER surfaced to the
    /// associate — only the customer receives it.
    @discardableResult
    func packAndNotify(id: UUID, associateID: UUID? = nil) async -> PackOutcome {
        // Optimistically move to "waiting" in the UI.
        if let index = orders.firstIndex(where: { $0.id == id }) {
            orders[index].status = .waitingForCustomer
        }

        // Attribute fulfillment to the associate who packs the order.
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

        // Generate + email the pickup code server-side.
        var outcome: PackOutcome = .sendFailed
        do {
            struct Params: Encodable { let order_id: String }
            struct Result: Decodable { let ok: Bool; let emailed: Bool?; let reason: String? }
            let result: Result = try await SupabaseManager.shared.client
                .functions
                .invoke("send-pickup-code", options: .init(body: Params(order_id: id.uuidString)))
            if result.emailed == true {
                outcome = .emailed
            } else if result.reason == "no_email" {
                outcome = .noEmail
            } else {
                outcome = .sendFailed
            }
        } catch {
            print("send-pickup-code failed: \(error)")
            outcome = .sendFailed
        }

        await loadData(storeID: lastLoadedStoreID)
        return outcome
    }

    /// Verifies the customer-provided code and, on success, marks the order collected.
    func verifyAndCollect(id: UUID, code: String) async -> Bool {
        struct Params: Encodable { let p_order_id: String; let p_code: String }
        do {
            let ok: Bool = try await SupabaseManager.shared.client
                .rpc("verify_pickup_code", params: Params(p_order_id: id.uuidString, p_code: code))
                .execute()
                .value
            if ok, let index = orders.firstIndex(where: { $0.id == id }) {
                await MainActor.run { orders[index].status = .collected }
            }
            return ok
        } catch {
            print("verify_pickup_code failed: \(error)")
            return false
        }
    }

    // Remembered so post-action reloads (pack/collect) hit the right store.
    private var lastLoadedStoreID: UUID?
}
