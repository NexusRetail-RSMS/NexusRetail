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
    var itemId: Int64
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
    let p_floor_price: Double?
}

struct UpdateProductParams: Encodable {
    let p_item_id: Int64
    let p_name: String
    let p_category: String
    let p_price: Double
    let p_image_url: String?
    let p_floor_price: Double?
}

struct DeleteProductParams: Encodable {
    let p_item_id: Int64
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
            
            var mapped = response.map { product -> CatalogueProduct in
                // Extract image from pexels_page or fallback to image_url
                let pexelsImageUrl = extractPexelsImageUrl(from: product.pexels_page ?? "") ?? product.image_url

                return CatalogueProduct(
                    id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", product.item_id)) ?? UUID(),
                    itemId: product.item_id,
                    name: product.item_name,
                    sku: "SKU-\(product.item_id)",
                    category: product.category,
                    price: product.price,
                    stock: 0, // replaced by real inventory below
                    date: fallbackDate,
                    imageName: nil,
                    imageUrl: pexelsImageUrl,
                    image: nil,
                    qrCode: nil
                )
            }

            // Load real stock: total on_hand per item across all stores.
            struct InventoryStockRow: Decodable {
                let item_id: Int64
                let on_hand: Int
            }
            do {
                let invRows: [InventoryStockRow] = try await SupabaseManager.shared.client
                    .from("inventory_item")
                    .select("item_id, on_hand")
                    .execute()
                    .value
                var stockByItem: [Int64: Int] = [:]
                for row in invRows { stockByItem[row.item_id, default: 0] += row.on_hand }
                for i in mapped.indices {
                    mapped[i].stock = stockByItem[mapped[i].itemId] ?? 0
                }
            } catch {
                print("ProductCatalogueViewModel: Non-fatal error loading inventory: \(error)")
            }

            self.allProducts = mapped
            

            struct TopProductsRPCParams: Encodable {
                let p_period: String
                let p_limit: Int
                let p_country: String?
            }
            
