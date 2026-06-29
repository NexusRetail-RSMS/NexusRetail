// Core ML product recommendations using the ItemRecommendation model.
// The model is an Item Similarity Recommender that takes item IDs (Int64)
// and returns recommended similar item IDs with confidence scores.

import Foundation
import CoreML

class RecommendationService {
    static let shared = RecommendationService()
    
    private var model: ItemRecommendation?
    
    /// Maps Supabase item_id (Int64) to product UUID
    private var itemIdToProductId: [Int64: UUID] = [:]
    /// Maps product UUID to Supabase item_id (Int64)
    private var productIdToItemId: [UUID: Int64] = [:]
    
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
    
    /// Call this after products are fetched from Supabase to build the item_id ↔ UUID mapping.
    /// Uses the real item_id from the sku table that the model was trained on.
    func buildProductMapping(from products: [POSProduct]) {
        itemIdToProductId.removeAll()
        productIdToItemId.removeAll()
        
        for product in products {
            guard product.itemId > 0 else { continue } // Skip fallback products with itemId 0
            print("Product:", product.name)
            print("UUID:", product.id)
            print("itemId:", product.itemId)
            itemIdToProductId[product.itemId] = product.id
            productIdToItemId[product.id] = product.itemId
        }
        
        print("RecommendationService: Built mapping for \(itemIdToProductId.count) products with valid item_ids")
    }
    
    /// Get ML-powered recommendations for a given product.
    /// Returns up to `count` recommended product UUIDs, sorted by relevance.
    func getRecommendations(for productId: UUID, count: Int = 5) -> [(productId: UUID, score: Double)] {
        guard let model = model else {
            print("RecommendationService: Model not loaded")
            return []
        }
        
        guard let itemId = productIdToItemId[productId] else {
            print("RecommendationService: Product \(productId) not found in mapping (no item_id)")
            print("RecommendationService: Current mapping has \(productIdToItemId.count) entries")
            return []
        }
        
        print("RecommendationService: [STEP 1] UUID \(productId) → item_id \(itemId)")
        
        do {
            // The model expects a dictionary of items the user has interacted with
            // We pass the current product with a score of 1.0
            let input = ItemRecommendationInput(
                items: [itemId: 1.0],
                k: Int64(count),
                restrict_: nil,
                exclude: nil
            )
            
            print("RecommendationService: [STEP 2] CoreML input → items: [\(itemId): 1.0], k: \(count)")
            
            let output = try model.prediction(input: input)
            
            print("RecommendationService: [STEP 3] CoreML output → \(output.recommendations.count) raw recommendations: \(output.recommendations)")
            
            // Map the recommended Int64 IDs back to product UUIDs
            var results: [(productId: UUID, score: Double)] = []
            
            for recommendedItemId in output.recommendations {
                if let uuid = itemIdToProductId[recommendedItemId] {
                    let score = output.scores[recommendedItemId] ?? 0.0
                    results.append((productId: uuid, score: score))
                    print("RecommendationService: [STEP 4] item_id \(recommendedItemId) → UUID \(uuid) (score: \(String(format: "%.3f", score)))")
                } else {
                    print("RecommendationService: [STEP 4] item_id \(recommendedItemId) → NOT in catalogue (model knows it, but not in our 62 products)")
                }
            }
            
            print("RecommendationService: [RESULT] \(results.count) of \(output.recommendations.count) recommendations matched catalogue products")
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
