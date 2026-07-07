import SwiftUI

struct RepairCardView: View {
    let customerName: String
    let customerTier: String
    let customerImageURL: String?
    let itemImageURL: String?
    let itemName: String
    let itemSKU: String
    let pickupDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Section: Customer Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(customerName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text(customerTier)
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                
                Spacer()
                
                if let customerImageURL = customerImageURL, let url = URL(string: customerImageURL) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.fill")
                            .foregroundColor(RSMSColors.burgundy)
                    }
                }
            }
            
            Divider()
                .background(RSMSColors.divider)
            
            // Middle Section: Item Info
            HStack(spacing: 16) {
                if let itemImageURL = itemImageURL, let url = URL(string: itemImageURL) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(Image(systemName: "photo").foregroundColor(RSMSColors.secondaryText))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(itemName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text("SKU: \(itemSKU)")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }
            
            // Bottom Section: Pickup Date
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(RSMSColors.burgundy)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ESTIMATED PICKUP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(RSMSColors.burgundy)
                        
                        Text(formatDate(pickupDate))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(RSMSColors.burgundy.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
