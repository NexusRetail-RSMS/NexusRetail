import SwiftUI

struct ExchangeProductView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItemIds: Set<UUID>
    
    // Mock original product for demonstration
    @State private var originalProduct = POSProduct(
        id: UUID(),
        itemId: 1, // Add missing itemId
        name: "Classic White T-Shirt",
        sku: "TSH-WHT-M",
        category: "Tops",
        price: 1500.0,
        stock: 1,
        size: "M",
        imageUrl: nil
    )
    
    @State private var searchText = ""
    @State private var allProducts: [POSProduct] = []
    @State private var isLoading = false
    @State private var selectedReplacement: POSProduct? = nil
    
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
    
    var isNextEnabled: Bool {
        guard let replacement = selectedReplacement else { return false }
        return replacement.price >= originalProduct.price
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                customHeaderSection
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        originalProductSection
                        
                        Divider()
                            .background(theme.divider)
                            .padding(.horizontal, RSMSSpacing.lg)
                        
                        Text("Select Replacement")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                            .padding(.horizontal, RSMSSpacing.lg)
                        
                        searchBarSection
                            .padding(.horizontal, RSMSSpacing.lg)
                        
                        inventorySection
                    }
                    .padding(.top, RSMSSpacing.md)
                    .padding(.bottom, 100)
                }
            }
            
            VStack {
                Spacer()
                bottomBar
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            isLoading = true
            allProducts = await POSProductRepository.shared.fetchProducts(storeID: sessionStore.currentUser?.storeID)
            isLoading = false
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.primaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Exchange Product")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
            }
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.md)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Original Product
    private var originalProductSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Product to Exchange")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.secondaryText)
                .padding(.horizontal, RSMSSpacing.lg)
            
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: originalProduct.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                            .overlay(Image(systemName: "shippingbox").foregroundColor(theme.secondaryText))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(originalProduct.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    Text("SKU: \(originalProduct.sku)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                    Text(formatIndianCurrency(originalProduct.price))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.burgundy)
                }
                Spacer()
            }
            .padding(16)
            .background(theme.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            .padding(.horizontal, RSMSSpacing.lg)
        }
    }
    
    // MARK: - Search Bar
    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.secondaryText)
            
            TextField("Search inventory...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Inventory List
    private var inventorySection: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView().padding(.top, 20)
            } else if filteredProducts.isEmpty {
                Text("No products found.")
                    .foregroundColor(theme.secondaryText)
                    .padding(.top, 20)
            } else {
                ForEach(filteredProducts) { product in
                    productRow(product)
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    private func productRow(_ product: POSProduct) -> some View {
        let isSelected = selectedReplacement?.id == product.id
        
        return Button {
            withAnimation {
                selectedReplacement = product
            }
        } label: {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    
                    Text(formatIndianCurrency(product.price))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.darkBrown)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.burgundy)
                } else {
                    Circle()
                        .stroke(theme.cardBorder, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(14)
            .background(isSelected ? theme.burgundy.opacity(0.05) : .white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? theme.burgundy : theme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 16) {
            if let replacement = selectedReplacement {
                let diff = replacement.price - originalProduct.price
                HStack {
                    Text("Difference:")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                    Spacer()
                    Text(formatIndianCurrency(diff))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(diff >= 0 ? theme.primaryText : theme.error)
                }
                
                if diff < 0 {
                    Text("Replacement product must be equal or higher value.")
                        .font(.system(size: 12))
                        .foregroundColor(theme.error)
                }
                
                Button {
                    guard isNextEnabled else { return }
                    if diff > 0 {
                        path.append(POSFlowDestination.exchangePayment(originalProductId: originalProduct.id, replacementProductId: replacement.id, amount: diff))
                    } else { 
                        path.append(POSFlowDestination.exchangeSummary(originalProductId: originalProduct.id, replacementProductId: replacement.id, amount: 0))
                    }
                } label: {
                    Text("Next")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isNextEnabled ? theme.burgundy : Color.gray.opacity(0.4))
                        .cornerRadius(12)
                }
                .disabled(!isNextEnabled)
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.md)
        .padding(.bottom, 32)
        .background(.ultraThinMaterial)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}
