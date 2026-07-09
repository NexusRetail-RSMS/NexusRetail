//
//  LowStockNotification.swift
//  NexusRetail
//
//  Model and ViewModel for low-stock notifications.
//  Queries inventory_item where on_hand < 5 from Supabase.
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Model

enum NotificationType: Equatable {
    case lowStock(onHand: Int, skuCode: String, category: String?)
    case transferApproved(quantity: Int)
    /// An inter-store transfer request awaiting this manager's approval.
    /// Includes the requesting store name, quantity, item info, and current stock at the source.
    case transferRequest(quantity: Int, requestingStoreName: String, transferId: UUID, itemId: Int64, sourceOnHand: Int, requestingStoreId: UUID)
}

struct LowStockNotification: Identifiable {
    let id: UUID
    let productName: String
    let imageUrl: String?
    let storeId: UUID
    let timestamp: Date
    let type: NotificationType
    
    /// Human-readable time ago string
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // MARK: - Backwards Compatibility
    var skuCode: String {
        if case .lowStock(_, let sku, _) = type { return sku }
        return "—"
    }
    
    var category: String? {
        if case .lowStock(_, _, let cat) = type { return cat }
        return nil
    }
    
    var onHand: Int {
        if case .lowStock(let qty, _, _) = type { return qty }
        if case .transferApproved(let qty) = type { return qty }
        if case .transferRequest(let qty, _, _, _, _, _) = type { return qty }
        return 0
    }
    
    var urgencyLabel: String {
        if case .lowStock(let qty, _, _) = type {
            if qty == 0 { return "Out of Stock" }
            if qty <= 2 { return "Critical" }
            return "Low Stock"
        }
        if case .transferApproved = type { return "Approved" }
        if case .transferRequest = type { return "Action Required" }
        return "Approved"
    }
    
    var urgencyColor: Color {
        let theme = AppTheme()
        if case .lowStock(let qty, _, _) = type {
            if qty == 0 { return theme.error }
            if qty <= 2 { return theme.error.opacity(0.8) } // Using theme error instead of hardcoded hex
            return theme.warning
        }
        if case .transferRequest = type { return theme.burgundy }
        return theme.success
    }
}

/// Codable DTO for the Supabase query
private struct LowStockInventoryRow: Codable, Identifiable {
    let id: UUID
    let itemId: Int64
    let storeId: UUID
    let onHand: Int
    let products: LowStockProductInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case storeId = "store_id"
        case onHand = "on_hand"
        case products
    }
    
    struct LowStockProductInfo: Codable {
        let itemName: String?
        let skuCode: String?
        let imageUrl: String?
        let category: String?
        
        enum CodingKeys: String, CodingKey {
            case itemName = "item_name"
            case skuCode = "sku_code"
            case imageUrl = "image_url"
            case category
        }
    }
}

private struct ApprovedTransferRow: Codable, Identifiable {
    let id: UUID
    let quantity: Int
    let products: ApprovedTransferProductInfo?
    
    enum CodingKeys: String, CodingKey {
        case id
        case quantity
        case products
    }
    
    struct ApprovedTransferProductInfo: Codable {
        let itemName: String?
        let imageUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case itemName = "item_name"
            case imageUrl = "image_url"
        }
    }
}

/// DTO for inter-store transfer requests targeting this manager's store
private struct IncomingTransferRow: Codable, Identifiable {
    let id: UUID
    let itemId: Int64
    let quantity: Int
    let requestingStoreId: UUID
    let createdAt: Date
    let products: TransferProductInfo?
    let store: TransferStoreInfo?
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case quantity
        case requestingStoreId = "requesting_store_id"
        case createdAt = "created_at"
        case products
        case store
    }
    
    struct TransferProductInfo: Codable {
        let itemName: String?
        let skuCode: String?
        let imageUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case itemName = "item_name"
            case skuCode = "sku_code"
            case imageUrl = "image_url"
        }
    }
    
    struct TransferStoreInfo: Codable {
        let name: String
    }
}

// MARK: - ViewModel

@Observable
final class LowStockNotificationViewModel {
    
    var notifications: [LowStockNotification] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    /// IDs the manager has already seen/dismissed (persisted so they stay read).
    private var readIDs: Set<UUID> = []
    private static let readIDsKey = "managerReadNotificationIDs"
    
    /// The store we're monitoring — kept so the realtime callback can reload.
    private var monitoredStoreID: UUID?

    /// Tracks which transfer request is currently showing the decline reason input
    var declineTargetId: UUID? = nil
    var declineReasonText: String = ""
    var isProcessingAction: Bool = false

