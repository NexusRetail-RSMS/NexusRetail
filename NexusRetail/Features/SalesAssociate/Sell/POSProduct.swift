import Foundation
import Supabase

struct POSProduct: Identifiable, Codable, Hashable {
    let id: UUID
    let itemId: Int64
    let name: String
    let sku: String
    let category: String
    let price: Double
    var stock: Int
    let size: String
    let imageUrl: String?
}

class POSProductRepository {
    static let shared = POSProductRepository()
    
    // In-memory products list loaded from Supabase.
    var products: [POSProduct] = []
    
    init() {
        self.products = []
    }
    
    /// Extracts a direct Pexels image URL from a Pexels photo page URL.
    func extractPexelsImageUrl(from pageUrl: String) -> String? {
        var cleanUrl = pageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanUrl.hasSuffix("/") {
            cleanUrl.removeLast()
        }
        guard let lastComponent = cleanUrl.split(separator: "/").last else { return nil }
        
        // Extract all digits (photo ID)
        let idString = lastComponent.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard !idString.isEmpty else { return nil }
        
        return "https://images.pexels.com/photos/\(idString)/pexels-photo-\(idString).jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940"
    }
    
    func fetchProducts(storeID: UUID?) async -> [POSProduct] {
        do {
            struct ProductResponse: Codable {
                let item_id: Int64
                let item_name: String
                let category: String
                let price: Double
                let pexels_page: String?
                let image_url: String?
            }
            
            let response: [ProductResponse] = try await SupabaseManager.shared.client
                .from("products")
                .select("item_id, item_name, category, price, pexels_page, image_url")
                .execute()
                .value
            
            print("POSProductRepository: Loaded \(response.count) products from products table")
            
            if response.isEmpty {
                return self.products
            }
            
            let sizes = ["S", "M", "L", "XL"]
            var mapped: [POSProduct] = []
            
            for (index, product) in response.enumerated() {
                let size = sizes[index % sizes.count]
                
                // Generate a deterministic UUID based on item_id
                let uuid = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", product.item_id)) ?? UUID()
                
                // Extract image from pexels_page or fallback to image_url
                let pexelsImageUrl = extractPexelsImageUrl(from: product.pexels_page ?? "") ?? product.image_url
                
                mapped.append(POSProduct(
                    id: uuid,
                    itemId: product.item_id,
                    name: product.item_name,
                    sku: "SKU-\(product.item_id)",
                    category: product.category,
                    price: product.price,
                    stock: 50, // default fallback stock
                    size: size,
                    imageUrl: pexelsImageUrl
                ))
            }
            
            struct SkuRow: Codable {
                let id: UUID
                let item_id: Int64?
            }
            
            var skuToItemIdMap: [UUID: Int64] = [:]
            do {
                let skuRows: [SkuRow] = try await SupabaseManager.shared.client
                    .from("sku")
                    .select("id, item_id")
                    .execute()
                    .value
                for row in skuRows {
                    if let itemId = row.item_id {
                        skuToItemIdMap[row.id] = itemId
                    }
                }
            } catch {
                print("POSProductRepository: Non-fatal error fetching from sku table: \(error)")
            }
            
            // Fetch inventory stock from inventory_item table
            var inventoryStock: [UUID: Int] = [:]
            
            struct InventoryItemResponse: Codable {
                let sku_id: UUID
                let on_hand: Int
            }
            
            do {
                let invItems: [InventoryItemResponse]
                
                if let storeID = storeID {
                    invItems = try await SupabaseManager.shared.client
                        .from("inventory_item")
                        .select("sku_id, on_hand")
                        .eq("store_id", value: storeID)
                        .execute()
                        .value
                } else {
                    invItems = try await SupabaseManager.shared.client
                        .from("inventory_item")
                        .select("sku_id, on_hand")
                        .execute()
                        .value
                }
                
                for item in invItems {
                    if let itemId = skuToItemIdMap[item.sku_id] {
                        let deterministicId = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", itemId)) ?? item.sku_id
                        inventoryStock[deterministicId, default: 0] += item.on_hand
                    } else {
                        inventoryStock[item.sku_id, default: 0] += item.on_hand
                    }
                }
            } catch {
                print("POSProductRepository: Non-fatal error querying inventory_item: \(error)")
            }
            
            // Apply actual inventory stock
            for i in 0..<mapped.count {
                if let invStock = inventoryStock[mapped[i].id] {
                    mapped[i].stock = invStock
                }
            }
            
            self.products = mapped
            
            // Build the ML recommendation mapping with the loaded products
            RecommendationService.shared.buildProductMapping(from: self.products)
            
            return self.products
        } catch {
            print("POSProductRepository: Error fetching from Supabase, using current in-memory list: \(error)")
            return self.products
        }
    }
    func decrementStock(productId: UUID) {
        if let index = products.firstIndex(where: { $0.id == productId }) {
            products[index].stock = max(0, products[index].stock - 1)
        }
    }
}
