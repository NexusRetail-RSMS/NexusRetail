import SwiftUI

struct NewSaleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom Curved Header
                    customHeaderSection
                    
                    VStack(alignment: .leading, spacing: 28) {
                        Text("How would you like to add products?")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSColors.darkBrown)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 16) {
                            // Search Product Link
                            NavigationLink(destination: ProductSearchView()) {
                                actionRow(
                                    title: "Search Product",
                                    subtitle: "Search by name, SKU, or category",
                                    icon: "magnifyingglass",
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Scan Barcode Link
                            NavigationLink(destination: BarcodeScannerView()) {
                                actionRow(
                                    title: "Scan Barcode",
                                    subtitle: "Scan barcode instantly using camera",
                                    icon: "barcode.viewfinder",
                                    color: .orange
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Recent Products
                            NavigationLink(destination: ProductSearchView(initialSearch: "")) {
                                actionRow(
                                    title: "Recent Products",
                                    subtitle: "Frequently sold items in your store",
                                    icon: "clock.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Favorites
                            NavigationLink(destination: ProductSearchView(initialSearch: "")) {
                                actionRow(
                                    title: "Favorites",
                                    subtitle: "Frequently purchased by regular clients",
                                    icon: "star.fill",
                                    color: .yellow
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.resetFlow()
        }
    }
    
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Back")
            
            VStack(alignment: .leading, spacing: 2) {
                Text("New Sale")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Point of Sale Checkout")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }
    
    private func actionRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
