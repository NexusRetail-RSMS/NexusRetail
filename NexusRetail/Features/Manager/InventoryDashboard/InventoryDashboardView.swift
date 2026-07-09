//
//  InventoryDashboardView.swift
//  NexusRetail
//
//  Manager Inventory screen: search/filter/sort,
//  rich inventory list.
//

import SwiftUI

struct InventoryDashboardView: View {
    @Environment(AppTheme.self) private var theme
    @State private var viewModel = InventoryViewModel()
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Pinned top area: header + search + chips ──
            // Completely outside the ScrollView so chips NEVER
            // overlap grid items and can never leak taps.
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, RSMSSpacing.sm)
                    .padding(.bottom, RSMSSpacing.md)
                searchBar
                    .padding(.bottom, RSMSSpacing.md)
                filterSection
                    .padding(.bottom, RSMSSpacing.sm)
            }
            .fadingMaterialHeader()
            
            // ── Scrollable content: grid only ──
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    Spacer()
                    ProgressView("Loading inventory…")
                        .font(RSMSFonts.body)
                        .foregroundColor(theme.secondaryText)
                    Spacer()
                } else {
                    ScrollView {
                        inventoryList
                            .padding(.top, RSMSSpacing.md)
                            .padding(.bottom, RSMSSpacing.xxxl)
                    }
                    .refreshable {
                        await viewModel.load(storeID: sessionStore.currentUser?.storeID)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
        }
        .ignoresSafeArea(edges: .top)
        .background(theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load(storeID: sessionStore.currentUser?.storeID)
        }
        .sheet(isPresented: $viewModel.showRestockSheet) {
            if let item = viewModel.restockItem {
                RequestStockSheet(item: item, storeID: sessionStore.currentUser?.storeID) { itemId, qty in
                    guard let storeID = sessionStore.currentUser?.storeID else {
                        return "No store is associated with your account."
                    }
                    return await viewModel.requestRestock(itemId: itemId, quantity: qty, storeID: storeID)
                }
                .presentationDetents([.height(590)])
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Inventory")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Spacer()
            
            HStack(spacing: 0) {
                Menu {
                    ForEach(InventorySortOrder.allCases, id: \.self) { order in
                        Button {
                            viewModel.sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if viewModel.sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                        .frame(width: 44, height: 44)
                }
                
                NavigationLink(destination: ManagerPendingRequestsView(viewModel: viewModel)) {
                    Image(systemName: "shippingbox.and.arrow.backward")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Stock Requests")
            }
            .background(theme.burgundy.opacity(0.08))
            .clipShape(Capsule())
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 50) // safe area top
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        NexusSearchBar(text: $viewModel.searchText, placeholder: "Search by name or SKU…")
            .padding(.horizontal, RSMSSpacing.lg)
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(label: "All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                
                ForEach(InventoryCategory.allCases, id: \.self) { cat in
                    CategoryChip(label: cat.rawValue, isSelected: viewModel.selectedCategory == cat) {
                        viewModel.selectedCategory = viewModel.selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
        }
    }
    
    // MARK: - Inventory List
    
    private var inventoryList: some View {
        Group {
            if viewModel.filteredItems.isEmpty {
                if let errorMessage = viewModel.errorMessage {
                    emptyState(
                        icon: "exclamationmark.triangle",
                        title: "Couldn't load inventory",
                        message: errorMessage
                    )
                    .padding(.top, 40)
                } else {
                    emptyState(
                        icon: "shippingbox",
                        title: "No items found",
                        message: viewModel.searchText.isEmpty ? "No inventory items match the current filter." : "No results for \"\(viewModel.searchText)\"."
                    )
                    .padding(.top, 40)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.filteredItems) { item in
                        Button {
                            viewModel.restockItem = item
                            viewModel.showRestockSheet = true
                        } label: {
                            InventoryGridItemCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, RSMSSpacing.lg)
            }
        }
    }
    
    // MARK: - Empty State
    
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryText.opacity(0.4))
            Text(title)
                .font(RSMSFonts.headline)
                .foregroundColor(theme.primaryText)
            Text(message)
                .font(RSMSFonts.caption)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    @Environment(AppTheme.self) private var theme
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : theme.primaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? theme.burgundy : theme.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : theme.inputBorder, lineWidth: 1)
            )
            .contentShape(Capsule())
            .highPriorityGesture(
                TapGesture().onEnded { action() }
            )
    }
}

// MARK: - Transfer Request Card

struct ManagerTransferRequestCard: View {
    @Environment(AppTheme.self) private var theme
    let request: TransferRequestRow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product info + status + units row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.productName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                    
                    Text(request.skuCode)
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    
                    // Units
                    Label("\(request.quantity) units", systemImage: "cube.box")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                    
                    
                    Text(request.formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                }
            }
            
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}

#Preview {
    NavigationStack {
        InventoryDashboardView()
            .environment(SessionStore())
    }
}
