//
//  InventoryDashboardView.swift
//  NexusRetail
//
//  Manager Inventory screen: search/filter/sort,
//  rich inventory list.
//

import SwiftUI

struct InventoryDashboardView: View {
    @State private var viewModel = InventoryViewModel()
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ZStack {
                    RSMSColors.background.ignoresSafeArea()
                    ProgressView("Loading inventory…")
                        .font(RSMSFonts.body)
                        .foregroundColor(RSMSColors.secondaryText)
                }
            } else {
                ScrollView {
                    VStack(spacing: RSMSSpacing.lg) {
                        // MARK: - Filter/Category Chips
                        filterSection
                        
                        // MARK: - Content
                        inventoryList
                    }
                    .padding(.bottom, RSMSSpacing.xxxl)
                }
                .safeAreaInset(edge: .top) {
                    VStack(spacing: RSMSSpacing.lg) {
                        headerSection
                            .padding(.top, RSMSSpacing.sm)
                        searchBar
                    }
                    .padding(.bottom, RSMSSpacing.sm)
                    .background(.ultraThinMaterial)
                }
                .background(RSMSColors.background.ignoresSafeArea())
                .refreshable {
                    await viewModel.load(storeID: sessionStore.currentUser?.storeID)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load(storeID: sessionStore.currentUser?.storeID)
        }
        .sheet(isPresented: $viewModel.showRestockSheet) {
            if let item = viewModel.restockItem {
                RequestStockSheet(item: item, storeID: sessionStore.currentUser?.storeID) { itemId, qty in
                    if let storeID = sessionStore.currentUser?.storeID {
                        Task {
                            _ = await viewModel.requestRestock(itemId: itemId, quantity: qty, storeID: storeID)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Inventory")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            NavigationLink(destination: ManagerPendingRequestsView(viewModel: viewModel)) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
                    
                    Image(systemName: "tray.full.fill")
                        .font(.title3)
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            .accessibilityLabel("Stock Requests")
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(RSMSColors.secondaryText)
                TextField("Search by name or SKU…", text: $viewModel.searchText)
                    .font(.system(size: 15))
                    .foregroundColor(RSMSColors.primaryText)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(RSMSRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.medium)
                    .stroke(RSMSColors.inputBorder, lineWidth: 1)
            )
            
            // Filter Menu (Sort + Low Stock Filter)
            Menu {
                Section(header: Text("Filter")) {
                    Button {
                        viewModel.selectedFilter = .allItems
                    } label: {
                        HStack {
                            Text("All Items")
                            if viewModel.selectedFilter == .allItems { Image(systemName: "checkmark") }
                        }
                    }
                    
                    Button {
                        viewModel.selectedFilter = .lowStock
                    } label: {
                        HStack {
                            Text("Low Stock")
                            if viewModel.selectedFilter == .lowStock { Image(systemName: "checkmark") }
                        }
                    }
                }
                
                Section(header: Text("Sort By")) {
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
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(RSMSColors.burgundy)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .cornerRadius(RSMSRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSRadius.medium)
                            .stroke(RSMSColors.inputBorder, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        // Category chips
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(label: "All", isSelected: viewModel.selectedCategory == nil) {
                    withAnimation { viewModel.selectedCategory = nil }
                }
                
                ForEach(InventoryCategory.allCases, id: \.self) { cat in
                    CategoryChip(label: cat.rawValue, isSelected: viewModel.selectedCategory == cat) {
                        withAnimation {
                            viewModel.selectedCategory = viewModel.selectedCategory == cat ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
        }
    }
    
    // MARK: - Inventory List
    
    private var inventoryList: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            if viewModel.filteredItems.isEmpty {
                emptyState(
                    icon: "shippingbox",
                    title: "No items found",
                    message: viewModel.searchText.isEmpty ? "No inventory items match the current filter." : "No results for \"\(viewModel.searchText)\"."
                )
            } else {
                ForEach(viewModel.filteredItems) { item in
                    NavigationLink(destination: ProductDetailView(item: item, viewModel: viewModel, storeID: sessionStore.currentUser?.storeID)) {
                        InventoryGridItemCard(item: item) {
                            viewModel.triggerRestock(for: item)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    // MARK: - Empty State
    
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
            Text(title)
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.primaryText)
            Text(message)
                .font(RSMSFonts.caption)
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : RSMSColors.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? RSMSColors.burgundy : Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : RSMSColors.inputBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// Removed InventoryGridItemCard as it was extracted to a separate file

// MARK: - Transfer Request Card

struct ManagerTransferRequestCard: View {
    let request: TransferRequestRow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product info row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.productName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text(request.skuCode)
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                
                Spacer()
                
                // Status pill
                Text(request.status.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(request.status.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(request.status.color.opacity(0.12))
                    .cornerRadius(10)
            }
            
            // Status pipeline
            HStack(spacing: 4) {
                ForEach(0..<5) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= request.status.step ? request.status.color : Color.gray.opacity(0.15))
                        .frame(height: 4)
                }
            }
            
            // Details row
            HStack {
                Label("\(request.quantity) units", systemImage: "cube.box")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
                
                Spacer()
                
                Text(request.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(14)
        .background(Color.white)
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
