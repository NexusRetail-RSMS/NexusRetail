//
//  ManagerPendingRequestsView.swift
//  NexusRetail
//

import SwiftUI

enum RequestFilterTab: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case approved = "Approved"
}

struct ManagerPendingRequestsView: View {
    @Bindable var viewModel: InventoryViewModel
    @Environment(SessionStore.self) private var sessionStore
    @State private var selectedTab: RequestFilterTab = .all
    
    var filteredRequests: [TransferRequestRow] {
        switch selectedTab {
        case .all:
            return viewModel.requests
        case .pending:
            return viewModel.requests.filter { $0.status == .pending }
        case .approved:
            return viewModel.requests.filter { $0.status == .approved }
        }
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.requests.isEmpty {
                ProgressView("Loading requests…")
            } else {
                ScrollView {
                    VStack(spacing: RSMSSpacing.md) {
                        // Segmented Control Filter
                        Picker("Filter", selection: $selectedTab) {
                            ForEach(RequestFilterTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 4)
                        
                        if filteredRequests.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 48))
                                    .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                                Text("No requests")
                                    .font(RSMSFonts.headline)
                                    .foregroundColor(RSMSColors.primaryText)
                                Text("You haven't submitted any stock transfer requests matching this filter.")
                                    .font(RSMSFonts.caption)
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: RSMSSpacing.md) {
                                ForEach(filteredRequests) { request in
                                    ManagerTransferRequestCard(request: request)
                                }
                            }
                            .padding(.horizontal, RSMSSpacing.lg)
                        }
                    }
                    .padding(.bottom, RSMSSpacing.xxxl)
                }
                .refreshable {
                    await viewModel.load(storeID: sessionStore.currentUser?.storeID)
                }
            }
        }
        .navigationTitle("Stock Requests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showRestockSheet = true
                    viewModel.restockItem = viewModel.items.first
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundColor(RSMSColors.burgundy)
                }
                .accessibilityLabel("New Stock Request")
            }
        }
    }
}
