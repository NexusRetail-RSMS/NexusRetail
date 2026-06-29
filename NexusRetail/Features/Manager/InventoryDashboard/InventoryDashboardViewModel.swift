//
//  InventoryDashboardViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI

@Observable
class InventoryDashboardViewModel {
    var inventoryItems: [InventoryItem] = []
    
    init() {
        loadMockData()
    }
    
    var lowStockItems: [InventoryItem] {
        inventoryItems.filter { $0.isLowStock }
    }
    
    private func loadMockData() {
        inventoryItems = [
            InventoryItem(id: UUID(), name: "Premium Leather Jacket", sku: "JKT-001", category: "Apparel", currentStock: 3, minimumRequired: 10, price: 12999, imageUrl: nil),
            InventoryItem(id: UUID(), name: "Classic Cotton T-Shirt", sku: "TSH-042", category: "Apparel", currentStock: 45, minimumRequired: 20, price: 999, imageUrl: nil),
            InventoryItem(id: UUID(), name: "Slim Fit Denim Jeans", sku: "DNM-103", category: "Apparel", currentStock: 2, minimumRequired: 15, price: 3499, imageUrl: nil),
            InventoryItem(id: UUID(), name: "Sports Running Shoes", sku: "SHO-099", category: "Footwear", currentStock: 1, minimumRequired: 12, price: 4999, imageUrl: nil),
            InventoryItem(id: UUID(), name: "Elegant Silk Scarf", sku: "SCF-011", category: "Accessories", currentStock: 8, minimumRequired: 25, price: 1499, imageUrl: nil),
            InventoryItem(id: UUID(), name: "Winter Wool Beanie", sku: "BNI-005", category: "Accessories", currentStock: 15, minimumRequired: 10, price: 799, imageUrl: nil)
        ]
    }
    
    func requestStock(for items: [InventoryItem]) {
        // In a real app, this would send an API request to Supabase.
        print("Stock requested for: \(items.map { $0.name }.joined(separator: ", "))")
        
        // Mock updating the local state (optional for mock, but good for UX)
        // Here we could simulate the items no longer being low stock, or just showing a success message.
    }
}
