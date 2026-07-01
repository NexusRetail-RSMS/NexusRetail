//
//  InventoryDashboardModels.swift
//  NexusRetail
//
//  Data models for the Manager Inventory screen.
//  Includes Codable DTOs for Supabase queries plus local enums/structs.
//

import Foundation
import SwiftUI

// MARK: - Enums

/// Stock health status derived from on_hand vs reorder_threshold
enum StockStatus: String {
    case inStock = "In Stock"
    case low = "Low"
    case outOfStock = "Out"
    
    var color: Color {
        switch self {
        case .inStock: return RSMSColors.success
        case .low: return RSMSColors.warning
        case .outOfStock: return RSMSColors.error
        }
    }
    
    var icon: String {
        switch self {
        case .inStock: return "checkmark.circle.fill"
        case .low: return "exclamationmark.triangle.fill"
        case .outOfStock: return "xmark.circle.fill"
        }
    }
}

/// Filter for the inventory list
enum InventoryFilter: String, CaseIterable {
    case allItems = "All Items"
    case lowStock = "Low Stock"
}

/// Sort options for the inventory list
enum InventorySortOrder: String, CaseIterable {
    case stockLowToHigh = "Stock: Low → High"
    case nameAZ = "Name: A → Z"
    case category = "Category"
    case valueHighToLow = "Value: High → Low"
}

/// Product categories from the database
enum InventoryCategory: String, CaseIterable {
    case accessories = "Accessories"
    case bags = "Bags"
    case clothes = "Clothes"
    case fragrances = "Fragrances"
    case jewelry = "Jewelry"
    case leatherGoods = "Leather Goods"
    case shoes = "Shoes"
    case watches = "Watches"
    
    var icon: String {
        switch self {
        case .accessories: return "sparkles"
        case .bags: return "bag.fill"
        case .clothes: return "tshirt.fill"
        case .fragrances: return "drop.fill"
        case .jewelry: return "diamond.fill"
        case .leatherGoods: return "bag.fill"
        case .shoes: return "shoe.fill"
        case .watches: return "clock.fill"
        }
    }
}

/// Transfer request status — matches the DB enum
enum TransferStatus: String, Codable, CaseIterable {
    case pending
    case approved
    case routed
    case dispatched
    case delivered
    case unfulfillable
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .pending: return RSMSColors.warning
        case .approved: return RSMSColors.burgundy.opacity(0.6)
        case .routed: return RSMSColors.burgundy.opacity(0.8)
        case .dispatched: return RSMSColors.burgundy
        case .delivered: return RSMSColors.success
        case .unfulfillable: return RSMSColors.error
        }
    }
    
    /// Position in the status pipeline (0-based)
    var step: Int {
        switch self {
        case .pending: return 0
        case .approved: return 1
        case .routed: return 2
        case .dispatched: return 3
        case .delivered: return 4
        case .unfulfillable: return 5
        }
    }
}

/// Urgency level — matches the DB enum
enum UrgencyLevel: String, Codable, CaseIterable {
    case low
    case medium
    case high
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return RSMSColors.success
        case .medium: return RSMSColors.warning
        case .high: return RSMSColors.error
        }
    }
}

// MARK: - Codable DTOs

/// Nested SKU info returned by the Supabase join
struct SKUInfo: Codable {
    let name: String
    let category: String?
    let skuCode: String?
    let imageUrl: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case name, category, description
        case skuCode = "sku_code"
        case imageUrl = "image_url"
        case priceBand = "price_band"
        case storePrice = "store_price"
    }
    
    let priceBand: [PriceBandInfo]?
    let storePrice: [StorePriceInfo]?
}

/// Nested price band info
struct PriceBandInfo: Codable {
    let basePrice: Double
    let floorPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case basePrice = "base_price"
        case floorPrice = "floor_price"
    }
}

/// Nested store price info
struct StorePriceInfo: Codable {
    let localPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case localPrice = "local_price"
    }
}

