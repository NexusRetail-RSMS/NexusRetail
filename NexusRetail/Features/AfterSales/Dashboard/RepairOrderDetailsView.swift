import SwiftUI

struct RepairOrderDetailsView: View {
    @Environment(AppTheme.self) private var theme
    let repair: ActiveRepairsView.RepairOrderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                // Product Info Card
                HStack(alignment: .center, spacing: 16) {
                    if let imageURL = repair.itemImageURL, let url = URL(string: imageURL) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } placeholder: {
                            placeholderImage
                        }
                    } else {
                        placeholderImage
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(repair.itemName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Divider()
                        
                        Text("SKU: \(repair.itemSKU)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(theme.cardBackground)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 16)
                
                // Details Cards
                VStack(spacing: 16) {
                    // Customer & Order Info Card
                    VStack(spacing: 16) {
                        detailRow(title: "Customer Name", value: repair.customerName)
                        
                        Divider()
                        
                        detailRow(title: "Order ID", value: repair.id.uuidString)
                    }
                    .padding(16)
                    .background(theme.cardBackground)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 12)
                    
                    // Dates Card
                    VStack(spacing: 16) {
                        detailRow(title: "Request Generated", value: formatDate(repair.createdAt))
                        
                        Divider()
                        
                        detailRow(title: "Estimated Pickup", value: formatDate(repair.pickupDate))
                    }
                    .padding(16)
                    .background(theme.cardBackground)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 12)
                    
                    // Problem Description Card
                    if let problemDesc = repair.problemDescription, !problemDesc.isEmpty {
                        detailRow(title: "Problem Description", value: problemDesc)
                            .padding(16)
                            .background(theme.cardBackground)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 12)
                    }
                }
                
                    Spacer()
                }
            }
        }
    }
    .navigationBarHidden(true)
}
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.burgundy)
                }
            }
            .accessibilityLabel("Back")
            
            Spacer()
            
            Text("Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Spacer()
            
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .frame(width: 110, height: 110)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 32))
                    .foregroundColor(theme.secondaryText)
            )
    }
    
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.secondaryText)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
}
