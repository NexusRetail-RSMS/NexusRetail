//
//  BOPISView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISView: View {
    @State private var viewModel = BOPISViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: BOPISOrderStatus? = nil
    @State private var orderToPack: BOPISOrder?
    @State private var showNotifiedAlert = false
    @State private var notifiedCustomerName = ""
    
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
            .navigationTitle("BOPIS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: BOPISHistoryView(viewModel: viewModel)) {
                        Image(systemName: "clock")
                            .foregroundColor(RSMSColors.burgundy)
                    }
                }
            }
            .sheet(item: $orderToPack) { order in
                BOPISPackOrderView(order: order) {
                    viewModel.packAndNotify(id: order.id)
                    notifiedCustomerName = order.customerName
                    showNotifiedAlert = true
                }
            }
            .alert("Customer Notified", isPresented: $showNotifiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\(notifiedCustomerName) has been sent a verification code for pickup.")
            }
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
            case .pending:
                orderToPack = order
            case .waitingForCustomer:
                viewModel.markCollected(id: order.id)
            case .collected:
                break
            }
        }
    }
}
