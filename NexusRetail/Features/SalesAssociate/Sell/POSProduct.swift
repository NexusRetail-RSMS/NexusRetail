import Foundation
import Supabase

struct POSProduct: Identifiable, Codable, Hashable {
    let id: UUID
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
    
    init() {
        self.products = getFallbackProducts()
    }
    
    func fetchProducts() async -> [POSProduct] {
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
            }
            
            let response: [CatalogueProductRPC] = try await SupabaseManager.shared.client
                .rpc("get_catalogue_products")
                .execute()
                .value
            
            if response.isEmpty {
                self.products = getFallbackProducts()
                return self.products
            }
            
            // Map catalogue products to POSProducts, injecting size attributes
            let sizes = ["S", "M", "L", "XL"]
            var mapped: [POSProduct] = []
            for (index, rpc) in response.enumerated() {
                let size = sizes[index % sizes.count]
                mapped.append(POSProduct(
                    id: rpc.id,
                    name: rpc.name,
                    sku: rpc.sku_code ?? "SKU-\(index)",
                    category: rpc.category,
                    price: rpc.price,
                    stock: rpc.stock,
                    size: size,
                    imageUrl: rpc.image_url
                ))
            }
            
            // Let's ensure the user's specific sample products from the prompt are present
            let userSamples = getFallbackProducts()
            for sample in userSamples {
                if !mapped.contains(where: { $0.name.localizedCaseInsensitiveContains(sample.name) }) {
                    mapped.append(sample)
                }
            }
            
            self.products = mapped
            return mapped
        } catch {
            print("POSProductRepository: Error fetching from Supabase, using fallbacks: \(error)")
            self.products = getFallbackProducts()
            return self.products
        }
    }
    
    private func getFallbackProducts() -> [POSProduct] {
        return [
            POSProduct(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777771")!,
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
                name: "Nike Shoes",
                sku: "NKE-SHS-06",
                category: "Bags", // putting under bags/shoes
                price: 4999.0,
                stock: 5,
                size: "XL",
                imageUrl: "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400"
            )
        ]
    }
}
