//
//  InventoryDashboardViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI

@Observable
class InventoryDashboardViewModel {
    var inventoryItems: [InventoryItem] = []
    
    var searchText: String = ""
    var sortOrder: InventorySortOrder = .criticalFirst
    
    var pendingRequestsCount: Int = 0
    var showSuccessToast: Bool = false
    
    init() {
        loadMockData()
    }
    
    var filteredItems: [InventoryItem] {
        var result = inventoryItems
        
        // We removed selectedFilter chips, so we just use all items initially
        
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.sku.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
        switch sortOrder {
        case .criticalFirst:
            result.sort {
                // Stock / Minimum ratio ascending (Critical first)
                let ratio1 = Double($0.currentStock) / Double($0.minimumRequired)
                let ratio2 = Double($1.currentStock) / Double($1.minimumRequired)
                return ratio1 < ratio2
            }
        case .healthyFirst:
            result.sort {
                let ratio1 = Double($0.currentStock) / Double($0.minimumRequired)
                let ratio2 = Double($1.currentStock) / Double($1.minimumRequired)
                return ratio1 > ratio2
            }
        }
        
        return result
    }
    
    var lowStockItems: [InventoryItem] {
        inventoryItems.filter { $0.isLowStock }
    }
    
    private func loadMockData() {
        inventoryItems = [
            // Current 3, Min 10 => 30% => Low Stock
            InventoryItem(id: UUID(), name: "Premium Leather Jacket", sku: "JKT-001", category: "Apparel", currentStock: 3, minimumRequired: 10, price: 12999, imageUrl: nil),
            // Current 45, Min 20 => Healthy
            InventoryItem(id: UUID(), name: "Classic Cotton T-Shirt", sku: "TSH-042", category: "Apparel", currentStock: 45, minimumRequired: 20, price: 999, imageUrl: nil),
            // Current 2, Min 15 => 13% => Critical
            InventoryItem(id: UUID(), name: "Slim Fit Denim Jeans", sku: "DNM-103", category: "Apparel", currentStock: 2, minimumRequired: 15, price: 3499, imageUrl: nil),
            // Current 1, Min 12 => 8% => Critical
            InventoryItem(id: UUID(), name: "Sports Running Shoes", sku: "SHO-099", category: "Footwear", currentStock: 1, minimumRequired: 12, price: 4999, imageUrl: nil),
            // Current 8, Min 25 => 32% => Low Stock
            InventoryItem(id: UUID(), name: "Elegant Silk Scarf", sku: "SCF-011", category: "Accessories", currentStock: 8, minimumRequired: 25, price: 1499, imageUrl: nil),
            // Current 15, Min 10 => Healthy
            InventoryItem(id: UUID(), name: "Winter Wool Beanie", sku: "BNI-005", category: "Accessories", currentStock: 15, minimumRequired: 10, price: 799, imageUrl: nil)
        ]
    }
    
    func requestStock(for payloads: [StockRequestPayload]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        let randomNum = String(format: "%04d", Int.random(in: 1...9999))
        
        let request = StockRequest(
            id: "REQ-\(dateString)-\(randomNum)",
            date: Date(),
            storeId: "STR-01",
            managerId: "MGR-99",
            status: "Pending",
            items: payloads
        )
        
        print("Stock request generated: \(request.id)")
        // In a real app, this would send an API request.
        
        pendingRequestsCount += 1
        
        // Temporarily show toast
        showSuccessToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showSuccessToast = false
        }
    }
}
