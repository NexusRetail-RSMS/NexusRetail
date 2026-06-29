import SwiftUI

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Binding var path: NavigationPath
    
    @State private var allProducts: [POSProduct] = []
    @State private var scannedProduct: POSProduct? = nil
    @State private var isScanning = true
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom Curved Header
                    customHeaderSection
                    
                    if scannedProduct == nil {
                        // Scanner view
                        scannerViewSection
                    } else if let product = scannedProduct {
                        // Details and alternatives
                        productDetailSection(product)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .task {
            allProducts = await POSProductRepository.shared.fetchProducts()
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                if scannedProduct != nil {
                    withAnimation {
                        scannedProduct = nil
                        isScanning = true
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
                Text(scannedProduct == nil ? "Scan Barcode" : scannedProduct!.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(scannedProduct == nil ? "Barcode Scanner" : scannedProduct!.sku)
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
    
    // MARK: - Viewfinder Camera Mock
    private var scannerViewSection: some View {
        VStack(spacing: 32) {
            Text("Point camera at product barcode")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
            
            // Viewfinder Simulator Frame
            ZStack {
                // Dark translucent camera background
                Color.black.opacity(0.82)
                    .frame(height: 240)
                    .cornerRadius(20)
                
                // Clear center cutout
                RoundedRectangle(cornerRadius: 12)
                    .blendMode(.destinationOut)
                    .frame(width: 280, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RSMSColors.burgundy, lineWidth: 3)
                    )
                
                // Laser line animation
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 270, height: 2)
                    .offset(y: 0)
                
                Text("📷 Viewfinder Simulator")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .offset(y: 45)
            }
            .background(Color.clear)
            .compositingGroup()
            .padding(.horizontal, RSMSSpacing.lg)
            
            // Simulator Controls
            VStack(alignment: .leading, spacing: 14) {
                Text("Simulate Scans (For Demo/Testing)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.darkBrown)
                    .padding(.horizontal, 4)
                
                HStack(spacing: 12) {
                    // Available item trigger
                    Button {
                        simulateScan(forSku: "OX-SKY-03") // Sky Blue Shirt (In Stock)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Scan Available Item")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RSMSColors.success)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    
                    // Out of stock item trigger
                    Button {
                        simulateScan(forSku: "OX-BLUE-01") // Blue Oxford Shirt (Out of Stock)
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Scan Out of Stock")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RSMSColors.error)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
        }
        .padding(.top, 24)
        .padding(.bottom, 48)
    }
    
    private func simulateScan(forSku sku: String) {
        if let match = allProducts.first(where: { $0.sku == sku }) {
            withAnimation {
                isScanning = false
                scannedProduct = match
                viewModel.originalUnavailableProduct = match
            }
            
            // If in stock, immediately add to cart and go to Cart page!
            if match.stock > 0 {
                viewModel.addToCart(product: match)
                path.append(POSFlowDestination.cart)
            }
        }
    }
    
    // MARK: - Product Detail & Alternatives for Out-of-stock
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
                    
                    Text("₹\(Int(product.price))")
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
                
                Text("Price: ₹\(Int(alt.price))  •  Size: \(alt.size)")
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
    
    private func getAlternatives(for product: POSProduct) -> [POSProduct] {
        return allProducts.filter { item in
            item.id != product.id &&
            item.category == product.category &&
            item.stock > 0 &&
            abs(item.price - product.price) / product.price <= 0.3
        }
    }
}
