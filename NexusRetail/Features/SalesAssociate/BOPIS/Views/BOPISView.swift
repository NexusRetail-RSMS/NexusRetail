//
//  BOPISView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SessionStore.self) private var sessionStore
    @State private var viewModel = BOPISViewModel()
    @State private var orderToPack: BOPISOrder?
    @State private var orderToCollect: BOPISOrder?
    @State private var showNotifiedAlert = false
    @State private var notifiedMessage = ""

    var hideHeader: Bool = false
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Area
                VStack(spacing: RSMSSpacing.md) {
                    SearchBarView(text: $viewModel.searchText, placeholder: "Search by order ID, customer or phone")
                        .padding(.horizontal, RSMSSpacing.lg)
                    
                    FilterSegmentControl(selectedFilter: $viewModel.selectedFilter)
                }
                .padding(.top, RSMSSpacing.md)
                .padding(.bottom, RSMSSpacing.sm)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                
                // Main Content — always a ScrollView so pull-to-refresh works
                // even when the list is empty (e.g. waiting for a new online order).
                ScrollView {
                    if viewModel.filteredOrders.isEmpty {
                        emptyStateView
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 480)
                    } else {
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
                .refreshable {
                    await viewModel.loadData(storeID: sessionStore.currentUser?.storeID)
                }
            }
        }
        .navigationTitle("BOPIS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: BOPISHistoryView(viewModel: viewModel)) {
                    Image(systemName: "clock")
                        .foregroundColor(theme.burgundy)
                }
            }
        }
        .sheet(item: $orderToPack) { order in
            BOPISPackOrderView(order: order) {
                Task {
                    let outcome = await viewModel.packAndNotify(id: order.id, associateID: sessionStore.currentUser?.id)
                    switch outcome {
                    case .emailed:
                        notifiedMessage = "A pickup code has been emailed to \(order.customerName)."
                    case .noEmail:
                        notifiedMessage = "Order packed, but no email is on file for \(order.customerName). Ask them for their code another way."
                    case .sendFailed:
                        notifiedMessage = "Order packed, but the pickup email couldn't be sent right now. Please try resending or check the email setup."
                    }
                    showNotifiedAlert = true
                }
            }
        }
        .sheet(item: $orderToCollect) { order in
            CollectVerifyView(order: order) { code in
                await viewModel.verifyAndCollect(id: order.id, code: code)
            }
        }
        .alert("Ready for Pickup", isPresented: $showNotifiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(notifiedMessage)
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
                    .fill(theme.burgundy.opacity(0.05))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bag.fill")
                    .font(.system(size: 60))
                    .foregroundColor(theme.burgundy.opacity(0.4))
                    .offset(x: -8, y: -8)
                
                ZStack {
                    Circle().fill(Color.white).frame(width: 36, height: 36)
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(theme.burgundy.opacity(0.6))
                }
                .offset(x: 4, y: 4)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("No pickup orders available")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.primaryText)
                
                Text("We couldn't find any orders matching\nyour search or filter.")
                    .font(.system(size: 15))
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                viewModel.searchText = ""
                viewModel.selectedFilter = .pending
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Clear Filters")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(theme.burgundy)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule().stroke(theme.burgundy.opacity(0.5), lineWidth: 1)
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
                orderToCollect = order
            case .collected:
                break
            }
        }
    }
}