/// An inventory item row from Supabase with joined SKU + price info
struct InventoryItemRow: Codable, Identifiable {
    let id: UUID
    let skuId: UUID
    let storeId: UUID
    let onHand: Int
    let reorderThreshold: Int
    let sku: SKUInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case skuId = "sku_id"
        case storeId = "store_id"
        case onHand = "on_hand"
        case reorderThreshold = "reorder_threshold"
        case sku
    }
    
    // MARK: Computed Helpers
    
    var name: String { sku.name }
    var category: String { sku.category ?? "Uncategorized" }
    var skuCode: String { sku.skuCode ?? "—" }
    var imageUrl: String? { sku.imageUrl }
    
    var basePrice: Double { sku.priceBand?.first?.basePrice ?? 0 }
    var floorPrice: Double { sku.priceBand?.first?.floorPrice ?? 0 }
    var localPrice: Double { sku.storePrice?.first?.localPrice ?? basePrice }
    
    /// Stock health status
    var stockStatus: StockStatus {
        if onHand == 0 { return .outOfStock }
        if onHand <= reorderThreshold { return .low }
        return .inStock
    }
    
    /// Progress of on_hand relative to a "healthy" level (2× threshold or at least 20)
    var stockProgress: Double {
        let target = max(Double(reorderThreshold) * 2.0, 20.0)
        return min(Double(onHand) / target, 1.0)
    }
    
    /// Color for the progress bar
    var progressColor: Color {
        stockStatus.color
    }
    
    /// Inventory value = on_hand × local_price (or base_price)
    var inventoryValue: Double {
        Double(onHand) * localPrice
    }
    
    /// Formatted price string with Lac/Cr
    var formattedValue: String {
        formatIndianCurrency(inventoryValue)
    }
    
    var isLowStock: Bool {
        onHand <= reorderThreshold
    }
}

/// A transfer request row from Supabase with joined SKU info
struct TransferRequestRow: Codable, Identifiable {
    let id: UUID
    let skuId: UUID
    let requestingStoreId: UUID
    let sourceStoreId: UUID?
    let quantity: Int
    let urgency: UrgencyLevel
    let status: TransferStatus
    let createdAt: Date
    let sku: SKUInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case skuId = "sku_id"
        case requestingStoreId = "requesting_store_id"
        case sourceStoreId = "source_store_id"
        case quantity, urgency, status
        case createdAt = "created_at"
        case sku
    }
    
    var productName: String { sku.name }
    var skuCode: String { sku.skuCode ?? "—" }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}

/// Insert payload for creating a new transfer request
struct TransferRequestInsert: Codable {
    let skuId: UUID
    let requestingStoreId: UUID
    let quantity: Int
    let urgency: UrgencyLevel
    let status: TransferStatus
    
    enum CodingKeys: String, CodingKey {
        case skuId = "sku_id"
        case requestingStoreId = "requesting_store_id"
        case quantity, urgency, status
    }
}

/// Insert/upsert payload for store_price
struct StorePriceUpsert: Codable {
    let skuId: UUID
    let storeId: UUID
    let localPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case skuId = "sku_id"
        case storeId = "store_id"
        case localPrice = "local_price"
    }
}

// MARK: - Summary

/// Aggregated inventory metrics for the summary strip
struct InventorySummary {
    let totalSKUs: Int
    let unitsInStock: Int
    let outOfStock: Int
    let inventoryValue: Double
    let lowStockCount: Int
    
    var formattedValue: String {
        formatIndianCurrency(inventoryValue)
    }
    
    static let empty = InventorySummary(totalSKUs: 0, unitsInStock: 0, outOfStock: 0, inventoryValue: 0, lowStockCount: 0)
}

// MARK: - Currency Formatting Helper

/// Formats a number into Indian ₹ with Lac / Cr suffixes
func formatIndianCurrency(_ value: Double) -> String {
    if value >= 1_00_00_000 {
        let cr = value / 1_00_00_000
        return String(format: "₹%.1fCr", cr)
    } else if value >= 1_00_000 {
        let lac = value / 1_00_000
        return String(format: "₹%.1fL", lac)
    } else if value >= 1_000 {
        let k = value / 1_000
        return String(format: "₹%.1fK", k)
    } else {
        return String(format: "₹%.0f", value)
    }
}

// MARK: - Mock Data

