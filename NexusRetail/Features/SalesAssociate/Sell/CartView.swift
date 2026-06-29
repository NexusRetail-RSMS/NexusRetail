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
                                ForEach(viewModel.cartItems) { product in
                                    activeCartRow(product)
                                }
                            }
                        }
                        
                        // Add/Remove Status Changelog (Mockup style)
                        if !viewModel.actionLogs.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Activity Log")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(RSMSColors.secondaryText)
                                
                                VStack(spacing: 0) {
                                    ForEach(viewModel.actionLogs) { log in
                                        HStack {
                                            Text(log.productName)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(RSMSColors.primaryText)
                                            
                                            Spacer()
                                            
                                            if log.action == .removed {
                                                HStack(spacing: 4) {
                                                    Text("❌ Removed")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(RSMSColors.error)
                                                }
                                            } else {
                                                HStack(spacing: 4) {
                                                    Text("✓ Added")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(RSMSColors.success)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 10)
                                        
                                        if log != viewModel.actionLogs.last {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(16)
                                .background(RSMSColors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(RSMSColors.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                        
                        // Pricing Summary Card
                        VStack(spacing: 12) {
                            HStack {
                                Text("Subtotal")
                                    .font(.system(size: 15))
                                    .foregroundColor(RSMSColors.secondaryText)
                                Spacer()
                                Text("₹\(Int(viewModel.subtotalAmount))")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(RSMSColors.primaryText)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Amount")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(RSMSColors.darkBrown)
                                Spacer()
                                Text("₹\(Int(viewModel.totalAmount))")
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
    
    private func activeCartRow(_ product: POSProduct) -> some View {
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
                
                Text("₹\(Int(product.price))  •  Size: \(product.size)")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    viewModel.removeFromCart(product: product)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(RSMSColors.error.opacity(0.8))
                    .font(.system(size: 14))
                    .frame(width: 32, height: 32)
                    .background(RSMSColors.error.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
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
