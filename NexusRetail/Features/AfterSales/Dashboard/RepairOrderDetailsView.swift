import SwiftUI

struct RepairOrderDetailsView: View {
    let repair: ActiveRepairsView.RepairOrderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                // Header Image & Item Details
                VStack(spacing: 16) {
                    if let imageURL = repair.itemImageURL, let url = URL(string: imageURL) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .accessibilityHidden(true)
                        } placeholder: {
                            placeholderImage
                        }
                    } else {
                        placeholderImage
                    }
                    
                    VStack(spacing: 4) {
                        Text(repair.itemName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)
                        
                        Text("SKU: \(repair.itemSKU)")
                            .font(.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }
                .padding(.top, 24)
                
                // Details Card
                VStack(spacing: 20) {
                    detailRow(title: "Customer Name", value: repair.customerName)
                    
                    Divider()
                    
                    detailRow(title: "Order ID", value: repair.id.uuidString)
                    
                    Divider()
                    
                    detailRow(title: "Request Generated", value: formatDate(repair.createdAt))
                    
                    Divider()
                    
                    detailRow(title: "Estimated Pickup", value: formatDate(repair.pickupDate))
                    
                    if let problemDesc = repair.problemDescription, !problemDesc.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Problem Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(RSMSColors.secondaryText)
                            
                            Text(problemDesc)
                                .font(.system(size: 16))
                                .foregroundColor(RSMSColors.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
                
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
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            .accessibilityLabel("Back")
            .accessibilityHint("Go back")
            
            Spacer()
            
            Text("Details")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)
                .accessibilityAddTraits(.isHeader)
            
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
            .frame(width: 120, height: 120)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(RSMSColors.secondaryText)
            )
            .accessibilityHidden(true)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSColors.secondaryText)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
}
