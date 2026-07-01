import Foundation
import SwiftUI

// MARK: - Approval Method

enum ApprovalMethod: String, Codable {
    case immediate = "Immediate"
    case scheduled = "Scheduled"
    case early = "Early"

    var label: String {
        switch self {
        case .immediate: return ""
        case .scheduled: return "Scheduled Approval"
        case .early: return "Approved Early"
        }
    }
}

// MARK: - Supporting Models

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

// MARK: - Main Transfer Request

struct AdminStockRequest: Identifiable, Codable {
    let id: UUID
    let skuId: UUID
    let requestingStoreId: UUID
    let sourceStoreId: UUID?
    let quantity: Int
    var status: TransferStatus
    let createdAt: Date
    var updatedAt: Date?
    let sku: SKUInfo
    let store: AdminRequestStore?

    var scheduledAt: Date?
    var autoApproveAt: Date?
    var approvedAt: Date?
    var approvalMethod: ApprovalMethod?

    enum CodingKeys: String, CodingKey {
        case id
        case skuId = "sku_id"
        case requestingStoreId = "requesting_store_id"
        case sourceStoreId = "source_store_id"
        case quantity, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sku
        case store
    }

    var productName: String { sku.name }
    var skuCode: String { sku.skuCode ?? "\u{2014}" }
    var storeName: String { store?.name ?? "Unknown Store" }
    var managerName: String { store?.manager?.name ?? "No Manager" }
}
