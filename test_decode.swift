import Foundation

let jsonString = """
[{"id":"086fcf3d-85f9-48f5-b4c0-8383b57c531b","item_id":316753,"store_id":"2efddfc8-2388-4301-be16-79caa0cb9a9c","on_hand":12,"reorder_threshold":5,"products":{"item_name":"Zara Green Kurti","category":"Clothes","sku_code":"WAT-6625","image_url":"https://images.pexels.com/photos/28512787/pexels-photo-28512787.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940","description":"Zara kurti...","price_band":[{"base_price":192722.46,"floor_price":163814.09}],"store_price":null}}]
"""

struct ProductInfo: Codable {
    let name: String
    let category: String?
    let skuCode: String?
    let imageUrl: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "item_name"
        case category, description
        case skuCode = "sku_code"
        case imageUrl = "image_url"
        case priceBand = "price_band"
        case storePrice = "store_price"
    }
    
    let priceBand: [PriceBandInfo]?
    let storePrice: [StorePriceInfo]?
}

struct PriceBandInfo: Codable {
    let basePrice: Double
    let floorPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case basePrice = "base_price"
        case floorPrice = "floor_price"
    }
}

struct StorePriceInfo: Codable {
    let localPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case localPrice = "local_price"
    }
}

struct InventoryItemRow: Codable {
    let id: UUID
    let itemId: Int64
    let storeId: UUID
    let onHand: Int
    let reorderThreshold: Int
    let products: ProductInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case storeId = "store_id"
        case onHand = "on_hand"
        case reorderThreshold = "reorder_threshold"
        case products
    }
}

let data = jsonString.data(using: .utf8)!
do {
    let decoder = JSONDecoder()
    let items = try decoder.decode([InventoryItemRow].self, from: data)
    print("Success: \(items.count) items")
} catch {
    print("Decoding error: \(error)")
}
