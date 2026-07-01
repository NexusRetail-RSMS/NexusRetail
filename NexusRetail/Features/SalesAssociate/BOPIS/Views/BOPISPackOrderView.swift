//
//  BOPISPackOrderView.swift
//  NexusRetail
//

import SwiftUI

struct BOPISPackOrderView: View {
    @Environment(\.dismiss) var dismiss
    let order: BOPISOrder
    let onMarkAsPacked: () -> Void
    
    @State private var selectedQRCode: String?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                RSMSColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RSMSSpacing.lg) {
                        // Header info
                        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                            Text("Order \(order.orderId)")
                                .font(RSMSFonts.title)
                                .foregroundColor(RSMSColors.primaryText)
                            Text("Customer: \(order.customerName)")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.lg)
                        
                        // Item List
                        VStack(spacing: RSMSSpacing.md) {
                            ForEach(order.items) { item in
                                PackItemRow(item: item) {
                                    selectedQRCode = item.qrCode
                                }
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
                        .background(RSMSColors.divider)
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
                            .background(RSMSColors.burgundy)
                            .cornerRadius(RSMSRadius.medium)
                    }
                    .padding(RSMSSpacing.lg)
                    .background(Color.white)
                }
            }
            .navigationTitle("Pack Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            .sheet(item: Binding(
                get: { selectedQRCode.map { QRCodeWrapper(qrCode: $0) } },
                set: { selectedQRCode = $0?.qrCode }
            )) { wrapper in
                NavigationStack {
                    VStack(spacing: 24) {
                        QRCodeView(qrCodeString: wrapper.qrCode)
                            .frame(width: 250, height: 250)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(radius: 4)
                        
                        Text("Scan to update inventory")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .navigationTitle("Product QR")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                selectedQRCode = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}

// Wrapper for Sheet
private struct QRCodeWrapper: Identifiable {
    var id: String { qrCode }
    let qrCode: String
}

private struct PackItemRow: View {
    let item: BOPISOrderItem
    let onShowQR: () -> Void
    
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
                    .foregroundColor(RSMSColors.primaryText)
                
                Text("SKU: \(item.sku)")
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
                
                Text("Qty: \(item.quantity)")
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.primaryText)
            }
            
            Spacer()
            
            Button(action: onShowQR) {
                VStack(spacing: 4) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 20))
                    Text("QR")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(RSMSColors.burgundy)
                .padding(8)
                .background(RSMSColors.burgundy.opacity(0.1))
                .cornerRadius(RSMSRadius.small)
            }
        }
        .padding(RSMSSpacing.md)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    @ViewBuilder
    private var fallbackImage: some View {
        RoundedRectangle(cornerRadius: RSMSRadius.small)
            .fill(RSMSColors.cream)
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "bag.fill")
                    .foregroundColor(RSMSColors.burgundy.opacity(0.3))
            )
    }
}
