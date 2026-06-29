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
                    
                    // Low Stock Alert Banner
                    if !viewModel.lowStockItems.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(RSMSColors.warning)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Low Stock Alert")
                                    .font(RSMSFonts.headline)
                                    .foregroundColor(RSMSColors.primaryText)
                                Text("\(viewModel.lowStockItems.count) items are below minimum required stock.")
                                    .font(RSMSFonts.caption)
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(RSMSRadius.medium)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                        .padding(.horizontal, RSMSSpacing.md)
                    }
                    
                    // Inventory List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Inventory")
                            .font(RSMSFonts.headline)
                            .foregroundColor(RSMSColors.primaryText)
                            .padding(.horizontal, RSMSSpacing.md)
                            .padding(.top, RSMSSpacing.sm)
                        
                        ForEach(viewModel.inventoryItems) { item in
                            InventoryItemRow(item: item)
                                .padding(.horizontal, RSMSSpacing.md)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, RSMSSpacing.md)
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

struct InventoryItemRow: View {
    let item: InventoryItem
    
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
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.currentStock)")
                    .font(RSMSFonts.headline)
                    .fontWeight(.bold)
                    .foregroundColor(item.isLowStock ? RSMSColors.error : RSMSColors.primaryText)
                
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
                .stroke(item.isLowStock ? RSMSColors.error.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        InventoryDashboardView()
    }
}
