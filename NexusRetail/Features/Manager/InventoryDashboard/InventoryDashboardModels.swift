//
//  InventoryDashboardModels.swift
//  NexusRetail
//

import Foundation

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
    
    /// Returns true if the current stock is strictly less than the minimum required
    var isLowStock: Bool {
        return currentStock < minimumRequired
    }
}
