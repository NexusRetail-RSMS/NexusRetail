//
//  InventoryDashboardView.swift
//  NexusRetail
//

import SwiftUI

struct InventoryDashboardView: View {
    @State private var viewModel = InventoryDashboardViewModel()
    
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
                        HStack(spacing: RSMSSpacing.md) {
                            // Native-like search bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                
                                TextField("Search", text: $viewModel.searchText)
                                    .font(.body)
                                    .submitLabel(.search)
                                
                                if !viewModel.searchText.isEmpty {
                                    Button(action: { viewModel.searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(Capsule())
                            
                            // Filter Menu
                            Menu {
                                Menu {

                                    Button {
                                        viewModel.sortOrder = .healthyFirst
                                    } label: {
                                        HStack {
                                            Text("Healthy First")
                                            if viewModel.sortOrder == .healthyFirst {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                    Button {
                                        viewModel.sortOrder = .criticalFirst
                                    } label: {
                                        HStack {
                                            Text("Critical First")
                                            if viewModel.sortOrder == .criticalFirst {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                } label: {
                                    Label("Stock Level", systemImage: "shippingbox.fill")
                                }
                                
                                Button(role: .destructive) {
                                    viewModel.sortOrder = .criticalFirst
                                    viewModel.searchText = ""
                                } label: {
                                    Label("Reset Filters", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.title2)
                                    .foregroundColor(RSMSColors.burgundy)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.md)
                        .padding(.vertical, RSMSSpacing.sm)
                        

                        
                        // Inventory List
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.filteredItems) { item in
                                NavigationLink(destination: InventoryItemDetailView(item: item, viewModel: viewModel)) {
                                    InventoryItemRow(item: item)
                                }
                                .buttonStyle(.plain)
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
