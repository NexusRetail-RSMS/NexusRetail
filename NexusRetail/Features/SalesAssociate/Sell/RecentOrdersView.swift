import SwiftUI

struct RecentOrdersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom Curved Header
                    customHeaderSection
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Order History")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSColors.darkBrown)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.completedOrders) { order in
                                orderRow(order)
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
                Text("Recent Orders")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("POS Transaction History")
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
    
    private func orderRow(_ order: MockPOSOrder) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.08))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(RSMSColors.burgundy)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Order \(order.id)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(order.client)
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
                
                Text(order.time)
                    .font(.system(size: 11))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.8))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("$\(String(format: "%.2f", order.amount))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                // Status Pill
                statusPill(order.status)
            }
        }
        .padding(14)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
    }
    
    private func statusPill(_ status: String) -> some View {
        let color: Color
        let bgColor: Color
        
        switch status {
        case "Completed":
            color = RSMSColors.success
            bgColor = RSMSColors.success.opacity(0.08)
        case "Pending Payment":
            color = RSMSColors.warning
            bgColor = RSMSColors.warning.opacity(0.08)
        case "Alternative Suggested":
            color = Color.blue
            bgColor = Color.blue.opacity(0.08)
        default:
            color = RSMSColors.secondaryText
            bgColor = Color.gray.opacity(0.08)
        }
        
        return Text(status)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bgColor)
            .clipShape(Capsule())
    }
}
