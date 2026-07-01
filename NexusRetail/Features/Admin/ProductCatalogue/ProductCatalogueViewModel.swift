import SwiftUI
import Combine
import Supabase

// MARK: - Models

struct TrendingProduct: Identifiable {
    let id: UUID
    let name: String
    let stockStatus: String
    let units: Int
    let price: Double
    let imageName: String?
    let imageUrl: String?
}

struct CatalogueProduct: Identifiable {
    let id: UUID
    var name: String
    var sku: String
    var category: String
    var price: Double
    var stock: Int
    var date: String
    var imageName: String?
    var imageUrl: String?
    var image: UIImage?
    var qrCode: String?
}

struct CatalogueProductRPC: Codable {
    let id: UUID
    let name: String
    let sku_code: String?
    let category: String
    let price: Double
    let stock: Int
    let launch_date: String
    let image_url: String?
    let qr_code: String?
}

struct AddProductParams: Encodable {
    let p_name: String
    let p_category: String
    let p_description: String
    let p_price: Double
    let p_stock: Int
    let p_launch_date: String
    let p_image_url: String
}

// MARK: - ViewModel

@MainActor
final class ProductCatalogueViewModel: ObservableObject {

    @Published var trendingProducts: [TrendingProduct]
    @Published var currentTrendingIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var searchText = ""
    @Published var selectedCategory = "All"

    let categoryOptions = ["All", "Watches", "Bags", "Perfumes", "Clothes", "Jewellery"]

    @Published private(set) var allProducts: [CatalogueProduct]
    private var timer: AnyCancellable?

