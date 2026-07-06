import SwiftUI

struct InvoiceItemsSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    let invoiceId: String
    
    // Mocked data for demonstration
    @State private var items: [POSProduct] = [
        POSProduct(id: UUID(), itemId: 1, name: "Signature Leather Tote", sku: "TOTE-001", category: "Bags", price: 14500, stock: 10, size: "One Size", imageUrl: "https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=500&auto=format&fit=crop&q=60"),
        POSProduct(id: UUID(), itemId: 2, name: "Classic Silk Scarf", sku: "SCRF-045", category: "Accessories", price: 4200, stock: 25, size: "M", imageUrl: "https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=500&auto=format&fit=crop&q=60"),
        POSProduct(id: UUID(), itemId: 3, name: "Aviator Sunglasses", sku: "SUN-892", category: "Eyewear", price: 8900, stock: 5, size: "Standard", imageUrl: "https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=500&auto=format&fit=crop&q=60")
    ]
    
    @State private var selectedItemIds: Set<UUID> = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                customHeaderSection
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Select items to process")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(RSMSColors.secondaryText)
                            .padding(.horizontal, RSMSSpacing.lg)
                            .padding(.top, RSMSSpacing.md)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(items) { item in
                                itemRow(item)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 120) // Give space for bottom bar
                    }
                }
            }
            
            // Bottom Action Bar
            bottomActionBar
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Invoice Items")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(invoiceId)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.md)
        .background(.regularMaterial)
    }
    
    // MARK: - Item Row
    private func itemRow(_ item: POSProduct) -> some View {
        let isSelected = selectedItemIds.contains(item.id)
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedItemIds.remove(item.id)
                } else {
                    selectedItemIds.insert(item.id)
                }
            }
        } label: {
            HStack(spacing: 16) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? RSMSColors.burgundy : RSMSColors.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(RSMSColors.burgundy)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Product Image
                AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                            .overlay(Image(systemName: "shippingbox").foregroundColor(.gray))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(item.category) • Size: \(item.size)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Text(formatIndianCurrency(item.price))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                }
                
                Spacer()
            }
            .padding(16)
            .background(RSMSColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? RSMSColors.burgundy : RSMSColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack {
            Button {
                path.append(POSFlowDestination.actionSelection(invoiceId: invoiceId, selectedItemIds: selectedItemIds))
            } label: {
                HStack {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Text("\(selectedItemIds.count) Selected")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(selectedItemIds.isEmpty ? RSMSColors.secondaryText.opacity(0.5) : RSMSColors.burgundy)
                .cornerRadius(16)
            }
            .disabled(selectedItemIds.isEmpty)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, RSMSSpacing.lg)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
        )
    }
}
