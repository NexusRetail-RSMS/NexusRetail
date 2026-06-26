//
//  ProductCatalogueView.swift
//  NexusRetail
//

import SwiftUI

// MARK: - Main View

struct ProductCatalogueView: View {
    @StateObject private var viewModel = ProductCatalogueViewModel()
    @State private var showAddProduct = false
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xl)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: RSMSSpacing.lg) {
                        searchBar
                        if viewModel.searchText.isEmpty {
                            trendingCarousel
                            .animation(.easeInOut(duration: 0.3), value: viewModel.searchText.isEmpty)
                        }
                        productListSection
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddProduct) {
            NavigationStack {
                AddProductView()
                    .environmentObject(viewModel)
            }
        }
    }
    
    
    private var searchBar: some View {

        HStack(spacing: 12) {

            Image(systemName: "magnifyingglass")
                .foregroundColor(RSMSColors.burgundy)

            TextField(
                "Search products, SKU...",
                text: $viewModel.searchText
            )
            .foregroundColor(RSMSColors.darkBrown)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RSMSColors.background)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(RSMSRadius.large)
    }
    
    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Product Catalogue")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(RSMSColors.darkBrown)
            }

            Spacer()

            Button {
                showAddProduct = true
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy)
                        .frame(width: 44, height: 44)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Trending Carousel

    private var trendingCarousel: some View {
        VStack(spacing: RSMSSpacing.sm) {
            TabView(selection: $viewModel.currentTrendingIndex) {
                ForEach(Array(viewModel.trendingProducts.enumerated()), id: \.element.id) { index, product in
                    trendingCard(for: product)
                        .tag(index)
                        .padding(.horizontal, 2)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 240)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in viewModel.stopAutoScroll() }
                    .onEnded   { _ in viewModel.resumeAutoScroll() }
            )

            // Dot indicators
            HStack(spacing: 6) {
                ForEach(viewModel.trendingProducts.indices, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == viewModel.currentTrendingIndex
                                ? RSMSColors.burgundy
                                : RSMSColors.burgundy.opacity(0.25)
                        )
                        .frame(
                            width: index == viewModel.currentTrendingIndex ? 18 : 6,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.25), value: viewModel.currentTrendingIndex)
                }
            }
        }
    }

    // MARK: - Single Trending Card

    private func trendingCard(for product: TrendingProduct) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .fill(RSMSColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSRadius.large)
                        .stroke(RSMSColors.cardBorder, lineWidth: 1)
                )
                .frame(height: 240)
                .frame(maxWidth: .infinity)

            Text("TOP SELLING")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(RSMSColors.burgundy)
                .kerning(1.4)
                .padding(.horizontal, RSMSSpacing.md)
                .padding(.vertical, RSMSSpacing.xs)
                .background(Capsule().fill(RSMSColors.burgundy.opacity(0.08)))
                .padding(RSMSSpacing.md)

            HStack(spacing: RSMSSpacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: RSMSRadius.medium)
                        .fill(RSMSColors.burgundy.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                                .stroke(RSMSColors.burgundy.opacity(0.10), lineWidth: 1)
                        )
                        .frame(width: 150, height: 150)

                    Image(product.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))
                }
                .padding(.leading, RSMSSpacing.md)

                VStack(alignment: .leading, spacing: RSMSSpacing.xs) {
                    Spacer()
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(RSMSColors.darkBrown)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)

                    Text(viewModel.stockLabel(for: product))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.stockColor(for: product))

                    Text(viewModel.formattedPrice(for: product))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(RSMSColors.darkBrown)
                    Spacer()
                }
                .padding(.trailing, RSMSSpacing.md)

                Spacer(minLength: 0)
            }
            .padding(.top, 36)
        }
        .frame(maxWidth: .infinity)
        .shadow(
            color: RSMSColors.darkBrown.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }

    // MARK: - Product List Section

    private var productListSection: some View {
        VStack(spacing: RSMSSpacing.md) {
            productListHeader
            productRows
        }
    }

    private func toolIconButton(icon: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: RSMSRadius.small)
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(RSMSColors.darkBrown)
        }
    }

    private var productListHeader: some View {
        HStack {
            Text("Products")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(RSMSColors.darkBrown)
            Spacer()
            Menu {
                ForEach(viewModel.categoryOptions, id: \.self) { option in
                    Button(option) {
                        viewModel.selectedCategory = option
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
    
    private var productRows: some View {

        if viewModel.filteredProducts.isEmpty {

            VStack(spacing: 16) {

                Image(systemName: "shippingbox")
                    .font(.system(size: 42))
                    .foregroundColor(RSMSColors.secondaryText)

                Text("No Products Found")
                    .font(.headline)
                    .foregroundColor(RSMSColors.darkBrown)

                Text("Try a different product name, SKU, or category.")
                    .font(.subheadline)
                    .foregroundColor(RSMSColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity) as! VStack<ForEach<[CatalogueProduct], UUID, ProductRowCard>>

        } else {

            VStack(spacing: RSMSSpacing.sm) {
                ForEach(viewModel.filteredProducts) { product in
                    ProductRowCard(product: product, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Product Row Card

private struct ProductRowCard: View {

    let product: CatalogueProduct
    let viewModel: ProductCatalogueViewModel

    var body: some View {
        HStack(spacing: RSMSSpacing.md) {

            // Image well
            ZStack {
                RoundedRectangle(cornerRadius: RSMSRadius.medium)
                    .fill(RSMSColors.burgundy.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSRadius.medium)
                            .stroke(
                                RSMSColors.burgundy.opacity(0.10),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 80, height: 80)

                if let image = product.image {

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))

                } else if let imageName = product.imageName {

                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))

                } else {

                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))
                }
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {

                HStack(alignment: .top) {
                    Text(product.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(RSMSColors.darkBrown)
                        .lineLimit(1)

                    Spacer(minLength: RSMSSpacing.xs)
                }

                Text("\(product.sku) · \(product.category)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(RSMSColors.secondaryText)
                    .lineLimit(1)

                HStack(spacing: RSMSSpacing.md) {
                    Text("Stock \(product.stock)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(RSMSColors.secondaryText)

                    Text(product.date)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Text(viewModel.formattedPrice(for: product))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(RSMSColors.darkBrown)
                }
            }
        }
        .padding(RSMSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .fill(RSMSColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSRadius.large)
                        .stroke(
                            RSMSColors.cardBorder,
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: RSMSColors.darkBrown.opacity(0.04),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}



// MARK: - Preview

#Preview {
    NavigationStack {
        ProductCatalogueView()
    }
}

