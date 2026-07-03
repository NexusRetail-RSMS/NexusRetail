//
//  BOPISHistoryView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISHistoryView: View {
    var viewModel: BOPISViewModel
    
    var collectedOrders: [BOPISOrder] {
        viewModel.orders.filter { $0.status == .collected }
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()
            
            if collectedOrders.isEmpty {
                VStack(spacing: RSMSSpacing.xl) {
                    Spacer()
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 64))
                        .foregroundColor(RSMSColors.secondaryText)
                    Text("No Completed Orders")
                        .font(RSMSFonts.title)
                        .foregroundColor(RSMSColors.primaryText)
                    Text("Orders you mark as collected will appear here.")
                        .font(RSMSFonts.body)
                        .foregroundColor(RSMSColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: RSMSSpacing.lg) {
                        ForEach(collectedOrders) { order in
                            BOPISCardView(order: order) {
                                // No action needed for completed orders
                            }
                        }
                    }
                    .padding(RSMSSpacing.lg)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
