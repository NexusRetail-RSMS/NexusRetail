import SwiftUI

struct CartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom Curved Header
                    customHeaderSection
                    
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Active Cart Items Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Selected Items")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)
                            
                            if viewModel.cartItems.isEmpty {
                                Text("Your cart is empty")
                                    .font(.system(size: 14))
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(groupedItems, id: \.product.id) { item in
                                    activeCartRow(item.product, count: item.count)
                                }
                            }
                        }
                        
                        // Pricing Summary Card
                        VStack(spacing: 12) {
                            HStack {
                                Text("Subtotal")
                                    .font(.system(size: 15))
                                    .foregroundColor(RSMSColors.secondaryText)
                                Spacer()
                                Text("$\(String(format: "%.2f", viewModel.subtotalAmount))")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(RSMSColors.primaryText)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Amount")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(RSMSColors.darkBrown)
                                Spacer()
                                Text("$\(String(format: "%.2f", viewModel.totalAmount))")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(RSMSColors.burgundy)
                            }
                        }
                        .padding(18)
                        .background(RSMSColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(RSMSColors.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                        
                        // Proceed to Checkout
                        if !viewModel.cartItems.isEmpty {
                            VStack(spacing: 12) {
                                Button {
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "barcode.viewfinder")
                                        Text("Scan Another Item")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .foregroundColor(RSMSColors.burgundy)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(RSMSColors.burgundy, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    path.append(POSFlowDestination.checkout)
                                } label: {
                                    HStack {
                                        Text("Checkout")
                                            .font(.system(size: 16, weight: .bold))
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(RSMSColors.burgundy)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: RSMSColors.burgundy.opacity(0.2), radius: 10, x: 0, y: 5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
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
                Text("Shopping Cart")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(viewModel.cartItems.count) Item\(viewModel.cartItems.count == 1 ? "" : "s") Selected")
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
    
    // Computed property to get unique products and their quantities
    private var groupedItems: [(product: POSProduct, count: Int)] {
        var counts: [UUID: Int] = [:]
        var uniqueProducts: [POSProduct] = []
        for item in viewModel.cartItems {
            if counts[item.id] == nil {
                uniqueProducts.append(item)
                counts[item.id] = 1
            } else {
                counts[item.id]! += 1
            }
        }
        return uniqueProducts.map { ($0, counts[$0.id] ?? 1) }
    }
    
    private func activeCartRow(_ product: POSProduct, count: Int) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
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
                Text(product.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text("$\(String(format: "%.2f", product.price))  •  Size: \(product.size)")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
            
            // Stepper
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        viewModel.removeFromCart(product: product)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSColors.darkBrown)
                        .frame(width: 28, height: 28)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .frame(minWidth: 16, alignment: .center)
                
                Button {
                    withAnimation {
                        viewModel.addToCart(product: product)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSColors.darkBrown)
                        .frame(width: 28, height: 28)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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
}
