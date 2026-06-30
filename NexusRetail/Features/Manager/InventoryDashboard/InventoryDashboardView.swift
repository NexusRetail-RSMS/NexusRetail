//
//  InventoryDashboardView.swift
//  NexusRetail
//

import SwiftUI

struct InventoryDashboardView: View {
    @State private var viewModel = InventoryDashboardViewModel()
    @State private var showRequestSheet = false
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: RSMSSpacing.lg) {
                        // Header Section
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Inventory Dashboard")
                                    .font(RSMSFonts.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(RSMSColors.primaryText)
                                
                                Text("Manage stock and request refills")
                                    .font(RSMSFonts.subheadline)
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, RSMSSpacing.md)
                        
                        // Search & Filter
                        VStack(spacing: RSMSSpacing.md) {
                            SearchBarView(text: $viewModel.searchText)
                                .padding(.horizontal, RSMSSpacing.lg)
                            
                            InventoryFilterBar(selectedFilter: $viewModel.selectedFilter)
                        }
                        .padding(.vertical, RSMSSpacing.sm)
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        
                        // Low Stock Alert Banner
                        if !viewModel.lowStockItems.isEmpty {
                            Button {
                                withAnimation {
                                    if let firstId = viewModel.lowStockItems.first?.id {
                                        proxy.scrollTo(firstId, anchor: .top)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(RSMSColors.warning)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Low Stock Alert")
                                            .font(RSMSFonts.headline)
                                            .foregroundColor(RSMSColors.primaryText)
                                        Text("\(viewModel.lowStockItems.count) Products Require Reordering")
                                            .font(RSMSFonts.caption)
                                            .foregroundColor(RSMSColors.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(RSMSColors.secondaryText)
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(RSMSRadius.medium)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, RSMSSpacing.md)
                        }
                        
                        // Inventory List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Inventory")
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                                .padding(.horizontal, RSMSSpacing.md)
                                .padding(.top, RSMSSpacing.sm)
                            
                            ForEach(viewModel.filteredItems) { item in
                                InventoryItemRow(item: item)
                                    .padding(.horizontal, RSMSSpacing.md)
                                    .id(item.id)
                            }
                            
                            if viewModel.filteredItems.isEmpty {
                                Text("No items found.")
                                    .font(RSMSFonts.body)
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 40)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, RSMSSpacing.md)
                }
            }
            
            // Success Toast Overlay
            if viewModel.showSuccessToast {
                VStack {
                    Spacer()
                    RequestSuccessBanner()
                        .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: viewModel.showSuccessToast)
                .zIndex(1)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showRequestSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(RSMSColors.burgundy)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Request Stock")
            }
        }
        .sheet(isPresented: $showRequestSheet) {
            RequestStockSheet(lowStockItems: viewModel.lowStockItems) { requestedItems in
                viewModel.requestStock(for: requestedItems)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Filter Bar
struct InventoryFilterBar: View {
    @Binding var selectedFilter: InventoryStatus?
    
    private let filters: [InventoryStatus?] = [nil, .healthy, .lowStock, .critical]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RSMSSpacing.sm) {
                ForEach(0..<filters.count, id: \.self) { index in
                    let filter = filters[index]
                    let title = filter?.rawValue ?? "All"
                    
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(title)
                            .font(RSMSFonts.subheadline)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .padding(.horizontal, RSMSSpacing.md)
                            .padding(.vertical, RSMSSpacing.sm)
                            .background(selectedFilter == filter ? RSMSColors.burgundy : Color.white)
                            .foregroundColor(selectedFilter == filter ? .white : RSMSColors.primaryText)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedFilter == filter ? Color.clear : RSMSColors.inputBorder, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
        }
    }
}

// MARK: - Status Badge
struct InventoryStatusBadge: View {
    let status: InventoryStatus
    
    private var badgeColor: Color {
        switch status {
        case .healthy: return RSMSColors.success
        case .lowStock: return RSMSColors.warning
        case .critical: return RSMSColors.error
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(RSMSFonts.caption)
            .fontWeight(.semibold)
            .foregroundColor(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.1))
            .cornerRadius(4)
    }
}

// MARK: - Row
struct InventoryItemRow: View {
    let item: InventoryItem
    
    private var borderColor: Color {
        switch item.status {
        case .healthy: return Color.clear
        case .lowStock: return RSMSColors.warning.opacity(0.5)
        case .critical: return RSMSColors.error.opacity(0.5)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder Image
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "shippingbox")
                    .foregroundColor(RSMSColors.secondaryText)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)
                
                Text("SKU: \(item.sku) • \(item.category)")
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
                
                InventoryStatusBadge(status: item.status)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.currentStock)")
                    .font(RSMSFonts.headline)
                    .fontWeight(.bold)
                    .foregroundColor(item.status == .healthy ? RSMSColors.primaryText : (item.status == .lowStock ? RSMSColors.warning : RSMSColors.error))
                
                Text("Min: \(item.minimumRequired)")
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Success Banner
struct RequestSuccessBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(RSMSColors.success)
            Text("Stock request submitted successfully.")
                .font(RSMSFonts.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .cornerRadius(30)
        .shadow(radius: 4)
    }
}

#Preview {
    NavigationStack {
        InventoryDashboardView()
    }
}
