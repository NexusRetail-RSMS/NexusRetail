import Foundation
import SwiftUI

// MARK: - Models

enum TransferRequestStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case approved = "Approved"
    case denied = "Denied"
    case awaitingRestock = "Awaiting Restock"
    case readyForDispatch = "Ready for Dispatch"
    case dispatched = "Dispatched"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .denied: return .red
        case .awaitingRestock: return .yellow
        case .readyForDispatch: return .blue
        case .dispatched: return .gray
        }
    }
}

enum RequestPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct AdminTransferManager: Identifiable, Codable {
    let id: UUID
    let name: String
    let storeName: String
    let email: String
    let phone: String
    let avatarInitials: String
    
    var totalRequests: Int
    var approvedRequests: Int
    var pendingRequests: Int
}

struct AdminTransferStore: Identifiable, Codable {
    let id: UUID
    let name: String
    let location: String
    let managerID: UUID
}

struct AdminTransferProduct: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let sku: String
    let category: String
    var warehouseQuantity: Int
    let reorderLevel: Int
    var lastUpdated: Date
    
    var stockHealth: StockHealth {
        if warehouseQuantity == 0 { return .outOfStock }
        if warehouseQuantity <= reorderLevel { return .lowStock }
        return .inStock
    }
}

enum StockHealth: String, Codable {
    case inStock = "In Stock"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
    
    var color: Color {
        switch self {
        case .inStock: return .green
        case .lowStock: return .orange
        case .outOfStock: return .red
        }
    }
}

struct AdminRequestProfile: Codable {
    let name: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case imageUrl = "image_url"
    }
}

struct AdminRequestStore: Codable {
    let name: String
    let city: String?
    let manager: AdminRequestProfile?
    
    enum CodingKeys: String, CodingKey {
        case name, city
        case manager
    }
}

struct AdminStockRequest: Identifiable, Codable {
    let id: UUID
    let skuId: UUID
    let requestingStoreId: UUID
    let sourceStoreId: UUID?
    let quantity: Int
    let urgency: UrgencyLevel
    var status: TransferStatus
    let createdAt: Date
    let sku: SKUInfo
    let store: AdminRequestStore?
    
    enum CodingKeys: String, CodingKey {
        case id
        case skuId = "sku_id"
        case requestingStoreId = "requesting_store_id"
        case sourceStoreId = "source_store_id"
        case quantity, urgency, status
        case createdAt = "created_at"
        case sku
        case store
    }
    
    var productName: String { sku.name }
    var storeName: String { store?.name ?? "Unknown Store" }
    var managerName: String { store?.manager?.name ?? "No Manager" }
}

enum PurchaseOrderStatus: String, Codable, CaseIterable {
    case ordered = "Ordered"
    case inTransit = "In Transit"
    case delivered = "Delivered"
    
    var color: Color {
        switch self {
        case .ordered: return .blue
        case .inTransit: return .orange
        case .delivered: return .green
        }
    }
}

struct AdminPurchaseOrder: Identifiable, Codable {
    let id: String
    let productID: UUID
    let supplierName: String
    let quantity: Int
    let createdDate: Date
    let estimatedDeliveryDate: Date
    var deliveryDate: Date?
    var status: PurchaseOrderStatus
    var notes: String?
}

// MARK: - Delivery Models

enum DeliveryStatus: String, Codable, CaseIterable {
    case preparing = "Preparing"
    case dispatched = "Dispatched"
    case inTransit = "In Transit"
    case delivered = "Delivered"
    
    var color: Color {
        switch self {
        case .preparing: return .purple
        case .dispatched: return .blue
        case .inTransit: return .orange
        case .delivered: return .green
        }
    }
}

struct AdminDelivery: Identifiable, Codable {
    let id: String
    let transferRequestID: String
    let productID: UUID
    let quantity: Int
    let destinationStoreID: UUID
    let destinationStoreName: String
    let managerID: UUID
    let managerName: String
    let managerAvatarInitials: String
    let dispatchDate: Date
    let estimatedArrival: Date
    var actualDeliveryDate: Date?
    var status: DeliveryStatus
    let trackingNumber: String?
}
