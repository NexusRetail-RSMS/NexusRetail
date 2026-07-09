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
        return 0
    }
    
    var urgencyLabel: String {
        if case .lowStock(let qty, _, _) = type {
            if qty == 0 { return "Out of Stock" }
            if qty <= 2 { return "Critical" }
            return "Low Stock"
        }
        return "Approved"
    }
    
    var urgencyColor: Color {
        let theme = AppTheme()
        if case .lowStock(let qty, _, _) = type {
            if qty == 0 { return theme.error }
            if qty <= 2 { return theme.error.opacity(0.8) } // Using theme error instead of hardcoded hex
            return theme.warning
        }
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

    init() {
        let stored = UserDefaults.standard.stringArray(forKey: Self.readIDsKey) ?? []
        readIDs = Set(stored.compactMap { UUID(uuidString: $0) })
    }

    private func persistReadIDs() {
        UserDefaults.standard.set(readIDs.map { $0.uuidString }, forKey: Self.readIDsKey)
    }
    
    /// Supabase realtime channel for live inventory updates.
    private var realtimeChannel: RealtimeChannelV2?
    
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
    
    /// Fetch low-stock items and approved transfer requests
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
                
            let (lowStockRows, transferRows) = try await (lowStockTask, transfersTask)
            
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
            
            let combined = lowStockMapped + transfersMapped
            
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
    
    /// Subscribe to real-time inventory changes so notifications appear instantly.
    func startListening(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        monitoredStoreID = storeID
        
        // Remove any existing subscription first
        await stopListening()
        
        let channel = SupabaseManager.shared.client.realtimeV2.channel("inventory-low-stock")
        
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "inventory_item",
            filter: "store_id=eq.\(storeID.uuidString)"
        )
        
        await channel.subscribe()
        self.realtimeChannel = channel
        
        // Listen for any inventory changes and reload notifications
        for await _ in changes {
            // Small debounce so batch updates (e.g. multi-item checkout) coalesce
            try? await Task.sleep(for: .milliseconds(500))
            await self.load(storeID: storeID)
        }
    }
    
    /// Unsubscribe from real-time updates.
    func stopListening() async {
        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
        }
    }
}
