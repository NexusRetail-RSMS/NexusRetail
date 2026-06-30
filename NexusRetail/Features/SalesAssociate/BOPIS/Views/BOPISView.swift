//
//  BOPISView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISView: View {
    @State private var viewModel = BOPISViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Area
                    VStack(spacing: RSMSSpacing.md) {
                        SearchBarView(text: $viewModel.searchText)
                            .padding(.horizontal, RSMSSpacing.lg)
                        
                        FilterSegmentControl(selectedFilter: $viewModel.selectedFilter)
                    }
                    .padding(.top, RSMSSpacing.md)
                    .padding(.bottom, RSMSSpacing.sm)
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                    
                    // Main Content
                    if viewModel.filteredOrders.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: RSMSSpacing.lg) {
                                ForEach(viewModel.filteredOrders) { order in
                                    BOPISCardView(order: order) {
                                        handleAction(for: order)
                                    }
                                }
                            }
                            .padding(RSMSSpacing.lg)
                        }
                    }
                }
            }
            .navigationTitle("Buy Online Pickup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSColors.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: RSMSSpacing.xl) {
            Spacer()
            
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(RSMSColors.secondaryText)
            
            Text("No pickup orders available")
                .font(RSMSFonts.title)
                .foregroundColor(RSMSColors.primaryText)
            
            Text("Try changing your filters or search terms.")
                .font(RSMSFonts.body)
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func handleAction(for order: BOPISOrder) {
        withAnimation {
            switch order.status {
            case .pendingPreparation:
                viewModel.prepareOrder(id: order.id)
            case .readyForPickup:
                viewModel.notifyCustomer(id: order.id)
            case .waitingForCustomer:
                viewModel.markCollected(id: order.id)
            case .collected:
                break
            }
        }
    }
}
