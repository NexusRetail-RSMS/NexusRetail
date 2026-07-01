import SwiftUI

struct ProductSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore
    @Binding var path: NavigationPath
    
    var initialSearch: String = ""
    
    @State private var searchText = ""
    @State private var allProducts: [POSProduct] = []
    @State private var isLoading = false
    
    // Track selected product to display its details/alternatives
    @State private var selectedProduct: POSProduct? = nil
    
    var filteredProducts: [POSProduct] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return allProducts
        }
        return allProducts.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.sku.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query)
        }
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if selectedProduct == nil {
                        // Search Results List
                        searchResultsSection
                    } else if let product = selectedProduct {
                        // Out of Stock / Product Detail Mode
                        productDetailSection(product)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    customHeaderSection
                    if selectedProduct == nil {
                        searchBarSection
                            .padding(.horizontal, RSMSSpacing.lg)
                            .padding(.top, RSMSSpacing.md)
                            .padding(.bottom, RSMSSpacing.sm)
                    }
                }
                .background(.ultraThinMaterial)
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .task {
            isLoading = true
            allProducts = await POSProductRepository.shared.fetchProducts(storeID: sessionStore.currentUser?.storeID)
            isLoading = false
        }
        .onAppear {
            if !initialSearch.isEmpty {
                searchText = initialSearch
            }
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                if selectedProduct != nil {
                    // Go back to search list
                    withAnimation {
                        selectedProduct = nil
                    }
                } else {
                    dismiss()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Back")
            
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedProduct == nil ? "Search Product" : selectedProduct!.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(selectedProduct == nil ? "Point of Sale" : selectedProduct!.sku)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }
    
    // MARK: - Search Mode View
    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(RSMSColors.secondaryText)
            
            TextField("Search by name, SKU, or category...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.6))
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading products...")
                        .tint(RSMSColors.burgundy)
                    Spacer()
                }
                .padding(.top, 40)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Text(searchText.isEmpty ? "All Products" : "Search Results")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.darkBrown)
                    
                    if filteredProducts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 40))
                                .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                            Text("No products found matching '\(searchText)'")
                                .font(.system(size: 14))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredProducts) { product in
                            productRow(product)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.xxl)
    }
    
    private func productRow(_ product: POSProduct) -> some View {
        Button {
            if product.stock > 0 {
                // Add directly and go to Cart
                viewModel.addToCart(product: product)
                path.append(POSFlowDestination.cart)
            } else {
                // Go to Out-of-Stock Detail Mode
                viewModel.originalUnavailableProduct = product
                withAnimation {
                    selectedProduct = product
                }
            }
        } label: {
            HStack(spacing: 16) {
                // Product Image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                            .overlay(
                                Image(systemName: "shippingbox")
                                    .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                            )
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text("SKU: \(product.sku)  •  Size: \(product.size)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                }
                
                Spacer()
                
                // Status Pill
                VStack(alignment: .trailing, spacing: 6) {
                    if product.stock > 10 {
                        Text("In Stock")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(RSMSColors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RSMSColors.success.opacity(0.08))
                            .clipShape(Capsule())
                    } else if product.stock > 0 {
                        Text("Only \(product.stock) left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(RSMSColors.warning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RSMSColors.warning.opacity(0.08))
                            .clipShape(Capsule())
                    } else {
                        Text("Out of Stock")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(RSMSColors.error)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RSMSColors.error.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                }
            }
            .padding(14)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Product Detail & Out-of-Stock Alternatives
    private func productDetailSection(_ product: POSProduct) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Main Product Detail Card
            HStack(spacing: 20) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                            .overlay(Image(systemName: "shippingbox"))
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text("Category: \(product.category)  •  Size: \(product.size)")
                        .font(.system(size: 13))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                    
                    // Out of stock banner
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Out of Stock")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(RSMSColors.error)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RSMSColors.error.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                }
                Spacer()
            }
            .padding(18)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            
            // Suggested Alternatives Checklist
            VStack(alignment: .leading, spacing: 14) {
                Text("Suggested Alternatives")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.darkBrown)
                
                HStack(spacing: 12) {
                    checklistBadge("Same Category")
                    checklistBadge("Similar Price")
                    checklistBadge("Same Size")
                }
                .padding(.bottom, 6)
                
                // Fetch and list alternatives
                let alternatives = getAlternatives(for: product)
                if alternatives.isEmpty {
                    Text("No suitable alternatives found in stock.")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                        .padding(.vertical, 10)
                } else {
                    VStack(spacing: 12) {
                        ForEach(alternatives) { alt in
                            alternativeRow(alt)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.xxl)
    }
    
    private func checklistBadge(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(RSMSColors.burgundy)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(RSMSColors.burgundy.opacity(0.08))
        .clipShape(Capsule())
    }
    
    private func alternativeRow(_ alt: POSProduct) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: alt.imageUrl ?? "")) { phase in
                if let image = phase.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alt.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text("Price: $\(String(format: "%.2f", alt.price))  •  Size: \(alt.size)")
                    .font(.system(size: 11))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
            
            Button {
                // Add to cart as alternative
                viewModel.isAlternativeSuggested = true
                viewModel.addToCart(product: alt, isAlternative: true)
                path.append(POSFlowDestination.cart)
            } label: {
                Text("Add")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RSMSColors.burgundy)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(12)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Alternatives Fetching Logic (ML-Powered)
    private func getAlternatives(for product: POSProduct) -> [POSProduct] {
        // Try ML-powered recommendations first
        let mlRecommendations = RecommendationService.shared.getRecommendedProducts(
            for: product,
            from: allProducts,
            count: 5
        )
        
        if !mlRecommendations.isEmpty {
            print("ProductSearchView: Using ML recommendations for \(product.name): \(mlRecommendations.map { $0.name })")
            return mlRecommendations
        }
        
        // Fallback: same category, stock > 0, not itself, similar price (within 30% difference)
        print("ProductSearchView: ML returned no results, falling back to category match for \(product.name)")
        return allProducts.filter { item in
            item.id != product.id &&
            item.category == product.category &&
            item.stock > 0 &&
            abs(item.price - product.price) / product.price <= 0.3
        }
    }
}
