//
//  BOPISView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var viewModel = BOPISViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: BOPISOrderStatus? = nil
    @State private var orderToPack: BOPISOrder?
    @State private var showNotifiedAlert = false
    @State private var notifiedCustomerName = ""
    
    var hideHeader: Bool = false
    
    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Area
                HStack(spacing: RSMSSpacing.md) {
                    SearchBarView(text: $viewModel.searchText, placeholder: "Search by order ID, customer or phone")
                    
                    Menu {
                        Button {
                            viewModel.selectedFilter = nil
                        } label: {
                            if viewModel.selectedFilter == nil {
                                Label("All", systemImage: "checkmark")
                            } else {
                                Text("All")
                            }
                        }
                        
                        ForEach([BOPISOrderStatus.pending, BOPISOrderStatus.waitingForCustomer], id: \.self) { status in
                            Button {
                                viewModel.selectedFilter = status
                            } label: {
                                if viewModel.selectedFilter == status {
                                    Label(status.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(status.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease")
                            Text("Filter")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(RSMSColors.burgundy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(RSMSColors.burgundy.opacity(0.05)))
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.md)
                .padding(.bottom, RSMSSpacing.lg)
                
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
        .task {
            await viewModel.loadData(storeID: sessionStore.currentUser?.storeID)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: RSMSSpacing.xl) {
            Spacer()
            
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.05))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bag.fill")
                    .font(.system(size: 60))
                    .foregroundColor(RSMSColors.burgundy.opacity(0.4))
                    .offset(x: -8, y: -8)
                
                ZStack {
                    Circle().fill(Color.white).frame(width: 36, height: 36)
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(RSMSColors.burgundy.opacity(0.6))
                }
                .offset(x: 4, y: 4)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("No pickup orders available")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text("We couldn't find any orders matching\nyour search or filter.")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                viewModel.searchText = ""
                viewModel.selectedFilter = nil
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Clear Filters")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(RSMSColors.burgundy)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule().stroke(RSMSColors.burgundy.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.top, RSMSSpacing.lg)
            
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
