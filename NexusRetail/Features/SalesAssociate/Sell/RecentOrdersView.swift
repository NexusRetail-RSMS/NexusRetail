import SwiftUI

struct RecentOrdersView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Mock orders log matching mockup details
    let recentOrders = [
        MockPOSOrder(id: "#421", client: "Ananya Rao", amount: 3299, status: "Completed", time: "11:30 AM", date: "Today"),
        MockPOSOrder(id: "#420", client: "Kabir Mehta", amount: 2199, status: "Pending Payment", time: "10:15 AM", date: "Today"),
        MockPOSOrder(id: "#419", client: "Mira Kapoor", amount: 1999, status: "Alternative Suggested", time: "Yesterday", date: "Yesterday"),
        MockPOSOrder(id: "#418", client: "Rhea Sethi", amount: 1299, status: "Completed", time: "2 days ago", date: "2 days ago")
    ]
    
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
                            ForEach(recentOrders) { order in
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
                Text("₹\(Int(order.amount))")
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

struct MockPOSOrder: Identifiable {
    let id: String
    let client: String
    let amount: Double
    let status: String
    let time: String
    let date: String
}
