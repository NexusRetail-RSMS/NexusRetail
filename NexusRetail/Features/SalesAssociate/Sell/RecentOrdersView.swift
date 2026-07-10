import SwiftUI

struct RecentOrdersView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore

    var hideHeader: Bool = false
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !hideHeader {
                        customHeaderSection
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Order History")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(theme.darkBrown)
                            .padding(.horizontal, 4)

                        if viewModel.isLoadingOrders {
                            HStack {
                                Spacer()
                                ProgressView("Loading orders…").tint(theme.burgundy)
                                Spacer()
                            }
                            .padding(.top, 40)
                        } else if viewModel.completedOrders.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bag")
                                    .font(.system(size: 40))
                                    .foregroundColor(theme.secondaryText.opacity(0.4))
                                Text("No recent orders")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.secondaryText)
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
            await viewModel.fetchRecentOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
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
            LinearGradient(colors: [theme.burgundy, theme.darkBurgundy],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(HeaderCurve())
    }

    private func orderRow(_ order: DBOrder) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(theme.burgundy.opacity(0.08)).frame(width: 44, height: 44)
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(theme.burgundy).font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(order.id)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                Text(order.formattedDate)
                    .font(.system(size: 12)).foregroundColor(theme.secondaryText)
                Text(order.formattedTime)
                    .font(.system(size: 11)).foregroundColor(theme.secondaryText.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatIndianCurrency(order.amount))
                    .font(.system(size: 14, weight: .bold)).foregroundColor(theme.primaryText)
                statusPill(order.status)
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder, lineWidth: 1))
    }

    private func statusPill(_ status: String) -> some View {
        let color: Color = status == "Completed" ? theme.success : theme.secondaryText
        let bg: Color    = status == "Completed" ? theme.success.opacity(0.08) : Color.gray.opacity(0.08)
        return Text(localized: status)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(bg).clipShape(Capsule())
    }
}
