//
//  InventoryDashboardModels.swift
//  NexusRetail
//

import Foundation
import SwiftUI

enum InventoryStatus: String, CaseIterable, Identifiable {
    case healthy = "Healthy"
    case lowStock = "Low Stock"
    case critical = "Critical"
    
    var id: String { self.rawValue }
}

enum InventorySortOrder: String, CaseIterable, Identifiable {
    case none = "None"
    case criticalFirst = "Critical First"
    case healthyFirst = "Healthy First"
    
    var id: String { self.rawValue }
}

/// Represents an item in the store's inventory
struct InventoryItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let sku: String
    let category: String
    let currentStock: Int
    let minimumRequired: Int
    let price: Double
    let imageUrl: String?
    
    var status: InventoryStatus {
        if Double(currentStock) <= 0.25 * Double(minimumRequired) {
            return .critical
        } else if currentStock <= minimumRequired {
            return .lowStock
        } else {
            return .healthy
        }
    }
    
    /// Convenience boolean for easy filtering of anything requiring action
    var isLowStock: Bool {
        return status == .lowStock || status == .critical
    }
}

/// Urgency level for a stock request
enum StockRequestUrgency: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var id: String { self.rawValue }
}

/// Payload sent to admin for a single item request
struct StockRequestPayload: Identifiable {
    var id: UUID { item.id }
    let item: InventoryItem
    var quantity: Int
    var urgency: StockRequestUrgency
    var reason: String?
}

/// Overall stock request container
struct StockRequest: Identifiable {
    let id: String // E.g. REQ-20260630-0001
    let date: Date
    let storeId: String
    let managerId: String
    let status: String // E.g. "Pending"
    let items: [StockRequestPayload]
}
