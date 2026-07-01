import SwiftUI
import Supabase

struct ClientProfileView: View {
    let client: AssociateClient
    @Environment(SessionStore.self) private var sessionStore
    
    @State private var selectedTab = 0
    @State private var forYouProducts: [POSProduct] = []
    @State private var trendingProducts: [POSProduct] = []
    
    @State private var isLoading = true
    
    private struct TopProductsRPCParams: Encodable {
        let p_period: String
        let p_limit: Int
        let p_country: String?
    }
    
    private struct MinimalTopProduct: Decodable {
        let id: UUID
        let units: Int
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                profileHeader
                
                // Tabs
                Picker("Recommendations", selection: $selectedTab) {
                    Text("For You").tag(0)
                    Text("Trending").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                // Content
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else {
                    if selectedTab == 0 {
                        recommendationsGrid(forYouProducts)
                    } else {
                        recommendationsGrid(trendingProducts)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(RSMSColors.background.ignoresSafeArea())
        .task {
            await loadRecommendations()
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 80, height: 80)
                Text(String(client.name.prefix(1)))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.burgundy)
            }
            .padding(.top, 24)
            
            VStack(spacing: 4) {
                Text(client.phone)
                    .font(.system(size: 15))
                    .foregroundStyle(RSMSColors.secondaryText)
                
                Text(client.preferences)
                    .font(.system(size: 14))
                    .foregroundStyle(RSMSColors.darkBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
        }
    }
    
    private func recommendationsGrid(_ products: [POSProduct]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
            ForEach(products) { product in
                ProductCardView(product: product)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func loadRecommendations() async {
        isLoading = true
        defer { isLoading = false }
        
        let allProducts = await POSProductRepository.shared.fetchProducts(storeID: sessionStore.currentUser?.storeID)
        
        // --- 1. For You (ML Recommendations) ---
        RecommendationService.shared.buildProductMapping(from: allProducts)
        
        // Extract keywords from client's preferences
        let preferencesKeywords = client.preferences
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
            
        // Find products matching the preferences
        let matchingProducts = allProducts.filter { product in
            let searchString = "\(product.name) \(product.category)".lowercased()
            return preferencesKeywords.contains { keyword in
                searchString.contains(keyword)
            }
        }
        
        // Try to show products directly matching preferences
        if !matchingProducts.isEmpty {
            forYouProducts = Array(matchingProducts.shuffled().prefix(6))
            
            // If we have fewer than 6 matches, use the ML model to fill the rest
            if forYouProducts.count < 6, let seed = matchingProducts.randomElement() {
                let additionalRecs = RecommendationService.shared.getRecommendedProducts(
                    for: seed,
                    from: allProducts,
                    count: 6 - forYouProducts.count
                )
                // Append only unique products
                for rec in additionalRecs {
                    if !forYouProducts.contains(where: { $0.id == rec.id }) {
                        forYouProducts.append(rec)
                    }
                }
            }
        } else {
            // Fallback: seed the ML model with a random product if no preferences match
            if let seed = allProducts.randomElement() {
                forYouProducts = RecommendationService.shared.getRecommendedProducts(for: seed, from: allProducts, count: 6)
            }
        }
        
        if forYouProducts.isEmpty {
            forYouProducts = Array(allProducts.shuffled().prefix(6))
        }
        
        // --- 2. Trending ---
        do {
            let topParams = TopProductsRPCParams(p_period: "month", p_limit: 6, p_country: nil)
            let topProductsResp: [MinimalTopProduct] = try await SupabaseManager.shared.client
                .rpc("top_products", params: topParams)
                .execute()
                .value
            
            trendingProducts = topProductsResp.compactMap { top in
                allProducts.first(where: { $0.id == top.id })
            }
            
            if trendingProducts.isEmpty {
                trendingProducts = Array(allProducts.prefix(6))
            }
        } catch {
            print("Error fetching top products for profile: \(error)")
            trendingProducts = Array(allProducts.shuffled().prefix(6))
        }
    }
}

fileprivate struct ProductCardView: View {
    let product: POSProduct
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            Color.white
                .aspectRatio(0.8, contentMode: .fit)
                .overlay {
                    if let urlString = product.imageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Image(systemName: "photo").foregroundStyle(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RSMSColors.primaryText)
                    .lineLimit(2)
                
                Text(String(format: "$%.2f", product.price))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(RSMSColors.burgundy)
            }
            .padding(.horizontal, 4)
        }
    }
}
