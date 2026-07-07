import SwiftUI

struct AfterSalesActionSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItem: POSProduct
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    productHeroSection
                    actionGridSection
                }
                .padding(.bottom, 60)
            }
            .ignoresSafeArea(edges: .top)
            
            customHeaderSection
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Product Hero
    private var productHeroSection: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let width = geo.size.width
                CachedAsyncImage(url: URL(string: selectedItem.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: width * 1.1)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: width, height: width * 1.1)
                        .overlay(ProgressView())
                }
            }
            .frame(height: UIScreen.main.bounds.width * 1.1)
            
            // Product info
            VStack(alignment: .center, spacing: 8) {
                Text(selectedItem.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(String(format: "₹%.0f", selectedItem.price))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
                
                Text("\(selectedItem.category) • Size: \(selectedItem.size)")
                    .font(.system(size: 14))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.8))
            }
            .padding(.top, 32)
            .padding(.horizontal, RSMSSpacing.lg)
        }
    }
    
    // MARK: - Action Grid
    private var actionGridSection: some View {
        HStack(spacing: 16) {
            actionTile(
                title: "Exchange",
                icon: "arrow.triangle.2.circlepath",
                color: RSMSColors.burgundy
            ) {
                print("Exchange initiated for invoice \(invoiceId), item: \(selectedItem.id)")
                // Future navigation to exchange flow
            }
            
            actionTile(
                title: "Repair",
                icon: "wrench.and.screwdriver.fill",
                color: Color(hex: "34495E")
            ) {
                path.append(POSFlowDestination.repairForm(invoiceId: invoiceId, selectedItem: selectedItem))
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 40)
    }
    
    private func actionTile(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.06))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
