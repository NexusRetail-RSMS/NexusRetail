import SwiftUI

struct OrdersHubView: View {
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss

    enum OrderFlowType: String, CaseIterable {
        case instore = "In-Store POS"
        case bopis = "BOPIS Fulfill"
    }
    
    @State private var selectedFlow: OrderFlowType = .instore
    
    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented Control Area
                VStack {
                    HStack(alignment: .center, spacing: RSMSSpacing.md) {
                        Button { dismiss() } label: {
                            ZStack {
                                Circle().fill(RSMSColors.burgundy.opacity(0.1)).frame(width: 44, height: 44)
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold)).foregroundColor(RSMSColors.burgundy)
                            }
                        }
                        .accessibilityLabel("Back")
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Orders Hub")
                                .font(.system(size: 24, weight: .bold)).foregroundColor(RSMSColors.primaryText)
                        }
                        Spacer()
                        
                        // Profile Avatar
                        ZStack {
                            Circle()
                                .fill(RSMSColors.burgundy)
                                .frame(width: 40, height: 40)
                            Text("NI")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 60)
                    .padding(.bottom, 12)
                    
                    // Custom segmented control
                    HStack(spacing: 0) {
                        ForEach(OrderFlowType.allCases, id: \.self) { flow in
                            Button {
                                withAnimation {
                                    selectedFlow = flow
                                }
                            } label: {
                                Text(flow.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedFlow == flow ? .white : RSMSColors.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        ZStack {
                                            if selectedFlow == flow {
                                                Capsule().fill(RSMSColors.burgundy)
                                            }
                                        }
                                    )
                                    .contentShape(Capsule())
                            }
                        }
                    }
                    .background(Capsule().fill(RSMSColors.burgundy.opacity(0.05)).overlay(Capsule().stroke(RSMSColors.burgundy.opacity(0.1), lineWidth: 1)))
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xxxl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .zIndex(1)
                
                // Content
                if selectedFlow == .instore {
                    RecentOrdersView(hideHeader: true)
                } else {
                    BOPISView(hideHeader: true)
                }
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
    }
}
