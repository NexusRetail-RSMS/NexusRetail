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
    
    // In-memory products list loaded either from Supabase or falling back to samples.
    var products: [POSProduct] = []
    private var fallbackProducts: [POSProduct] = []
    
    init() {
        self.fallbackProducts = getFallbackProducts()
        self.products = fallbackProducts
    }
    
    func fetchProducts(storeID: UUID?) async -> [POSProduct] {
        do {
            struct CatalogueProductRPC: Codable {
                let id: UUID
                let name: String
                let sku_code: String?
                let category: String
                let price: Double
                let stock: Int
                let launch_date: String
                let image_url: String?
                let item_id: Int64?
            }
            
            let response: [CatalogueProductRPC] = try await SupabaseManager.shared.client
                .rpc("get_catalogue_products")
                .execute()
                .value
            
            print("POSProductRepository: RPC returned \(response.count) products")
            
            if response.isEmpty {
                return self.products
            }
            
            // Map catalogue products to POSProducts, injecting size attributes
            let sizes = ["S", "M", "L", "XL"]
            var mapped: [POSProduct] = []
            
            // Fetch inventory stock for this store if available from inventory_item table
            var inventoryStock: [UUID: Int] = [:]
            if let storeID = storeID {
                struct InventoryItemResponse: Codable {
                    let sku_id: UUID
                    let on_hand: Int
                }
                
                do {
                    let invItems: [InventoryItemResponse] = try await SupabaseManager.shared.client
                        .from("inventory_item")
                        .select("sku_id, on_hand")
                        .eq("store_id", value: storeID)
                        .execute()
                        .value
                    
                    print("POSProductRepository: Found \(invItems.count) inventory_item rows for store \(storeID)")
                    for item in invItems {
                        inventoryStock[item.sku_id] = item.on_hand
                        print("  -> sku_id: \(item.sku_id), on_hand: \(item.on_hand)")
                    }
                } catch {
                    print("POSProductRepository: Non-fatal error querying store inventory_item: \(error)")
                }
            } else {
                print("POSProductRepository: No storeID provided, skipping inventory_item lookup")
            }
            
            for (index, rpc) in response.enumerated() {
                let size = sizes[index % sizes.count]
                
                // Priority: 1) inventory_item on_hand for this store, 2) RPC stock, 3) default 10
                let finalStock: Int
                if let invStock = inventoryStock[rpc.id] {
                    finalStock = invStock
                    print("POSProductRepository: \(rpc.name) -> using inventory_item on_hand: \(invStock)")
                } else if rpc.stock > 0 {
                    finalStock = rpc.stock
                    print("POSProductRepository: \(rpc.name) -> using RPC stock: \(rpc.stock)")
                } else {
                    // Default to 10 instead of 0 when no stock info exists
                    // This prevents falsely showing "Out of Stock" for products 
                    // that simply haven't had inventory_item rows created yet
                    finalStock = 10
                    print("POSProductRepository: \(rpc.name) -> no stock data found, defaulting to \(finalStock)")
                }
                
                mapped.append(POSProduct(
                    id: rpc.id,
                    itemId: rpc.item_id ?? 0,
                    name: rpc.name,
                    sku: rpc.sku_code ?? "SKU-\(index)",
                    category: rpc.category,
                    price: rpc.price,
                    stock: finalStock,
                    size: size,
                    imageUrl: rpc.image_url
                ))
            }
            
            self.products = mapped
            
            // If the RPC didn't return item_id, fetch them directly from the sku table
            let missingItemIds = mapped.filter { $0.itemId == 0 }.count
            if missingItemIds > 0 {
                print("POSProductRepository: \(missingItemIds) products missing item_id, fetching from sku table...")
                
                struct SkuItemId: Codable {
                    let id: UUID
                    let item_id: Int64?
                }
                
                do {
                    let skuRows: [SkuItemId] = try await SupabaseManager.shared.client
                        .from("sku")
                        .select("id, item_id")
                        .execute()
                        .value
                    
                    var itemIdMap: [UUID: Int64] = [:]
                    for row in skuRows {
                        if let itemId = row.item_id {
                            itemIdMap[row.id] = itemId
                        }
                    }
                    
                    print("POSProductRepository: Found \(itemIdMap.count) item_ids from sku table")
                    
                    // Update products with the fetched item_ids
                    for i in 0..<self.products.count {
                        if self.products[i].itemId == 0, let realItemId = itemIdMap[self.products[i].id] {
                            self.products[i] = POSProduct(
                                id: self.products[i].id,
                                itemId: realItemId,
                                name: self.products[i].name,
                                sku: self.products[i].sku,
                                category: self.products[i].category,
                                price: self.products[i].price,
                                stock: self.products[i].stock,
                                size: self.products[i].size,
                                imageUrl: self.products[i].imageUrl
                            )
                        }
                    }
                } catch {
                    print("POSProductRepository: Non-fatal error fetching item_ids from sku table: \(error)")
                }
            }
            
            // Build the ML recommendation mapping with the loaded products
            RecommendationService.shared.buildProductMapping(from: self.products)
            
            return self.products
        } catch {
            print("POSProductRepository: Error fetching from Supabase, using current in-memory list: \(error)")
            return self.products
        }
    }
    
    func decrementStock(productId: UUID) {
        if let index = fallbackProducts.firstIndex(where: { $0.id == productId }) {
            fallbackProducts[index].stock = max(0, fallbackProducts[index].stock - 1)
        }
        if let index = products.firstIndex(where: { $0.id == productId }) {
            products[index].stock = max(0, products[index].stock - 1)
        }
    }
    
    private func getFallbackProducts() -> [POSProduct] {
        return [
            POSProduct(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777771")!,
                itemId: 0,
                name: "Blue Oxford Shirt",
                sku: "OX-BLUE-01",
                category: "Clothes",
                price: 1999.0,
                stock: 0, // Out of Stock
                size: "M",
                imageUrl: "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400"
            ),
            POSProduct(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777772")!,
                itemId: 0,
                name: "Grey Oxford Shirt",
                sku: "OX-GREY-02",
                category: "Clothes",
                price: 1949.0,
                stock: 2, // Only 2 left
                size: "M",
                imageUrl: "https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=400"
            ),
            POSProduct(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777773")!,
                itemId: 0,
                name: "Sky Blue Shirt",
                sku: "OX-SKY-03",
                category: "Clothes",
                price: 1899.0,
                stock: 15,
                size: "M",
                imageUrl: "https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=400"
            ),
            POSProduct(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777774")!,
                itemId: 0,
                name: "Black Shirt",
                sku: "OX-BLK-04",
                category: "Clothes",
                price: 2099.0,
                stock: 8,
                size: "M",
                imageUrl: "https://images.unsplash.com/photo-1603252109303-2751441dd157?w=400"
            ),
            POSProduct(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777775")!,
                itemId: 0,
                name: "Levi Jeans",
                sku: "LVI-JNS-05",
                category: "Clothes",
                price: 2999.0,
                stock: 12,
                size: "L",
                imageUrl: "https://images.unsplash.com/photo-1542272604-787c3835535d?w=400"
            ),
            POSProduct(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777776")!,
                itemId: 0,
                name: "Nike Shoes",
                sku: "NKE-SHS-06",
                category: "Bags",
                price: 4999.0,
                stock: 5,
                size: "XL",
                imageUrl: "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400"
            )
        ]
    }
}
