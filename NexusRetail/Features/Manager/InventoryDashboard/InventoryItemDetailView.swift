//
//  InventoryItemDetailView.swift
//  NexusRetail
//

import SwiftUI

struct InventoryItemDetailView: View {
    let item: InventoryItem
    var viewModel: InventoryDashboardViewModel
    
    @State private var showRequestSheet = false
    @Environment(\.dismiss) private var dismiss
    
    // To ensure the view stays updated if the item changes in the view model
    private var currentItem: InventoryItem? {
        viewModel.inventoryItems.first { $0.id == item.id }
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            if let displayItem = currentItem {
                ScrollView {
                    VStack(spacing: RSMSSpacing.xl) {
                        // Product Header
                        VStack(spacing: RSMSSpacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "shippingbox.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                            
                            VStack(spacing: 4) {
                                Text(displayItem.name)
                                    .font(RSMSFonts.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(RSMSColors.primaryText)
                                    .multilineTextAlignment(.center)
                                
                                Text(displayItem.category)
                                    .font(RSMSFonts.subheadline)
                                    .foregroundColor(RSMSColors.secondaryText)
                                
                                InventoryStatusBadge(status: displayItem.status)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, RSMSSpacing.lg)
                        
                        // Details Card
                        VStack(spacing: 0) {
                            InventoryDetailRow(title: "SKU", value: displayItem.sku)
                            Divider().padding(.horizontal, RSMSSpacing.md)
                            InventoryDetailRow(title: "Price", value: String(format: "$%.2f", displayItem.price))
                            Divider().padding(.horizontal, RSMSSpacing.md)
                            InventoryDetailRow(title: "Current Stock", value: "\(displayItem.currentStock)", valueColor: displayItem.status == .healthy ? RSMSColors.primaryText : (displayItem.status == .lowStock ? RSMSColors.warning : RSMSColors.error))
                            Divider().padding(.horizontal, RSMSSpacing.md)
                            InventoryDetailRow(title: "Minimum Required", value: "\(displayItem.minimumRequired)")
                        }
                        .background(Color.white)
                        .cornerRadius(RSMSRadius.medium)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        .padding(.horizontal, RSMSSpacing.md)
                        
                        Spacer(minLength: 100) // Space for bottom button
                    }
                }
                
                // Bottom Button
                if displayItem.isLowStock {
                    VStack {
                        Spacer()
                        
                        Button {
                            showRequestSheet = true
                        } label: {
                            Text("Request Item")
                                .font(RSMSFonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RSMSColors.burgundy)
                                .cornerRadius(RSMSRadius.medium)
                        }
                        .padding(RSMSSpacing.md)
                        .background(
                            Color.white
                                .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
                                .ignoresSafeArea(edges: .bottom)
                        )
                    }
                    .ignoresSafeArea(.keyboard)
                }
            } else {
                Text("Item not found")
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRequestSheet) {
            if let displayItem = currentItem {
                RequestStockSheet(lowStockItems: [displayItem]) { requestedItems in
                    viewModel.requestStock(for: requestedItems)
                    dismiss() // Automatically dismiss the detail view back to dashboard after request
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct InventoryDetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = RSMSColors.primaryText
    
    var body: some View {
        HStack {
            Text(title)
                .font(RSMSFonts.body)
                .foregroundColor(RSMSColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(RSMSFonts.headline)
                .foregroundColor(valueColor)
        }
        .padding(RSMSSpacing.md)
    }
}