    var filteredProducts: [CatalogueProduct] {
        allProducts.filter { product in
            let matchesSearch =
                searchText.isEmpty ||
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.sku.localizedCaseInsensitiveContains(searchText)
            let matchesCategory =
                selectedCategory == "All" ||
                product.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    init() {
        self.trendingProducts = []
        self.allProducts = []
        Task {
            await fetchProducts()
        }
        startAutoScroll()
    }

    /// Extracts a direct Pexels image URL from a Pexels photo page URL.
    func extractPexelsImageUrl(from pageUrl: String) -> String? {
        var cleanUrl = pageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanUrl.hasSuffix("/") {
            cleanUrl.removeLast()
        }
        guard let lastComponent = cleanUrl.split(separator: "/").last else { return nil }
        
        let idString = lastComponent.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard !idString.isEmpty else { return nil }
        
        return "https://images.pexels.com/photos/\(idString)/pexels-photo-\(idString).jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940"
    }

    func fetchProducts() async {
        do {
            struct ProductResponse: Codable {
                let item_id: Int64
                let item_name: String
                let category: String
                let price: Double
                let pexels_page: String?
                let image_url: String?
                let description: String?
            }
            
            let response: [ProductResponse] = try await SupabaseManager.shared.client
                .from("products")
                .select("item_id, item_name, category, price, pexels_page, image_url, description")
                .execute()
                .value
            
            print("ProductCatalogueViewModel: Loaded \(response.count) products from products table")
            
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            let fallbackDate = displayFormatter.string(from: Date())
            
            let mapped = response.map { product -> CatalogueProduct in
                // Extract image from pexels_page or fallback to image_url
                let pexelsImageUrl = extractPexelsImageUrl(from: product.pexels_page ?? "") ?? product.image_url
                
                return CatalogueProduct(
                    id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", product.item_id)) ?? UUID(),
                    name: product.item_name,
                    sku: "SKU-\(product.item_id)",
                    category: product.category,
                    price: product.price,
                    stock: 50, // default fallback stock
                    date: fallbackDate,
                    imageName: nil,
                    imageUrl: pexelsImageUrl,
                    image: nil,
                    qrCode: nil
                )
            }
            
            self.allProducts = mapped
            
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
                print("ProductCatalogueViewModel: Non-fatal error fetching from sku table: \(error)")
            }
            
            struct TopProductsRPCParams: Encodable {
                let p_period: String
                let p_limit: Int
                let p_country: String?
            }
            
            struct MinimalTopProduct: Decodable {
                let id: UUID
                let units: Int
                
                enum CodingKeys: String, CodingKey {
                    case id = "sku_id"
                    case units
                }
            }
            
            let topParams = TopProductsRPCParams(p_period: "month", p_limit: 4, p_country: nil)
            let topProductsResp: [MinimalTopProduct] = try await SupabaseManager.shared.client
                .rpc("top_products", params: topParams)
                .execute()
                .value
            
            self.trendingProducts = topProductsResp.compactMap { top in
                let targetId: UUID
                if let itemId = skuToItemIdMap[top.id] {
                    targetId = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", itemId)) ?? top.id
                } else {
                    targetId = top.id
                }
                
                guard let match = mapped.first(where: { $0.id == targetId }) else { return nil }
                return TrendingProduct(
                    id: match.id,
                    name: match.name,
                    stockStatus: match.stock > 10 ? "In Stock" : "Low Stock",
                    units: top.units,
                    price: match.price,
                    imageName: match.imageName,
                    imageUrl: match.imageUrl
                )
            }
        } catch {
            print("Error fetching products: \(error)")
        }
    }

    func generateSKU(for category: String) -> String {
        let prefix = category.prefix(3).uppercased()
        let randomNum = String(format: "%04d", Int.random(in: 1...9999))
        return "\(prefix)-\(randomNum)"
    }
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badServerResponse)
        }
        let path = "products/\(UUID().uuidString).jpg"
        let fileOptions = FileOptions(contentType: "image/jpeg")
        try await SupabaseManager.shared.client.storage
            .from("product-images")
            .upload(path, data: data, options: fileOptions)
        
        let url = try SupabaseManager.shared.client.storage
            .from("product-images")
            .getPublicURL(path: path)
        return url.absoluteString
    }

    func addProduct(name: String, sku: String, category: String, price: Double, stock: Int, launchDate: Date, image: UIImage?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: launchDate)
        
        Task {
            var uploadedUrl = "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800"
            if let image = image {
                do {
                    uploadedUrl = try await uploadImage(image)
                } catch {
                    print("Failed to upload image: \(error)")
                }
            }
            
            let params = AddProductParams(
                p_name: name,
                p_category: category,
                p_description: "Added from app",
                p_price: price,
                p_stock: stock,
                p_launch_date: dateStr,
                p_image_url: uploadedUrl
            )
            
            do {
                try await SupabaseManager.shared.client
                    .rpc("add_catalogue_product", params: params)
                    .execute()
                await fetchProducts()
            } catch {
                print("Error adding product: \(error)")
            }
        }
    }
    
    func updateProduct(
        _ product: CatalogueProduct,
        name: String,
        sku: String,
        category: String,
        price: Double,
        stock: Int,
        image: UIImage?
    ) {
        guard let index = allProducts.firstIndex(where: { $0.id == product.id }) else {
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        allProducts[index].name = name
        allProducts[index].sku = sku
        allProducts[index].category = category
        allProducts[index].price = price
        allProducts[index].stock = stock
        allProducts[index].image = image
    }
    
    func deleteProduct(_ product: CatalogueProduct) {
        allProducts.removeAll { $0.id == product.id }
    }

    private func startAutoScroll() {
        timer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.trendingProducts.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.currentTrendingIndex = (self.currentTrendingIndex + 1) % self.trendingProducts.count
                }
            }
    }
    

    func stopAutoScroll() { timer?.cancel(); timer = nil }

    func resumeAutoScroll() {
        guard timer == nil else { return }
        startAutoScroll()
    }

    // MARK: - Helpers

    func formattedPrice(for product: TrendingProduct) -> String { formatPrice(product.price) }
    func formattedPrice(for product: CatalogueProduct) -> String { formatPrice(product.price) }

    func stockLabel(for product: TrendingProduct) -> String {
        "\(product.stockStatus) · \(product.units) units"
    }

    func stockColor(for product: TrendingProduct) -> Color {
        product.stockStatus.lowercased().contains("low") ? RSMSColors.warning : RSMSColors.success
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