            struct MinimalTopProduct: Decodable {
                let id: Int64
                let units: Int
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case units
                }
            }
            
            let topParams = TopProductsRPCParams(p_period: "month", p_limit: 4, p_country: nil)
            let topProductsResp: [MinimalTopProduct] = try await SupabaseManager.shared.client
                .rpc("top_products", params: topParams)
                .execute()
                .value
            
            self.trendingProducts = topProductsResp.compactMap { top in
                let targetId = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", top.id)) ?? UUID()
                
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
            
            if self.trendingProducts.isEmpty {
                self.trendingProducts = mapped.prefix(4).map { match in
                    TrendingProduct(
                        id: match.id,
                        name: match.name,
                        stockStatus: match.stock > 10 ? "In Stock" : "Low Stock",
                        units: 150, // Fallback units
                        price: match.price,
                        imageName: match.imageName,
                        imageUrl: match.imageUrl
                    )
                }
            }
        } catch {
            print("Error fetching products: \(error)")
            // Fallback if the RPC fails entirely
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            let fallbackDate = displayFormatter.string(from: Date())
            
            if self.trendingProducts.isEmpty && !self.allProducts.isEmpty {
                self.trendingProducts = self.allProducts.prefix(4).map { match in
                    TrendingProduct(
                        id: match.id,
                        name: match.name,
                        stockStatus: match.stock > 10 ? "In Stock" : "Low Stock",
                        units: 150, // Fallback units
                        price: match.price,
                        imageName: match.imageName,
                        imageUrl: match.imageUrl
                    )
                }
            }
        }
    }

    func generateSKU(for category: String) -> String {
        let prefix = category.prefix(3).uppercased()
        let randomNum = String(format: "%04d", Int.random(in: 1...9999))
        return "\(prefix)-\(randomNum)"
    }
    
    /// Downscales an image to a sane max dimension and compresses it, so uploads
    /// are ~100–300 KB instead of multi-MB full-res photos (which drop with
    /// NSURLError -1005 "network connection was lost" on flaky links/simulator).
    private func downscaledJPEG(_ image: UIImage, maxDimension: CGFloat = 1280, quality: CGFloat = 0.7) -> Data? {
        let longSide = max(image.size.width, image.size.height)
        let scale = longSide > maxDimension ? maxDimension / longSide : 1
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let data = downscaledJPEG(image) else {
            throw URLError(.badServerResponse)
        }
        let path = "products/\(UUID().uuidString).jpg"
        let fileOptions = FileOptions(contentType: "image/jpeg", upsert: true)

        // Retry transient network drops (-1005) a couple of times before giving up.
        var lastError: Error?
        for attempt in 1...3 {
            do {
                try await SupabaseManager.shared.client.storage
                    .from("product-images")
                    .upload(path, data: data, options: fileOptions)

                let url = try SupabaseManager.shared.client.storage
                    .from("product-images")
                    .getPublicURL(path: path)
                return url.absoluteString
            } catch {
                lastError = error
                print("uploadImage: attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s backoff
                }
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    /// Adds a product. Throws if the DB insert fails so the caller can surface it.
    /// A failed *image* upload is non-fatal (falls back to a placeholder image).
    func addProduct(name: String, sku: String, category: String, price: Double, stock: Int, launchDate: Date, floorPrice: Double? = nil, image: UIImage?) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: launchDate)

        var uploadedUrl = "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800"
        if let image = image {
            do {
                uploadedUrl = try await uploadImage(image)
            } catch {
                print("Failed to upload image (using placeholder): \(error)")
            }
        }

        let params = AddProductParams(
            p_name: name,
            p_category: category,
            p_description: "Added from app",
            p_price: price,
            p_stock: stock,
            p_launch_date: dateStr,
            p_image_url: uploadedUrl,
            p_floor_price: floorPrice
        )

        var lastError: Error?
        for attempt in 1...3 {
            do {
                try await SupabaseManager.shared.client
                    .rpc("add_catalogue_product", params: params)
                    .execute()
                await fetchProducts()
                return
            } catch {
                lastError = error
                print("addProduct attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < 3 { try? await Task.sleep(nanoseconds: 500_000_000) }
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    /// Updates catalogue fields (name/category/price/image/floor price).
    /// Stock is intentionally NOT a parameter: on-hand is tracked per store in
    /// `inventory_item` and aggregated for display, so there is no single stock
    /// value to write back here. The edit form hides its stock field for the
    /// same reason. Adjust stock through inventory, not the product catalogue.
    func updateProduct(
        _ product: CatalogueProduct,
        name: String,
        sku: String,
        category: String,
        price: Double,
        floorPrice: Double? = nil,
        image: UIImage?
    ) async throws {
        // Optimistically reflect the edit locally for a responsive UI.
        if let index = allProducts.firstIndex(where: { $0.id == product.id }) {
            allProducts[index].name = name
            allProducts[index].sku = sku
            allProducts[index].category = category
            allProducts[index].price = price
            allProducts[index].image = image
        }

        var uploadedUrl: String? = nil
        if let image = image {
            do {
                uploadedUrl = try await uploadImage(image)
            } catch {
                print("Failed to upload image (keeping existing): \(error)")
            }
        }

        let params = UpdateProductParams(
            p_item_id: product.itemId,
            p_name: name,
            p_category: category,
            p_price: price,
            p_image_url: uploadedUrl,
            p_floor_price: floorPrice
        )

        var lastError: Error?
        for attempt in 1...3 {
            do {
                try await SupabaseManager.shared.client
                    .rpc("update_catalogue_product", params: params)
                    .execute()
                await fetchProducts()
                return
            } catch {
                lastError = error
                print("updateProduct attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < 3 { try? await Task.sleep(nanoseconds: 500_000_000) }
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    func deleteProduct(_ product: CatalogueProduct) {
        // Optimistic local removal; reconcile with the DB below.
        allProducts.removeAll { $0.id == product.id }

        Task {
            do {
                try await SupabaseManager.shared.client
                    .rpc("delete_catalogue_product", params: DeleteProductParams(p_item_id: product.itemId))
                    .execute()
                await fetchProducts()
            } catch {
                print("Error deleting product: \(error)")
                // Re-sync so a failed delete reappears instead of vanishing silently.
                await fetchProducts()
            }
        }
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
        product.stockStatus.lowercased().contains("low") ? AppTheme().warning : AppTheme().success
    }

    private func formatPrice(_ value: Double) -> String {
        return formatIndianCurrency(value)
    }
}
