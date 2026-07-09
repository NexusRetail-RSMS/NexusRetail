import Foundation
import CoreLocation
import Supabase

class SmartRoutingService {
    static let shared = SmartRoutingService()
    
    struct StoreInventoryRow: Decodable {
        let store_id: UUID
        let on_hand: Int
    }
    
    /// Predicts the name of the source location (for UI display)
    func predictSourceString(requestingStoreId: UUID, itemId: Int64, quantity: Int) async -> String {
        do {
            let reqStore: Store = try await SupabaseManager.shared.client
                .from("store")
                .select("country")
                .eq("id", value: requestingStoreId)
                .single()
                .execute()
                .value
            
            let country = reqStore.country ?? ""
            var warehouseName = "Central Warehouse"
            if country.lowercased().contains("india") { warehouseName = "Mumbai Warehouse" }
            if country.lowercased().contains("usa") || country.lowercased().contains("united states") { warehouseName = "Kansas City Warehouse" }
            
            if quantity > 3 {
                return warehouseName
            }
            
            let sourceId = try await calculateSourceStore(requestingStoreId: requestingStoreId, itemId: itemId, quantity: quantity)
            if let sourceId = sourceId {
                let sourceStore: Store = try await SupabaseManager.shared.client
                    .from("store")
                    .select("name")
                    .eq("id", value: sourceId)
                    .single()
                    .execute()
                    .value
                return "\(sourceStore.name) (Nearby)"
            }
            return warehouseName
        } catch {
            return "Central Warehouse"
        }
    }
    
    /// Calculates the best source store for a transfer request based on distance and inventory
    /// Returns nil if it should fallback to the warehouse
    func calculateSourceStore(requestingStoreId: UUID, itemId: Int64, quantity: Int) async throws -> UUID? {
        print("--- STARTING SMART ROUTING ---")
        
        // Emergency Rule: Only source from stores if request quantity <= 3. Otherwise, use warehouse (nil)
        guard quantity <= 3 else {
            print("Quantity \(quantity) > 3. Routing to Warehouse.")
            return nil
        }
        
        // 1. Fetch requesting store details
        let reqStore: Store = try await SupabaseManager.shared.client
            .from("store")
            .select()
            .eq("id", value: requestingStoreId)
            .single()
            .execute()
            .value
            
        guard let reqLat = reqStore.latitude, let reqLon = reqStore.longitude, let country = reqStore.country else {
            print("Requesting store \(reqStore.name) is missing latitude, longitude, or country! Routing to Warehouse.")
            return nil
        }
        
        let reqLocation = CLLocation(latitude: reqLat, longitude: reqLon)
        print("Requesting store location: (\(reqLat), \(reqLon)), Country: \(country)")
        
        // 2. Determine country warehouse location
        var warehouseLocation: CLLocation?
        if country.lowercased().contains("india") {
            warehouseLocation = CLLocation(latitude: 19.0760, longitude: 72.8777) // Mumbai Warehouse
        } else if country.lowercased().contains("united states") || country.lowercased().contains("usa") {
            warehouseLocation = CLLocation(latitude: 39.0997, longitude: -94.5786) // Kansas City Warehouse
        }
        
        let distToWarehouse = warehouseLocation.map { reqLocation.distance(from: $0) } ?? .infinity
        print("Distance to warehouse: \(distToWarehouse) meters")
        
        // 3. Fetch all other stores in the same country
        let allStores: [Store] = try await SupabaseManager.shared.client
            .from("store")
            .select()
            .eq("country", value: country)
            .execute()
            .value
            
        print("Found \(allStores.count) total stores in country \(country)")
            
        // 4. Fetch inventory for the requested item
        let inventories: [StoreInventoryRow] = try await SupabaseManager.shared.client
            .from("inventory_item")
            .select("store_id, on_hand")
            .eq("item_id", value: Int(itemId))
            .execute()
            .value
            
        print("Fetched \(inventories.count) inventory records for item \(itemId)")
            
        var inventoryMap: [UUID: Int] = [:]
        for inv in inventories {
            inventoryMap[inv.store_id] = inv.on_hand
            print("Mapped store_id \(inv.store_id) to stock \(inv.on_hand)")
        }
        var closestStoreId: UUID? = nil
        var minDistance: CLLocationDistance = .infinity
        
        // 5. Find the closest store with sufficient stock (requested + 10 safety threshold)
        let safetyThreshold = 10
        let requiredStock = quantity + safetyThreshold
        
        for store in allStores {
            guard store.id != requestingStoreId else { continue }
            guard let lat = store.latitude, let lon = store.longitude else {
                print("Store \(store.name) is missing coordinates. Skipping.")
                continue
            }
            
            let stock = inventoryMap[store.id] ?? 0
            print("Evaluating store: \(store.name). Stock on hand: \(stock), Required: \(requiredStock)")
            
            if stock >= requiredStock {
                let loc = CLLocation(latitude: lat, longitude: lon)
                let dist = reqLocation.distance(from: loc)
                print("Store \(store.name) has enough stock! Distance: \(dist) meters")
                
                if dist < minDistance {
                    minDistance = dist
                    closestStoreId = store.id
                }
            } else {
                print("Store \(store.name) DOES NOT have enough stock.")
            }
        }
        
        // 6. If the closest valid store is closer than the warehouse, use it! Otherwise, warehouse.
        if minDistance < distToWarehouse {
            print("Closest store distance (\(minDistance)) is less than warehouse distance (\(distToWarehouse)). Routing to store!")
            return closestStoreId
        }
        
        print("Warehouse is closer, or no valid stores found. Routing to Warehouse.")
        return nil
    }
}
