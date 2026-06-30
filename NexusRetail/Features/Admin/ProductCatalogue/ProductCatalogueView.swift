import SwiftUI
import CoreImage.CIFilterBuiltins

struct ProductCatalogueView: View {
    @StateObject private var viewModel = ProductCatalogueViewModel()
    @State private var showAddProduct = false
    @State private var editingProduct: CatalogueProduct?
    @State private var productToDelete: CatalogueProduct?
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background.ignoresSafeArea()

            productList
        }
        .navigationBarHidden(true)
        .sheet(item: $editingProduct) { product in
            AddProductView(product: product)
                .environmentObject(viewModel)
        }

        .sheet(isPresented: $showAddProduct) {
            AddProductView()
                .environmentObject(viewModel)
        }
        .alert("Delete Product", isPresented: Binding(
            get: { productToDelete != nil },
            set: { if !$0 { productToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let product = productToDelete {
                    viewModel.deleteProduct(product)
                    productToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                productToDelete = nil
            }
        } message: {
            if let product = productToDelete {
                Text("Are you sure you want to delete \"\(product.name)\"? This action cannot be undone.")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: RSMSSpacing.md) {
            HStack {
                Text("Products")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                Button {
                    showAddProduct = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(RSMSColors.burgundy)
                        .frame(width: 44, height: 44)
                        .background(RSMSColors.burgundy.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            searchBarRow
        }
    }

    private var productList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                if viewModel.searchText.isEmpty {
                    trendingSection
                }

                productsHeader
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                if viewModel.filteredProducts.isEmpty {
                    ContentUnavailableView(
                        "No Products Found",
                        systemImage: "shippingbox",
                        description: Text("Try a different name, SKU, or category.")
                    )
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: RSMSSpacing.md) {
                        ForEach(viewModel.filteredProducts) { product in
                            ProductRowCard(
                                product: product,
                                viewModel: viewModel,
                                onEdit: { editingProduct = product },
                                onDelete: { productToDelete = product }
                            )
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                }
            }
            .padding(.top, RSMSSpacing.sm)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(RSMSColors.background)
        .animation(.easeInOut(duration: 0.2), value: viewModel.searchText)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedCategory)
    }

    private var searchBarRow: some View {
        NexusSearchBar(text: $viewModel.searchText, placeholder: "Search products, SKU…")
    }


    @ViewBuilder
    private var trendingSection: some View {
        if viewModel.trendingProducts.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 10) {
                GeometryReader { geo in
                    TabView(selection: $viewModel.currentTrendingIndex) {
                        ForEach(Array(viewModel.trendingProducts.enumerated()), id: \.element.id) { index, product in
                            trendingCard(for: product)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(width: geo.size.width, height: 210)
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { _ in viewModel.stopAutoScroll() }
                            .onEnded   { _ in viewModel.resumeAutoScroll() }
                    )
                }
                .frame(height: 210)

                HStack(spacing: 6) {
                    ForEach(viewModel.trendingProducts.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == viewModel.currentTrendingIndex
                                  ? RSMSColors.burgundy
                                  : RSMSColors.burgundy.opacity(0.2))
                            .frame(width: i == viewModel.currentTrendingIndex ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentTrendingIndex)
                    }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, 12)
        }
    }

    private func trendingCard(for product: TrendingProduct) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let imageUrlStr = product.imageUrl, let url = URL(string: imageUrlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.3)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Color.gray.opacity(0.3)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()
            } else if let imageName = product.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .clipped()
            } else {
                Color.gray.opacity(0.3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
            }

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.25),
                    .init(color: Color.black.opacity(0.75), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("TOP SELLING")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .kerning(1.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.18)))

                Text(product.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(viewModel.formattedPrice(for: product))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(18)
        }
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 6)
    }

    private var productsHeader: some View {
        HStack {
            Text("Products")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSColors.darkBrown)
            Spacer()
            Menu {
                ForEach(viewModel.categoryOptions, id: \.self) { option in
                    Button {
                        viewModel.selectedCategory = option
                    } label: {
                        if viewModel.selectedCategory == option {
                            Label(option, systemImage: "checkmark")
                        } else {
                            Text(option)
                        }
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: "line.3.horizontal.decrease")
                        .foregroundColor(RSMSColors.burgundy)
                        .font(.system(size: 14, weight: .medium))
                }
            }
        }
    }
}

private struct ProductRowCard: View {
    let product: CatalogueProduct
    let viewModel: ProductCatalogueViewModel
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var stockColor: Color {
        if product.stock == 0 { return RSMSColors.warning }
        if product.stock < 10 { return .orange }
        return RSMSColors.success
    }

        @State private var showQR = false
        
        var body: some View {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(RSMSColors.burgundy.opacity(0.06))

                    if let image = product.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else if let imageUrlStr = product.imageUrl, let url = URL(string: imageUrlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 72, height: 72)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(RSMSColors.secondaryText.opacity(0.4))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else if let imageName = product.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundStyle(RSMSColors.secondaryText.opacity(0.4))
                    }
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 3) {

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(product.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(RSMSColors.darkBrown)
                                .lineLimit(1)

                            Text(product.category)
                                .font(.system(size: 12))
                                .foregroundStyle(RSMSColors.secondaryText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            // Price on the right
                            Text(viewModel.formattedPrice(for: product))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSColors.darkBrown)
                            
                            if product.qrCode != nil {
                                Button {
                                    showQR = true
                                } label: {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 16))
                                        .foregroundColor(RSMSColors.burgundy)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(14)
            .frame(height: 100)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: RSMSColors.darkBrown.opacity(0.04), radius: 6, x: 0, y: 2)
            .contextMenu {
                if product.qrCode != nil {
                    Button {
                        showQR = true
                    } label: {
                        Label("Show QR Code", systemImage: "qrcode")
                    }
                }
                
                Button {
                    onEdit()
                } label: {
                    Label {
                        Text("Edit")
                    } icon: {
                        Image(systemName: "square.and.pencil")
                            .renderingMode(.template)
                            .foregroundColor(.black)
                    }
                }
                .tint(.black)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label {
                        Text("Delete")
                    } icon: {
                        Image(systemName: "trash")
                            .renderingMode(.template)
                            .foregroundColor(.red)
                    }
                }
                .tint(.red)
            }
            .tint(.black)
            .sheet(isPresented: $showQR) {
                if let qr = product.qrCode {
                    NavigationStack {
                        VStack(spacing: 24) {
                            Text(product.name)
                                .font(.headline)
                            
                            QRCodeView(qrCodeString: qr)
                                .frame(width: 250, height: 250)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(radius: 4)
                            
                            Text("SKU: \(product.sku)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .navigationTitle("Product QR")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showQR = false
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium])
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductCatalogueView()
    }
}

// MARK: - QR Code Utility

struct QRCodeView: View {
    let qrCodeString: String
    
    var body: some View {
        Image(uiImage: generateQRCode(from: qrCodeString))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }
    
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
