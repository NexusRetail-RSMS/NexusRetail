import SwiftUI

struct RepairCardView: View {
    @Environment(AppTheme.self) private var theme
    let customerName: String
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
                        .foregroundColor(theme.primaryText)
                }
                
                Spacer()
            }
            
            Divider()
                .background(theme.divider)
            
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
                        .overlay(Image(systemName: "photo").foregroundColor(theme.secondaryText))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(itemName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                    
                    Text("SKU: \(itemSKU)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            // Bottom Section: Pickup Date
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(theme.burgundy)
                        .font(.system(size: 20))
                    
                    Text("ESTIMATED PICKUP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.burgundy)
                }
                
                Spacer()
                
                Text(formatDate(pickupDate))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.primaryText)
            }
            .padding(14)
            .background(theme.burgundy.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(16)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(customerName), \(itemName), SKU \(itemSKU). Estimated pickup: \(formatDate(pickupDate))")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
