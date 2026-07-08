import SwiftUI

/// A sticky bottom bar summarizing the current cart (item count + live total)
/// with a "View Cart" call-to-action. Hidden when the cart is empty.
///
/// Attach via `.safeAreaInset(edge: .bottom)` on any POS screen so the cart and
/// checkout are always one tap away. Reads `SellViewModel` from the environment
/// and appends `POSFlowDestination.cart` to the bound navigation path on tap.
struct POSCartBar: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SellViewModel.self) private var viewModel
    @Binding var path: NavigationPath

    var body: some View {
        if !viewModel.cartItems.isEmpty {
            Button {
                path.append(POSFlowDestination.cart)
            } label: {
                HStack(spacing: 14) {
                    // Count badge
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        // Item-count bubble
                        Text("\(viewModel.cartItems.count)")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(theme.burgundy)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: 15, y: -15)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.cartItems.count) item\(viewModel.cartItems.count == 1 ? "" : "s") in cart")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                        Text(formatIndianCurrency(viewModel.totalAmount))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("View Cart")
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [theme.burgundy, theme.darkBurgundy],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: theme.burgundy.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.sm)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
