import SwiftUI

struct RecentOrdersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    customHeaderSection

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Order History")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSColors.darkBrown)
                            .padding(.horizontal, 4)

                        if viewModel.isLoadingOrders {
                            HStack {
                                Spacer()
                                ProgressView("Loading orders…").tint(RSMSColors.burgundy)
                                Spacer()
                            }
                            .padding(.top, 40)
                        } else if viewModel.completedOrders.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bag")
                                    .font(.system(size: 40))
                                    .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                                Text("No recent orders")
                                    .font(.system(size: 14))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.completedOrders) { order in
                                    orderRow(order)
                                }
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
        .task {
            await viewModel.fetchRecentOrders(storeID: sessionStore.currentUser?.storeID)
        }
    }

    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                }
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Recent Orders")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Text("POS Transaction History")
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(HeaderCurve())
    }

    private func orderRow(_ order: DBOrder) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(RSMSColors.burgundy.opacity(0.08)).frame(width: 44, height: 44)
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(RSMSColors.burgundy).font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(order.id)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                Text(order.formattedDate)
                    .font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
                Text(order.formattedTime)
                    .font(.system(size: 11)).foregroundColor(RSMSColors.secondaryText.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("₹\(formatINR(order.amount))")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(RSMSColors.primaryText)
                statusPill(order.status)
            }
        }
        .padding(14)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }

    private func statusPill(_ status: String) -> some View {
        let color: Color = status == "Completed" ? RSMSColors.success : RSMSColors.secondaryText
        let bg: Color    = status == "Completed" ? RSMSColors.success.opacity(0.08) : Color.gray.opacity(0.08)
        return Text(status)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(bg).clipShape(Capsule())
    }

    private func formatINR(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal; f.groupingSeparator = ","
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}
