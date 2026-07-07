import SwiftUI

struct CartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    customHeaderSection

                    VStack(alignment: .leading, spacing: 24) {

                        // Active Cart Items
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

                        // Pricing Summary
                        VStack(spacing: 12) {
                            HStack {
                                Text("Total Amount")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(RSMSColors.darkBrown)
                                Spacer()
                                Text(formatIndianCurrency(viewModel.totalAmount))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(RSMSColors.burgundy)
                            }
                        }
                        .padding(18)
                        .background(RSMSColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSColors.cardBorder, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)

                        // "Scan another" stays inline; the primary Checkout CTA
                        // lives in the sticky bottom bar below.
                        if !viewModel.cartItems.isEmpty {
                            Button { dismiss() } label: {
                                HStack {
                                    Image(systemName: "barcode.viewfinder")
                                    Text("Scan Another Item").font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(RSMSColors.burgundy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.burgundy, lineWidth: 1))
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
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if !viewModel.cartItems.isEmpty {
                stickyCheckoutBar
            }
        }
    }

    // Sticky bottom checkout bar: live total + primary CTA.
    private var stickyCheckoutBar: some View {
        Button { path.append(POSFlowDestination.checkout) } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                    Text(formatIndianCurrency(viewModel.totalAmount))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("Proceed to Checkout").font(.system(size: 16, weight: .bold))
                    Image(systemName: "arrow.right").font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: RSMSColors.burgundy.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.sm)
        .background(.ultraThinMaterial)
    }

    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                }
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Shopping Cart").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Text("\(groupedItems.count) SKU\(groupedItems.count == 1 ? "" : "s")  •  \(viewModel.cartItems.count) item\(viewModel.cartItems.count == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(HeaderCurve())
    }

    private var groupedItems: [(product: POSProduct, count: Int)] {
        var counts: [UUID: Int] = [:]
        var uniqueProducts: [POSProduct] = []
        for item in viewModel.cartItems {
            if counts[item.id] == nil { uniqueProducts.append(item); counts[item.id] = 1 }
            else { counts[item.id]! += 1 }
        }
        return uniqueProducts.map { ($0, counts[$0.id] ?? 1) }
    }

    private func activeCartRow(_ product: POSProduct, count: Int) -> some View {
        // Find the live stock from the repository
        let available = POSProductRepository.shared.products
            .first(where: { $0.id == product.id })?.stock ?? product.stock
        let atMax = count >= available

        return HStack(spacing: 14) {
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                if let image = phase.image { image.resizable().aspectRatio(contentMode: .fill) }
                else { Color.gray.opacity(0.1) }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(formatIndianCurrency(product.price))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(RSMSColors.burgundy)
                    Text("each")
                        .font(.system(size: 11))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                if atMax {
                    Text("Max stock reached (\(available) available)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(RSMSColors.warning)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                // Line total
                Text(formatIndianCurrency(product.price * Double(count)))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)

                HStack(spacing: 10) {
                    Button {
                        withAnimation { viewModel.removeFromCart(product: product) }
                    } label: {
                        Image(systemName: count == 1 ? "trash" : "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(count == 1 ? RSMSColors.error : RSMSColors.darkBrown)
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }.buttonStyle(.plain)

                    Text("\(count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                        .frame(minWidth: 18, alignment: .center)

                    Button {
                        withAnimation { viewModel.addToCart(product: product) }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(atMax ? Color.gray : RSMSColors.darkBrown)
                            .frame(width: 28, height: 28)
                            .background(atMax ? Color.gray.opacity(0.08) : Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(atMax)
                }
            }
        }
        .padding(14)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }


}
