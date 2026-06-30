// Core ML product recommendations using the ItemRecommendation model.
// The model is an Item Similarity Recommender that takes item IDs (Int64)
// and returns recommended similar item IDs with confidence scores.

import Foundation
import CoreML

class RecommendationService {
    static let shared = RecommendationService()
    
    private var model: ItemRecommendation?
    
    /// Maps catalogue product index (1-based Int64) to product UUID
    private var indexToProductId: [Int64: UUID] = [:]
    /// Maps product UUID to catalogue index (1-based Int64)
    private var productIdToIndex: [UUID: Int64] = [:]
    
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            model = try ItemRecommendation(configuration: config)
            print("RecommendationService: ItemRecommendation model loaded successfully")
        } catch {
            print("RecommendationService: Failed to load ItemRecommendation model: \(error)")
        }
    }
    
    /// Call this after products are fetched from Supabase to build the Int64 ↔ UUID mapping.
    /// The model was trained with 1-based integer item IDs, so we map each product's
    /// position in the catalogue to a 1-based Int64 index.
    func buildProductMapping(from products: [POSProduct]) {
        indexToProductId.removeAll()
        productIdToIndex.removeAll()
        
        for (index, product) in products.enumerated() {
            let itemIndex = Int64(index + 1) // 1-based to match training data
            indexToProductId[itemIndex] = product.id
            productIdToIndex[product.id] = itemIndex
        }
        
        print("RecommendationService: Built mapping for \(products.count) products")
    }
    
    /// Get ML-powered recommendations for a given product.
    /// Returns up to `count` recommended product UUIDs, sorted by relevance.
    func getRecommendations(for productId: UUID, count: Int = 5) -> [(productId: UUID, score: Double)] {
        guard let model = model else {
            print("RecommendationService: Model not loaded")
            return []
        }
        
        guard let itemIndex = productIdToIndex[productId] else {
            print("RecommendationService: Product \(productId) not found in mapping")
            return []
        }
        
        do {
            // The model expects a dictionary of items the user has interacted with
            // We pass the current product with a score of 1.0
            let input = ItemRecommendationInput(
                items: [itemIndex: 1.0],
                k: Int64(count),
                restrict_: nil,
                exclude: nil
            )
            
            let output = try model.prediction(input: input)
            
            // Map the recommended Int64 IDs back to product UUIDs
            var results: [(productId: UUID, score: Double)] = []
            
            for recommendedIndex in output.recommendations {
                if let uuid = indexToProductId[recommendedIndex] {
                    let score = output.scores[recommendedIndex] ?? 0.0
                    results.append((productId: uuid, score: score))
                }
            }
            
            print("RecommendationService: Got \(results.count) recommendations for product index \(itemIndex)")
            return results
            
        } catch {
            print("RecommendationService: Prediction failed: \(error)")
            return []
        }
    }
    
    /// Convenience method: returns recommended POSProduct objects from the current product list.
    func getRecommendedProducts(for product: POSProduct, from allProducts: [POSProduct], count: Int = 5) -> [POSProduct] {
        let recommendations = getRecommendations(for: product.id, count: count)
        
        if recommendations.isEmpty {
            print("RecommendationService: No ML recommendations, falling back to category match")
            return []
        }
        
        // Look up each recommended UUID in the product list
        var recommended: [POSProduct] = []
        for rec in recommendations {
            if let matchedProduct = allProducts.first(where: { $0.id == rec.productId }) {
                // Skip the same product and out-of-stock items
                if matchedProduct.id != product.id && matchedProduct.stock > 0 {
                    recommended.append(matchedProduct)
                }
            }
        }
        
        return recommended
    }
}
