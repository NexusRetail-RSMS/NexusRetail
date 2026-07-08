//
//  InventoryGridItemCard.swift
//  NexusRetail
//

import SwiftUI

struct InventoryGridItemCard: View {
    @Environment(AppTheme.self) private var theme
    let item: InventoryItemRow
    
    @State private var showQR: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image and Restock Icon
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        CachedAsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Color.gray.opacity(0.05)
                                Image(systemName: "shippingbox")
                                    .foregroundColor(theme.secondaryText.opacity(0.4))
                                    .font(.system(size: 40))
                            }
                        }
                    )
                    .clipShape(TopCorners(radius: 12))
                
            }
            
            // Info Section
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 40, alignment: .topLeading) // Fixed height to prevent jagged grid
                
                HStack(alignment: .center) {
                    Text("Stock: \(item.onHand)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
                    
                    Spacer()
                    
                    Text(item.stockStatus.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(item.stockStatus.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(item.stockStatus.color.opacity(0.12))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        .contextMenu {
            Button(action: { showQR = true }) {
                Label("Show QR Code", systemImage: "qrcode")
            }
        }
        .sheet(isPresented: $showQR) {
            InventoryQRCodeSheet(item: item)
        }
    }
}

struct InventoryQRCodeSheet: View {
    @Environment(AppTheme.self) private var theme
    let item: InventoryItemRow
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Scan to Add to Cart")
                    .font(.title2.bold())
                    .padding(.top)
                
                Image(uiImage: generateQRCode(from: "nexus://product/\(item.skuCode)"))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                
                VStack(spacing: 8) {
                    Text(item.name)
                        .font(.headline)
                    Text("SKU: \(item.skuCode)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

// Custom shape to round only the top corners
struct TopCorners: Shape {
    var radius: CGFloat = 12
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}
