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
    func getRecommendations(for productId: UUID, count: Int = 30) -> [(productId: UUID, score: Double)] {
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
        // Request 30 recommendations from CoreML under the hood to ensure a large candidate pool
        let recommendations = getRecommendations(for: product.id, count: 30)
        
        var recommended: [POSProduct] = []
        var matchedCatalogueCount = 0
        var outOfStockCount = 0
        var missingFromCatalogueCount = 30 - recommendations.count // CoreML returns k=30, but how many mapped back
        
        // Keep track of the raw output mapping for detailed debugging
        print("\n=== Recommendation Candidate Evaluation ===")
        
        for (index, rec) in recommendations.enumerated() {
            let matchedProduct = allProducts.first(where: { $0.id == rec.productId })
            let itemId = productIdToItemId[rec.productId] ?? 0
            
            print("Recommendation Candidate \(index + 1):")
            
            if let matched = matchedProduct {
                matchedCatalogueCount += 1
                let hasStock = matched.stock > 0
                
                print("  Name: \(matched.name)")
                print("  item_id: \(itemId)")
                print("  UUID: \(matched.id)")
                print("  Stock: \(matched.stock)")
                print("  Available: \(hasStock)")
                
                if matched.id == product.id {
                    print("  Reason skipped: Same product")
                    continue
                }
                
                if !hasStock {
                    outOfStockCount += 1
                    print("  Reason skipped: Out of stock")
                    continue
                }
                
                // If it is valid, append it
                if recommended.count < count {
                    recommended.append(matched)
                    print("  Status: Added to recommendations")
                } else {
                    print("  Status: Skipped (already collected target count of \(count))")
                }
            } else {
                print("  UUID: \(rec.productId)")
                print("  item_id: \(itemId)")
                print("  Reason skipped: Missing from catalogue")
            }
        }
        
        // Print Summary of CoreML vs Catalogue overlap
        print("\n=== CoreML Recommendation Run Summary ===")
        print("CoreML returned: 30")
        print("Matched catalogue: \(matchedCatalogueCount)")
        print("Out of stock: \(outOfStockCount)")
        print("Missing from catalogue: \(30 - matchedCatalogueCount)")
        print("Present in catalogue: \(matchedCatalogueCount)")
        
        // Resilience: If we have fewer than 5, fill the rest with category-based alternatives
        let mlCount = recommended.count
        if recommended.count < count {
            print("RecommendationService: Only found \(mlCount) valid ML recommendations. Filling remaining \(count - mlCount) slots with category match...")
            
            let categoryAlternatives = allProducts.filter { item in
                item.id != product.id &&
                item.category == product.category &&
                item.stock > 0 &&
                abs(item.price - product.price) / product.price <= 0.3 &&
                !recommended.contains(where: { $0.id == item.id }) // Don't duplicate already selected ML recommendations
            }
            
            for alt in categoryAlternatives {
                if recommended.count < count {
                    recommended.append(alt)
                    print("  Added Category Alternative: \(alt.name) (UUID: \(alt.id))")
                } else {
                    break
                }
            }
        }
        
        print("Final recommendations: \(recommended.map { $0.name })")
        print("==========================================\n")
        
        return recommended
    }
}
