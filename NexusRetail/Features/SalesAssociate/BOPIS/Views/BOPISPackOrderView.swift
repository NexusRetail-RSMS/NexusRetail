//
//  BOPISPackOrderView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISPackOrderView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) var dismiss
    let order: BOPISOrder
    let onMarkAsPacked: () -> Void

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RSMSSpacing.lg) {
                        // Header info
                        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                            Text("Order \(order.orderId)")
                                .font(RSMSFonts.title)
                                .foregroundColor(theme.primaryText)
                            Text("Customer: \(order.customerName)")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.lg)
                        
                        // Item List
                        VStack(spacing: RSMSSpacing.md) {
                            ForEach(order.items) { item in
                                PackItemRow(item: item)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        
                        // Padding for sticky bottom button
                        Spacer().frame(height: 100)
                    }
                }
                
                // Sticky Action Button
                VStack {
                    Divider()
                        .background(theme.divider)
                    Button(action: {
                        onMarkAsPacked()
                        dismiss()
                    }) {
                        Text("Mark as Packed")
                            .font(RSMSFonts.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, RSMSSpacing.md)
                            .background(theme.burgundy)
                            .cornerRadius(RSMSRadius.medium)
                    }
                    .padding(RSMSSpacing.lg)
                    .background(theme.cardBackground)
                }
            }
            .navigationTitle("Pack Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(theme.burgundy)
                }
            }
        }
    }
}

private struct PackItemRow: View {
    @Environment(AppTheme.self) private var theme
    let item: BOPISOrderItem

    var body: some View {
        HStack(spacing: RSMSSpacing.md) {
            if let urlStr = item.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.small))
                    case .failure:
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(RSMSFonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text("SKU: \(item.sku)")
                    .font(RSMSFonts.caption)
                    .foregroundColor(theme.secondaryText)
                
                Text("Qty: \(item.quantity)")
                    .font(RSMSFonts.caption)
                    .foregroundColor(theme.primaryText)
            }
            
            Spacer()
        }
        .padding(RSMSSpacing.md)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    @ViewBuilder
    private var fallbackImage: some View {
        RoundedRectangle(cornerRadius: RSMSRadius.small)
            .fill(theme.cream)
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "bag.fill")
                    .foregroundColor(theme.burgundy.opacity(0.3))
            )
    }
}