    init() {
        let stored = UserDefaults.standard.stringArray(forKey: Self.readIDsKey) ?? []
        readIDs = Set(stored.compactMap { UUID(uuidString: $0) })
    }

    private func persistReadIDs() {
        UserDefaults.standard.set(readIDs.map { $0.uuidString }, forKey: Self.readIDsKey)
    }
    
    /// Supabase realtime channel for live inventory updates.
    private var realtimeChannel: RealtimeChannelV2?
    /// Supabase realtime channel for live transfer request updates.
    private var transferRealtimeChannel: RealtimeChannelV2?
    
    /// Number of unread notifications
    var unreadCount: Int {
        notifications.filter { !readIDs.contains($0.id) }.count
    }
    
    /// Whether a specific notification has been read
    func isRead(_ notification: LowStockNotification) -> Bool {
        readIDs.contains(notification.id)
    }
    
    /// Mark a single notification as read
    func markAsRead(_ id: UUID) {
        readIDs.insert(id)
        persistReadIDs()
    }
    
    /// Mark all current notifications as read
    func markAllAsRead() {
        for notification in notifications {
            readIDs.insert(notification.id)
        }
        persistReadIDs()
    }
    
    /// Fetch low-stock items, approved transfer requests, and incoming inter-store transfer requests
    func load(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            async let lowStockTask: [LowStockInventoryRow] = SupabaseManager.shared.client
                .from("inventory_item")
                .select("id, item_id, store_id, on_hand, products(item_name, sku_code, image_url, category)")
                .eq("store_id", value: storeID.uuidString)
                .lt("on_hand", value: 5)
                .order("on_hand", ascending: true)
                .execute()
                .value
                
            async let transfersTask: [ApprovedTransferRow] = SupabaseManager.shared.client
                .from("transfer_request")
                .select("id, quantity, products:item_id(item_name, image_url)")
                .eq("requesting_store_id", value: storeID.uuidString)
                .eq("status", value: "approved")
                .execute()
                .value
            
            // Incoming inter-store requests: this store is the SOURCE, awaiting manager approval
            async let incomingRequestsTask: [IncomingTransferRow] = SupabaseManager.shared.client
                .from("transfer_request")
                .select("id, item_id, quantity, requesting_store_id, created_at, products:item_id(item_name, sku_code, image_url), store:requesting_store_id(name)")
                .eq("source_store_id", value: storeID.uuidString)
                .eq("status", value: "pending_store_approval")
                .execute()
                .value
                
            let (lowStockRows, transferRows, incomingRows) = try await (lowStockTask, transfersTask, incomingRequestsTask)
            
            // Fetch current stock for each incoming request's item at this store
            var stockMap: [Int64: Int] = [:]
            let uniqueItemIds = Set(incomingRows.map { $0.itemId })
            if !uniqueItemIds.isEmpty {
                struct StockRow: Decodable {
                    let item_id: Int64
                    let on_hand: Int
                }
                for itemId in uniqueItemIds {
                    if let row: StockRow = try? await SupabaseManager.shared.client
                        .from("inventory_item")
                        .select("item_id, on_hand")
                        .eq("store_id", value: storeID.uuidString)
                        .eq("item_id", value: Int(itemId))
                        .single()
                        .execute()
                        .value {
                        stockMap[itemId] = row.on_hand
                    }
                }
            }
            
            let lowStockMapped = lowStockRows.map { row in
                LowStockNotification(
                    id: row.id,
                    productName: row.products.itemName ?? "Unknown Product",
                    imageUrl: row.products.imageUrl,
                    storeId: row.storeId,
                    timestamp: Date(), // Current fetch time
                    type: .lowStock(onHand: row.onHand, skuCode: row.products.skuCode ?? "—", category: row.products.category)
                )
            }
            
            let transfersMapped = transferRows.map { row in
                LowStockNotification(
                    id: row.id,
                    productName: row.products?.itemName ?? "Unknown Transfer",
                    imageUrl: row.products?.imageUrl,
                    storeId: storeID,
                    timestamp: Date(), // Current fetch time
                    type: .transferApproved(quantity: row.quantity)
                )
            }
            
            let incomingMapped = incomingRows.map { row in
                LowStockNotification(
                    id: row.id,
                    productName: row.products?.itemName ?? "Unknown Product",
                    imageUrl: row.products?.imageUrl,
                    storeId: storeID,
                    timestamp: row.createdAt,
                    type: .transferRequest(
                        quantity: row.quantity,
                        requestingStoreName: row.store?.name ?? "Unknown Store",
                        transferId: row.id,
                        itemId: row.itemId,
                        sourceOnHand: stockMap[row.itemId] ?? 0,
                        requestingStoreId: row.requestingStoreId
                    )
                )
            }
            
            // Transfer requests first (actionable), then low stock, then approved
            let combined = incomingMapped + lowStockMapped + transfersMapped
            
            await MainActor.run {
                self.notifications = combined
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            print("LowStockNotification fetch error: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Transfer Request Actions
    
    /// Approve an inter-store transfer: move stock from this store to the requesting store
    func approveTransferRequest(transferId: UUID, itemId: Int64, quantity: Int, sourceStoreId: UUID, requestingStoreId: UUID) async {
        await MainActor.run { isProcessingAction = true }
        
        do {
            struct ApproveParams: Encodable {
                let p_transfer_id: UUID
                let p_item_id: Int64
                let p_quantity: Int
                let p_source_store_id: UUID
                let p_requesting_store_id: UUID
            }
            
            let params = ApproveParams(
                p_transfer_id: transferId,
                p_item_id: itemId,
                p_quantity: quantity,
                p_source_store_id: sourceStoreId,
                p_requesting_store_id: requestingStoreId
            )
            
            try await SupabaseManager.shared.client
                .rpc("approve_store_transfer", params: params)
                .execute()
            
            // Remove from local notifications
            await MainActor.run {
                notifications.removeAll { $0.id == transferId }
                isProcessingAction = false
            }
            
            // Reload to reflect updated stock
            await load(storeID: sourceStoreId)
        } catch {
            print("Failed to approve transfer request: \(error)")
            await MainActor.run { isProcessingAction = false }
        }
    }
    
    /// Decline an inter-store transfer: escalate back to admin
    func declineTransferRequest(transferId: UUID, reason: String, storeID: UUID) async {
        await MainActor.run { isProcessingAction = true }
        
        do {
            struct DeclineUpdate: Encodable {
                let status: String
                let source_store_id: UUID?
                let decline_reason: String
            }
            
            try await SupabaseManager.shared.client
                .from("transfer_request")
                .update(DeclineUpdate(
                    status: "pending",
                    source_store_id: nil,
                    decline_reason: reason.isEmpty ? "Declined by store manager" : reason
                ))
                .eq("id", value: transferId)
                .execute()
            
            // Remove from local notifications
            await MainActor.run {
                notifications.removeAll { $0.id == transferId }
                declineTargetId = nil
                declineReasonText = ""
                isProcessingAction = false
            }
            
            // Reload
            await load(storeID: storeID)
        } catch {
            print("Failed to decline transfer request: \(error)")
            await MainActor.run { isProcessingAction = false }
        }
    }
    
    /// Subscribe to real-time inventory changes so notifications appear instantly.
    func startListening(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        monitoredStoreID = storeID
        
        // Remove any existing subscription first
        await stopListening()
        
        // Channel 1: Inventory changes (low stock alerts)
        let inventoryChannelName = "inventory-low-stock-\(UUID().uuidString)"
        let inventoryChannel = SupabaseManager.shared.client.realtimeV2.channel(inventoryChannelName)
        
        let inventoryChanges = inventoryChannel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "inventory_item",
            filter: .eq("store_id", value: storeID.uuidString)
        )
        
        try? await inventoryChannel.subscribeWithError()
        self.realtimeChannel = inventoryChannel
        
        // Channel 2: Transfer request changes (inter-store approval notifications)
        let transferChannelName = "transfer-requests-\(UUID().uuidString)"
        let transferChannel = SupabaseManager.shared.client.realtimeV2.channel(transferChannelName)
        
        let transferChanges = transferChannel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "transfer_request",
            filter: .eq("source_store_id", value: storeID.uuidString)
        )
        
        try? await transferChannel.subscribeWithError()
        self.transferRealtimeChannel = transferChannel
        
        // Listen for inventory changes
        Task {
            for await _ in inventoryChanges {
                try? await Task.sleep(for: .milliseconds(500))
                await self.load(storeID: storeID)
            }
        }
        
        // Listen for transfer request changes
        Task {
            for await _ in transferChanges {
                try? await Task.sleep(for: .milliseconds(500))
                await self.load(storeID: storeID)
            }
        }
    }
    
    /// Unsubscribe from real-time updates.
    func stopListening() async {
        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
        }
        if let channel = transferRealtimeChannel {
            await channel.unsubscribe()
            transferRealtimeChannel = nil
        }
    }
}
