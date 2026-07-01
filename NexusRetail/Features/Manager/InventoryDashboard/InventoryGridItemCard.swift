//
//  InventoryGridItemCard.swift
//  NexusRetail
//

import SwiftUI

struct InventoryGridItemCard: View {
    let item: InventoryItemRow
    let onRestock: () -> Void
    
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
                                    .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                                    .font(.system(size: 40))
                            }
                        }
                    )
                    .clipShape(TopCorners(radius: 12))
                
                // Restock icon instead of heart
                if item.isLowStock {
                    Button(action: onRestock) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
            
            // Info Section
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 40, alignment: .topLeading) // Fixed height to prevent jagged grid
                
                HStack(alignment: .center) {
                    Text("Stock: \(item.onHand)")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                    
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
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