extension InventoryItemRow {
    static let mockItems: [InventoryItemRow] = [
        InventoryItemRow(id: UUID(), skuId: UUID(), storeId: UUID(), onHand: 13, reorderThreshold: 5,
                         sku: SKUInfo(name: "Imperial Ring #23", category: "Jewelry", skuCode: "JEW-4909", imageUrl: "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400", description: nil, priceBand: [PriceBandInfo(basePrice: 192722.46, floorPrice: 163814.09)], storePrice: nil)),
        InventoryItemRow(id: UUID(), skuId: UUID(), storeId: UUID(), onHand: 9, reorderThreshold: 5,
                         sku: SKUInfo(name: "Heritage Wallet #24", category: "Accessories", skuCode: "ACC-5403", imageUrl: "https://images.unsplash.com/photo-1601333144130-8c1f12356224?w=400", description: nil, priceBand: [PriceBandInfo(basePrice: 45000, floorPrice: 38000)], storePrice: nil)),
        InventoryItemRow(id: UUID(), skuId: UUID(), storeId: UUID(), onHand: 2, reorderThreshold: 5,
                         sku: SKUInfo(name: "Celeste Watch #9", category: "Watches", skuCode: "WAT-2254", imageUrl: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400", description: nil, priceBand: [PriceBandInfo(basePrice: 350000, floorPrice: 280000)], storePrice: nil)),
        InventoryItemRow(id: UUID(), skuId: UUID(), storeId: UUID(), onHand: 0, reorderThreshold: 3,
                         sku: SKUInfo(name: "Noir Leather Bag", category: "Leather Goods", skuCode: "LEA-7385", imageUrl: "https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=400", description: nil, priceBand: [PriceBandInfo(basePrice: 125000, floorPrice: 100000)], storePrice: nil)),
        InventoryItemRow(id: UUID(), skuId: UUID(), storeId: UUID(), onHand: 25, reorderThreshold: 10,
                         sku: SKUInfo(name: "Silk Scarf Royale", category: "Accessories", skuCode: "ACC-1122", imageUrl: "https://images.unsplash.com/photo-1601333144130-8c1f12356224?w=400", description: nil, priceBand: [PriceBandInfo(basePrice: 18000, floorPrice: 14000)], storePrice: nil)),
        InventoryItemRow(id: UUID(), skuId: UUID(), storeId: UUID(), onHand: 4, reorderThreshold: 8,
                         sku: SKUInfo(name: "Crystal Earrings Duo", category: "Jewelry", skuCode: "JEW-3310", imageUrl: "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400", description: nil, priceBand: [PriceBandInfo(basePrice: 78000, floorPrice: 62000)], storePrice: nil)),
        InventoryItemRow(id: UUID(), skuId: UUID(), storeId: UUID(), onHand: 30, reorderThreshold: 5,
                         sku: SKUInfo(name: "Oxford Dress Shoes", category: "Shoes", skuCode: "SHO-0044", imageUrl: "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400", description: nil, priceBand: [PriceBandInfo(basePrice: 28000, floorPrice: 22000)], storePrice: nil))
    ]
}

extension TransferRequestRow {
    static let mockRequests: [TransferRequestRow] = [
        TransferRequestRow(id: UUID(), skuId: UUID(), requestingStoreId: UUID(), sourceStoreId: nil, quantity: 10, urgency: .high, status: .pending, createdAt: Date().addingTimeInterval(-86400),
                           sku: SKUInfo(name: "Celeste Watch #9", category: "Watches", skuCode: "WAT-2254", imageUrl: nil, description: nil, priceBand: nil, storePrice: nil)),
        TransferRequestRow(id: UUID(), skuId: UUID(), requestingStoreId: UUID(), sourceStoreId: nil, quantity: 5, urgency: .medium, status: .approved, createdAt: Date().addingTimeInterval(-172800),
                           sku: SKUInfo(name: "Noir Leather Bag", category: "Leather Goods", skuCode: "LEA-7385", imageUrl: nil, description: nil, priceBand: nil, storePrice: nil)),
        TransferRequestRow(id: UUID(), skuId: UUID(), requestingStoreId: UUID(), sourceStoreId: UUID(), quantity: 20, urgency: .low, status: .dispatched, createdAt: Date().addingTimeInterval(-345600),
                           sku: SKUInfo(name: "Crystal Earrings Duo", category: "Jewelry", skuCode: "JEW-3310", imageUrl: nil, description: nil, priceBand: nil, storePrice: nil))
    ]
}
