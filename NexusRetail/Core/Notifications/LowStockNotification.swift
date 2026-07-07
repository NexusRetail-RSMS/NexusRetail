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

struct LowStockNotification: Identifiable {
    let id: UUID
    let productName: String
    let skuCode: String
    let imageUrl: String?
    let category: String?
    let onHand: Int
    let storeId: UUID
    let timestamp: Date
    
    /// Human-readable time ago string
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Urgency label based on stock count
    var urgencyLabel: String {
        if onHand == 0 { return "Out of Stock" }
        if onHand <= 2 { return "Critical" }
        return "Low Stock"
    }
    
    var urgencyColor: Color {
        if onHand == 0 { return RSMSColors.error }
        if onHand <= 2 { return Color(hex: "E76F51") }
        return RSMSColors.warning
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

// MARK: - ViewModel

@Observable
final class LowStockNotificationViewModel {
    
    var notifications: [LowStockNotification] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    /// IDs the manager has already seen/dismissed
    private var readIDs: Set<UUID> = []
    
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
    }
    
    /// Mark all current notifications as read
    func markAllAsRead() {
        for notification in notifications {
            readIDs.insert(notification.id)
        }
    }
    
    /// Fetch low-stock items (on_hand < 5) from Supabase for the given store
    func load(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            let rows: [LowStockInventoryRow] = try await SupabaseManager.shared.client
                .from("inventory_item")
                .select("id, item_id, store_id, on_hand, products(item_name, sku_code, image_url, category)")
                .eq("store_id", value: storeID.uuidString)
                .lt("on_hand", value: 5)
                .order("on_hand", ascending: true)
                .execute()
                .value
            
            let mapped = rows.map { row in
                LowStockNotification(
                    id: row.id,
                    productName: row.products.itemName ?? "Unknown Product",
                    skuCode: row.products.skuCode ?? "—",
                    imageUrl: row.products.imageUrl,
                    category: row.products.category,
                    onHand: row.onHand,
                    storeId: row.storeId,
                    timestamp: Date() // Current fetch time
                )
            }
            
            await MainActor.run {
                self.notifications = mapped
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
}
