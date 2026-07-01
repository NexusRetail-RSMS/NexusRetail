//
//  InventoryDashboardViewModel.swift
//  NexusRetail
//
//  ViewModel for the Manager Inventory screen.
//  Fetches from Supabase with joined SKU + price data,
//  supports filtering, sorting, search, and restock requests.
//

import Foundation
import SwiftUI
import Supabase

@Observable
class InventoryViewModel {
    // MARK: - Data
    var items: [InventoryItemRow] = []
    var requests: [TransferRequestRow] = []
    
    // MARK: - UI State
    var searchText: String = ""
    var selectedFilter: InventoryFilter = .allItems
    var selectedCategory: InventoryCategory? = nil
    var sortOrder: InventorySortOrder = .stockLowToHigh
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // Restock sheet
    var restockItem: InventoryItemRow? = nil
    var showRestockSheet: Bool = false
    
    // MARK: - Computed: Summary
    
    var summary: InventorySummary {
        let totalSKUs = items.count
        let unitsInStock = items.reduce(0) { $0 + $1.onHand }
        let outOfStock = items.filter { $0.onHand == 0 }.count
        let inventoryValue = items.reduce(0.0) { $0 + $1.inventoryValue }
        let lowStockCount = items.filter { $0.isLowStock }.count
        return InventorySummary(totalSKUs: totalSKUs, unitsInStock: unitsInStock, outOfStock: outOfStock, inventoryValue: inventoryValue, lowStockCount: lowStockCount)
    }
    
    // MARK: - Computed: Filtered & Sorted Items
    
    var filteredItems: [InventoryItemRow] {
        var result = items
        
        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.skuCode.lowercased().contains(query)
            }
        }
        
        // Filter by stock status
        if selectedFilter == .lowStock {
            result = result.filter { $0.isLowStock }
        }
        
        // Category
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat.rawValue }
        }
        
        // Sort
        switch sortOrder {
        case .stockLowToHigh:
            result.sort { $0.onHand < $1.onHand }
        case .nameAZ:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .category:
            result.sort { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
        case .valueHighToLow:
            result.sort { $0.inventoryValue > $1.inventoryValue }
        }
        
        return result
    }
    
    // MARK: - Load Data
    
    func load(storeID: UUID?) async {
        var targetStoreID = storeID
        if targetStoreID == nil {
            if let stores: [Store] = try? await SupabaseManager.shared.client.from("store").select().execute().value {
                targetStoreID = stores.first?.id
            }
        }
        
        guard let finalStoreID = targetStoreID else {
            await loadMockData()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch inventory items with joined SKU + price data
            let inventoryResponse: [InventoryItemRow] = try await SupabaseManager.shared.client
                .from("inventory_item")
                .select("*, sku!inner(name, category, sku_code, image_url, description, price_band(base_price, floor_price), store_price(local_price))")
                .eq("store_id", value: finalStoreID.uuidString)
                .execute()
                .value
            
            // Fetch transfer requests for this store
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let requestsResponse: [TransferRequestRow] = try await SupabaseManager.shared.client
                .from("transfer_request")
                .select("*, sku!inner(name, category, sku_code, image_url, description)")
                .eq("requesting_store_id", value: finalStoreID.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.items = inventoryResponse
                self.requests = requestsResponse
                self.isLoading = false
            }
        } catch {
            print("Inventory fetch error: \(error)")
            // Fallback to mock data
            await loadMockData()
            await MainActor.run {
                self.errorMessage = "Using offline data. Pull to refresh."
                self.isLoading = false
            }
        }
    }
    
    private func loadMockData() async {
        await MainActor.run {
            self.items = InventoryItemRow.mockItems
            self.requests = TransferRequestRow.mockRequests
            self.isLoading = false
        }
    }
    
    // MARK: - Actions
    
    func requestRestock(skuID: UUID, quantity: Int, storeID: UUID) async -> String? {
        let payload = TransferRequestInsert(
            skuId: skuID,
            requestingStoreId: storeID,
            quantity: quantity,
            status: .pending
        )
        
        do {
            try await SupabaseManager.shared.client
                .from("transfer_request")
                .insert(payload)
                .execute()
            
            // Reload to get the fresh request in the list
            await load(storeID: storeID)
            return nil // success
        } catch {
            print("Restock request error: \(error)")
            return error.localizedDescription
        }
    }
    
    func saveLocalPrice(skuID: UUID, storeID: UUID, price: Double) async -> Bool {
        let payload = StorePriceUpsert(skuId: skuID, storeId: storeID, localPrice: price)
        
        do {
            try await SupabaseManager.shared.client
                .from("store_price")
                .upsert(payload)
                .execute()
            
            await load(storeID: storeID)
            return true
        } catch {
            print("Save price error: \(error)")
            return false
        }
    }
    
    func triggerRestock(for item: InventoryItemRow) {
        restockItem = item
        showRestockSheet = true
    }
}
